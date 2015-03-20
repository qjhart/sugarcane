// qjhart - Fields Library
var Fields = {
    countries: 'ft:1uL8KJV0bMb7A8-SkrIe0ko2DMtSypHX52DatEE4',
    br: {
	farms:'ft:1yOtZapVUFdyy4MvwEbEjK20LnE7ZRCJaCizLIyTY',
	burns:'ft:1qKxvXnVbSkQTwK-Cw2tKb4wPCimsVbjjyodW6E5T'
    },
    farm:'example',
    get_fields : function(year) {
	return ee.FeatureCollection(this.br.farms)
	    .filter(ee.Filter().and(
		ee.Filter().eq('farm',this.farm),
		ee.Filter().eq('year',year)));
    },
    brazil:function() {
	return ee.FeatureCollection(this.countries)
	    .filter(ee.Filter.eq('ISO_2DIGIT','BR'));
    },
    brazil_farms: function(year) {
     	return ee.FeatureCollection(this.br.farms)
     	.filter(ee.Filter().eq('year',year));
    },
    brazil_burns: function(year) {
     	return ee.FeatureCollection(this.br.burns)
     	.filter(ee.Filter().eq('year',year));
    },
    cr: {
	farms:'ft:1Dm3K3ufEA9jStKca0jxS5h4Nf0hyGgPI3i1eO6kt',
	burns:'ft:1APDkvLOsSoKH5YqyQzZX4M6yPjJ-dg6RQrwcMXLI'
    },
    costa_rica:function() {
	return ee.FeatureCollection(this.countries)
	    .filter(ee.Filter.eq('ISO_2DIGIT','CR'));
    },
    costa_rica_farms: function() {
	return ee.FeatureCollection(this.cr.farms);
    },
    costa_rica_burns: function(year) {
	return ee.FeatureCollection(this.cr.burns)
	  .filter(ee.Filter().eq('year',year));
    }
};

function display_fields() {
    var year=2013;
    var fields=Fields.get_fields(year);
    Map.centerObject(fields);
    addToMap(fields,{color:"004400"});
    return fields;
};

function show_landsat_images() {
    var year=2013;
    var fields=Fields.get_fields(year);
   
    var yL8 = ee.ImageCollection('LC8_L1T_TOA')
	.filterDate(new Date(year,1,1),new Date(year,12,31))
	.filterBounds(fields);

    addToMap(yL8);
}

function get_download_url() {
    var fields=Fields.get_fields(2013);
    var url=fields.getDownloadURL("json");
    print(url);
}

// This will set up a task that saves to your Google Drive, you will find in your EarthEngine Folder.
// Have to run Taks on the RHS
function export_fields() {
    var fields=Fields.get_fields(2013);
    Export.table(
	fields,'ExampleFields',
	{
	    "driveFileNamePrefix":"sugarcane_fields",
	    "driveFolder":"EarthEngine",
	    "fileFormat":"GeoJSON"
	});
}

//Try one of these 
//show_landsat_images();
//display_fields();
//get_download_url();
//export_fields();
