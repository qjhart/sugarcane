// qjhart.sugarcane - L8 library
// This can be used as a starting point for some simple Landsat 8 processing.
// The latest can be found at: 
// https://bitbucket.org/spatial-ucd/earthengine/src/qjhart/qjhart/sugarcane/L8.js
var L8 = {
    PRODUCTS : {
	TOA: 'LANDSAT/LC8_L1T_TOA',
    },
    VIZ: {
	// Define visualization parameters for a true color image.
	true_color : {'bands': 'B4,B3,B2', 'max': 0.5, 'gamma': 1.6}
    },
    IMG: {
	LC8_BANDS : ['B2',   'B3',    'B4',  'B5',  'B6',    'B7',    'B10'],
	STD_NAMES : ['blue', 'green', 'red', 'nir', 'swir1', 'swir2', 'temp'],

	nbi: function(img) {
            img = img.select(this.LC8_BANDS,this.STD_NAMES);
	    var nbi=img.normalizedDifference(['nir','swir2']).
		select([0],['nbi']);
	    return nbi;
	},
	// add a time stamp to the image to the collection
	// https://ee-api.appspot.com/#6577bc130951e5c86a0a687637436eb9
	add_date : function(img) {
	    var timestamp = img.get('system:time_start');
	    var doy=ee.Date(timestamp).format('D');
	    img=img.set('doy',ee.Number.parse(doy));
	    img=img.addBands(img.metadata('doy'));
	    img=img.addBands(ee.Image(0)
			     .subtract(img.select('doy')).select([0],['oppdoy']));
	    return img;
	},
	
	// Compute a cloud score.  This expects the input image to have the common
	// band names: ["red", "blue", etc], so it can work across sensors.
	cloudScore : function(img) {
            img = img.select(this.LC8_BANDS,this.STD_NAMES);
            // A helper to apply an expression and linearly rescale the output.
            var rescale = function(img, exp, thresholds) {
		return img.expression(exp, {img: img})
                    .subtract(thresholds[0]).divide(thresholds[1] - thresholds[0]);
            };
            
            // Compute several indicators of cloudyness and take the minimum of them.
            var score = ee.Image(1.0);
            // Clouds are reasonably bright in the blue band.
            score = score.min(rescale(img, 'img.blue', [0.1, 0.3]));
            
            // Clouds are reasonably bright in all visible bands.
            score = score.min(rescale(img, 'img.red + img.green + img.blue', [0.2, 0.8]));
            
            // Clouds are reasonably bright in all infrared bands.
            score = score.min(
		rescale(img, 'img.nir + img.swir1 + img.swir2', [0.3, 0.8]));
            
            // Clouds are reasonably cool in temperature.
            score = score.min(rescale(img, 'img.temp', [300, 290]));
            
            // However, clouds are not snow.
            var ndsi = img.normalizedDifference(['green', 'swir1']);
            return score.min(rescale(ndsi, 'img', [0.8, 0.6]));
	},
	cloud_mask : function (img,score) {
            var cloud_score = this.cloudScore(img);
	    return cloud_score.lt(score);
	},
	// Landsat 8 has it's own Band Quality index (bqa) that comes with each image.  We can use this as well.
	// http://landsat.usgs.gov/L8QualityAssessmentBand.php
	// These are bitmaps:
	// EG. 61440 =  0b1111 0000 0000 0000   ( All Clouds ) 
	bqa_mask: function(img) {
	    var bad = img.select('BQA')
		.eq([61440,59424,57344,56320,53248,52256,52224,49184,49152])
		.reduce('max');
	    return bad.not();
	},
	// Returns the image masked to the bqa_mask
	bqa_masked : function(img) {
	    return img.mask(this.bqa_mask(img));
	},
	cloud_masked : function(img,score) {
	    var mask=this.cloud_mask(img,score);
            return img.mask(this.cloud_mask(img,score));
	},
    },
    COL : {
	TOA: function() {
	    return ee.ImageCollection('LANDSAT/LC8_L1T_TOA');
	},
	cloud_masked : function(collection,score) {
	    var I=this.IMG;
	    return collection.map(function(img) {
		return I.cloud_masked(img,score);
	    });
	},
	bqa_masked : function(collection) {
	    var I=this.IMG;
	    return collection.map(function(img) {
		return I.bqa_masked(img);
	    });
	},
	add_date: function(collection) {
	    return collection.map(this.IMG.add_date);
	},
	// Passed in a collection, return an image of the most recent
	latest : function(collection) {
	    return collection.qualityMosaic('doy');
	},
	earliest : function(collection) {
	    return collection.qualityMosaic('oppdoy');
	},
    },
    init : function(){
	this.COL.IMG=this.IMG;
    }
};

L8.init();

// Here are some short examples
function show_one_cloud_free_image() {
    var img=ee.Image('LC8_L1T_TOA/LC82190752014023LGN00');
    var cloud_free=L8.IMG.cloud_masked(img,0.3);
    var bqa = L8.IMG.bqa_masked(img);
    centerMap(-46.2068, -21.3585,8);
    // You can turn these on and off to check.
    addToMap(img,L8.VIZ.true_color,"Original",false);
    addToMap(cloud_free,L8.VIZ.true_color,"Simple",false);
    addToMap(bqa,L8.VIZ.true_color,"BQA",true);
}

function show_latest_cloud_free_image() {
    var year=2013;
    var month=6;
    var rect=ee.Geometry.Rectangle (-46.4818, -21.6076,-45.8446, -21.2132);
    var study_area = ee.Feature(rect,{name: 'Sao Paulo', fill: 1});

    var yL8 = ee.ImageCollection('LC8_L1T_TOA')
	.filterDate(new Date(year,month,15),new Date(year,month+2,15))
	.filterBounds(study_area.geometry());

    yL8=L8.COL.add_date(yL8);
    var cloud_free=L8.COL.bqa_masked(yL8);
    var first=ee.Image(cloud_free.first());
//    var last=cloud_free.last();
    var latest_cloud_free=L8.COL.latest(cloud_free);
    var earliest_cloud_free=L8.COL.earliest(cloud_free);
    // first_cloud_free is a single mosaiced image
    addToMap(first,L8.VIZ.true_color,"first",false);
    addToMap(latest_cloud_free,L8.VIZ.true_color,"latest_cloud_free",true);
    addToMap(earliest_cloud_free,L8.VIZ.true_color,"earliest_cloud_free",true);
    Map.centerObject(rect);
}

//Uncomment one of these to test
//show_one_cloud_free_image();
//show_latest_cloud_free_image();
