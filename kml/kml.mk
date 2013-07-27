#! /usr/bin/make -f 

#ifndef configure.mk
#include configure.mk
#endif

PG:=psql -d sugarcane

pwd:=$(shell pwd)
schema:=kml

# cmz34.csv:gcsv:=https://docs.google.com/a/ucdavis.edu/spreadsheet/ccc?key=0AgN3B21vEtMFdFJNZkR0d2w0aWdjTU55Sk9faUdpY1E&single=true&gid=0&output=csv
# cmz34.csv:
# 	wget -O $@ '${gcsv}'

db/kml:
	${PG} --variable=kml="${schema}" -f kml.sql
	${PG} --variable=kml="${schema}" --variable=styles="'${pwd}/styles.csv'" --variable=stylemaps="'${pwd}/stylemaps.csv'" -f styles.sql


