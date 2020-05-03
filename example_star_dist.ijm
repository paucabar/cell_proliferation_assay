#@ File (label="Select a counterstain image", style="file") counterstain
#@ File (label="Select a nucleoside analogue image", style="file") nucleoside_analogue
#@ String (label="Size", value="0-Infinity", persist=true) size
#@ String (label="Exclude edges", choices={"Yes", "No"}, style="radioButtonHorizontal", persist=true) exclude
#@ String (label="Visualize", choices={"Yes", "No"}, style="radioButtonHorizontal", persist=true) visualize

//get min and max sizes
size=min_max_size(size);

//activate expandable arrays
setOption("ExpandableArrays", true);

//open
open(counterstain);
open(nucleoside_analogue);
counterstain=File.getName(counterstain);
nucleoside_analogue=File.getName(nucleoside_analogue);

//stardist segmentation
run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'"+counterstain+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', 'percentileTop':'99.8', 'probThresh':'0.5', 'nmsThresh':'0.4', 'outputType':'ROI Manager', 'nTiles':'1', 'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', 'showProbAndDist':'false'], process=[false]");

//exclude edges
if (exclude == "Yes") {
	excludeEdges();
}

//display outlines
if (visualize == "Yes") {
	displayOutlines(counterstain, nucleoside_analogue, 500);
}

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

function min_max_size(string) {
	errorMessage="Size must contain 2 numbers separated by a hyphen (e.g., 20-85)."
				+ "\nThe maximum size can also be 'Infinity' (e.g., 0-Infinity).";
	hyphenIndex=indexOf(string, "-");
	if (hyphenIndex == -1) {
		exit(errorMessage);
	}
	sizeArray=newArray(2);
	sizeArray[0]=substring(string, 0, hyphenIndex);
	sizeArray[1]=substring(string, hyphenIndex + 1);
	sizeArray[0]=parseInt(sizeArray[0]);
	sizeArray[1]=parseInt(sizeArray[1]);
	if (isNaN(sizeArray[0]) || isNaN(sizeArray[1])) {
		exit(errorMessage);
	}
	return sizeArray;
}

function excludeEdges() {
	roiEdge=newArray();
	run("Set Measurements...", "bounding display redirect=None decimal=2");
	roiManager("deselect");
	roiManager("measure");
	nROI=roiManager("count");
	getDimensions(width, height, channels, slices, frames);
	toScaled(width);
	toScaled(height);
	roiEdgeCount=0;
	for (i=0; i<nROI; i++) {
		bx=getResult("BX", i);
		by=getResult("BY", i);
		iWidth=getResult("Width", i);
		iHeight=getResult("Height", i);	
		if (bx == 0 || by == 0 || bx + iWidth >= width || by + iHeight >= height) {
			roiEdge[roiEdgeCount]=i;
			roiEdgeCount++;
		}
	}	
	roiManager("select", roiEdge);
	roiManager("delete");
	run("Clear Results");
}

function displayOutlines (image1, image2, threshold) {
	index1=indexOf(image1, "(");
	index2=indexOf(image1, " wv");
	well=substring(image1, 0, index1);
	field=substring(image1, 0, index2);
	name=well + " " +field;
	run("Merge Channels...", "c1=["+image2+"] c3=["+image1+"] keep");
	rename(name);
	run("Set Measurements...", "mean display redirect=["+image2+"] decimal=2");
	roiManager("deselect");
	roiManager("measure");
	nROI=roiManager("count");
	roiManager("Set Line Width", 5);
	
	for (i=0; i<nROI; i++) {
		mean=getResult("Mean", i);
		if (mean > threshold) {
			setForegroundColor(255, 200, 0);
			roiManager("select", i);
			roiManager("draw");
		} else {
			setForegroundColor(0, 255, 255);
			roiManager("select", i);
			roiManager("draw");
		}
	}
	roiManager("show none");
}
