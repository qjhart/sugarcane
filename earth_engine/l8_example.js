// qjhart - Mask by cloud score
//@import L8.js

// 2013-06-03 Landsat 8 scene as TOA.
var image = ee.Image('LC8_L1T_TOA/LC80440342013154LGN00');

// Define visualization parameters for a true color image.
var vizParams = {'bands': 'B4,B3,B2', 'max': 0.5, 'gamma': 1.6};
centerMap(-122.24487, 37.52280, 8);

var cloud = L8.cloudScore(image);
var cloudfree = L8.masked(image,0.3);

addToMap(image, vizParams);
addToMap(cloud);
addToMap(cloudfree,vizParams);
