#! /usr/bin/make -f 

ifndef configure.mk
include configure.mk
endif

mod:=MOD15A2
#scenes:=h07v05 h08v04 h08v05 h09v04 h09v05
scenes:=h07v05 h07v06 h08v04 h08v05 h08v06 h09v04 h09v05 h10v04
yr:=2007

jds:=001 009 017 025 033 041 049 057 065 073 081 089 \
     097 105 113 121 129 137 145 153 161 169 177 185 \
     193 201 209 217 225 233 241 249 257 265 273 281 \
     289 297 305 313 321 329 337 345 353 361

mjds:=017 041 073 105 137 161 193 225 257 281 313 345

#define jds 
#jds.$1:=$(shell ls ${mod}.$1/${mod}.A${yr}*.$1.tsf.sat.hdf | cut -b29-31)
#endef
#$(foreach s,$(scenes),$(eval $(call jds,$s)))

INFO::
	echo jds ${jds}
#	echo jds ${jds.h08v04}
#	$(call grass_or_die)


ifeq (${LOCATION_NAME},modis)

ifneq (${MAPSET},lai${yr})
 $(error ${MAPSET} is wrong mapset)
endif

.PHONY:lai
define lai
lai:${rast}/lai.$1.$2
${rast}/lai.$1.$2:${mod}.$1/${mod}.A${yr}$2.$1.tsf.sat.hdf
	r.in.gdal input=$$< output=$$(notdir $$@)
endef

$(foreach s,$(scenes),$(foreach d,${jds},$(eval $(call lai,$s,$d))))

else ifeq (${LOCATION_NAME},conus)

#ifneq (${MAPSET},lai${yr})
# $(error ${MAPSET} is wrong mapset)
#endif

.PHONY:lai
define lai
lai:${rast}/lai.$1
#${rast}/lai.$1:$(patsubst %,${gdb}/modis/lai${yr}/cellhd/lai.%.$1,${scenes})
${rast}/lai.$1:
#	${g.region5}
	for s in ${scenes};\
	do r.proj input=lai.$$$$s.$1 location=modis mapset=lai${yr} method=nearest resolution=500;\
	done;
	r.mapcalc lai.$1='if(isnull(lai.h07v05.$1),if(isnull(lai.h07v06.$1),if(isnull(lai.h08v04.$1),if(isnull(lai.h08v05.$1),if(isnull(lai.h08v06.$1),if(isnull(lai.h09v04.$1),if(isnull(lai.h09v05.$1),if(isnull(lai.h10v04.$1),0,lai.h10v04.$1),lai.h09v05.$1),lai.h09v04.$1),lai.h08v06.$1),lai.h08v05.$1),lai.h08v04.$1),lai.h07v06.$1),lai.h07v05.$1)'
	for s in ${scenes}; do g.remove lai.$$$$s.$1; done
endef

$(foreach d,${jds},$(eval $(call lai,$d)))

#define mfiles
#lai/${fn}.$1.hdr lai/${fn}.$1:${rast}/lai.$1
#	r.out.gdal input=lai.$1 output=lai/${fn}.$1 format=ENVI type=Byte nodata=0
#endef
#$(foreach d,${mjds},$(eval $(call mfiles,$d)))

mfiles:=$(patsubst %,lai${yr}/${fnl}.%,${mjds})
${mfiles}:lai${yr}/${fnl}.%:${rast}/lai.%
	r.out.gdal input=lai.$* output=lai${yr}/${fnl}.$* format=ENVI type=Byte nodata=255

lai${yr}.zip:lai${yr}/${fnl} lai${yr}/${fnl}.index
	zip $@ $^

lai${yr}/${fnl}.index:laiYR.index
	sed -e 's/{YR}/${yr}/' < $< >  $@

lai${yr}/${fnl}:${mfiles}
	rm -f $@
	cat ${mfiles} >> $@

endif
