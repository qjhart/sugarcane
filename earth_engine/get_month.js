// qjhart.sugarcane - get before images
var field_table='ft:1yOtZapVUFdyy4MvwEbEjK20LnE7ZRCJaCizLIyTY';
var farm='adedcoagro_monta_alegre';
var yr=2013;

// Get Field polygons
var fields = ee.FeatureCollection(field_table)
  .filter(ee.Filter().and(
    ee.Filter().eq('farm',farm),
    ee.Filter().eq('year',yr)));

fields=fields.set('dates',ee.List.repeat(0,0));

fields=fields.map(function(f){
  return f.set(
    'area',f.geometry().area(),
    'cloud',ee.List.repeat(0,0),
    'nbi',ee.List.repeat(0,0));
});

// Return a set of NBI data from a particular date
// @param {FeatureCollection} regions Regions of intereste
// @param {Date} Starting date
// @param {Integer} count Number of cycles 
// @param {Boolean} backward Go Backword? 
// Return appropriate Landsat8 Scenes 
function get_nbi(regions,d,count,backward) {
  var cycle=28;
  var start_date=d;
  var end_date=d;
  if (backward) {
    start_date.setDate(d.getDate()-count*cycle);
  } else {
    end_date=d.advance(cycle*count,'day');
  }

print (start_date);
print (end_date);
var yL8 = ee.ImageCollection('LC8_L1T_TOA')
    .filterDate(start_date,end_date)
    .filterBounds(regions);

print(yL8.getInfo());

// Now we are creating a new Collection of images that create
// our normalized burn index for every scene in the collection.
// We also use Google's built in Cloud cover algorythm.
var threshold=25;
var nbi=yL8.map(function(img){
  var nbi=img.normalizedDifference(['B5','B7']).select([0],['nbi']);
  var nw=ee.Algorithms.SimpleLandsatCloudScore(img).select(['cloud']);
  var cloud_mask=nw.lte(threshold);
  nw=nw.addBands(nbi);
  nw=nw.mask(cloud_mask);
  nw=nw.addBands(ee.Image.constant(count).select([0],['count']));
  return nw;
  });
print(nbi.getInfo());
// Now get minimum nbi values;
var mn=nbi.min();
var mx=nbi.max();
var nbimm=mn.select(['nbi','count','cloud'],['min','min_count','min_cloud']);
nbimm=nbimm.addBands(mx.select(['nbi','count','cloud'],['max','max_count','max_cloud']));
return nbimm;
}

// Get your nbi
var m=ee.Date.fromYMD(2013,9,15);
var nbi=get_nbi(fields,m,1,false).first(get_nbi(fields,m,2,false));
var nbi=nbi.clip(fields);
print (nbi.getInfo());

Map.centerObject(fields,12);
addToMap(fields,{color:"004400"});
addToMap(nbi);
