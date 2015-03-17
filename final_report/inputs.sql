create materialized view final_report.inputs as
select 'adecoagro_monte_alegre',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.adecoagro_monte_alegre
union
select 'alta_mogiana',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.alta_mogiana
union
select 'alto_alegre_junqueira',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.alto_alegre_junqueira
union
select 'biosev_lem',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.biosev_lem
union
select 'biosev_sel',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.biosev_sel
union
select 'biosev_umb',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.biosev_umb
union
select 'biosev_vro',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.biosev_vro
union
select 'bunge_frutal',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.bunge_frutal
union
select 'bunge_ouroeste',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.bunge_ouroeste
union
select 'cargill_mosaico',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.cargill_mosaico
union
select 'catsa_costa_rica',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.catsa_costa_rica
union
select 'conquista_do_pontal',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.conquista_do_pontal
union
select 'copersucar',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.copersucar
union
select 'copersucar_cerradao',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.copersucar_cerradao
union
select 'destilaria_alcidia',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.destilaria_alcidia
union
select 'itb',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.itb
union
select 'itt',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.itt
union
select 'jalles_machado',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.jalles_machado
union
select 'meridiano',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.meridiano
union
select 'noble_meridiano',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.noble_meridiano
union
select 'noble_potireendaba',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.noble_potireendaba
union
select 'odebrecht_alto_taquari',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.odebrecht_alto_taquari
union
select 'parceria',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.parceria
union
select 'propia',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.propia
union
select 'raizen_costapinto',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.raizen_costapinto
union
select 'renuka',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.renuka
union
select 'santa_candida',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.santa_candida
union
select 'sao_joao',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.sao_joao
union
select 'sao_luiz',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.sao_luiz
union
select 'sao_martinho',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.sao_martinho
union
select 'solazyme',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.solazyme
union
select 'usm',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.usm
union
select 'usmshp',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.usmshp
union
select 'vista_alegre',ogc_fid,
st_envelope(st_transform(wkb_geometry,4269)) as env
from input.vista_alegre


create index adm1_gix ON country.adm1 USING GIST (geom);
create index inputs_centroid_gix ON final_report.inputs USING GIST (st_centroid(env));
create index inputs_gix ON final_report.inputs USING GIST (env)

-- This shows the various states where the fields are located.
create materialized view input_locale as
select farm,ogc_fid,iso,name_1
from inputs join country.adm1 on st_contains(geom,st_centroid(env))
order by farm;


select farm as identifier,iso as country,name_1 as state,count(*) from inputs join input_locale using (farm,ogc_fid) group by farm,iso,name_1 order by farm,iso,name_1; 

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

