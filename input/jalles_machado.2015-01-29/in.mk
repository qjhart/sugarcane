# Once filled out 
# grass; cd $BASE/input; make in=${dir} kml
#field.download:=_via_email_
field.data:=jalles_poly
field.data.type:=SHP
field.identifier:=NAME
#field.srs:=epsg:4326
years:=2012 2013 2014
buffer:=250

#.PHONY::in.download in.unzip
#in.download: 
#	wget --directory=${in} --mirror "${field.download}"

