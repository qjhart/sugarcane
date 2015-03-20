// qjhart/sugarcane/nbi.js

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
    delta=delta.addBands(pre.select(['nbi','doy'],['pre:nbi','pre:doy']));
    delta=delta.addBands(post.select(['nbi','doy'],['post:nbi','post:doy']));
    delta=delta.set({'interval':ranges[i].mid.format()});
    delta=delta.set({'doy':ee.Number.parse(ranges[i].mid.format('D'))});
    delta=delta.addBands(delta.metadata('doy'));
    deltas.push(delta);
}    

var nbidelta=ee.ImageCollection(deltas);
var max=nbidelta.qualityMosaic('delta');
Map.centerObject(fields,12);
//addToMap(nbidelta,{'bands':['delta'],'min':-2,'max':2},"NBI_DELTA");
addToMap(max,{'bands':['delta'],'min':-2,'max':2},"MAX_DELTA");
addToMap(fields,{color:"004400"});
