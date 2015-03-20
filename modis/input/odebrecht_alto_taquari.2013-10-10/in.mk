field.download:=ftp.arb.ca.gov/pub/outgoing/FOR%20QH-UCD-LAWR%20MODIS%20EVAL/wgs84.zip
field.data:=Shape_UAT_WGS84
field.data.type:=SHP
field.identifier:=Codigo
years:=2011 2012

.PHONY::in.download in.unzip
in.download:
	wget --directory=${in} --mirror ftp://${field.download}

in.unzip:
	(cd ${in}; unzip ${field.download})