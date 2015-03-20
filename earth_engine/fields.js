// qjhart.sugarcane - features
// This example shows that GEOJson is a good method of preserving Array types
// for processing.

var field_table='ft:1yOtZapVUFdyy4MvwEbEjK20LnE7ZRCJaCizLIyTY';
var farm='adedcoagro_monta_alegre';
var year=2013;
 
// Get Field polygons
var fields = ee.FeatureCollection(field_table)
  .filter(ee.Filter().and(
    ee.Filter().eq('farm',farm),
    ee.Filter().eq('year',year)));
 
fields=fields.set('dates',[]);
 
fields=fields.map(function(f){
  return f.set('cloud',[1,2,3],
               'nbi',[4,5,6]);
});
 
fields=fields.map(function(f){
  var c=ee.List(f.get('cloud'));
  c=c.add(50.5);
  return f.set('cloud',c,
  'nbi',[1]);
});

// A mapping from a standard name to the sensor-specific bands.
var LC8_BANDS = ['B2',   'B3',    'B4',  'B5',  'B6',    'B7',    'B10'];
var STD_NAMES = ['blue', 'green', 'red', 'nir', 'swir1', 'swir2', 'temp'];

// List of Landsat Images used.
var yL8 = ee.ImageCollection('LC8_L1T_TOA')
    .filterDate(new Date(year,1,1),new Date(year,12,31))
    .filterBounds(fields);
  
//print(yL8.getInfo());

// Compute the Cloud Cover and NBI
var all=yL8.map(function(img){
  var nbi=img.normalizedDifference(['B5','B7']).select([0],['nbi']);
  var nw=ee.Algorithms.SimpleLandsatCloudScore(img).select(['cloud']);
  return nw.addBands(nbi);
  });

print (all.getInfo());

 
//print(fields.getInfo());
Map.centerObject(fields);
addToMap(fields,{color:"004400"});
// In this case you can get a quick Download URL for your data....
print(fields.getDownloadURL("json"));
// Or you can export it as a Task
Export.table(fields,'ExampleFields',
  {
//      "gmeProjectId":"Sugarcane",
//      "gmeAttributionName":"qjhart@gmail.com",
//      "gmeAssetName":"fields",
      "driveFileNamePrefix":"sugarcane_fields",
      "driveFolder":"EarthEngine",
      "fileFormat":"GeoJSON"
  });
