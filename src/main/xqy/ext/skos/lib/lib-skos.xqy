xquery version "1.0-ml";

module namespace skoslib = "http://marklogic.com/solutions/lib-skos";

declare namespace mlskos = "http://marklogic.com/skos";
declare namespace owl = "http://www.w3.org/2002/07/owl#";
declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";

declare option xdmp:mapping "false";

declare variable $SKIP-DEPRECATED-CATEGORIES := fn:true();


declare function skoslib:insert-rdf-from-file($filepath as xs:string) as empty-sequence()
{
  let $rdf := xdmp:document-get($filepath,
    <options xmlns="xdmp:document-get"><format>xml</format></options>)/*
  return skoslib:insert-rdf($rdf)
};

declare function skoslib:insert-rdf($rdf as element(rdf:RDF)) as empty-sequence()
{
  for $desc in $rdf/rdf:Description
  let $about := $desc/fn:data(@rdf:about)
  return
    if ($desc/owl:deprecated = "true" and $SKIP-DEPRECATED-CATEGORIES) then
      ()
    else
      xdmp:document-insert($about, $desc)
};

(: the RDF Description docs must all be in the database before running this (skoslib:insert-rdf) :)
declare function skoslib:add-paths-and-query()
{
  for $desc in /rdf:Description
  let $about := $desc/fn:string(@rdf:about)
  let $paths := skoslib:paths($desc)
  let $labels :=
    for $label in ($desc/fn:data(skos:prefLabel), $desc/fn:data(skos:altLabel))
    return fn:lower-case($label)
  let $query := cts:word-query($labels)
  return
  (
    xdmp:node-insert-child($desc, <mlskos:query>{ $query }</mlskos:query>)
    ,
    for $path in $paths
    return xdmp:node-insert-child($desc, <mlskos:path>{ $path }</mlskos:path>)
  )
};

declare function skoslib:paths($desc as element(rdf:Description)) as xs:string*
{
  let $about := $desc/fn:data(@rdf:about)
  let $broaders := $desc/skos:broader/fn:data(@rdf:resource)
  let $label := fn:normalize-space($desc/fn:data(skos:prefLabel))
  return
    if (fn:exists($broaders)) then
      let $parents := /rdf:Description[@rdf:about = $broaders]
      return
        if (fn:empty($parents)) then
          fn:error((), "Parent not found: " || $broaders)
        else
          for $parent in $parents
          for $parent-path in skoslib:paths($parent)
          return
            fn:string-join(
              ($parent-path, $label),
              "|"
            )
    else
      $label
};

declare function skoslib:categorize($doc as element(), $params as map:map)
  as document-node()
{
  let $hits := cts:search(/rdf:Description, cts:reverse-query($doc), "unfiltered")
  let $log := xdmp:log("hits: " || fn:count($hits))
  let $paths :=
    for $hit in $hits
    return $hit/mlskos:path
  let $docpaths :=
    fn:distinct-values(
      for $path in $paths
      let $parts := fn:tokenize($path, "\|")
      let $count := fn:count($parts)
      for $i in (1 to $count)
      return fn:concat($i, "_", fn:string-join(fn:subsequence($parts, 1, $i), "|"))
    )
  let $docpaths :=
    for $docpath in $docpaths
    return <mlskos:docpath>{ $docpath }</mlskos:docpath>
  return
    document {
      element mlskos:paths {
        $paths, $docpaths
      }
    }
};
