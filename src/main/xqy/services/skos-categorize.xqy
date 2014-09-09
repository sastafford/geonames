xquery version "1.0-ml";

module namespace skcat = "http://marklogic.com/rest-api/resource/skos-categorize";

import module namespace skoslib = "http://marklogic.com/solutions/lib-skos"
  at "/ext/skos/lib/lib-skos.xqy";

declare option xdmp:mapping "false";


declare function skcat:get(
  $context as map:map,
  $params  as map:map)
  as document-node()*
{
	let $text := map:get($params, "text")
  let $doc := <doc>{ $text }</doc>
  return skoslib:categorize($doc, $params)
};

declare function skcat:post(
  $context as map:map,
  $params as map:map,
  $input as document-node()*)
  as document-node()*
{
  let $doc := $input/*[1]
  return skoslib:categorize($doc, $params)
};

