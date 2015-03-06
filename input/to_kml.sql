set search_path=carb,kml,public;
--\set pixels :in/modis_pixels.csv
--\set kml :in/:field.kml
--\set sum :in/:field_summary.csv

truncate carb.field_modis_pixels
\COPY field_modis_pixels (x,y,field_id,c,r,modis_id,year,vals) from :in/modis_pixels.csv  WITH CSV

\copy (select kml.file(doc) from kml_sugarcane) to :in/:field.kml CSV QUOTE '|'

\COPY (select field_id,year,hectares,array_to_string(modis_ids,',') as modis,pixels,total as burned_pixels,array_to_string(julian,'+') as days_burned,array_to_string(count,',') as num_burned from field_modis_info left join field_modis_burns using (field_id) order by year desc,field_id) to :in/:field_summary.csv WITH CSV HEADER



