-- Special one time function

--update public.ITT set name=name||' (ITT)';
--update public.ITT set name=name||' (ITB)';
update ITT set name='SANTA MARIA (ITT)' where name='SANTA MARIA';

truncate carb.fields cascade;

with 
polys as (
 select name,wkb_geometry as p from public.itb 
 union  
 select name,wkb_geometry as p from public.itt),
pc as (
 select name,st_isValid(p) as v,p,st_convexHull(p) as c 
 from polys) 
insert into carb.fields (field_id,unmodified,boundary,buffered) 
select name,bool_or(v) as unmodified,
st_multi(st_buffer(st_transform(st_collect(CASE WHEN (v is true) THEN p ELSE c END),96842),0)),
st_multi(st_union(st_buffer(st_transform(CASE WHEN (v is true) THEN p ELSE c END,96842),50))) 
as boundary 
from pc 
group by name 
order by name;

insert into carb.fields (field_id,unmodified,boundary,buffered) 
 select field_id,false,
 st_multi(st_Union(st_transform(wkb_geometry,96842))) as boundary, 
 st_multi(st_Union(st_transform(wkb_geometry,96842))) as buffered 
from public.fields 
group by field_id;

-- USM data
update usm set name='T0212316100' where name='T02123161';
update usm set name='T0143257009' where name='T014325709';
-- All valid after buffering....

insert into carb.fields (field_id,unmodified,boundary,buffered) 
select farm||' (USM)',true as unmodified,
st_multi(st_buffer(st_transform(st_collect(wkb_geometry),96842),0)),
st_multi(st_union(st_buffer(st_transform(wkb_geometry,96842),50))) 
as boundary 
from usmshp
group by farm 
order by farm;

insert into fields_modis select * from fields_modis_v;

