set search_path=modis,public;
\set srid 96842

create table products (
       product_id serial primary key,
       name varchar(32) unique,
       base text,
       description text
);
COPY products (product_id,name,base,description) from STDIN WITH CSV;
1,MCD45A1.005,ftp://e4ftl01.cr.usgs.gov/MODIS_Composites/MOTA/,MODIS Burned Area Product
\.

create table product_dirs (
       product_dir_id serial primary key,
       product_id integer references products,
       date date,
       files text[],
       unique(product_id,date)
);

create or replace function add_product_dir(integer,date) RETURNS VOID as 
$$
 insert into product_dirs (product_id,date,files) 
select $1,$2,
string_to_array(curl_l(base||'/'||name||'/'||
regexp_replace($2::text,'-','.','g')||'/'),E'\n') 
from products where product_id=$1
$$ LANGUAGE 'SQL';

with f as (
 select product_id,date,unnest(files) as file 
 from product_dirs
),
v(tile) as (VALUES ('h13v11'),('h13v10')) 
select date,tile,base||p.name||'/'||replace(date::text,'-','.')||'/'||file 
as url 
from f 
join products p 
using (product_id),v 
where file 
like '%.'||tile||'.%.hdf';


create table modis (
modis_id varchar(8) primary key,
h integer,
v integer,
w double precision,
n double precision,
e double precision,
s double precision,
nsres double precision,
ewres double precision
);

--h12v11,12,11,-6671703.118,-2223901.039,-5559752.598,-3335851.559
--h13v11,13,11,-5559752.598,-2223901.039,-4447802.079,-3335851.559
--h13v10...
COPY modis (modis_id,h,v,n,s,w,e,nsres,ewres) from STDIN WITH CSV;
h12v11,12,11,-2223901.039333,-3335851.559,-5559752.598333,-6671703.118,463.31271653,463.31271653
h13v11,13,11,-2223901.039333,-3335851.559,-4447802.078667,-5559752.598333,463.31271653,463.31271653
h13v10,13,10,-1111950.519667,-2223901.039333,-4447802.078667,-5559752.598333,463.31271653,463.31271653
\.

create table templates (
modis_id varchar(8) primary key,
boundary geometry(POLYGON,96842),
rast raster);

insert into templates
select modis_id,
st_setsrid(
st_makebox2d(st_makepoint(w,s),
           st_makepoint(e,n)),96842) as boundary,
st_asRaster(
st_setsrid(
st_makebox2d(st_makepoint(w,s),
           st_makepoint(e,n)),
96842),2400,2400,'1BB') as rast
from modis m left join templates t using (modis_id)
where t is null;

select addrasterconstraints('modis'::name,'templates'::name,'rast'::name,'srid','pixel_types');

-- From http://gis.cri.fmach.it/modis-sinusoidal-gis-files/
--h12v11,-2232223,-3343334,-6686668,-5575557
--h13v11,-2232223,-3343334,-5575557,-4464446

--ogr2ogr -f "PostgreSQL" -nln fields -nlt POLYGON2D PG:"dbname=sugarcane" 'GFT:email=qjhart@gmail.com password=zsnnnsdhoessrudf tables=1f1Bb8L3Cc8dt-02W2pz9tmv5ebV68lyCD5WXv94' 1f1Bb8L3Cc8dt-02W2pz9tmv5ebV68lyCD5WXv94

alter table public.fields add unique(field_id);

select addgeometrycolumn('public','fields','boundary',96842,'POLYGON',2);
update fields set boundary=st_transform(wkb_geometry,96842);

create or replace view field_modis as 
WITH modis_rast as (
select field_id,modis_id,
st_asraster(st_intersection(t.boundary,f.boundary),t.rast) as rast,
(st_metadata(t.rast)).* 
from fields f
join modis.templates t 
on st_intersects(f.boundary,t.boundary))
select 
field_id,modis_id,
(((st_metadata(f.rast)).upperleftx-upperleftx)/scalex)::integer as dx,
(((st_metadata(f.rast)).upperlefty-upperlefty)/scaley)::integer as dy,
rast
from modis_rast f
order by field_id,modis_id;

CREATE OR REPLACE FUNCTION rwhatinput (modis_id varchar(8))
RETURNS TABLE (x float,y float,label text) AS 
$$
select st_x(c),st_y(c),field_id || '|' || x+dx || '|' || y+dy || '|' || $1
from 
(
 select field_id,dx,dy,st_centroid((st_pixelAsPolygons(rast)).geom) as c,
 (st_pixelAsPolygons(rast)).*
 from carb.fieldd_modis 
 where modis_id=$1
) as f
where val=1;
$$ LANGUAGE 'SQL';

-- GRASS 6.4.2 (modis):~/projects/sugarcane > for t in h12 h13; do g.region rast=${t}v11.2011.01.01; files=$(g.mlist separator=',' type=rast pattern=${t}v11.*); psql -t -F' ' -A -P footer -d sugarcane -c "select * from modis.rwhatinput('${t}v11')" | r.what input=${files} null=''; done | grep -v '||||' | tr '|' ',' | sed -e 's/v11,/v11,"{/' -e 's/$/}"/' > burn_pixels.csv


create table field_modis_pixels (
       field_modis_pixel_id serial primary key,
       x float,
       y float,
       field_id text references public.fields(field_id),
       modis_id varchar(8) references modis.templates(modis_id),
       c integer,
       r integer,
       vals integer[]
);


\COPY field_modis_pixels (x,y,field_id,c,r,modis_id,vals) 
from burn_pixels.csv WITH CSV

create view field_modis_counts as select field_id,modis_id,count(*) 
from field_modis_pixels group by field_id,modis_id;

create or replace view field_modis_pixel_all_burn_days as 
select field_modis_pixel_id,year,julian from 
( select field_modis_pixel_id,2010 as year,unnest(vals[1:12]) as julian 
  from field_modis_pixels
) as p where julian >0 and julian < 366
union
select field_modis_pixel_id,year,julian from 
( select field_modis_pixel_id,2011 as year,unnest(vals[13:24]) as julian 
  from field_modis_pixels
) as p where julian >0 and julian < 366
union
select field_modis_pixel_id,year,julian from 
( select field_modis_pixel_id,2012 as year,unnest(vals[25:36]) as julian 
  from field_modis_pixels
) as p where julian >0 and julian < 366
;

create or replace view field_modis_pixel_burns as 
select distinct b.* from field_modis_pixel_all_burn_days b 
left join 
(select distinct b2.* 
 from field_modis_pixel_all_burn_days b1 
 join field_modis_pixel_all_burn_days b2 
 using (field_modis_pixel_id,year) 
 where b1.julian < b2.julian and b2.julian-b1.julian <30
) as double 
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
  select field_id,year,julian,count(*) as count,
  sum(count(*)) over (partition by field_id,year order by julian) as cumulative
  from field_modis_pixel_burns 
  join field_modis_pixels 
  using (field_modis_pixel_id) 
  group by field_id,year,julian
) as bd
group by field_id,year order by field_id,year,julian;

create or replace view field_modis_info as 
select field_id,modis_ids,pixels,pixels*21.466 as hectares,boundary from
(
 select field_id,array_agg(modis_id) as modis_ids,
 sum(count) as pixels
 from field_modis join 
 field_modis_counts using (field_id,modis_id)
 group by field_id ) as f 
join 
(
  select field_id,st_collect(geom) as boundary from 
  (
   select field_id,(st_dumpAsPolygons(rast)).geom as geom 
   from field_modis) as f 
  group by field_id
) as b 
using (field_id);

create or replace view field_info as 
select field_id,modis_ids,boundary,
raster_boundary,pixels,
(st_area(boundary)/10000)::integer as hectares,
raster_hectares
from fields
left join
field_modis_info
using (field_id);

-- Outputing the Files:
-- All Pixels
create or replace view kml.all_pixels as 
select as_kmldoc(geom,name) as kml from 
(
 select distinct geom,modis_id||' ('||x||','||y||')' as name 
 from 
 (
  select modis_id,field_id,
  (st_pixelAsPolygons(rast)).* 
  from modis.field_modis
 ) as f 
 where val=1
) as pixels;

create view kml.burned_pixels as
select year,
as_kmldoc(st_pixelAsPolygon(rast,c,r),field_id,
          'Burned '|| year || '(' || julian || ')') as kml 
from field_modis_pixel_burns 
join field_modis_pixels using (field_modis_pixel_id) 
join field_modis using(field_id) 
group by year;

--\copy (select kml.join_kmldocs(array_agg(kml)) from kml.burned_pixels) to burned.kml


create view kml.pixelated_output as 
select year,
as_kmldoc(boundary,field_id,
'Burned Fraction:' || 1.0*b.total/pixels || 'Year:' || year ||
'Burn Days:' || array_to_string(julian,',')) as kml
from
modis.field_modis_info f left join
modis.field_modis_burns b
using (field_id);

create or replace view kml.pixelated_output as 
select year,
as_kmldoc(boundary,field_id,
('Burned Fraction:' || 1.0*b.total/pixels || 'Year:' || year ||
'Burn Days:' || array_to_string(julian,','))::varchar(2500)
) as kml
from
modis.field_modis_info f join
modis.field_modis_burns b
using (field_id)
group by year;

\copy (select kml.join_kmldocs(array_agg(kml)) from kml.pixelated_output) 
to rasterized.kml


