#! /usr/bin/make -f 
SHELL = /bin/bash

# Link from our setup
ifndef configure.mk
include ../configure.mk
endif

field:=destilaria_alcidia
in:=UAL_fazendas_SAD69

db/input.${field}:
	${OGR} -overwrite -nln input.${field} -nlt MULTIPOLYGON ${in}.shp '${in}'
	[[ -d $(dir $@) ]] || mkdir $(dir $@)
	touch $@

db/carb.fields: db/input.${field}
	${PG} --variable=field=${field} -f ${field}.sql
	touch $@

# Run in grass ~/projects/sugarcane/modis/MCD45A1
${field}.csv:
	modis_id=$$(${PG} -t -F' ' -A -P footer -c 'select distinct modis_id from carb.fields_modis'); \
	for t in $${modis_id}; do \
	  g.region rast=$${t}.2011.01.01; \
	  files=$$(g.mlist separator=',' type=rast pattern=$${t}.*); \
	  ${PG} -t -F' ' -A -P footer -c "select * from carb.rwhatinput('$${t}')" |\
	   r.what input=$${files} null='' | grep -v '||||' |\
	    tr '|' ',' | sed -e "s/$${t},/$${t},\"{/" -e 's/$$/}"/'; \
	done > $@

${field}.kml: ${field}.csv
	cat ../to_kml.sql | sed -e 's/:field/${field}/g' | ${PG} -f -
