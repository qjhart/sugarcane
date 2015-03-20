# Sugarcane Field Burning

The goal of this project is to determine whether certain sugarcane
fields have been burned in either 2013 or 2014.  California give
carbon credits for ethanol produced in Brazil, but the size of these
credits is based on whether the sugarcane fields have been
mechanically harvested or burned.  

Previously, the project has used a monthly MODIS based burn product to
determine whether or not fields have been burned.  Here we look at
some simple methods to use LandSAT 8 to preform a similar task.

The idea is fairly straight-forward.  For every month, determine the
normalized burn index (NBI) for each pixel in the sugarcane fields.
If the NBR has increased dramatically, then identify that as a
potential burned pixel.  This is somewhat confused by the fact that
the NBI is affected by cloud cover, and our overpasses are
substantially less then the overpasses from MODIS.  In addition,
fields that are mechanically harvested also show and increas in NBI,
though presumably, not as high as a burned pixel.

* ```fields.js``` is a simple example retrieving sugarcane fields from a
fusion table.

* ```get_nbi.js``` is a simple example retrieving all Landsat 8 images
for a particular set of fields for one year, and calculating the
cloud-cover and nbi for those images.

* ```get_month.js``` is an example of retrieving the closest
 non-clouded landsat pixel from a given date.
