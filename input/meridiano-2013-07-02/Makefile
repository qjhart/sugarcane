#! /usr/bin/make -f 

# Link from our setup
ifndef configure.mk
include ../configure.mk
endif

db/input.meridiano:
	${OGR} -overwrite -nln input.meridiano -nlt MULTIPOLYGON UM_1.shp 'UM_1'
	touch $@

db/meridiano.carb.fields: db/input.meridiano
	${PG} -f meridiano.sql
	touch $@

# Run in grass ~/projects/sugarcane/modis/MCD45A1
meridiano.csv:
	modis_id=$$(${PG} -t -F' ' -A -P footer -c 'select distinct modis_id from carb.fields_modis'); \
	for t in $${modis_id}; do \
	  g.region rast=$${t}.2011.01.01; \
	  files=$$(g.mlist separator=',' type=rast pattern=$${t}.*); \
	  ${PG} -t -F' ' -A -P footer -c "select * from carb.rwhatinput('$${t}')" |\
	   r.what input=$${files} null='' | grep -v '||||' |\
	    tr '|' ',' | sed -e "s/$${t},/$${t},\"{/" -e 's/$$/}"/'; \
	done > $@

meridiano.kml: meridiano.csv
	${PG} -f to_kml.sql
