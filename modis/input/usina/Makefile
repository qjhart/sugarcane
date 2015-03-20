#! /usr/bin/make -f 

# Link from our setup
ifndef configure.mk
include configure.mk
endif

db/usina:
db/usina:
	unzip -p parceria.kmz | perl -i.bak -n -e 'print unless (m|<META http-equiv="Content-Type" content="text/html">|)' > parceria.kml
	${OGR} -overwrite -nln parceria -nlt MULTIPOLYGON parceria.kml 'TALHÕES PARCERIAS USC'
	unzip -p propia.kmz | perl -i.bak -n -e 'print unless (m|<META http-equiv="Content-Type" content="text/html">|)' > propia.kml
	${OGR} -overwrite -nln propia -nlt MULTIPOLYGON propia.kml 'TALHÕES USC'
	touch $@

db/carb.fields: db/usina
	${PG} -f usina.sql
	touch $@
