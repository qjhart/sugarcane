#! /usr/bin/make  -f

# This is the Configuation file
configure.mk:=1

# OGR parameters
OGR:=ogr2ogr -f "PostgreSQL" PG:"dbname=sugarcane"
PG:=psql -d sugarcane


nil:=
space:=${nil} ${nil}

# Conversion Info
fn:=00001-08041.00001-12348
n:=2458800
s:=1224000
w:=-2427800
e:=-1623700
res:=100

fn5:=00001-01608.00001-02470
n5:=2458800
s5:=1223800
w5:=-2427800
e5:=-1623800
res5:=500

# Liyi's region
fnl:=00001-03900.00001-04000
nl=2850000
sl=850000
wl=-3100000
el=-1150000
resl=500
g.regionl:=g.region n=${nl} w=${wl} e=${el} s=${sl} res=${resl}

g.region:=g.region n=$n w=$w e=$e s=$s res=${res}
g.region5:=g.region n=${n5} w=${w5} e=${e5} s=${s5} res=${res5}

# Specify the directory for data downloads
down:=downloads

# Grass specific functions
define grass_or_die
$(if ifndef GISRC,$(error Must be running in GRASS))
endef

ifdef GISRC
GISDBASE:=$(shell g.gisenv get=GISDBASE)
LOCATION_NAME:=$(shell g.gisenv get=LOCATION_NAME)
MAPSET:=$(shell g.gisenv get=MAPSET)
# Shortcut Directories
gdb:=${GISDBASE}
loc:=$(GISDBASE)/$(LOCATION_NAME)
map:=$(GISDBASE)/$(LOCATION_NAME)/${MAPSET}
rast:=$(loc)/$(MAPSET)/cellhd
vect:=$(loc)/$(MAPSET)/vector
etc:=$(loc)/$(MAPSET)/etc
endif

# We use a projection that doesn't come standard in the postgis
# database, so we need to add it in here.  It is the contiguous albers
# equal area projection.  ESRI uses the folloinwg code for the
# projection.
srid:=102004
srid-prj:=PROJCS["USA_Contiguous_Lambert_Conformal_Conic",GEOGCS["GCS_North_American_1983",DATUM["D_North_American_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-96],PARAMETER["Standard_Parallel_1",33],PARAMETER["Standard_Parallel_2",45],PARAMETER["Latitude_Of_Origin",39],UNIT["Meter",1]]
srid-url:=http://spatialreference.org/ref/esri/${srid}/postgis/
# This is what you get.
#INSERT into spatial_ref_sys (srid, auth_name, auth_srid, proj4text, srtext) values ( 9102004, 'esri', 102004, '+proj=lcc +lat_1=33 +lat_2=45 +lat_0=39 +lon_0=-96 +x_0=0 +y_0=0 +ellps=GRS80 +datum=NAD83 +units=m +no_defs ', 'PROJCS["USA_Contiguous_Lambert_Conformal_Conic",GEOGCS["GCS_North_American_1983",DATUM["North_American_Datum_1983",SPHEROID["GRS_1980",6378137,298.257222101]],PRIMEM["Greenwich",0],UNIT["Degree",0.017453292519943295]],PROJECTION["Lambert_Conformal_Conic_2SP"],PARAMETER["False_Easting",0],PARAMETER["False_Northing",0],PARAMETER["Central_Meridian",-96],PARAMETER["Standard_Parallel_1",33],PARAMETER["Standard_Parallel_2",45],PARAMETER["Latitude_Of_Origin",39],UNIT["Meter",1],AUTHORITY["EPSG","102004"]]');

# This is seutp to be the first item to get run. 
.PHONY: INFO
INFO::
	@echo This is the configure makefile
	@echo src:=${src}
	@echo srid:=${srid}	

define fetch_zip 
	[[ -f ${down}/$2 ]] || ( cd ${down}; wget $1/$2; unzip $2 )
endef

