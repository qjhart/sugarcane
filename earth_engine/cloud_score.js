// qjhart.sugarcane - get images
//https://ee-api.appspot.com/7c189580ffa0781409a808d9f53e81f9

var L8 = {
    LC8_BANDS : ['B2',   'B3',    'B4',  'B5',  'B6',    'B7',    'B10'],
    STD_NAMES : ['blue', 'green', 'red', 'nir', 'swir1', 'swir2', 'temp'],

    // Compute a cloud score.  This expects the input image to have the common
    // band names: ["red", "blue", etc], so it can work across sensors.
    cloudScore : function(img) {
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
    cloudMask : function (img,score) {
	var cloud_score = this.cloudScore(img);
	return img.mask(cloud_score.lt(score));
    }
};


// Given a set of regions, and a particular year
// Return appropriate Landsat8 Scenes 
// filtered to the year and region
function get_nbi(regions,year) {
var yL8 = ee.ImageCollection('LC8_L1T_TOA')
    .filterDate(new Date(year,1,1),new Date(year,12,31))
    .filterBounds(regions);

// Now we are creating a new Collection of images that create
// our normalized burn index for every scene in the collection.
// We also use Google's built in Cloud cover algorythm.
var nbiColl=yL8.map(function(img){
  var nbi=img.expression("(b('B5')-b('B7'))/(b('B5')+b('B7'))").select([0],['nbi']);
  
  //
  var score = cloudScore(img.select(LC8_BANDS, STD_NAMES));
  var cloud = ee.Image(1).subtract(score).select([0], ['cloudscore']);
  //var nw=ee.Algorithms.SimpleLandsatCloudScore(img).select(['cloud']);
   return cloud.addBands(nbi);
  });
return nbiColl;
}

// Get your nbi
var all=get_nbi(fields,yr);
var nbi=all.select('nbi').median().clip(fields);
print (all.getInfo());

Map.centerObject(fields,12);
addToMap(fields,{color:"004400"});
addToMap(nbi);
