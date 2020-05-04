/*
 * Cell_Proliferation
 * Authors: Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia (Valencia, Spain)
 */

/*
 * This macro is a high-throughput screening tool for cell proliferation assays.
 * It is based on nucleoside analogue pulse alone or in combination with up to
 * two additional nuclear markers.
 */

macro "Cell_Proliferation" {

//choose a macro mode and a directory
#@ String (label=" ", value="<html><font size=6><b>High Content Screening</font><br><font color=teal>Cell Proliferation</font></b></html>", visibility=MESSAGE, persist=false) heading
#@ String(label="Select mode:", choices={"Analysis", "Pre-Analysis (parameter tweaking)"}, style="radioButtonVertical") mode
#@ File(label="Select a directory:", style="directory") dir
#@ String (label="<html>Load pre-established<br>parameter dataset?</html>", choices={"No", "Yes"}, persist=true, style="radioButtonHorizontal") importPD
#@ String (label="<html>Load llumination<br>correction reference<br>image?</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") illumCorr
#@ String (label="<html>Save ROIs?</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") saveROIs
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

//set options
setOption("ExpandableArrays", true);
setOption("BlackBackground", false);
setOption("ScaleConversions", true);
roiManager("reset");
print("\\Clear");
roiManager("reset");
run("Close All");

//File management
//Identification of the TIF files
//create an array containing the names of the files in the directory path
list = getFileList(dir);
Array.sort(list);
tifFiles=0;

//count the number of TIF files
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tifFiles++;
	}
}

//check that the directory contains TIF files
if (tifFiles==0) {
	beep();
	exit("No TIF files")
}

//create a an array containing only the names of the TIF files in the directory path
tifArray=newArray(tifFiles);
count=0;
for (i=0; i<list.length; i++) {
	if (endsWith(list[i], "tif")) {
		tifArray[count]=list[i];
		count++;
	}
}

//Extraction of the ‘well’ and ‘field’ information from the images’ filenames
//calculate: number of wells, images per well, images per field and fields per well
nWells=1;
nFields=1;
well=newArray(tifFiles);
field=newArray(tifFiles);
well0=substring(tifArray[0],0,6);
field0=substring(tifArray[0],11,14);

for (i=0; i<tifArray.length; i++) {
	well[i]=substring(tifArray[i],0,6);
	field[i]=substring(tifArray[i],11,14);
	well1=substring(tifArray[i],0,6);
	field1=substring(tifArray[i],11,14);
	if (field0!=field1 || well1!=well0) {
		nFields++;
		field0=substring(tifArray[i],11,14);
	}
	if (well1!=well0) {
		nWells++;
		well0=substring(tifArray[i],0,6);
	}
}

//create an array containing the well codes
wellName=newArray(nWells);
imagesxwell = (tifFiles / nWells);
imagesxfield = (tifFiles / nFields);
fieldsxwell = nFields / nWells;
for (i=0; i<nWells; i++) {
	wellName[i]=well[i*imagesxwell];
}

//create an array containing the field codes
fieldName=newArray(fieldsxwell);
for (i=0; i<fieldsxwell; i++) {
	fieldName[i]=i+1;
	fieldName[i]=d2s(fieldName[i], 0);
	while (lengthOf(fieldName[i])<3) {
		fieldName[i]="0"+fieldName[i];
	}
}

//extraction of the ‘channel’ information from the images’ filenames
//create an array containing the names of the channels
channels=newArray(imagesxfield+1);
count=0;
while (channels.length > count+1) {
	index1=indexOf(tifArray[count], "wv ");
	index2=lastIndexOf(tifArray[count], " - ");
	channels[count]=substring(tifArray[count], index1+3, index2);
	count++;
}

//add an 'Empty' option into the channels name array
for (i=0; i<channels.length; i++) {
	if(i>=imagesxfield) {
		channels[i]="Empty";
	}
}

//create a channel array without the 'Empty' option
channelsSlice=Array.slice(channels, 0, channels.length-1);

//set some parameter menu arrays
threshold=getList("threshold.methods");
pattern=newArray(4);
flat_field=newArray(4);

//create a flat-field array with a 'None' option
if(illumCorr=="Yes") {
	illumCorrPath=getDirectory("Choose the folder containing the flat-field images");
	illumCorrList=getFileList(illumCorrPath);
	concatNone=newArray("None");
	illumCorrList=Array.concat(concatNone,illumCorrList);
} else {
	illumCorrList=newArray("None");
}

//Extract values from a parameter dataset file
if(importPD=="Yes") {
	parametersDatasetPath=File.openDialog("Choose the parameter dataset file:");
	//parameter selection (pre-established)
	parametersString=File.openAsString(parametersDatasetPath);
	parameterRows=split(parametersString, "\n");
	parameters=newArray(parameterRows.length);
	for(i=0; i<parameters.length; i++) {
		parameterColumns=split(parameterRows[i],"\t"); 
		parameters[i]=parameterColumns[1];
	}
	projectName=parameters[0];
	pattern[0]=parameters[1];
	pattern[1]=parameters[2];
	pattern[2]=parameters[3];
	pattern[3]=parameters[4];
	normalize=parameters[5];
	gaussianNuclei=parameters[6];
	thresholdNuclei=parameters[7];
	erodeNuclei=parameters[8];
	openNuclei=parameters[9];
	watershedNuclei=parameters[10];
	size=parameters[11];
	flat_field[0]=parameters[12];
	flat_field[1]=parameters[13];
	flat_field[2]=parameters[14];
	flat_field[3]=parameters[15];
} else {
	//default parameters
	projectName="Project";
	pattern[0]=channelsSlice[0];
	pattern[1]=channelsSlice[0];
	pattern[2]=channels[imagesxfield];
	pattern[3]=channels[imagesxfield];
	normalize=true;
	gaussianNuclei=2;
	thresholdNuclei=threshold[6];
	erodeNuclei=2;
	openNuclei=2;
	watershedNuclei=true;
	size="0-Infinity";
	flat_field[0]="None";
	flat_field[1]="None";
	flat_field[2]="None";
	flat_field[3]="None";
}

//'Select Parameters' dialog box
//edit parameters
title = "Select Parameters";
Dialog.create(title);
Dialog.addString("Project", projectName, 40);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("CHANNEL SELECTION:");
Dialog.addChoice("Nuclei", channelsSlice, pattern[0]);
Dialog.addToSameRow();
Dialog.addChoice("Nucleoside analogue", channelsSlice, pattern[1]);
Dialog.addChoice("Marker_1", channels, pattern[2]);
Dialog.addToSameRow();
Dialog.addChoice("Marker_2", channels, pattern[3]);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("SEGMENTATION:");
Dialog.addCheckbox("Normalize", normalize);
Dialog.addNumber("Gaussian Blur (sigma)", gaussianNuclei);
Dialog.addToSameRow();
Dialog.addChoice("setAutoThreshold", threshold, thresholdNuclei);
Dialog.addNumber("Erode (iterations)", erodeNuclei);
Dialog.addToSameRow();
Dialog.addNumber("Open (iterations)", openNuclei);
Dialog.setInsets(0, 170, 0);
Dialog.addCheckbox("Watershed", watershedNuclei);
Dialog.addString("Size", size);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("ILLUMINATION CORRECTION IMAGES:");
Dialog.addChoice("Nuclei", illumCorrList, flat_field[0]);
Dialog.addToSameRow();
Dialog.addChoice("Nucleoside analogue", illumCorrList, flat_field[1]);
Dialog.addChoice("Marker_1", illumCorrList, flat_field[2]);
Dialog.addToSameRow();
Dialog.addChoice("Marker_2", illumCorrList, flat_field[3]);

html = "<html>"
	+"Check "
	+"<a href=\"https://github.com/paucabar/cell_proliferation_assay/wiki\">documentation</a>"
	+" for help";
Dialog.addHelp(html);
Dialog.show()
projectName=Dialog.getString();
pattern[0]=Dialog.getChoice();
pattern[1]=Dialog.getChoice();
pattern[2]=Dialog.getChoice();
pattern[3]=Dialog.getChoice();
normalize=Dialog.getCheckbox();
gaussianNuclei=Dialog.getNumber();
thresholdNuclei=Dialog.getChoice();
erodeNuclei=Dialog.getNumber();
openNuclei=Dialog.getNumber();
watershedNuclei=Dialog.getCheckbox();
size=Dialog.getString();
flat_field[0]=Dialog.getChoice();
flat_field[1]=Dialog.getChoice();
flat_field[2]=Dialog.getChoice();
flat_field[3]=Dialog.getChoice();

//check the channel selection
if(pattern[0]==pattern[1]) {
	beep();
	exit("Nuclei ["+pattern[0]+"] and nucleoside analogue ["+pattern[1]+"] channels can not be the same")
} else if (pattern[0]==pattern[2] || pattern[0]==pattern[3]) {
	beep();
	exit("Nuclei ["+pattern[0]+"] and addititional marker ["+pattern[2]+"]/["+pattern[3]+"] channels can not be the same")
} else if (pattern[1]==pattern[2] || pattern[1]==pattern[3]) {
	beep();
	exit("Nucleoside analogue ["+pattern[1]+"] and addititional marker ["+pattern[2]+"]/["+pattern[3]+"] channels can not be the same")
} else if (pattern[2]==pattern[3] && pattern[2]!="Empty") {
	beep();
	exit("Addititional marker ["+pattern[2]+"]/["+pattern[3]+"] channels can not be the same")
}

//get min and max sizes
size=min_max_size(size);

//Create a parameter dataset file
title1 = "Parameter dataset";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "Project\t" + projectName);
print(f, "Nuclei\t" + pattern[0]);
print(f, "Nucleoside analogue\t" + pattern[1]);
print(f, "Marker1\t" + pattern[2]);
print(f, "Marker2\t" + pattern[3]);
print(f, "Enhance (nuclei)\t" + normalize);
print(f, "Gaussian (nuclei)\t" + gaussianNuclei);
print(f, "Threshold (nuclei)\t" + thresholdNuclei);
print(f, "Erode (nuclei)\t" + erodeNuclei);
print(f, "Open (nuclei)\t" + openNuclei);
print(f, "Watershed (nuclei)\t" + watershedNuclei);
print(f, "Size\t" + size[0]+"-"+size[1]);
print(f, "Flat-field (nuclei)\t" + flat_field[0]);
print(f, "Flat-field (nucleoside analogue)\t" + flat_field[1]);
print(f, "Flat-field (marker1)\t" + flat_field[2]);
print(f, "Flat-field (marker2)\t" + flat_field[3]);

//save as TXT
saveAs("txt", dir+File.separator+projectName);
selectWindow(title1);
run("Close");

//'Well Selection' dialog box
selectionOptions=newArray("Select All", "Include", "Exclude");
fileCheckbox=newArray(nWells);
selection=newArray(nWells);
title = "Select Wells";
Dialog.create(title);
Dialog.addRadioButtonGroup("", selectionOptions, 3, 1, selectionOptions[0]);
Dialog.addCheckboxGroup(sqrt(nWells) + 1, sqrt(nWells) + 1, wellName, selection);		
if(mode=="Pre-Analysis (parameter tweaking)") {
	if(fieldsxwell>=10) {
		maxRandomFields=10;
	} else {
		maxRandomFields=fieldsxwell;
	}
	Dialog.addMessage("Random fields per well:");
	Dialog.addSlider("", 1, maxRandomFields, maxRandomFields);
}
Dialog.show();
selectionMode=Dialog.getRadioButton();
if(mode=="Pre-Analysis (parameter tweaking)") {
	maxRandomFields=Dialog.getNumber();
}

for (i=0; i<wellName.length; i++) {
	fileCheckbox[i]=Dialog.getCheckbox();
	if (selectionMode=="Select All") {
		fileCheckbox[i]=true;
	} else if (selectionMode=="Exclude") {
		if (fileCheckbox[i]==true) {
			fileCheckbox[i]=false;
		} else {
			fileCheckbox[i]=true;
		}
	}
}

//check that at least one well have been selected
checkSelection = 0;
for (i=0; i<nWells; i++) {
	checkSelection += fileCheckbox[i];
}

if (checkSelection == 0) {
	exit("There is no well selected");
}

// PRE-ANALYSIS WORKFLOW
if(mode=="Pre-Analysis (parameter tweaking)") {
	print("Initializing 'Pre-Analysis' mode");
	setBatchMode(true);
	for (z=0; z<nWells; z++) {
		if (fileCheckbox[z]==true) {
			randomArray=newArray(maxRandomFields);
			options=fieldsxwell;
			count=0;
			
			// random selection of fields
			while (count < randomArray.length) {
				recurrent=false;
				number=round((options-1)*random);
				for(i=count-1; i>=0; i--) {
					if (number==randomArray[i]) {
						recurrent=true;
					}
				}
				if(recurrent==false || count==0) {
					// open images
					channels_test=newArray(2);
					for (i=0; i<imagesxfield; i++) {
						open(dir+File.separator+tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i]);
						field_channel=getTitle();
						for (j=0; j<channels_test.length; j++) {
							if (indexOf(field_channel, pattern[j]) != -1) {
								channels_test[j]=field_channel;
							}
						}
					}				
					
					print("Pre-Analyzing: "+wellName[z]+" ("+count+1+"/"+randomArray.length+")");
					
					// illumination correction
					if (illumCorr == "Yes") {
						if (flat_field[0] != "None") {
							open(illumCorrPath+File.separator+flat_field[0]);
							imageCalculator("Divide", channels_test[0], flat_field[0]);
							close(flat_field[0]);
						}
						if (flat_field[1] != "None") {
							open(illumCorrPath+File.separator+flat_field[1]);
							imageCalculator("Divide", channels_test[1], flat_field[1]);
							close(flat_field[1]);
						}
					}
					
					// nuclei segmentation
					selectImage(channels_test[0]);
					run("Duplicate...", "title=nuclei_mask");
					if (normalize) {
						run("Enhance Contrast...", "saturated=0.1 normalize");
					}
					run("Gaussian Blur...", "sigma="+gaussianNuclei);
					setAutoThreshold(thresholdNuclei+" dark");
					run("Make Binary");
					run("Options...", "iterations="+erodeNuclei+" count=1 pad do=Erode");
					run("Options...", "iterations="+openNuclei+" count=1 pad do=Open");
					if (watershedNuclei) {
						run("Watershed");
					}

					// visualization image
					run("Set Measurements...", "  redirect=None decimal=2");
					run("Analyze Particles...", "size="+size[0]+"-"+size[1]+" exclude add");		
					displayOutlines(channels_test[0], channels_test[1], 500);

					// clean up
					close("nuclei_mask");
					close(channels_test[0]);
					close(channels_test[1]);

					// update loop variables
					randomArray[count]=number;
					count++;
				}
			}
		}
	}
	// show as a stack
	run("Images to Stack", "name=Stack title=[] use");
	setBatchMode(false);
	print("End of process");
}

// ANALYSIS WORKFLOW
if(mode=="Analysis") {
	print("Running analysis");
	setBatchMode(true);

	// open illumination correction images
	if (illumCorr == "Yes") {
		for (i=0; i<flat_field.length; i++) {
			if (flat_field[i] != "None") {
				open(illumCorrPath+File.separator+flat_field[i]);
			}
		}
	}

	// define variables
	total_fields=checkSelection*fieldsxwell;
	count=0;
	row=newArray;
	column=newArray;
	field=newArray;
	mean_std_ratio=newArray;
	satPix=newArray;
	maxCount=newArray;
	area=newArray;
	circularity=newArray;
	aspect_ratio=newArray;
	solidity=newArray;
	roundness==newArray;
	mean_nucleoside_analogue=newArray;
	intDen_nucleoside_analogue==newArray;
	if (pattern[2] != "Empty") {
		mean_marker1=newArray;
		intDen_marker1==newArray;
		if (pattern[3] != "Empty") {
			mean_marker2=newArray;
			intDen_marker2==newArray;
		}
	}
	
	for (i=0; i<nWells; i++) {
		if (fileCheckbox[i]) {
			for (j=0; j<fieldName.length; j++) {
				print(wellName[i]+" (fld " +fieldName[j] + ") " + count+1+"/"+total_fields);
				counterstain=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern[0]+ " - "+pattern[0]+").tif";
				open(dir+File.separator+counterstain);
				nucleoside_analogue=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern[1]+ " - "+pattern[1]+").tif";
				open(dir+File.separator+nucleoside_analogue);
				if (pattern[2] != "Empty") {
					marker1=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern[2]+ " - "+pattern[2]+").tif";
					open(dir+File.separator+marker1);
					if (pattern[3] != "Empty") {
						marker2=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern[3]+ " - "+pattern[3]+").tif";
						open(dir+File.separator+marker2);
					}
				}
				
				// quality control: blurring
				selectImage(counterstain);
				getStatistics(areaImage, meanImage, minImage, maxImage, stdImage, histogramImage);
				mean_std_ratio[count]=meanImage/stdImage;

				// quality control: % sat pixels
				selectImage(counterstain);
				run("Duplicate...", "title=QC_sat");
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				run("Set Measurements...", "area_fraction display redirect=None decimal=2");
				setThreshold(255, 255);
				run("Measure");
				satPix[count]=getResult("%Area", 0);
				run("Clear Results");
				close("QC_sat");

				// quality control: no content
				selectImage(counterstain);
				run("Duplicate...", "title=QC_nc1");
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				run("Gaussian Blur...", "sigma=1");
				run("Duplicate...", "title=QC_nc2");
				selectImage("QC_nc1");
				run("Find Maxima...", "prominence=100 output=Count");
				maxCount1=getResult("Count", 0);
				selectImage("QC_nc2");
				run("Enhance Contrast...", "saturated=0.4 normalize");
				run("Find Maxima...", "prominence=100 output=Count");
				maxCount2=getResult("Count", 1);
				maxCount[count]=maxCount1/maxCount2;
				run("Clear Results");
				close("QC_nc1");
				close("QC_nc2");

				// illumination correction
				if (illumCorr == "Yes") {
					if (flat_field[0] != "None") {
						imageCalculator("Divide", counterstain, flat_field[0]);
					}
					if (flat_field[1] != "None") {
						imageCalculator("Divide", nucleoside_analogue, flat_field[1]);
					}
					if (flat_field[2] != "None" && pattern[2] != "Empty") {
						imageCalculator("Divide", marker1, flat_field[2]);
					}
					if (flat_field[3] != "None" && pattern[3] != "Empty") {
						imageCalculator("Divide", marker2, flat_field[3]);
					}
				}

				// nuclei segmentation
				selectImage(counterstain);
				run("Duplicate...", "title=nuclei_mask");
				if (normalize) {
					run("Enhance Contrast...", "saturated=0.1 normalize");
				}
				run("Gaussian Blur...", "sigma="+gaussianNuclei);
				setAutoThreshold(thresholdNuclei+" dark");
				run("Make Binary");
				run("Options...", "iterations="+erodeNuclei+" count=1 pad do=Erode");
				run("Options...", "iterations="+openNuclei+" count=1 pad do=Open");
				if (watershedNuclei) {
					run("Watershed");
				}

				// measure nucleoside analogue intensity and object area and shape descriptors
				run("Set Measurements...", "area mean shape integrated display redirect=["+nucleoside_analogue+"] decimal=2");
				run("Analyze Particles...", "size="+size[0]+"-"+size[1]+" display exclude clear add");
				n=nResults;
				for (k=0; k<n; k++) {
					area[count]=getResult("Area", k);
					circularity[count]=getResult("Circ.", k);
					aspect_ratio[count]=getResult("AR", k);
					solidity[count]=getResult("Solidity", k);
					roundness[count]=getResult("Round", k);
					mean_nucleoside_analogue[count]=getResult("Mean", k);
					intDen_nucleoside_analogue[count]=getResult("IntDen", k);
					
					// store metadata as well
					row[count]=substring(wellName[i], 0, 1);
					column[count]=substring(wellName[i], 4, 6);
					field[count]=fieldName[j];
				}

				// save ROIs
				if (saveROIs == "Yes") {
					roiManager("deselect");
					roiManager("save", dir+File.separator+wellName[i]+" (fld " +fieldName[j] + ") ROI.zip");
				}
				roiManager("reset");

				// measure additional markers
				if (pattern[2] != "Empty") {
					run("Set Measurements...", "mean integrated display redirect=["+marker1+"] decimal=2");
					n=nResults;
					for (k=0; k<n; k++) {
						mean_marker1[count]=getResult("Mean", k);
						mean_marker1[count]=getResult("IntDen", k);
					}
					if (pattern[3] != "Empty") {
						run("Set Measurements...", "mean integrated display redirect=["+marker2+"] decimal=2");
						for (k=0; k<n; k++) {
							mean_marker2[count]=getResult("Mean", k);
							mean_marker2[count]=getResult("IntDen", k);
						}
					}
				}

				// clean up
				close(counterstain);
				close(nucleoside_analogue);	
				close("nuclei_mask");
				if (pattern[2] != "Empty") {
					close(marker1);
					if (pattern[3] != "Empty") {
						close(marker2);
					}
				}

				// update count
				count++;
			}
		}
	}
	close("*");
	setBatchMode(false);
	print("End of process");
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

function displayOutlines (image1, image2, threshold) {
	index1=indexOf(image1, "(");
	index2=indexOf(image1, " wv");
	well=substring(image1, 0, index1)+ ")";
	field=substring(image1, index1, index2)+ ")";
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
			roiManager("select", i);
			roiManager("Set Color", "orange");
			roiManager("draw");
		} else {
			roiManager("select", i);
			roiManager("Set Color", "cyan");
			roiManager("draw");
		}
	}
	roiManager("reset");
	run("Clear Results");
}
}