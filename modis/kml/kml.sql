-- http://blog.mackerron.com/2010/09/29/as_kmldoc/
CREATE OR REPLACE FUNCTION :kml.escape(TEXT)
RETURNS TEXT AS $$
  SELECT replace(replace(replace($1, '&', '&amp;'), '<', '&lt;'), '>', '&gt;');
$$ LANGUAGE sql IMMUTABLE STRICT;

DROP TYPE :kml.featuretype CASCADE;
CREATE TYPE :kml.featuretype AS ENUM ('Placemark','Folder', 'Document');

CREATE OR REPLACE FUNCTION :kml.feature(
type :kml.featuretype,
kml text default '',
name text default '',
description text default '',
styleUrl text default '',
data hstore default ''::hstore,
display hstore default ''::hstore)
RETURNS TEXT AS $$
SELECT
'<' || $1 || '>' ||
CASE WHEN (length($3) >0) THEN
       '<name>' || kml.escape($3) || '</name>'
  ELSE '' END ||
--CASE WHEN ($6 is Null) THEN
-- '' ELSE
kml.hstoreToExtendedData($6,$7) 
-- END ||
||
  CASE WHEN (length($5)>0) THEN
  '<styleUrl>' || kml.escape($5) || '</styleUrl>' 
  ELSE '' END || 
  CASE WHEN (length($4)>0) THEN
  '<description>' || kml.escape($4) || '</description>' 
  ELSE '' END || 
  $2 ||
  '</' || $1 || '>';
$$ LANGUAGE sql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION :kml.file(
feature text default '<!--FeatureLess-->',
networkLinkControl text default '<!--NetworkLinkControlless-->'
)
RETURNS TEXT AS $$
SELECT
   E'<?xml version="1.0" encoding="UTF-8"?>
<kml xmlns="http://www.opengis.net/kml/2.2" 
     xmlns:gx="http://www.google.com/kml/ext/2.2" 
     xmlns:kml="http://www.opengis.net/kml/2.2" 
     xmlns:atom="http://www.w3.org/2005/Atom">\n' ||
    COALESCE($1,'<!--Featureless-->') || E'\n' || 
    COALESCE($2,'<!--NetworkLinkControlless-->') || E'\n</kml>';
$$ LANGUAGE sql IMMUTABLE STRICT;

CREATE OR REPLACE FUNCTION 
:kml.hstoreToExtendedData(data hstore,dis hstore default ''::hstore)
RETURNS TEXT AS $$
with kv as (
 select (each($1)).*
) 
select coalesce(E'<ExtendedData>\n'||
string_agg('<Data name="'||key||'">'||
CASE WHEN (($2->key) is Not Null) THEN
'<displayName>'||($2->key)||E'</displayName>\n'
ELSE '' END ||
'<value>'||value||'</value></Data>',E'\n')||E'\n</ExtendedData>','')
from kv;
$$ LANGUAGE sql IMMUTABLE STRICT;
