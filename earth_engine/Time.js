// qjhart/sugarcane/Time.js
// These Time functions provide some simple support for getting time
// ranges from collections.

// @import L8
var Time={
    get_intervals: function(start,end,step) {
	var intervals=[];
	var m=0;
	var cnt=Math.floor(end.difference(start,'day').getInfo()/step);
	for (var m=0; m<cnt; m++) {
	  var cur=start.advance(m*step,'day');
	  intervals.push(cur);
	}
  	 return intervals;
    },  
    get_month : function(year) {
	var months = [];
	for (var m = 1; m <= 12; m++) {	    
	    months.push(new ee.Date.fromYMD(year,m,15));
	}
	return months;
    },	
    get_ranges: function(dates,half_width) {
	var ranges = [];
	for (var m = 0; m < dates.length; m++) {
	    ranges.push(
		{ pre:dates[m].advance(-1*half_width,'day'),
		  mid:dates[m],
		  post:dates[m].advance(half_width,'day')});
	}
	return ranges;
    },
    filter_and_timestamp: function(collection,start,end) {
	var new_coll = collection.filterDate(start,end);
	new_coll=L8.COL.add_date(new_coll);
	return new_coll;
    },
};


function get_closest_before_and_after_images() {
    var year=2013;
    var month=6;
    var threshold=0.2;
    
    var rect=ee.Geometry.Rectangle (-46.4818, -21.6076,-45.8446, -21.2132);
    var study_area = ee.Feature(rect,{name: 'Sao Paulo', fill: 1});

    var rL8 = ee.ImageCollection('LC8_L1T_TOA').
	filterBounds(study_area.geometry());

    var intervals = Time.get_intervals(ee.Date.fromYMD(year,month,15),
				   ee.Date.fromYMD(year+1,month,15),
				   28);
    print(intervals);
    // This gives you a 120 day interval
    var ranges=Time.get_ranges(intervals,60);
    print(ranges);

    // Now get the pre and post closest cloud_free images in interval
    var pre=Time.filter_and_timestamp(rL8,
				      ranges[0].pre,
				      ranges[0].mid);
    // Mask, get latest and calculate NBI
    pre=L8.COL.cloud_masked(pre,threshold);
    pre=L8.COL.latest(pre);
    var post=Time.filter_and_timestamp(rL8,
				       ranges[0].mid,
				       ranges[0].post);
    post=L8.COL.cloud_masked(post,threshold);
    post=L8.COL.earliest(post);

    addToMap(pre,L8.VIZ.true_color,"pre",false);
    addToMap(post,L8.VIZ.true_color,"post",true);
    Map.centerObject(rect);
}

// Uncomment for Examples
//get_closest_before_and_after_images();
