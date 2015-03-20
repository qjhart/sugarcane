// qjhart/sugarcane/fieldMeans.js
// @import Fields
// @import L8
// @import Time

var year=2013;
var threshold=0.2;
var fields=Fields.get_fields(year);
var intervals=Time.get_intervals(ee.Date.fromYMD(year,6,1),
			     ee.Date.fromYMD(year,9,1),28);
var ranges=Time.get_ranges(intervals,60);

// Get the Landsat images.
var rL8 = ee.ImageCollection('LC8_L1T_TOA').filterBounds(fields);

// For each interval of time, get post and pre cloud free images
// Calculate NBI, and add to a collection
var deltas=[];
for (var i=0; i < ranges.length; i++) {  
    var pre=Time.filter_and_timestamp(rL8,
				      ranges[i].pre,
				      ranges[i].mid);
    // Mask, get latest and calculate NBI
    pre=L8.COL.cloud_masked(pre,threshold);
    pre=L8.COL.latest(pre);
    var nbi=L8.IMG.nbi(pre);
    pre=pre.addBands(nbi,['nbi']);
    
    var post=Time.filter_and_timestamp(rL8,
				       ranges[i].mid,
				       ranges[i].post);
    post=L8.COL.cloud_masked(post,threshold);
    post=L8.COL.earliest(post);
    nbi=L8.IMG.nbi(post);
    post=post.addBands(nbi);
    post.addBands(L8.IMG.nbi(post));

    var delta=pre.select(['nbi']).subtract(post.select(['nbi'])).select(['nbi'],['delta']);
    delta=delta.addBands(pre.select(['nbi','system:time_start'],['pre:nbi','pre:time_start']));
    delta=delta.addBands(post.select(['nbi','system:time_start'],['post:nbi','post:time_start']));
    delta=delta.set({'interval':ranges[i].mid.format(),'time_stamp':ranges[i].mid.millis()});
    delta=delta.addBands(delta.metadata('time_stamp'));
    deltas.push(delta);
}    

var nbidelta=ee.ImageCollection(deltas);
var max=nbidelta.qualityMosaic('delta');

Map.centerObject(fields,12);
//get just the delta band and clip to fields 
var max_nbis = max.clip(fields).select(['delta','time_stamp']);
addToMap(max_nbis,{'bands':['delta'],'min':-2,'max':2},"Max_NBIs");

//get overall mean
//var mnred = ee.Reducer.mean();
//var mn_all = max_nbis.reduceRegion(mnred, fields, 30);
//print(mn_all.getInfo());
//var mn_maxdelta = mn_all.values().get(0);
//print ('Overall Mean: ');
//print(mn_maxdelta);

//get field means, mode, pct80
//80th percential
var pct_red = ee.Reducer.percentile([80]);
//mode
var mode_red = ee.Reducer.mode(); // should we specify maxBuckets, minBucketWidth, maxRaw??
//var combo_red = ee.Reducer.mean().combine(pct_red,null,true).combine(mode_red,null,true);
var combo_red = ee.Reducer.mean().combine(pct_red,null,true).combine(mode_red,null);

var red_dict = max_nbis.reduceRegions(fields, combo_red,  30);
//individual field means;
print(red_dict.getInfo());
var featColl = ee.FeatureCollection(red_dict);
//print(featColl.getDownloadURL('csv', ['mean'])); //works
// Just need to grab the pixel
// show that these are the same
addToMap(featColl,{color:"004400"}, 'Field Means and 80th percentile FC',false);

// Make image of field means
var mnImg = featColl.reduceToImage(['mean'],ee.Reducer.mean());
addToMap(mnImg,{'bands':['mean'],'min':-2,'max':2},"Field Means");

//Make image of 80th pcntile
var img80 = featColl.reduceToImage(['p80'],ee.Reducer.mean()).select([0],['p80']);
addToMap(img80,{'bands':['p80'],'min':-2,'max':2},"Field 80th Percentile");

//Make image of mode
var modeImg = featColl.reduceToImage(['mode'],ee.Reducer.mean()).select([0],['mode']);
addToMap(modeImg,{'bands':['mode'],'min':-2,'max':2},"Time_stamp Mode",false);