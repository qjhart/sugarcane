#! /usr/bin/make -f 

# Link from our setup
ifndef configure.mk
include ../configure.mk
endif

field:=copersucar
in:=Mapa_Geral

db/input.${field}_str:
	${OGR} -overwrite -nln input.${field} -nlt LINESTRING ${in}.shp '${in}'
	touch $@

db/input.${field}:
#	${OGR} -overwrite -nln input.${field} -nlt MULTIPOLYGON ${in}.shp '${in}'
	touch $@

db/${field}.carb.fields: db/input.${field}
	${PG} -f ${field}.sql
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
	${PG} -f ../to_kml.sql
