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
