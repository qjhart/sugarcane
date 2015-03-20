// Get range of Dates
foreach(date in dates) {
    // Call delta_nbi(date);
    L8.select(date-60,date+60).median();
    This returns a single image with bands:
    delta_nbi;
    max_nbi;
    min_nbi;
    max_date;
    min_date;
    date = constant of the date we called
    //Then add this delta to an image collection;
}
// Now use qualityMosaic on deltas mask on delta_nbi
// We then have an image
delta_nbi,
max_nbi,
min_nbi,
max_date,
min_date,
date

where date shows when the max occurred.

OPTIONAL: Mask on dates in Oct,Nov,Dec,

Then use histgram feature delta_nbi fpor each field
return % of fields burned
(But what about the date it was burned? )

