#field.download:=ftp://ftp.arb.ca.gov/pub/outgoing/Cargill CEVASA/
field.data:=Bunge_Ouroeste_WGS84
field.data.type:=SHP
field.identifier:=Layer
field.srs:=epsg:3857
years:=2012 2013
buffer:=400

#.PHONY::in.download in.unzip
#in.download: 
#	wget --directory=${in} --mirror "${field.download}"

