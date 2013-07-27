truncate carb.fields restart identity cascade;
with i as (
select cod_faz as name,st_isValid(wkb_geometry) as v,
 wkb_geometry from input.vista_alegre where st_npoints(wkb_geometry) > 3)
insert into carb.fields(field_id,unmodified,boundary,buffered) 
select name,bool_or(v),
st_multi(st_union(st_buffer(st_transform(
 case when (v is true) 
      then wkb_geometry 
      else st_buffer(wkb_geometry,0) end ,96842),1))
),
st_multi(
st_union(
  st_buffer(st_transform(st_buffer(wkb_geometry,0),96842),50))
)
from i group by name;


truncate fields_modis;
insert into fields_modis select * from fields_modis_v ;

-- Now go back to workflow (carb.sql), and fill in field_modis_pixels with:
-- grass ~/projects/sugarcane/modis/MCD45A1
-- for t in h12v11; do g.region rast=${t}.2011.01.01; files=$(g.mlist separator=',' type=rast pattern=${t}.*); psql -t -F' ' -A -P footer -d sugarcane -c "\set search_path=carb,public; select * from carb.rwhatinput('${t}')" | r.what input=${files} null='' | grep -v '||||' | tr '|' ',' | sed -e "s/${t},/${t},\"{/" -e 's/$/}"/'; done > vista_alegre.csv 

-- \COPY field_modis_pixels (x,y,field_id,c,r,modis_id,vals) from input/un_santa_candida_2013-06-26/vista_alegre.csv WITH CSV

--\copy (select kml.file(doc) from kml_sugarcane) to input/un_santa_candida_2013-06-26/vista_alegre.kml CSV QUOTE '|'

--\COPY (select field_id,year,hectares,array_to_string(modis_ids,',') as modis,pixels,total as burned_pixels,array_to_string(julian,',') as days_burned,array_to_string(count,',') as num_burned from field_modis_info left join field_modis_burns using (field_id) order by year desc,field_id) to input/un_santa_candida_2013-06-26/vista_alegre_summary.csv CSV HEADER



