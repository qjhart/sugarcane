#! /usr/bin/make  -f

# This is the Configuation file
configure.mk:=1

# OGR parameters
OGR:=ogr2ogr -f "PostgreSQL" PG:"dbname=sugarcane"
PG:=psql -d sugarcane

# SHP parameters
