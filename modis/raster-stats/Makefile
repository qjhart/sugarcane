#! /usr/bin/make -f
# Need to run in grass.

#for d in `find ../input -type d -maxdepth 1`; do f=`echo $d | sed -e 's#\.\./input/##' -e 's/[-_]20..\-..\(\-..\)\?$//'`; ls $d/$f.csv ; done > files.inp
files:= \
../input/alta_mogiana/alta_mogiana.csv \
../input/un_santa_candida_2013-06-26/un_santa_candida.csv \
../input/sao-luiz-2013-07-02/sao-luiz.csv \
../input/meridiano-2013-07-02/meridiano.csv \
../input/solazyme-2013-07-22/solazyme.csv \
../input/conquista_do_pontal-2013-07-22/conquista_do_pontal.csv \
../input/destilaria_alcidia-2013-07-22/destilaria_alcidia.csv \
../input/santa_cruz-2012-12/santa_cruz.csv \
../input/renuka-2013-08-02/renuka.csv \
../input/noble_potireendaba-2013-07-10/noble_potireendaba.csv

stats.csv:
	r.mask -r
	for r in `g.mlist mapset=MCD45A1 type=rast pattern=h??v??.20??.??.??`; do g.region rast=$$r@MCD45A1; r.stats -c $$r@MCD45A1 | sed -e "s/ /,$$r,/"; done  > stats.csv

masked_stats.csv:
	for r in `g.mlist mapset=MCD45A1 type=rast pattern=h??v??.20??.??.??`; do m=$${r%%.*}; g.region rast=$$r@MCD45A1; r.mask -o $$m.mask maskcats=1; r.stats -n -c $$r@MCD45A1 | sed -e "s/ /,$$r,/"; done  > $@
	r.mask -r


list-files:
	@echo ${files}

h13v11.2012.09.01.fire.csv:%.fire.csv:
	g.region rast=$*
	r.stats -1 -g -x  $* | grep -v ' 0$$' | grep -v ' 10000$$' | grep -v ' 999.$$' > $@

burned_pixels.csv:blocks:=h09v07 h12v10 h12v11 h13v10 h13v11 
burned_pixels.csv:years:=2011 2012 2013 2014
burned_pixels.csv:
	echo 'modis_id,year,month,east,north,doy' > $@
	for b in ${blocks}; do for y in ${years} ; do \
	 for m in `seq -f '%02g' 1 12`; do \
	  eval `g.findfile element=cellhd file=$${b}.$${y}.$${m}.01`;\
	  echo $${name};\
	  g.region rast=$${name}; \
	  r.stats -1 -c -g fs=',' input=$${name} | grep -v ',0$$' | grep -v ',900$$' | grep -v ',999.$$' | grep -v ',10000$$' | sed "s/^/$${b},$${y},$${m},/" >> burned_pixels.csv; \
	 done; done; done

url:=http://ngdc.noaa.gov/eog/data/viirs_fire
test:
	for d in `seq -f '%02g'  02 30`; \
	  do echo $d; \
	  curl -O ${url}/viirs-ir-sources-201209${d}.csv; \
	done

burned_2013.kml:
	${PG} -c "\COPY (select kml.file(kml.feature('Document',folder)) from burned_kml_folders where modis_id is null and year=2013) to $* with csv quote '|'"
	perl -i -p -e 's/^\|//; s/\|$$//' $@

