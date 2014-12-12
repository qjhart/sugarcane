#! /usr/bin/make  -f
# run by specifing the input  make in=foo
SHELL := /bin/bash

# MODIFIABLE Parameters
ifdef field.srs
S_SRS:=-s_srs ${field.srs} -a_srs ${field.srs}
else
S_SRS:=
endif

# OGR parameters
OGR:=ogr2ogr -f "PostgreSQL" PG:"dbname=sugarcane"
PG:=psql -d sugarcane

#DEFAULTS
years:=2012 2013
years_glob:=201[123]
field:=$(firstword $(subst ., ,${in}))
date:=$(lastword $(subst ., ,${in}))

buffer:=50
include ${in}/in.mk

INFO::
	@echo ${field} ${date}
	@echo "Years: ${years}"

.PHONY::input
input:${in}/input.${field}

ifeq (${field.data.type},SHP)

${in}/input.${field}:
#	${OGR} ${S_SRS} -overwrite -nln input.${field} -nlt MULTIPOLYGON ${field.data}.shp '$(notdir ${field.data})'
	${OGR} --config SHAPE_ENCODING "ISO-8859-2" ${S_SRS} -overwrite -nln input.${field} -nlt MULTIPOLYGON ${in}/${field.data}.shp '$(notdir ${field.data})' > $@
	${PG} -c '\d input.${field}' >> $@
	${PG} -c 'select count(*) from input.${field}' >> $@

else 
ifeq (${field.data.type},KML)
${in}/input.${field}:
	${OGR} --config SHAPE_ENCODING "ISO-8859-2" ${S_SRS} -overwrite -nln input.${field} -nlt MULTIPOLYGON ${in}/${field.data}.kml '$(notdir ${field.data})'
	${PG} -c '\d input.${field}' >> $@
	${PG} -c 'select count(*) from input.${field}' >> $@
else
${in}/input.${field}:
	@echo "Don't know field.data.type: ${field.data.type}"
endif
endif

.PHONY::carb.fields
carb.fields:${in}/carb.fields
${in}/carb.fields: ${in}/input.${field}
	${PG} --variable='name=${field.identifier}' --variable='field=${field}' --variable='buffer=${buffer}' -f carb.fields.sql > $@

# Run in grass ~/projects/sugarcane/modis/MCD45A1
${in}/${field}.csv:
	modis_id=$$(${PG} -t -F' ' -A -P footer -c 'select distinct modis_id from carb.fields_modis'); \
	for t in $${modis_id}; do \
	  g.region rast=$${t}.2012.01.01; \
	  files=$$(g.mlist separator=',' type=rast pattern=$${t}.${years_glob}.??.??); \
	  ${PG} -t -F' ' -A -P footer -c "select * from carb.rwhatinput('$${t}')" |\
	   r.what input=$${files} null='' | grep -v '||||' |\
	    tr '|' ',' | sed -e "s/$${t},/$${t},\"{/" -e 's/$$/}"/'; \
	done > $@

.PHONY::modis_pixels.csv
modis_pixels.csv:${in}/modis_pixels.csv
# Run in grass ~/projects/sugarcane/modis/MCD45A1
${in}/modis_pixels.csv:${in}/carb.fields
	modis_id=$$(${PG} -t -F' ' -A -P footer -c 'select distinct modis_id from carb.fields_modis'); \
	for t in $${modis_id}; do \
	  ${PG} -t -F' ' -A -P footer -c "select * from carb.rwhatinput('$${t}')" > ${in}/${field}.$${t}.in; \
	for y in ${years}; do \
	  g.region rast=$${t}.$${y}.01.01; \
	  files=$$(g.mlist separator=',' type=rast pattern=$${t}.$${y}.??.??); \
	  cat ${in}/${field}.$${t}.in | \
            r.what input=$${files} null='' | grep -v '||||' |\
	    tr '|' ',' | sed -e "s/$${t},/$${t},$${y},\"{/" -e 's/$$/}"/'; \
	done; done > $@

.PHONY::kml
kml:${in}/${field}.kml

${in}/${field}.kml: ${in}/modis_pixels.csv
#	${PG} --variable=in='${in}' --variable=field='${field}' -f to_kml.sql
	cat to_kml.sql | sed -e 's|:in|${in}|g' -e 's|:field|${field}|g' | ${PG} -f -
	perl -i -p -e 's/^\|//; s/\|$$//' $@

