--\set buffer 150

truncate carb.fields restart identity cascade;
with i as (
select :name as name,st_isValid(wkb_geometry) as v,
 wkb_geometry from input.:"field")
insert into carb.fields(field_id,unmodified,boundary,buffered) 
select name,bool_or(v),
st_multi(st_union(st_buffer(st_transform(
 case when (v is true) 
      then wkb_geometry 
      else st_buffer(wkb_geometry,0) end ,96842),1))
),
st_multi(
st_union(
  st_buffer(st_transform(st_buffer(wkb_geometry,0),96842),:buffer))
)
from i group by name;

select 'buffer size:'||:buffer;
select count(*) from carb.fields; 

truncate carb.fields_modis;
insert into carb.fields_modis select * from carb.fields_modis_v ;

select count(*) from carb.fields_modis;
select distinct modis_id from carb.fields_modis;
