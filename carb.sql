drop schema carb cascade;
create schema carb;
set search_path=carb,public;

create table fields (
       field_id varchar(254) primary key,
       unmodified boolean,
       boundary geometry('MultiPolygon',96842),
       buffered geometry('MultiPolygon',96842)
);

create or replace view fields_modis_v as 
WITH modis_rast as (
select field_id,modis_id,
st_asraster(st_intersection(t.boundary,f.buffered),t.rast) as rast,
(st_metadata(t.rast)).* 
from fields f
join modis.templates t 
on st_intersects(f.boundary,t.boundary)
where st_isvalid(f.boundary) is true)
select 
field_id,modis_id,
(((st_metadata(f.rast)).upperleftx-upperleftx)/scalex)::integer as dx,
(((st_metadata(f.rast)).upperlefty-upperlefty)/scaley)::integer as dy,
rast
from modis_rast f
order by field_id,modis_id;

create table fields_modis as select * from fields_modis_v limit 0;

-- This is replaced with in POSTGIS rasters...
CREATE OR REPLACE FUNCTION rwhatinput (modis_id varchar(8))
RETURNS TABLE (x float,y float,label text) AS 
$$
select st_x(c),st_y(c),'"'|| field_id || '"|' || 
x+dx || '|' || y+dy || '|' || $1
from 
(
 select field_id,dx,dy,st_centroid((st_pixelAsPolygons(rast)).geom) as c,
 (st_pixelAsPolygons(rast)).*
 from carb.fields_modis 
 where modis_id=$1
) as f
where val=1;
$$ LANGUAGE 'SQL';

create table field_modis_pixels (
       field_modis_pixel_id serial primary key,
       x float,
       y float,
       field_id text references fields(field_id),
       modis_id varchar(8) references modis.templates(modis_id),
       year integer,
       c integer,
       r integer,
       vals integer[]
);

-- \COPY field_modis_pixels (x,y,field_id,c,r,modis_id,vals) from burn_pixels.csv WITH CSV

create or replace view field_modis_pixel_burns as 
with j as (
 select field_modis_pixel_id,year,unnest(vals[1:12]) as julian
 from field_modis_pixels
),
field_modis_pixel_all_burn_days as (
 select field_modis_pixel_id,year,julian
 from j
 where julian >0 and julian < 366
),
double as (
 select distinct b2.* 
 from field_modis_pixel_all_burn_days b1 
 join field_modis_pixel_all_burn_days b2 
 using (field_modis_pixel_id,year) 
 where b1.julian < b2.julian and b2.julian-b1.julian <30
)
select distinct b.* from field_modis_pixel_all_burn_days b 
left join double
using (field_modis_pixel_id,year,julian) 
where double is null 
order by field_modis_pixel_id,julian;

create or replace view field_modis_burns as 
select field_id,year,array_agg(julian) as julian,
array_agg(count) as count,
array_agg(cumulative) as cumulative,
max(cumulative) as total 
from 
(
  select field_id,p.year,julian,count(*) as count,
  sum(count(*)) over (partition by field_id,p.year order by julian) as cumulative
  from field_modis_pixel_burns b 
  join field_modis_pixels p 
  using (field_modis_pixel_id) 
  group by field_id,p.year,julian
) as bd
group by field_id,year order by field_id,year,julian;

create or replace view field_modis_info as 
with 
bounds as (
  select field_id,st_collect(geom) as boundary from 
  (
   select field_id,(st_dumpAsPolygons(rast)).geom as geom 
   from fields_modis) as f 
  group by field_id
),
field_modis_counts as (
 select field_id,modis_id,count(*) as count
 from field_modis_pixels group by field_id,modis_id
),
counts as (
 select field_id,array_agg(modis_id) as modis_ids,
 sum(count) as pixels
 from fields_modis join 
 field_modis_counts using (field_id,modis_id)
 group by field_id )
select field_id,modis_ids,pixels,pixels*21.466 as hectares,boundary from
counts 
join bounds
using (field_id);

create or replace view kml_input as 
select 
kml.feature('Folder',
 kml.feature('Folder',
 string_agg(kml.feature('Placemark',st_asKML(boundary),field_id,'','fieldIn',
 hstore('unmodified',unmodified::text)),E'\n'),
 'Input Fields',
 'These are the fields used for input in the processing'
)||kml.feature('Folder',
 string_agg(kml.feature('Placemark',st_asKML(buffered),field_id,'','fieldBuf',
 hstore('unmodified',unmodified::text)),E'\n'),
 'Buffered Fields',
 'These fields are buffered by 50 meters and used in the pixel selection',
  'fieldBuf'
),'Input Farms')
 as folder from fields;

-- All Pixels
create or replace view kml_pixels as 
WITH f as (
  select modis_id,field_id,dx,dy,
  (st_pixelAsPolygons(rast)).* 
  from fields_modis
 ),
pixels as (
 select distinct geom,modis_id||' ('||x+dx||','||y+dy||')' as name,
 hstore('col',(x+dx)::text)||hstore('row',(y+dy)::text)||
 hstore('modis_id',modis_id) as hs
 from f
 where val=1
)
select kml.feature('Folder',
 string_agg(kml.feature('Placemark',st_asKML(geom),name,'','pixelModis',hs),E'\n'),
 'MODIS MCD451 Pixels',
 'These are all the pixels examined in the processing calculations') as folder 
from pixels;

create or replace view kml_burned as
WITH y as (
 select kml.feature('Folder',
 string_agg(kml.feature('Placemark',st_asKML(st_pixelAsPolygon(rast,c,r)),
  field_id,'','pixelBurn',
  hstore('col',c::text)||hstore('row',r::text)||hstore('modis_id',modis_id)||
  hstore('julian',julian::text),
  hstore('col','MCD45A1 Column')||hstore('row','MCD45A1 Row')||
  hstore('modis_id','MCD45A1 Tile')||
  hstore('julian','Julian Day')),E'\n'),
  p.year::text,'Burned MCD45A1 pixels for ' || p.year) as f
 from field_modis_pixel_burns 
 join field_modis_pixels p using (field_modis_pixel_id) 
 join modis.templates using (modis_id) 
 group by p.year)
 select kml.feature('Folder',string_agg(f,E'\n'),
       'Burned Pixels','Burned MCD45A1 Pixels arranged by year') as folder
 from y;

create or replace view kml_rasterized as 
WITH y as (
 select kml.feature('Folder',
 string_agg(kml.feature('Placemark',st_asKML(f.boundary),
 field_id,'','fieldBurn',
 hstore('field_id',field_id)||
 hstore('modis_id',array_to_string(f.modis_ids,', '))||
 hstore('pixels',f.pixels::text)||
 hstore('hectares',f.hectares::decimal(10,2)::text)||  
 hstore('burned_fraction',(1.0*b.total/pixels)::decimal(6,2)::text)||
 hstore('year',year::text)||hstore('days',array_to_string(b.julian,','))||
 hstore('count',array_to_string(b.count,','))||
 hstore('cumulative',array_to_string(b.cumulative,','))||
 hstore('total',b.total::text),
 hstore('field_id','Field Identifier')||hstore('modis_id','MCD45A1 Tiles')||
 hstore('pixels','Total Pixels')||hstore('hectares','Rasterized Hectares')||  
 hstore('burned_fraction','Field Burned Fraction')||
 hstore('year','Year')||hstore('days','Julian Days')||
 hstore('count','Pixels Burned (per Julian Day)')||
 hstore('cumulative','Cumulative Pixels Burned (per Julian Day)')||
 hstore('total','Total Pixels Burned')),E'\n'),
 year::text,'Field Burn Summary for ' || year) as f
 from
 field_modis_info f join
 field_modis_burns b
 using (field_id)
 group by year)
 select kml.feature('Folder',string_agg(f,E'\n'),
        'Burned Fields','Burned Field Summary arranged by year') as folder
 from y;

create or replace view carb.kml_results as 
select kml.feature('Folder',string_agg(folder,E'\n'),
     'MCD45A1','MCD45A1 MODIS Burned Pixel Product processing output') 
     as folder
from (select folder from carb.kml_pixels 
union
select folder from carb.kml_burned
union 
select folder from carb.kml_rasterized) as o;

create or replace view carb.kml_sugarcane as 
select kml.feature('Document',kml.style_part()||string_agg(folder,E'\n'),
'Sugarcane Example',
'This example shows the use of MODIS Burned area pixels 
 to determine the mechanized harvesting for the CARB sugarcane ethanol') as doc
from (
select folder from carb.kml_input
union
select folder from carb.kml_results) as f;

--\copy (select kml.file(doc) from kml_sugarcane) to sugarcane.kml CSV QUOTE '|'

--\COPY (select field_id,year,hectares,array_to_string(modis_ids,',') as modis,pixels,total as burned_pixels,array_to_string(julian,',') as days_burned,array_to_string(count,',') as num_burned from field_modis_info left join field_modis_burns using (field_id) order by year desc,field_id) to summary.csv



