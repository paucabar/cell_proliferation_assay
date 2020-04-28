
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'C - 04(fld 001 wv DAPI - DAPI).tif', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");
run("Set Measurements...", "area mean integrated display redirect=[C - 04(fld 001 wv Cy3 - Cy3).tif] decimal=2");
nROI=roiManager("count");
roiManager("deselect");
roiManager("measure");
run("Merge Channels...", "c1=[C - 04(fld 001 wv Cy3 - Cy3).tif] c3=[C - 04(fld 001 wv DAPI - DAPI).tif] keep");
nROI=roiManager("count");
//run("RGB Color");
roiManager("Set Line Width", 5);
for (i=0; i<nROI; i++) {
	mean=getResult("Mean", i);
	if (mean > 500) {
		setForegroundColor(255, 200, 0);
		roiManager("select", i);
		roiManager("draw");
	} else {
		setForegroundColor(0, 255, 255);
		roiManager("select", i);
		roiManager("draw");
	}
}
