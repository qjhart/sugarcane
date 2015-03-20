create table pixel_location as
with a as (
 select distinct east,north
 from burned_pixels
)
select east,north,
st_transform(st_setsrid(st_makepoint(east,north),96842),4269) as centroid
from a;

create index pixel_location_centroid_gix ON final_report.pixel_location USING GIST (centroid);

create materialized view pixel_locale as
select
east,north,iso,name_1
from pixel_location join country.adm1 on st_contains(geom,centroid);

create index pixel_locale_east_north on pixel_locale(east,north);

create materialized view region_stats as 
select 
name_1,year,doy,count(*) 
from burned_pixels join pixel_locale using (east,north)
where name_1 in
('Goiás','Mato Grosso','Mato Grosso do Sul','Minas Gerais',
'Paraná','São Paulo','Guanacaste')
group by name_1,year,doy;

create or replace view region_stats_crosstab as
select * from crosstab (
'select doy/7 as week,name_1||year,sum(count) from region_stats group by doy/7,name_1||year order by 1,2',
'select distinct name_1||year from region_stats order by 1') 
as 
(doy int,
Goiás_2011 int,Goiás_2012 int,Goiás_2013 int,Goiás_2014 int,
Guanacaste_2011 int,Guanacaste_2012 int,Guanacaste_2013 int,Guanacaste_2014 int,
Mato_Grosso_2011 int,Mato_Grosso_2012 int,Mato_Grosso_2013 int,Mato_Grosso_2014 int,
MG_do_Sul_2011 int,MG_do_Sul_2012 int,MG_do_Sul_2013 int,MG_do_Sul_2014 int,
Minas_Gerais_2011 int,Minas_Gerais_2012 int,Minas_Gerais_2013 int,Minas_Gerais_2014 int,
Paraná_2011 int,Paraná_2012 int,Paraná_2013 int,Paraná_2014 int,
São_Paulo_2011 int,São_Paulo_2012 int,São_Paulo_2013 int,São_Paulo_2014 int
);

create or replace view region_total_crosstab as 
select * from crosstab (
'select name_1,year,sum(count) as count from region_stats group by name_1,year order by name_1,year',
'select distinct year from region_stats order by 1')
as
(region text,"2011" int,"2012" int,"2013" int,"2014" int);

--\COPY (select * from region_stats_crosstab) to regional_burned_statistics.csv with csv header

create table region_burned_stats as 
with o as (
 select name_1,year,avg(doy)::integer as doy_offset
 from burned_pixels join pixel_locale using (east,north)
 group by name_1,year
)
select name_1,year,count(*),doy_offset,
avg(doy-doy_offset)::integer,
stddev_samp(doy-doy_offset)::integer as stddev 
from burned_pixels join pixel_locale using (east,north)
join o using (name_1,year)
group by name_1,year,doy_offset
order by name_1,year;

create view region_burned_stats_crosstab as
select * from crosstab (
'select name_1,year,doy_offset from region_burned_stats'||
' where name_1 in (''Goiás'',''Mato Grosso'',''Mato Grosso do Sul'',''Minas Gerais'','||
'''Paraná'',''São Paulo'',''Guanacaste'') order by name_1,year',
'select distinct year from region_burned_stats order by 1')
as
(region text,"2011" int,"2012" int,"2013" int,"2014" int);


drop table if exists burned_by_region;
create table burned_by_region as
with b as (
 select iso,name_1,year,east,north,string_agg(doy::text,',') as doys 
 from burned_pixels join pixel_locale using (east,north)
 group by iso,name_1,year,east,north
),
s as (
 select name_1,year,east,north,min(doy-doy_offset)+doy_offset,
 CASE WHEN( min(doy-doy_offset)>=avg-stddev 
        and min(doy-doy_offset)<=avg+stddev) 
      THEN true ELSE false END as std,
 CASE WHEN( min(doy-doy_offset)>=avg-2*stddev 
        and min(doy-doy_offset)<=avg+2*stddev) 
      THEN true ELSE false END as std2,
 CASE WHEN( min(doy-doy_offset)>=avg-3*stddev 
        and min(doy-doy_offset)<=avg+3*stddev) 
      THEN true ELSE false END as std3
from burned_pixels join pixel_locale using (east,north) 
join region_burned_stats using (name_1,year)
group by name_1,year,east,north,doy_offset,avg,stddev
)
select iso,name_1,year,east,north,std,std2,std3,doys,boundary
from b join s using (name_1,year,east,north)
join burned_boundary  using (east,north)
where name_1 in
('Goiás','Mato Grosso','Mato Grosso do Sul','Minas Gerais',
'Paraná','São Paulo','Guanacaste');


create index burned_by_region_east_north on burned(east,north);

drop table burned_region_kml_folders cascade;
create table burned_region_kml_folders as
select name_1,year,
kml.feature('Folder',string_agg(
 kml.feature('Placemark',st_asKML(boundary),'('||doys||')','',
  'pixelModis',hstore(burned_by_region)),'\n'
 ),
 'MODIS Burn Pixels, id:'||name_1||' year:'||year,
 'These comprise all the pixels burned in '||year||' from '||name_1||'.'
) as folder
from burned_by_region
group by name_1,year;

create view burned_region_kml_files as
select
name_1,
kml.file(kml.feature('Document',string_agg(folder,''))) as file
from burned_region_kml_folders
group by name_1;

create view burned_region_kml_files_by_year as
select
year,
kml.file(kml.feature('Document',string_agg(folder,''))) as file
from burned_region_kml_folders
group by year;


\COPY (select file from burned_region_kml_files where name_1='Goiás') to ~/goias.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso') to ~/mato_grosso.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso do Sul') to ~/mato_grosso_do_sul.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='Minas Gerais') to ~/minas_gerais.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='Paraná') to ~/parana.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='São Paulo') to ~/sao_paulo.kml with csv quote '|'
\COPY (select file from burned_region_kml_files where name_1='Guanacaste') to ~/guanacaste.kml with csv quote '|'
-- \set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/goias.kml`

\COPY (select file from burned_region_kml_files_by_year where year=2011) to ~/2011.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/2011.kml`
\COPY (select file from burned_region_kml_files_by_year where year=2012) to ~/2012.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/2012.kml`
\COPY (select file from burned_region_kml_files_by_year where year=2013) to ~/2013.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/2013.kml`
\COPY (select file from burned_region_kml_files_by_year where year=2014) to ~/2014.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/2014.kml`
