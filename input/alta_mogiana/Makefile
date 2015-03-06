#! /usr/bin/make -f 

# Link from our setup
ifndef configure.mk
include ../configure.mk
endif

db/alta_mogiana:
db/alta_mogiana:
	unzip -p usina_alta_mogiana.kmz | perl -i.bak -n -e 's|<td></td>|<td>#EMPTY#</td>|g;' -e 'print unless (m|<META http-equiv="Content-Type" content="text/html">|)' > usina_alta_mogiana.kml
	${OGR} -overwrite -nln alta_mogiana -nlt MULTIPOLYGON usina_alta_mogiana.kml 'faz_UsinaAltaMogiana_WGS84_usingCorregoAlegreTrnsf_WGS84_U23'
	touch $@

db/carb.fields: db/alta_mogiana
	${PG} -f alta_mogiana.sql
	touch $@
