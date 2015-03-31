// qjhart/sugarcane/Fields.js
var Fields = {
    countries: 'ft:1uL8KJV0bMb7A8-SkrIe0ko2DMtSypHX52DatEE4',
    ahb: {
        burns:'ft:1ogFAU2Gx8bmzaGHuknHSNQRP1NJ4WQDqFagTlaRZ',
        farms:'ft:1bk67d9kEXq2NrciRd56rkez0fPWPqZs810ZjrJbi',
    },
    br: {
        farms:'ft:1yOtZapVUFdyy4MvwEbEjK20LnE7ZRCJaCizLIyTY',
        burns:'ft:1qKxvXnVbSkQTwK-Cw2tKb4wPCimsVbjjyodW6E5T'
    },
    get_burns : function(iso,year) {
        return ee.FeatureCollection(this.ahb.burns)
            .filter(ee.Filter().and(
                ee.Filter().eq('iso',iso),
                ee.Filter().eq('year',year)));
    },
    get_fields : function(farm) {
        return ee.FeatureCollection(this.ahb.farms)
            .filter(ee.Filter().eq('farm',farm));
    }
};

function display_burns(iso,year) {
    var burns=Fields.get_burns(iso,year);
    Map.centerObject(burns);
    addToMap(burns,{color:"440000"});
    return burns;
}

function display_fields(farm) {
    var fields=Fields.get_fields(farm);
    Map.centerObject(fields);
    addToMap(fields,{color:"004400"});
    return fields;
};

function show_landsat_images(year,fc) {
    var yL8 = ee.ImageCollection('LC8_L1T_TOA')
        .filterDate(new Date(year,1,1),new Date(year,12,31))
        .filterBounds(fc.geometry().bounds());
    addToMap(yL8);
    return yL8;
}

// This will set up a task that saves to your Google Drive, you will find in your EarthEngine Folder.
// Have to run Taks on the RHS
function export_fields(fields) {
    Export.table(
	fields,'ExampleFields',
	{
	    "driveFileNamePrefix":"sugarcane_fields",
	    "driveFolder":"EarthEngine",
	    "fileFormat":"GeoJSON"
	});
}

//Example
var fc=display_burns('BRA',2014);
var l = show_landsat_images(2014,fc);
print(l.getInfo());

