// Delta Library
// import Time
var Delta={
    // Given set of images, and ranges, return image collection of all deltas in range
    deltas: function (rL8,ranges) {
	// For each interval of time, get post and pre cloud free images
	// Calculate NBI, and add to a collection
	var deltas=[];
	for (var i=0; i < ranges.length; i++) {  
	    var pre=Time.filter_and_timestamp(rL8,
				      ranges[i].pre,
				      ranges[i].mid);
	    // Mask, get latest and calculate NBI
	    pre=L8.COL.cloud_masked(pre,threshold);
	    pre=L8.COL.latest(pre);
	    var nbi=L8.IMG.nbi(pre);
	    pre=pre.addBands(nbi,['nbi']);
	    
	    var post=Time.filter_and_timestamp(rL8,
					       ranges[i].mid,
					       ranges[i].post);
	    post=L8.COL.cloud_masked(post,threshold);
	    post=L8.COL.earliest(post);
	    nbi=L8.IMG.nbi(post);
	    post=post.addBands(nbi);
	    post.addBands(L8.IMG.nbi(post));
	    
	    var delta=pre.select(['nbi']).subtract(post.select(['nbi'])).select(['nbi'],['delta']);
	    delta=delta.addBands(pre.select(['nbi','doy'],['pre:nbi','pre:doy']));
	    delta=delta.addBands(post.select(['nbi','doy'],['post:nbi','post:doy']));
	    delta=delta.set({'interval':ranges[i].mid.format()});
	    delta=delta.set({'doy':ee.Number.parse(ranges[i].mid.format('D'))});
	    delta=delta.addBands(delta.metadata('doy'));
	    deltas.push(delta);
	}    
	var nbidelta=ee.ImageCollection(deltas);
	return nbidelta;	
    }
};
