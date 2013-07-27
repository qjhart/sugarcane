set search_path=:kml,public;

drop foreign table :kml.styles;
create foreign table :kml.styles (
id text,
style text ) 
SERVER file_fdw_server 
OPTIONS (format 'csv', header 'true', 
filename :styles,
delimiter ',', null '');

drop foreign table :kml.stylemaps;
create foreign table :kml.stylemaps (
id text,
normal text,
highlight text
) 
SERVER file_fdw_server 
OPTIONS (format 'csv', header 'true', 
filename :stylemaps,
delimiter ',', null '');


create or replace function :kml.style_part() 
RETURNS text as $$
with s as (
 select '<Style id="'||id||'">'||style||'</Style>'
 as style from kml.styles),
m as (
 select 
'<StyleMap id="'||id||'">
<Pair>
 <key>normal</key>
 <styleUrl>#'||normal||'</styleUrl>
</Pair>
<Pair>
 <key>highlight</key>
 <styleUrl>#'||highlight||'</styleUrl>
</Pair>
</StyleMap>' as style from kml.stylemaps)
select string_agg(style,E'\n') as styles from
(select style from s 
union
select style from m) as s;

$$ LANGUAGE SQL IMMUTABLE STRICT;
