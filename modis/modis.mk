#! /usr/bin/make -f 

SHELL:=/bin/bash

ifndef configure.mk
include configure.mk
endif

modis.mk:=1

#years:=2011 2012 2013
years:=2014
months:=01 02 03 04 05 06 07 08 09 10 11 12
ymd:=$(foreach y,${years},$(patsubst %,$y-%-01,${months}))
#ftp:=http://e4ftl01.cr.usgs.gov/MODIS_Composites/MOTA
ftp:=http://e4ftl01.cr.usgs.gov/MOTA
mod:=MCD45A1
ver:=005
scenes:=h12v10 h12v11 h13v11 h13v10 h09v07

.PHONY:${mod}
define GETMOD

.PHONY:${mod}/$2
${mod}/$2::${mod}/$2/${mod}.$1.hdf

${mod}::${mod}/$2/${mod}.$1.hdf
#	yjd=`date --date=${ymd} +%Y%j`;
${mod}/$2/${mod}.$1.hdf:
	[[ -d $$(dir $$@) ]] || mkdir -p $$(dir $$@)
	file=`curl -q  ${ftp}/${mod}.${ver}/$2/ | sed -e 's/<img[^>]*>//g' -e 's/<.DOCTYPE[^>]*>//' -e 's/<hr[^>]*>//g' | xmlstarlet sel -t -v //a[@href] | grep '$1.*\.hdf$$$$'`; \
	if [[ -z $$$$file ]]; then \
	  echo "File for ${mod}/$2/${mod}.$1.hdf" not found; \
	  exit; \
	fi; \
	if [[ -n ${mod}/$2/$$$$file ]]; then \
	  curl --output ${mod}/$2/$$$$file ${ftp}/${mod}.${ver}/$2/$$$$file; \
	fi; \
	ln ${mod}/$2/$$$$file $$@;
endef 

$(foreach d,${ymd},$(foreach s,$(scenes),$(eval $(call GETMOD,$s,$(subst -,.,$d)))))

ifeq (${LOCATION_NAME},modis)

ifeq (${MAPSET},${mod})

.PHONY:${mod}
define INMOD
.PHONY:${mod}/$1.$2
${mod}/$1.$2::${rast}/$1.$2
${mod}/$2::${rast}/$1.$2
${mod}::${rast}/$1.$2
${rast}/$1.$2:${mod}/$2/${mod}.$1.hdf
	r.in.gdal -o input=HDF4_EOS:EOS_GRID:"$$<":MOD_GRID_Monthly_500km_BA:burndate output=$$(notdir $$@) || true

#$	r.mapcalc m.$1.$2='if($1.$2==0,0,if($1.$2==900,2^13,if($1.$2==9998,2^13,if($1.$2==9999,2^14,if($1.$2==10000,2^15,if($1.$2==366,2^12,2^(1+int($1.$2/30.5))))))))'
.PHONY:m.${mod}
m.${mod}::${rast}/m.$1.$2
${rast}/m.$1.$2:${rast}/$1.$2
	g.region rast=$1.$2;\
	r.mapcalc m.$1.$2='if($1.$2>0&&$1.$2<367,2^(1+int($1.$2/61)),0)'
endef

$(foreach d,${ymd},$(foreach s,$(scenes),$(eval $(call INMOD,$s,$(subst -,.,$d)))))

define YEARMOD

.PHONY:y.${mod}
y.${mod}::${rast}/y.$1.$2

#${rast}/y.$1.$2:$(patsubst %,${rast}/m.$1.$2.%.01,${months})
#	r.mapcalc y.$1.$2='$(replace $(patsubst %,${rast}/m.$1.$2.%.01,${months}),${space},&)'

${rast}/y.$1.$2:${rast}/m.$1.$2.01.01 ${rast}/m.$1.$2.02.01 ${rast}/m.$1.$2.03.01 ${rast}/m.$1.$2.04.01 ${rast}/m.$1.$2.05.01 ${rast}/m.$1.$2.06.01 ${rast}/m.$1.$2.07.01 ${rast}/m.$1.$2.08.01 ${rast}/m.$1.$2.09.01 ${rast}/m.$1.$2.10.01 ${rast}/m.$1.$2.11.01 ${rast}/m.$1.$2.12.01 
${rast}/y.$1.$2:$(patsubst %,${rast}/m.$1.$2.%.01,${months})
	g.region rast=m.$1.$2.01.01;\
	r.mapcalc y.$1.$2='m.$1.$2.01.01|m.$1.$2.02.01|m.$1.$2.03.01|m.$1.$2.04.01|m.$1.$2.05.01|m.$1.$2.06.01|m.$1.$2.07.01|m.$1.$2.08.01|m.$1.$2.09.01|m.$1.$2.10.01|m.$1.$2.11.01|m.$1.$2.12.01'

endef

$(foreach y,${years},$(foreach s,$(scenes),$(eval $(call YEARMOD,$s,$y))))


else
 $(error ${MAPSET} is wrong mapset)
endif # MAPSET=${mod}

else ifeq (${LOCATION_NAME},conus)

ifneq (${MAPSET},MCD45A1${yr})
 $(error ${MAPSET} is wrong mapset)
endif

.PHONY:MCD45A1
define MCD45A1
MCD45A1::${rast}/MCD45A1.$1
${rast}/MCD45A1.$1:$(patsubst %,${gdb}/modis/MCD45A1${yr}/cellhd/MCD45A1.%.$1,${scenes})
	${g.region}
	for s in ${scenes};\
	do r.proj input=MCD45A1.$$$$s.$1 location=modis method=nearest resolution=500;\
	done;
	r.mapcalc MCD45A1.$1='if(isnull(MCD45A1.h08v04.$1),if(isnull(MCD45A1.h08v05.$1),if(isnull(MCD45A1.h07v05.$1),if(isnull(MCD45A1.h09v04.$1),MCD45A1.h09v05.$1,MCD45A1.h09v04.$1),MCD45A1.h07v05.$1),MCD45A1.h08v05.$1),MCD45A1.h08v04.$1)'
	g.remove rast=MCD45A1.h07v05.$1,MCD45A1.h08v04.$1,MCD45A1.h08v05.$1,MCD45A1.h09v04.$1,MCD45A1.h09v05.$1
endef

$(foreach d,${jds},$(eval $(call MCD45A1,$d)))

#define mfiles
#MCD45A1/${fn}.$1.hdr MCD45A1/${fn}.$1:${rast}/MCD45A1.$1
#	r.out.gdal input=MCD45A1.$1 output=MCD45A1/${fn}.$1 format=ENVI type=Byte nodata=0
#endef
#$(foreach d,${mjds},$(eval $(call mfiles,$d)))

mfiles:=$(patsubst %,MCD45A1/${fn5}.%,${mjds})
${mfiles}:MCD45A1/${fn5}.%:${rast}/MCD45A1.%
	r.out.gdal input=MCD45A1.$* output=MCD45A1/${fn5}.$* format=ENVI type=Byte nodata=255

MCD45A1.zip:MCD45A1/${fn5} MCD45A1/${fn5}.index
	zip $@ $^

MCD45A1/${fn5}.index:MCD45A1.index
	cp $< $@

MCD45A1/${fn5}:${mfiles}
	rm -f $@
	cat ${mfiles} >> $@

endif

# for m in 01 02 03 04 05 06 07 08 09 10 11 12; do r.mapcalc d.2011.${m}.01="if(isnull(h12v11.2011.${m}.01@MCD45A1),h13v11.2011.${m}.01@MCD45A1,h12v11.2011.${m}.01@MCD45A1)"; done

#do r.mapcalc y.{y}="if(isnull(y.h12v11.${y}@MCD45A1),y.h13v11.${y}@MCD45A1,y.h12v11.${y}@MCD45A1)"; done 
