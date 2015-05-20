--create materialized view final_report.inputs as
create table final_report.inputs as
select 'adecoagro_monte_alegre' as farm,'2014-04-17'::date as date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.adecoagro_monte_alegre
union
select 'alta_mogiana',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.alta_mogiana
union
select 'alto_alegre_junqueira','2014-01-30'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.alto_alegre_junqueira
union
select 'biosev_lem','2014-10-01'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.biosev_lem
union
select 'biosev_sel','2014-10-01'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.biosev_sel
union
select 'biosev_umb','2014-10-01'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.biosev_umb
union
select 'biosev_vro','2014-10-01'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.biosev_vro
union
select 'bunge_frutal','2014-08-24'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.bunge_frutal
union
select 'bunge_ouroeste','2014-02-21'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.bunge_ouroeste
union
select 'cargill_mosaico','2013-11-19'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.cargill_mosaico
union
select 'catsa_costa_rica','2014-08-19'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.catsa_costa_rica
union
select 'conquista_do_pontal','2013-07-22'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.conquista_do_pontal
union
select 'copersucar','2013-07-22'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.copersucar
union
select 'copersucar_cerradao','2013-08-27'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.copersucar_cerradao
union
select 'destilaria_alcidia','2013-07-22'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.destilaria_alcidia
union
select 'itb',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.itb
union
select 'itt',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.itt
union
select 'jalles_machado','2015-01-29'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.jalles_machado
union
select 'meridiano','2013-07-02'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.meridiano
union
select 'noble_meridiano','2013-07-02'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.noble_meridiano
union
select 'noble_potireendaba','2013-07-10'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.noble_potireendaba
union
select 'odebrecht_alto_taquari','2013-10-10'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.odebrecht_alto_taquari
union
select 'parceria',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.parceria
union
select 'propia',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.propia
union
select 'raizen_costapinto','2013-08-20'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.raizen_costapinto
union
select 'renuka','2013-08-02'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.renuka
union
select 'santa_candida','2013-06-26'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.santa_candida
union
select 'sao_joao',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.sao_joao
union
select 'sao_luiz','2013-07-02'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.sao_luiz
union
select 'sao_martinho','2014-03-19'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.sao_martinho
union
select 'solazyme','2013-07-22'::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.solazyme
union
select 'usm',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.usm
union
select 'usmshp',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.usmshp
union
select 'vista_alegre',null::date,ogc_fid,
st_transform(wkb_geometry,4269) as boundary
from input.vista_alegre;

delete from inputs where st_npoints(boundary)<=3;

--create index inputs_centroid_gix ON final_report.inputs USING GIST (st_centroid(boundary));
create index inputs_gix ON final_report.inputs USING GIST (boundary);

-- This shows the various states where the fields are located.
create materialized view input_locale as
select farm,date,ogc_fid,iso,name_1,quad,boundary
from inputs join country.adm2_quad on st_contains(geom,st_centroid(boundary))
where date>'2014-01-01'::date
order by farm;

select farm as identifier,iso as country,name_1 as state,count(*)
from inputs join input_locale using (farm,ogc_fid) group by farm,iso,name_1 order by farm,iso,name_1; 

--select iso,name_1,count(*) from input_locale group by iso,name_1 order by iso,name_1;
-- iso |       name_1       | count
-- -----+--------------------+--------
-- BRA | Goiás              |   3476
-- BRA | Mato Grosso        |     70
-- BRA | Mato Grosso do Sul |   2528
-- BRA | Minas Gerais       |  17179
-- BRA | Paraná             |   6116
-- BRA | São Paulo          | 104037
-- CRI | Guanacaste         |   1467

