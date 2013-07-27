#! /usr/bin/make -f 

# Link from our setup
ifndef configure.mk
include ../configure.mk
endif

db/input.santa_candida:
	${OGR} -overwrite -nln input.santa_candida -nlt MULTIPOLYGON UN_SANTA_CANDIDA/MOSAICO/WGS84/MOSAICO_TONON_USC_3.shp 'MOSAICO_TONON_USC_3'
	touch $@

db/santa_candida.carb.fields: db/santa_candida.sql
	${PG} -f santa_candida.sql
	touch $@

db/input.vista_alegre:
	${OGR} -overwrite -nln input.vista_alegre -nlt MULTIPOLYGON UN_VISTA_ALEGRE/MOSAICO/WGS84/MOSAICO_TONON_UVA_3.shp 'MOSAICO_TONON_UVA_3'
	touch $@
