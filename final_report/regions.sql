-- Updates to the country data.
create view country.adm1_quad as
with p as (
 select name_1,
 st_xmin(geom) as w,st_xmax(geom) as e,
 st_ymin(geom) as s,st_ymax(geom) as n
 from country.adm1
 ),
b as (
 select name_1,'sw' as quad,st_makepoint(w,s) as ws,st_makepoint((w+e)/2.0,(s+n)/2.0) as en
 from p union
 select name_1,'se' as quad,st_makepoint((w+e)/2.0,s) as ws,st_makepoint(e,(s+n)/2.0) as en
 from p union
 select name_1,'nw' as quad,st_makepoint(w,(s+n)/2.0) as ws,st_makepoint((w+e)/2.0,n) as en
 from p union
 select name_1,'ne' as quad,st_makepoint((w+e)/2.0,(s+n)/2.0) as ws,st_makepoint(e,n) as en
 from p
)
select name_1,quad,st_setsrid(st_makebox2d(ws,en),4269) as box from b;

create materialized view country.adm2_quad as
select iso,a1.name_1,quad,name_2,a2.geom
from country.adm1_quad a1 join country.adm2 a2 on
(a1.name_1=a2.name_1 and st_contains(a1.box,st_centroid(a2.geom)));  

create index adm2_quad_gix ON country.adm2_quad USING GIST (geom);

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
east,north,iso,name_1,quad,name_2
from pixel_location join country.adm2_quad on st_contains(geom,centroid);

create index pixel_locale_east_north on pixel_locale(east,north);

create materialized view region_stats as 
select 
name_1,name_2,year,doy,count(*) 
from burned_pixels join pixel_locale using (east,north)
where name_1 in
('Goiás','Mato Grosso','Mato Grosso do Sul','Minas Gerais',
'Paraná','São Paulo','Guanacaste')
group by name_1,name_2,year,doy;

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

create materialized view region_burned_stats as 
with o as (
 select name_1,year,avg(doy)::integer as doy_offset
 from burned_pixels join pixel_locale using (east,north)
 group by name_1,quad,year
),
o2 as (
select name_1,quad,year,
doy_offset+avg(doy-doy_offset)::integer as doy_offset
from burned_pixels join pixel_locale using (east,north)
join o using (name_1,year)
group by name_1,quad,year,doy_offset
)
select name_1,quad,year,count(*),doy_offset,
stddev_samp(doy-doy_offset)::integer as stddev 
from burned_pixels join pixel_locale using (east,north)
join o2 using (name_1,quad,year)
group by name_1,quad,year,doy_offset
order by name_1,quad,year;

create view region_burned_stats_crosstab as
select * from crosstab (
'select name_1,year,doy_offset from region_burned_stats'||
' where name_1 in (''Goiás'',''Mato Grosso'',''Mato Grosso do Sul'',''Minas Gerais'','||
'''Paraná'',''São Paulo'',''Guanacaste'') order by name_1,year',
'select distinct year from region_burned_stats order by 1')
as
(region text,"2011" int,"2012" int,"2013" int,"2014" int);


create materialized view burned_by_region as
with b as (
 select iso,name_1,quad,year,east,north,string_agg(doy::text,',') as doys 
 from burned_pixels join pixel_locale using (east,north)
 group by iso,name_1,quad,year,east,north
),
s as (
 select name_1,quad,year,east,north,min(doy-doy_offset)+doy_offset,
 CASE WHEN( min(doy-doy_offset)>=-stddev 
        and min(doy-doy_offset)<=+stddev) 
      THEN true ELSE false END as std,
 CASE WHEN( min(doy-doy_offset)>=-2*stddev 
        and min(doy-doy_offset)<=+2*stddev) 
      THEN true ELSE false END as std2,
 CASE WHEN( min(doy-doy_offset)>=-3*stddev 
        and min(doy-doy_offset)<=+3*stddev) 
      THEN true ELSE false END as std3
from burned_pixels join pixel_locale using (east,north) 
join region_burned_stats using (name_1,quad,year)
group by name_1,quad,year,east,north,doy_offset,stddev
),
b2 as (
 select iso,name_1,year,east,north,string_agg(doy::text,',') as doys 
 from burned_pixels join pixel_locale using (east,north)
 group by iso,name_1,year,east,north
),
s2 as (
 select name_1,year,east,north,min(doy-doy_offset)+doy_offset,
 CASE WHEN( min(doy-doy_offset)>=-stddev 
        and min(doy-doy_offset)<=+stddev) 
      THEN true ELSE false END as std,
 CASE WHEN( min(doy-doy_offset)>=-2*stddev 
        and min(doy-doy_offset)<=+2*stddev) 
      THEN true ELSE false END as std2,
 CASE WHEN( min(doy-doy_offset)>=-3*stddev 
        and min(doy-doy_offset)<=+3*stddev) 
      THEN true ELSE false END as std3
from burned_pixels join pixel_locale using (east,north) 
join region_burned_stats using (name_1,year)
group by name_1,year,east,north,doy_offset,stddev
)
select iso,name_1,quad,year,east,north,std,std2,std3,doys,boundary
from b join s using (name_1,quad,year,east,north)
join burned_boundary  using (east,north)
where name_1 in
('Goiás','Mato Grosso')
union
select iso,name_1,'',year,east,north,std,std2,std3,doys,boundary
from b2 join s2 using (name_1,year,east,north)
join burned_boundary  using (east,north)
where name_1 in
('Mato Grosso do Sul','Minas Gerais','Paraná','São Paulo','Guanacaste');

create index burned_by_region_east_north on burned+by_region(east,north);

drop table burned_region_kml_folders cascade;
create table burned_region_kml_folders as
select iso,name_1,quad,year,
kml.feature('Folder',string_agg(
 kml.feature('Placemark',st_asKML(boundary),'('||doys||')','',
  'pixelModis',hstore(burned_by_region)),'\n'
 ),
 iso,name_1||'-'||quad||','||year,
 'These comprise all the pixels burned in '||year||' from State:'||name_1||' Municipality:'||quad||'.'
) as folder
from burned_by_region
group by iso,name_1,quad,year;

create view burned_region_kml_files as
select
iso,name_1,quad,
kml.file(kml.feature('Document',string_agg(folder,'' order by year))) as file
from burned_region_kml_folders
group by iso,name_1,quad;

create view copy_regions as
select iso,name_1,quad,
 '\COPY (select file from burned_region_kml_files where name_1='''||name_1||''' and quad='''||quad||''') to ~/'||replace(name_1,' ','_')||'/'||replace(quad,' ','_')||'goias.kml with csv quote ''|''' as copy
from burned_region_kml_files;


\COPY (select file from burned_region_kml_files where name_1='Goiás' and quad='sw') to ~/goias_sw.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/goias_sw.kml`
\COPY (select file from burned_region_kml_files where name_1='Goiás' and quad='se') to ~/goias_se.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/goias_se.kml`
\COPY (select file from burned_region_kml_files where name_1='Goiás' and quad='nw') to ~/goias_nw.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/goias_nw.kml`
\COPY (select file from burned_region_kml_files where name_1='Goiás' and quad='ne') to ~/goias_ne.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/goias_ne.kml`
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso'and quad='sw') to ~/mato_grosso_sw.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/mato_grosso_sw.kml`
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso'and quad='se') to ~/mato_grosso_se.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/mato_grosso_se.kml`
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso'and quad='nw') to ~/mato_grosso_nw.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/mato_grosso_nw.kml`
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso'and quad='ne') to ~/mato_grosso_ne.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/mato_grosso_ne.kml`
\COPY (select file from burned_region_kml_files where name_1='Mato Grosso do Sul') to ~/mato_grosso_do_sul.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/mato_grosso_do_sul.kml`
\COPY (select file from burned_region_kml_files where name_1='Minas Gerais') to ~/minas_gerais.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/minas_gerais.kml`
\COPY (select file from burned_region_kml_files where name_1='Paraná') to ~/parana.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/parana.kml`
\COPY (select file from burned_region_kml_files where name_1='São Paulo') to ~/sao_paulo.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/sao_paulo.kml`
\COPY (select file from burned_region_kml_files where name_1='Guanacaste') to ~/guanacaste.kml with csv quote '|'
\set foo `perl -i -p -e 's/^\|//; s/\|$$//' ~/guanacaste.kml`

