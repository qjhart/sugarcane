drop schema raster_stats cascade;
create schema raster_stats;
set search_path=raster_stats,public;

create table stats(file text, doy integer,count integer);            
\COPY stats(doy,file,count) from stats.csv with CSV

create view stats_histogram as with 
a as (
  select regexp_split_to_array(file,'\.') as a,doy,count 
  from stats
),
m as (
  select a[1] as modis,a[2] as year,doy,
  (avg(count))::integer as count 
  from a
  group by modis,year,doy
),
o as (
  select distinct modis,year from 
  m
),
days as (
  select * from o,generate_series(1,365) as doy
) 
select modis,year,doy,coalesce(count,0) as count 
from days 
left join m 
using (modis,year,doy) 
order by modis,year,doy;

create view stats_crosstab as
select * from crosstab (
'select doy,modis||year,count from stats_histogram order by 1',
'select distinct modis||year from stats_histogram') 
as 
(doy int, 
h12v112010 int,h12v112011 int,h12v112012 int,h12v112013 int,h12v112014 int,
h13v102010 int,h13v102011 int,h13v102012 int,h13v102013 int,h13v102014 int,
h13v112010 int,h13v112011 int,h13v112012 int,h13v112013 int,h13v112014 int);

create table masked_stats(file text, doy integer,count integer);
\COPY masked_stats(doy,file,count) from masked_stats.csv with CSV

create view masked_stats_histogram as with 
a as (
  select regexp_split_to_array(file,'\.') as a,doy,count 
  from masked_stats
),
m as (
  select a[1] as modis,a[2] as year,doy,
  (avg(count))::integer as count 
  from a
  group by modis,year,doy
),
o as (
  select distinct modis,year from 
  m
),
days as (
  select * from o,generate_series(1,365) as doy
) 
select modis,year,doy,coalesce(count,0) as count 
from days 
left join m 
using (modis,year,doy) 
order by modis,year,doy;

create or replace view masked_stats_crosstab as
select * from crosstab (
'select doy,modis||year,count from masked_stats_histogram order by 1',
'select distinct modis||year from masked_stats_histogram') 
as 
(doy int,
h12v112010 int,h12v112011 int,h12v112012 int,h12v112013 int,h12v112014 int,
h13v102010 int,h13v102011 int,h13v102012 int,h13v102013 int,h13v102014 int,
h13v112010 int,h13v112011 int,h13v112012 int,h13v112013 int,h13v112014 int);

create table burned_pixels (
modis_id varchar(8),
year integer,
month integer,
east float,
north float,
doy integer
);
\COPY burned_pixels(modis_id,year,month,east,north,doy) from burned_pixels.csv with csv header

create or replace view bp_stats as 
select 
modis_id,year,doy,count(*) 
from burned_pixels 
group by modis_id,year,doy;

create or replace view bp_stats_crosstab as
select * from crosstab (
'select doy,modis_id||year,count from bp_stats order by 1',
'select distinct modis_id||year from bp_stats') 
as 
(doy int, 
h09v072010 int,h09v072011 int,h09v072012 int,h09v072013 int,h09v072014 int,
h12v112010 int,h12v112011 int,h12v112012 int,h12v112013 int,h12v112014 int,
h13v102010 int,h13v102011 int,h13v102012 int,h13v102013 int,h13v102014 int,
h13v112010 int,h13v112011 int,h13v112012 int,h13v112013 int,h13v112014 int);

drop table modis_burned_stats cascade;
create table modis_burned_stats as 
with o as (
 select modis_id,year,avg(doy)::integer as doy_offset
 from burned_pixels
 group by modis_id,year
)
select modis_id,year,count(*),doy_offset,
avg(doy-doy_offset)::integer,
stddev_samp(doy-doy_offset)::integer as stddev 
from burned_pixels join o using (modis_id,year)
group by modis_id,year,doy_offset
order by modis_id,year;

drop table burned_boundary;
create table burned_boundary as
 select distinct east,north,
 st_setsrid(st_envelope(st_makebox2d(
  st_makepoint(east-(463.31271653/2),north-(463.31271653/2)),
  st_makepoint(east+(463.31271653/2),north+(463.31271653/2)))),
  96842) as boundary
 from burned_pixels;
create index burned_boundary_east_north on burned_boundary(east,north);
create index burned_boundary_boundary on burned_boundary USING GIST(boundary);

drop table if exists burned;
create table burned as
with b as (
 select modis_id,year,east,north,string_agg(doy::text,',') as doys 
 from burned_pixels group by modis_id,year,east,north
),
s as (
 select modis_id,year,east,north,min(doy-doy_offset)+doy_offset,
 CASE WHEN( min(doy-doy_offset)>=avg-stddev 
        and min(doy-doy_offset)<=avg+stddev) 
      THEN true ELSE false END as std,
 CASE WHEN( min(doy-doy_offset)>=avg-2*stddev 
        and min(doy-doy_offset)<=avg+2*stddev) 
      THEN true ELSE false END as std2,
 CASE WHEN( min(doy-doy_offset)>=avg-3*stddev 
        and min(doy-doy_offset)<=avg+3*stddev) 
      THEN true ELSE false END as std3
from burned_pixels 
join modis_burned_stats using (modis_id,year)
group by modis_id,year,east,north,doy_offset,avg,stddev
)
select modis_id,year,east,north,std,std2,std3,doys 
from b join s using (modis_id,year,east,north);

create index burned_east_north on burned(east,north);

drop table burned_kml_folders;
create table burned_kml_folders as
select modis_id,year,
kml.feature('Folder',string_agg(
 kml.feature('Placemark',st_asKML(boundary),'('||doys||')','',
  'pixelModis',hstore(burned)),'\n'
 ),
 'MODIS Burn Pixels, id:'||modis_id||' year:'||year,
 'These comprise all the pixels burned in '||year||' from '||modis_id||'.'
) as folder
from burned
join burned_boundary using (east,north) group by modis_id,year;


insert into burned_kml_folders (modis_id,year,folder)
select null,year,
kml.feature('Folder',
 string_agg(folder,'\n'),
 'MODIS Burn Pixels, year:'||year,
 'This Folder contains all burned pixels for '||year||'.'
)
from burned_kml_folders group by year;

\COPY (select kml.file(kml.feature('Document',folder)) from burned_kml_folders where modis_id='h09v07' and year=2014) to ~/h09v07_2014.kml with csv quote '|'

\COPY (select kml.file(kml.feature('Document',folder)) from burned_kml_folders where modis_id is null and year=2014) to ~/burned_2014.kml with csv quote '|'

