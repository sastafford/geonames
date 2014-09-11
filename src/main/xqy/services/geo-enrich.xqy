xquery version "1.0-ml";

module namespace geo = "http://marklogic.com/rest-api/resource/geo-enrich";

import module namespace libg = "http://geonames.org" at "/ext/geonames/lib/lib-geonames.xqy";
import module namespace json="http://marklogic.com/xdmp/json" at "/MarkLogic/json/json.xqy";

declare namespace fc = "http://geonames.org/featureCodes";
declare namespace gn = "http://geonames.org";
declare namespace html = "http://www.w3.org/1999/xhtml";

declare option xdmp:mapping "false";

declare variable $HIGHEST-POPULATION := fn:false();
declare variable $ONLY-POSITIVE-POPULATION := fn:false();

declare variable $USE-POPULATION := $HIGHEST-POPULATION or $ONLY-POSITIVE-POPULATION;


declare function geo:get(
  $context as map:map,
  $params  as map:map)
  as document-node()*
{
	let $doc :=
    <html xmlns="http://www.w3.org/1999/xhtml">
      <head />
      <body>
        <p>{ map:get($params, "text") }</p>
      </body>
    </html>
  let $format as xs:string? := map:get($params, "format")
	let $country-codes as xs:string? := map:get($params, "country-code")
  let $country-codes :=
    for $code in $country-codes
    return fn:tokenize($code, ",")

  let $feature-types as xs:string? := map:get($params, "feature-type")
  let $feature-types :=
    for $ft in $feature-types
    return fn:tokenize($ft, ",")

  let $geos :=
    if (fn:exists($country-codes) and fn:exists($feature-types)) then
      cts:search(/gn:geoname[gn:country-code = $country-codes and fc:feature-code/fc:name = $feature-types],
        cts:reverse-query($doc), "unfiltered")
    else if (fn:exists($country-codes)) then
      cts:search(/gn:geoname[gn:country-code = $country-codes],
        cts:reverse-query($doc), "unfiltered")
    else if (fn:exists($feature-types)) then
      cts:search(/gn:geoname[fc:feature-code/fc:name = $feature-types],
        cts:reverse-query($doc), "unfiltered")
    else
      cts:search(/gn:geoname, cts:reverse-query($doc), "unfiltered")
  let $doc as document-node()* := geo:highlight-and-summary($doc, $geos)
  return
    if (fn:exists($format) and $format = "json") then
      let $config := json:config("custom")
      let $_ := map:put($config, "array-element-names", (
        xs:QName("geonamegroup"),
        fn:QName("http://geonames.org", "geoname"),
        fn:QName("http://geonames.org", "name"),
        fn:QName("http://geonames.org/admin1Code", "name"),
        fn:QName("http://geonames.org/admin2Code", "name")
      ))
      let $_ := map:put($context,"output-types","application/json")

      return document { text { json:transform-to-json(element summary { $doc/summary/*, element query {xdmp:quote($doc//*:p) } }, $config) } }
    else $doc


};

declare function geo:post(
  $context as map:map,
  $params as map:map,
  $input as document-node()*)
  as document-node()*
{
  let $doc := $input/*[1]

  let $country-codes as xs:string? := map:get($params, "country-code")
  let $country-codes :=
    for $code in $country-codes
    return fn:tokenize($code, ",")

  let $feature-types as xs:string? := map:get($params, "feature-type")
  let $feature-types :=
    for $ft in $feature-types
    return fn:tokenize($ft, ",")

  let $geos :=
    if (fn:exists($country-codes) and fn:exists($feature-types)) then
      cts:search(/gn:geoname[gn:country-code = $country-codes and fc:feature-code/fc:name = $feature-types],
        cts:reverse-query($doc), "unfiltered")
    else if (fn:exists($country-codes)) then
      cts:search(/gn:geoname[gn:country-code = $country-codes],
        cts:reverse-query($doc), "unfiltered")
    else if (fn:exists($feature-types)) then
      cts:search(/gn:geoname[fc:feature-code/fc:name = $feature-types],
        cts:reverse-query($doc), "unfiltered")
    else
      cts:search(/gn:geoname, cts:reverse-query($doc), "unfiltered")

  return geo:highlight-and-summary($doc, $geos)
};

declare function geo:highlight-and-summary($doc as element(), $geos as item()*)
  as document-node()
{
  if (fn:empty($geos)) then
    document { $doc, <summary/> }
  else
    (: get matching geonames as element, not document-node :)
    let $geos :=
      for $geo in $geos
      return
        if ($geo instance of document-node()) then
          $geo/geo:geoname
        else
          $geo

    (: construct a map of query text to geoname ids with that text :)
    let $all-text-id-map := map:map()
    let $_ :=
      for $geo in $geos
      let $id := $geo/fn:data(gn:id)
      let $texts := $geo/gn:query//fn:data(cts:text)
      let $texts := libg:filter-names($texts)
      for $text in $texts
      return map:put($all-text-id-map, $text, ($id, map:get($all-text-id-map, $text)))

    (: get the query texts as a sequence and sort on descending length :)
    let $texts := map:keys($all-text-id-map)
    let $texts :=
      for $text in $texts
      order by fn:string-length($text) descending
      return $text

    (: construct a map of query text that matches the document to the geoname ids with that text. :)
    let $matching-text-id-map := map:map()
    let $match-superstring-map := map:map()
    let $_ :=
      for $text in $texts
      let $current-matches := map:keys($matching-text-id-map)
      let $_ :=
        for $word in $current-matches
        return
          if (fn:contains($word, $text)) then
            map:put($match-superstring-map, $text, ($word, map:get($match-superstring-map, $text)))
          else
            ()
      let $superstrings := map:get($match-superstring-map, $text)
      let $query := geo:not-in-query($text, $superstrings)
      return
        if (cts:contains($doc, $query)) then
          let $ids := map:get($all-text-id-map, $text)
          let $ids :=
            if ($USE-POPULATION) then
              geo:population-filter($ids)
            else
              $ids
          return
            if (fn:empty($ids)) then
              ()
            else
              map:put($matching-text-id-map, $text, $ids)
        else
          ()

    (: get the matching query texts as a sequence and sort on descending length :)
    let $texts := map:keys($matching-text-id-map)
    let $texts :=
      for $text in $texts
      order by fn:string-length($text) descending
      return $text

    (: highlight in order of descending length to minimize broken-up highlighting spans :)
    let $_ :=
      for $text in $texts
      (: get the ids and sort them (aesthetic) :)
      let $ids := map:get($matching-text-id-map, $text)
      let $ids :=
        for $id in $ids
        order by xs:integer($id)
        return $id
      (: use previously-calculated super strings to build not-in-query,
         e.g. highlight "York City", but not if it's a part of "New York City" :)
      let $superstrings := map:get($match-superstring-map, $text)
      let $query := geo:not-in-query($text, $superstrings)
      return
        xdmp:set($doc,
          cts:highlight(
            $doc,
            $query,
            <span xmlns="http://www.w3.org/1999/xhtml"
              class="{ if (fn:count($ids) > 1) then "many" else "one" }"
              geonames-id="{ fn:string-join($ids, ",") }">{ $cts:text }</span>
          )
        )

  let $doc := geo:collapse-spans($doc, ())

  let $spans := $doc//html:span[@geonames-id]
  (: construct a map of geonames-ids and the number of times they occur in the document :)
  let $id-count-map := map:map()
  let $_ :=
    for $span in $spans
    let $ids := fn:tokenize($span/fn:data(@geonames-id), ",")
    for $id in $ids
    return
      if (map:contains($id-count-map, $id)) then
        map:put($id-count-map, $id, map:get($id-count-map, $id) + 1)
      else
        map:put($id-count-map, $id, 1)

  (: construct a map of matching text to the number of times they occur in the document :)
  let $match-count-map := map:map()
  let $_ :=
    for $text in map:keys($matching-text-id-map)
    let $count := fn:count($doc//html:span[@geonames-id and . = $text])
    return map:put($match-count-map, $text, $count)

  (: get the inverse map, count to id :)
  let $count-match-map := -$match-count-map
  let $counts := map:keys($count-match-map)

  (: sort the counts from high to low so that we can show the results in count order :)
  let $counts :=
    for $count in $counts
    order by xs:integer($count) descending
    return $count

  (: construct a map of feature-code/name (aka feature-type) to the ids of that feature type :)
  let $feature-type-id-map := map:map()
  let $_ :=
    for $id in map:keys($id-count-map)
    let $feature-type := /gn:geoname[gn:id = $id]/fc:feature-code/fn:data(fc:name)
    let $feature-type :=
      if (fn:string-length($feature-type) = 0) then
        "NO FEATURE CODE NAME ?"
      else
        $feature-type
    return
      map:put($feature-type-id-map, $feature-type,
        ($id, map:get($feature-type-id-map, $feature-type)))

  let $summary :=
    element summary {
      element id-counts {
        for $count in $counts
        let $matches := map:get($count-match-map, $count)
        for $match in $matches
        return
          element geonamegroup {
            element querymatch { $match },
            element count { $count },
            element geonameidlist {
              let $ids := map:get($matching-text-id-map, $match)
              return /gn:geoname[gn:id = $ids]
            }
          }
      },
      element by-feature-type {
        for $feature-type in map:keys($feature-type-id-map)
        let $ids := map:get($feature-type-id-map, $feature-type)
        return
          element feature-type {
            element name { $feature-type },
            element geonames-ids {
              for $id in $ids
              return
                element geonames-id {
                  $id
                }
            }
          }
      }
    }

    return document { $doc, $summary }
};

declare function geo:population-filter($ids as xs:string+) as xs:string*
{
  let $max := fn:max(/gn:geoname[gn:id = $ids]/xs:integer(gn:population))
  return
    if ($ONLY-POSITIVE-POPULATION and $max = 0) then
      ()
    else if ($HIGHEST-POPULATION) then
      /gn:geoname[gn:id = $ids and gn:population = $max]/fn:data(gn:id)
    else
      $ids
};

declare function geo:not-in-query($text as xs:string, $superstrings as xs:string*)
  as cts:query
{
  if (fn:exists($superstrings)) then
    cts:not-in-query(
      cts:word-query($text, "exact"),
      cts:word-query($superstrings, "exact")
    )
  else
    cts:word-query($text, "exact")
};

declare function geo:collapse-spans($x as node()?, $map as map:map?)
{
  if (fn:empty($x)) then
    ()
  else
  typeswitch ($x)

  case element(html:span) return
    (: if there's one node child and it's a span element, we have nested spans :)
    if (fn:count($x/node()) = 1 and fn:exists($x/element()) and fn:local-name($x/element()) = "span") then
      let $inner := geo:collapse-spans($x/element(), $map)
      return
        <span xmlns="http://www.w3.org/1999/xhtml">
        {
          attribute geonames-id { fn:string-join(($x/@geonames-id, $inner/@geonames-id), ",") },
          attribute class { "many" },
          $inner/node()
        }
        </span>
    else
      geo:preserve-and-recurse($x, $map)

  case element() return
    geo:preserve-and-recurse($x, $map)

  case document-node() return
    geo:collapse-spans($x/*[1], $map)

  case processing-instruction() return
    $x

  case comment() return
    $x

  case text() return
    $x

  default return
    geo:preserve-and-recurse($x, $map)
};


declare function geo:transform-children($x as element(), $arg) as node()*
{
  for $z in $x/node()
  return geo:collapse-spans($z, $arg)
};

declare function geo:preserve-and-recurse($x as element(), $arg) as element()
{
  element { fn:node-name($x) }
  {
    $x/attribute::*,
    geo:transform-children($x, $arg)
  }
};
