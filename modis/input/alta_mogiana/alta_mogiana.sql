-- harvest information
create table alta_mogiana_harvest (
Property integer,
CCIR text,
Name text,
ATM float,
ATNM float,
AMSF float,
ANMSF float,
AREA float,
fraction float
);

\COPY alta_mogiana_harvest from input/alta_mogiana/info.csv with CSV HEADER

create or replace temp view tab as 
with x as (
 select ogc_fid,xmlparse(CONTENT description) as xml 
 from public.alta_mogiana), 
kv as ( 
 select ogc_fid,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[1]/text()',xml)) as k,
 unnest(xpath('/html/body/table/tr/td/table//tr/td[2]/text()',xml)) as v
 from x)
select ogc_fid,hstore(
       array_agg(xmlserialize(CONTENT k as text)),
       array_agg(xmlserialize(CONTENT v as text))) as hs
from kv group by ogc_fid;

truncate carb.fields restart identity cascade;
with i as (
select hs->'RECORD_ID' as name,st_isValid(wkb_geometry) as v,
 wkb_geometry from tab join alta_mogiana using (ogc_fid)
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
-- for t in h13v11; do g.region rast=${t}.2011.01.01; files=$(g.mlist separator=',' type=rast pattern=${t}.*); psql -t -F' ' -A -P footer -d sugarcane -c "\set search_path=carb,public; select * from carb.rwhatinput('${t}')" | r.what input=${files} null='' | grep -v '||||' | tr '|' ',' | sed -e "s/${t},/${t},\"{/" -e 's/$/}"/'; done > usina.csv 

-- \COPY field_modis_pixels (x,y,field_id,c,r,modis_id,vals) from input/alta_mogiana/alta_mogiana.csv WITH CSV

--\copy (select kml.file(doc) from kml_sugarcane) to input/alta_mogiana/sugarcane.kml CSV QUOTE '|'

--\COPY (select field_id,year,hectares,array_to_string(modis_ids,',') as modis,pixels,total as burned_pixels,array_to_string(julian,',') as days_burned,array_to_string(count,',') as num_burned from field_modis_info left join field_modis_burns using (field_id) order by year desc,field_id) to input/alta_mogiana/summary.csv


