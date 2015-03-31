// qjhart/sugarcane/nbi.js

// @import Fields
// @import L8
// @import Time
// @import Delta
var year=2014;
var threshold=0.2;
var name='jalles_machado';
var fields=Fields.get_fields(name);
var iso='BRA';
var burns=Fields.get_burns(iso,year);
var field_burns=burns.filterBounds(fields);

var intervals=Time.get_intervals(ee.Date.fromYMD(year,1,1),
			     ee.Date.fromYMD(year,12,1),28);
var ranges=Time.get_ranges(intervals,60);

// Get the Landsat images.
var rL8 = ee.ImageCollection('LC8_L1T_TOA').filterBounds(fields.geometry().bounds());

var nbidelta=Delta.deltas(rL8,ranges);
// Get Max version
var max=nbidelta.qualityMosaic('delta');


var max_clip=max.clip(fields).select(['delta','doy']);

// Reduce on Mean, Mode, pct80 and Histogram
var pct_red = ee.Reducer.percentile([80]);
var mean_red=ee.Reducer.mean();
var histo_red=ee.Reducer.histogram(16);
//var reduce = histo_red.combine(mean_red,'mean').combine(pct_red,'pct').combine(mode_red,'mode');
var reduce = histo_red.combine(mean_red,null,true).combine(pct_red,null,true);

// Get our average values
var crs='SR-ORG:6974';
var delta_fields=max_clip.reduceRegions(fields,reduce,30,crs,null,1);
var delta_field_burns=max_clip.reduceRegions(field_burns,reduce,30,crs,null,1);
//print (delta_field_burns.getInfo());
var delta_fields_alert=delta_fields.filter(
  ee.Filter.and(
    ee.Filter.neq('delta_p80',null),
    ee.Filter.greaterThan("delta_p80",0.6)
  ));

//Map.centerObject(fields,12);

//addToMap(max_clip,{'bands':['delta'],'min':-1,'max':1.2},"MAX_DELTA");
//addToMap(delta_fields,{color:"004400"},'Fields');
//addToMap(delta_field_burns,{color:"440000"},'Burns');

addToMap(max,{'bands':['delta'],'min':-1,'max':1.2},"MAX_DELTA");
addToMap(delta_fields,{color:"004400"},'Fields');
addToMap(delta_fields_alert,{color:"662222"},'Burned Fields')
addToMap(burns,{color:"440000"},'Burns');

// Now Export this data
Export.table(
	delta_fields,'Field_Statistics',
	{
    "driveFileNamePrefix":name,
    "driveFolder":"EarthEngine",
    "fileFormat":"KML"
	});

Export.table(
	delta_field_burns,'Burn_Statistics',
	{
    "driveFileNamePrefix":name+'_burn',
    "driveFolder":"EarthEngine",
    "fileFormat":"KML"
	});

