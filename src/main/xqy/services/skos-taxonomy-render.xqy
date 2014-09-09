xquery version "1.0-ml";

module namespace sktr = "http://marklogic.com/rest-api/resource/skos-taxonomy-render";

import module namespace search="http://marklogic.com/appservices/search"
  at "/MarkLogic/appservices/search/search.xqy";

declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace mlskos = "http://marklogic.com/skos";

declare option xdmp:mapping "false";

declare variable $CODEPOINT := "collation=http://marklogic.com/collation/codepoint";


declare function sktr:get(
  $context as map:map,
  $params  as map:map)
  as document-node()*
{
  let $query := map:get($params, "query")
  let $path := map:get($params, "path")

  let $query :=
    if (fn:string-length($query) > 0) then
      cts:query(search:parse($query))
    else
      cts:and-query(())

  let $depth :=
    if (fn:string-length($path) = 0) then
      1
    else
      fn:count(fn:tokenize($path, "\|")) + 1

  let $pattern :=
    if (fn:string-length($path) > 0) then
      fn:concat($depth, "_", $path, "|*")
    else
      "1_*"

  let $log := xdmp:log("pattern: " || $pattern)

  let $children := cts:element-value-match(xs:QName("mlskos:docpath"), $pattern, $CODEPOINT, $query)
  return
    document {
      let $array := json:array()
      let $_ :=
        for $child in $children
        let $count := cts:frequency($child)
        let $path := fn:replace($child, "^[0-9]*_", "")
        let $name := fn:tokenize($path, "\|")[fn:last()]
        let $map := map:map()
        let $_ := map:put($map, "name", $name)
        let $_ := map:put($map, "count", $count)
        let $_ := map:put($map, "path", $path)
        return json:array-push($array, sktr:json-object(("name", "count", "path"), $map))
      return xdmp:to-json($array)
    }
};


(: Builds a properly-ordered JSON object with no nulls :)
declare function sktr:json-object($names as xs:string*, $map as map:map)
{
  let $keys := map:keys($map)
  let $names :=
    for $name in $names
    return
      if ($name = $keys) then
        $name
      else
        ()
  let $obj := json:object-define($names)
  let $_ :=
    for $key in $keys
    return map:put($obj, $key, map:get($map, $key))
  return $obj
};