#! /usr/bin/make -f 

ifndef configure.mk
include configure.mk
endif

ifndef modis.mk
include modis.mk
endif

field_table:=
kml:=fields_2012-11-10.kml
layers:=ITB ITT

db/carb.fields:
	${OGR} -overwrite -nln itb -nlt POLYGON ${kml} ITB
	${OGR} -overwrite -nln itt -nlt POLYGON ${kml} ITT
	${PG} -f itt.sql

