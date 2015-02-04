#field.download:=ftp://ftp.arb.ca.gov/pub/outgoing/Cargill CEVASA/
field.data:=GIS_MAP_USM/USM_Mechanical_Sugarcane_harvesting_Map
field.data.type:=SHP
field.identifier:=Layer
# Set this when can't be predicted by ogr2ogr
#field.srs:=epsg:3857
years:=2012 2013
buffer:=400

#.PHONY::in.download in.unzip
#in.download: 
#	wget --directory=${in} --mirror "${field.download}"

