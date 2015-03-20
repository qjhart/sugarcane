// qjhart.sugarcane - get before  images

//import L8.js


// Return a set of NBI data from a particular date
// @param {FeatureCollection} regions Regions of intereste
// @param {Date} Starting date
// @param {Integer} count Number of cycles 
// @param {Boolean} backward Go Backword? 
// Return appropriate Landsat8 Scenes 
function get_nbi(regions,d,count) {
  var cycle=28;
  var start_date=d;
  var end_date=d;
  if (count < 0) {
    start_date=d.advance(cycle*count,'day');
  } else {
    end_date=d.advance(cycle*count,'day');
  }

function get_most_recent() {
    //L8 most recent values cloud free example
    var coll = ee.ImageCollection('LANDSAT/LC8_L1T_TOA');
    var Collection = coll.filterDate(start_date,end_date).
	filterBounds(regions);

    Collection = Collection.map(add_date);
  
    // apply cloud masking here via .map and mask
    Collection = Collection.map(cloud_score);
  
    // reduce the Collection by retaining the unmasked values with the latest date
    return Collection.qualityMosaic('system:time_start');
}
   
var regions=Fields.get_fields();

print (start_date);
print (end_date);
var yL8 = ee.ImageCollection('LC8_L1T_TOA')
    .filterDate(start_date,end_date)
    .filterBounds(regions);

//print(yL8.getInfo());

// Now we are creating a new Collection of images that create
// our normalized burn index for every scene in the collection.
// We also use Google's built in Cloud cover algorythm.
var threshold=10;
var nbi=yL8.map(function(img){
  var nbi=img.normalizedDifference(['B5','B7']).select([0],['nbi']);
  var nw=ee.Algorithms.SimpleLandsatCloudScore(img).select(['cloud']);
  var cloud_mask=nw.lte(threshold);
  nw=nw.addBands(nbi);
  nw=nw.addBands(ee.Image.constant(count).select([0],['count']));
  nw=nw.mask(cloud_mask);
  return nw;
  });
//print(nbi.getInfo());
// Now get minimum nbi values;
var mn=nbi.min();
var mx=nbi.max();
var nbimm=mn.select(['nbi','cloud'],['min','min_cloud']);
nbimm=nbimm.addBands(mx.select(['nbi','cloud'],['max','max_cloud']));
nbimm=nbimm.addBands(mx.select(['count']));
return nbimm;
}

// Get your nbi
var m=ee.Date.fromYMD(2013,9,15);
var nbi3=get_nbi(fields,m,3);
var nbi2=get_nbi(fields,m,2).mask(nbi3.mask());
var nbi1=get_nbi(fields,m,1).mask(nbi3.mask());
var nbi=nbi1.first_nonzero(nbi2).first_nonzero(nbi3);
nbi=nbi.clip(fields);
print (nbi.getInfo());

var nbi_m3=get_nbi(fields,m,-3);
var nbi_m2=get_nbi(fields,m,-2).mask(nbi_m3.mask());
var nbi_m1=get_nbi(fields,m,-1).mask(nbi_m3.mask());
var nbi_m=nbi_m1.first_nonzero(nbi_m2).first_nonzero(nbi_m3);
nbi_m=nbi_m.clip(fields);
print (nbi_m.getInfo());

var nbi_delta=nbi.select(['max'],['delta']).subtract(nbi_m.select(['min']));
print (nbi_delta.getInfo());

Map.centerObject(fields,12);
addToMap(fields,{color:"004400"});
addToMap(nbi1,{'bands':['max'],'min':-1,'max':1},'NBI1');
addToMap(nbi2,{'bands':['max'],'min':-1,'max':1},'NBI2');
addToMap(nbi3,{'bands':['max'],'min':-1,'max':1},'NBI3');
addToMap(nbi,{'bands':['max'],'min':0,'max':1},"NBI_MAX");
addToMap(nbi_m,{'bands':['min'],'min':0,'max':1},"NBI_MIN");
addToMap(nbi_delta,{'bands':['delta'],'min':0,'max':1},"NBI_DELTA");
