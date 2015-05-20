#! /usr/bin/make

countries:=CRI BRA
zips:=$(patsubst %,%.zip,${countries})

zipfile:url:=http://biogeo.ucdavis.edu/data/gadm2/shp/CRI_adm.zip

$(patsubst %,%_adm0.shp,${countries}):%_adm0.shp:
	wget http://biogeo.ucdavis.edu/data/gadm2/shp/$*_adm.zip
	unzip $*_adm.zip;

.PHONY:admin
admin:
	shp2pgsql -W LATIN1 -s 4269 CRI_adm0.shp country.adm0 | psql -d sugarcane
	shp2pgsql -W LATIN1 -s 4269 CRI_adm1.shp country.adm1 | psql -d sugarcane
	shp2pgsql -W LATIN1 -s 4269 CRI_adm2.shp country.adm2 | psql -d sugarcane
	shp2pgsql -a -W LATIN1 -s 4269 BRA_adm0.shp country.adm0 | psql -d sugarcane
	shp2pgsql -a -W LATIN1 -s 4269 BRA_adm1.shp country.adm1 | psql -d sugarcane
	shp2pgsql -a -W LATIN1 -s 4269 BRA_adm2.shp country.adm2 | psql -d sugarcane

