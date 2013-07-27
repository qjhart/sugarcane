set search_path=public;
create or replace FUNCTION curl_l(text) RETURNS text as
$$
#! /bin/bash
curl -l $1 2>/dev/null
$$ LANGUAGE plsh;

create or replace FUNCTION public.curl_l_err(text) RETURNS integer as
$$
#! /bin/bash
curl -l $1 >dev/null 2>/dev/null
echo $?
$$ LANGUAGE plsh;

create or replace FUNCTION public.mirror_file(url text,cache text)
RETURNS integer as 
$$
BEGIN
RAISE NOTICE 'Fetching: % to %',url,cache;
RETURN mirror_file_sh(url,cache);
END;
$$ LANGUAGE 'plpgsql';

create or replace FUNCTION public.mirror_file_sh(url text,cache text) 
RETURNS integer as
$$
#! /bin/bash
umask 0022
newgrp modis
wget  --quiet --directory-prefix=$2 --mirror $1 
echo $?
$$ LANGUAGE plsh;

create or replace FUNCTION mirror_file_text(url text,cache text) 
RETURNS text as
$$
#! /bin/bash
echo wget  --quiet --directory-prefix=$2 --mirror $1 
$$ LANGUAGE plsh;

-- with f as (select product_id,date,unnest(files) as file from product_dirs),v as (select modis_id from modis),u as (select date,modis_id,base||'/'||replace(date::text,'-','.')||'/'||file as url from f join products p using (product_id),v where file like '%.'||modis_id||'.%.hdf') select *,mirror_file(url,'/var/cache/modis') from u where date_part('year',date)=2012;


create or replace FUNCTION mirror_file(urls text[],cache text) 
RETURNS boolean as
$$
#! /bin/bash
wget  --directory-prefix=$2 --mirror string_agg($1,',')
$$ LANGUAGE plsh;


-- Previously I did this
--for f in `find /var/cache/modis -name \*.hdf`; do /usr/lib/postgresql/9.1/bin/raster2pgsql -s 96842 -a -R HDF4_EOS:EOS_GRID:$f:MOD_GRID_Monthly_500km_BA:burndate public.foo | psql -d sugarcane; done
-- But we now have notes on the binary representation of the files

-- This function returns the raster representation we can add to a table.
create or replace FUNCTION get_burndate_raster(cache text) 
RETURNS text as 
$$
#! /bin/bash
r2p=/usr/lib/postgresql/9.1/bin/raster2pgsql;
t=HDF4_EOS:EOS_GRID
l=MOD_GRID_Monthly_500km_BA:burndate
$r2p -Y -s 96842 -a -R $t:"$1":$l q 2>/dev/null | head -3 | tail -1
$$ LANGUAGE plsh;


