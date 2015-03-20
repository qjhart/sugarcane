// qjhart.sugarcane - get images
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
var nbi=yL8.map(function(img){
  var nbi=img.normalizedDifference(['B5','B7']).select([0],['nbi']);
  var nw=ee.Algorithms.SimpleLandsatCloudScore(img).select(['cloud']);
  return nw.addBands(nbi);
  });
return nbi;
}

// Get your nbi
var all=get_nbi(fields,yr);
var nbi=all.select('nbi').median().clip(fields);
print (all.getInfo());

Map.centerObject(fields,12);
addToMap(fields,{color:"004400"});
addToMap(nbi);

