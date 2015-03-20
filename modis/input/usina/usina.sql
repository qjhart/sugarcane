-- harvest information
create table usina_harvest (
Property text,
Sector text,
Found text,
Farm text,
Grid text,
Plot text,
Variety text,
Category text,
TotalArea float,
ProductionArea float,
PercentMechanization text,
Effective text,
MechanizedArea float,
ManualMechanization float,
mechTons text,
manTons text,
TCH float,
System text);

\COPY usina_harvest from input/usina/harvest.csv with CSV HEADER

create or replace temp view pro as 
with x as (
 select ogc_fid,xmlparse(CONTENT description) as xml 
 from public.propia), 
kv as ( 
 select ogc_fid,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[1]/text()',xml)) as k,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[2]/text()',xml)) as v
 from x)
select ogc_fid,hstore(
       array_agg(xmlserialize(CONTENT k as text)),
       array_agg(xmlserialize(CONTENT v as text))) as hs
from kv group by ogc_fid;

create or replace temp view par as 
with x as (
 select ogc_fid,xmlparse(CONTENT description) as xml 
 from public.parceria), 
kv as ( 
 select ogc_fid,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[1]/text()',xml)) as k,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[2]/text()',xml)) as v
 from x)
select ogc_fid,hstore(
       array_agg(xmlserialize(CONTENT k as text)),
       array_agg(xmlserialize(CONTENT v as text))) as hs
from kv group by ogc_fid;

create or replace temp view propar as 
select * from pro 
union 
select * from par;           

truncate carb.fields restart identity;
with i as (
select hs->'Chave' as name,st_isValid(wkb_geometry) as v,
 wkb_geometry from pro join propia using (ogc_fid)
union
select CASE WHEN ((hs->'Chave')='205711004' and (hs->'Talhao'='1003')) THEN
'205711003-4' ELSE hs->'Chave' END as name,
st_isValid(wkb_geometry) as v,
wkb_geometry from par join parceria using (ogc_fid)
)
insert into carb.fields(field_id,unmodified,boundary,buffered) 
select name,v,
st_multi(st_transform(
 case when (v is true) 
      then wkb_geometry 
      else st_buffer(wkb_geometry,0) end ,96842)),
st_multi(
  st_buffer(st_transform(st_buffer(wkb_geometry,0),96842),50))
from i;

truncate fields_modis;
insert into fields_modis select * from fields_modis_v;

-- Now go back to carb.sql, and fill in field_modis_pixels with:
for t in h13v11; do g.region rast=${t}.2011.01.01; files=$(g.mlist separator=',' type=rast pattern=${t}.*); psql -t -F' ' -A -P footer -d sugarcane -c "\set search_path=carb,public; select * from carb.rwhatinput('${t}')" | r.what input=${files} null='' | grep -v '||||' | tr '|' ',' | sed -e "s/${t},/${t},\"{/" -e 's/$/}"/'; done > usina.csv 

-- \COPY field_modis_pixels (x,y,field_id,c,r,modis_id,vals) from input/usina/usina.csv WITH CSV

--\copy (select kml.file(doc) from kml_sugarcane) to input/usina/sugarcane.kml CSV QUOTE '|'

--\COPY (select field_id,year,hectares,array_to_string(modis_ids,',') as modis,pixels,total as burned_pixels,array_to_string(julian,',') as days_burned,array_to_string(count,',') as num_burned from field_modis_info left join field_modis_burns using (field_id) order by year desc,field_id) to input/usina/summary.csv


