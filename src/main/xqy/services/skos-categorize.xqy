xquery version "1.0-ml";

module namespace skcat = "http://marklogic.com/rest-api/resource/skos-categorize";

(: import module namespace skoslib = "http://geonames.org" at "/ext/skos/lib/lib-skos.xqy"; :)

declare namespace rdf = "http://www.w3.org/1999/02/22-rdf-syntax-ns#";
declare namespace skos = "http://www.w3.org/2004/02/skos/core#";
declare namespace mlskos = "http://marklogic.com/skos";

declare option xdmp:mapping "false";


declare function skcat:get(
  $context as map:map,
  $params  as map:map)
  as document-node()*
{
	let $text := map:get($params, "text")
  let $doc := <doc>{ $text }</doc>
  return skcat:categories($doc, $params)
};

declare function skcat:post(
  $context as map:map,
  $params as map:map,
  $input as document-node()*)
  as document-node()*
{
  let $doc := $input/*[1]
  return skcat:categories($doc, $params)
};

declare function skcat:categories($doc as element(), $params as map:map)
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