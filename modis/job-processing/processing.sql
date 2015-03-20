set search_path=money,modis,public;


create table jobs (
       job_id serial primary key,
       product_id integer references products,
       dates date[],
       modis_ids varchar(8)[],	-- References MODIS tiles
       fetched boolean DEFAULT False,
       pixeled boolean DEFAULT False
);
COPY jobs (job_id,product_id,dates,modis_ids) from STDIN WITH CSV;
1,1,"{2011-01-01,2011-02-01,2011-03-01,2011-04-01,2011-05-01,2011-06-01,2011-07-01,2011-08-01,2011-09-01,2011-10-01,2011-11-01,2011-12-01,2012-01-01,2012-02-01,2012-03-01,2012-04-01,2012-05-01,2012-06-01,2012-07-01,2012-08-01}","{h12v11,h13v12}",f,f
2,1,"{2011-01-01,2011-02-01,2011-03-01,2011-04-01,2011-05-01,2011-06-01,2011-07-01,2011-08-01,2011-09-01,2011-10-01,2011-11-01,2011-12-01,2012-01-01,2012-02-01,2012-03-01,2012-04-01,2012-05-01,2012-06-01,2012-07-01,2012-08-01}","{h12v11,h13v12}",f,f
3,1,"{2012-01-01,2012-02-01,2012-03-01,2012-04-01,2012-05-01,2012-06-01,2012-07-01,2012-08-01,2012-09-01}","{h12v11,h13v11,h13v10}",f,f
\.

create table job_files (
       job_file_id serial primary key,
       job_id integer references jobs,
       modis_id varchar(8) references modis.modis,
       files text[],
       unique(job_id,modis_id)
);

insert into money.job_files (job_id,modis_id,files) 
with d as (
 select job_id,unnest(dates) as date 
 from money.jobs 
 where job_id=3),
m as (
 select job_id,unnest(modis_ids) as modis_id 
 from money.jobs where job_id=3
)
select job_id,modis_id,
 array_agg(replace(date::text,'-','.')
        ||'/MCD45A1.'||modis_id||'.hdf') as files 
from d join m using (job_id) group by job_id,modis_id;

create table job_polygons (
       job_polygon_id serial primary key,
       job_id integer references jobs,
       polygon_id text,
       boundary geometry(MultiPolygon,96842),
       unique(job_id,polygon_id)
      );

insert into job_polygons (job_id,polygon_id,boundary) 
select 3,field_id,buffered from carb.fields;

create table job_pixel_array (
       job_id integer references jobs,
       modis_id varchar(8) references modis.modis,
       job_polygon_id integer references job_polygons,
       centroids geometry(Point,96842)[],
       pixels geometry(Point,0)[],
       vals int[][],
       unique(modis_id,job_polygon_id)
       );

insert into job_pixel_array (job_id,modis_id,job_polygon_id,pixels,centroids)
with p as (
 select modis_id,field_id,dx,dy,(st_pixelAsPolygons(rast)).*
 from carb.fields_modis
),
f as (
 select 3 as job_id,field_id as polygon_id, modis_id,
 st_centroid(geom) as centroid,st_makepoint(x+dx,y+dy) as pixel
 from p where val=1
)
select job_id,modis_id,job_polygon_id,array_agg(pixel) as pixels,
array_agg(centroid) as centroids 
from  f join job_polygons using (job_id,polygon_id)
group by job_id,modis_id,job_polygon_id;

       
create or replace function fetched ( jid integer, success boolean )
RETURNS TABLE (job_id integer, fetched boolean) AS 
$$
	update jobs set fetched=$2 where job_id=$1
	returning job_id,fetched;
$$ LANGUAGE 'SQL';

create or replace function pixeled ( jid integer, success boolean )
RETURNS TABLE (job_id integer, pixeled boolean) AS 
$$
	update jobs set pixeled=$2 where job_id=$1
	returning job_id,pixeled;
$$ LANGUAGE 'SQL';

