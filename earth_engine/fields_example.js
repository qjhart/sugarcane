// qjhart.sugarcane - features
// @ import Fields
var fields=Fields.get_fields();
 
//print(fields.getInfo());
Map.centerObject(fields);
addToMap(fields,{color:"004400"});
// // In this case you can get a quick Download URL for your data....
// print(fields.getDownloadURL("json"));
// // Or you can export it as a Task
// Export.table(fields,'ExampleFields',
//   {
// //      "gmeProjectId":"Sugarcane",
// //      "gmeAttributionName":"qjhart@gmail.com",
// //      "gmeAssetName":"fields",
//       "driveFileNamePrefix":"sugarcane_fields",
//       "driveFolder":"EarthEngine",
//       "fileFormat":"GeoJSON"
//   });
