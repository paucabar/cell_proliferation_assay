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
#@ String (label="<html>Project</html>", choices={"Filtering", "StarDist", "Load"}, persist=true, style="radioButtonHorizontal") project
#@ String (label="<html>Load function</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") illumCorr
#@ String (label="<html>Save ROIs?</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") saveROIs
#@ String (label=" ", value="<html><img src=\"https://live.staticflickr.com/65535/48557333566_d2a51be746_o.png\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

//set options
setOption("ExpandableArrays", true);
setOption("BlackBackground", false);
setOption("ScaleConversions", true);
roiManager("reset");
print("\\Clear");
run("Clear Results");
close("*");

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
channels=newArray(imagesxfield);
channels_fullname=newArray(imagesxfield);
count=0;
for (i=0; i<channels.length; i++) {
	index1=indexOf(tifArray[i], "wv ");
	index2=lastIndexOf(tifArray[i], " - ");
	index3=lastIndexOf(tifArray[i], ")");
	channels[i]=substring(tifArray[i], index1 + 3, index2);
	channels_fullname[i]=substring(tifArray[i], index1 + 3, index3);
}

//add an 'Empty' option into a duplicated array of the channels' name
channels_with_empty=channels;
channels_with_empty[channels_with_empty.length]="Empty";

//set some parameter menu arrays
threshold=getList("threshold.methods");
pattern=newArray(4);
flat_field=newArray(4);

//create a flat-field array with a 'None' option
if(illumCorr=="Yes") {
	illumCorrPath=getDirectory("Choose the folder with the illumination correction functions");
	illumCorrList=getFileList(illumCorrPath);
	concatNone=newArray("None");
	illumCorrList=Array.concat(concatNone,illumCorrList);
} else {
	illumCorrList=newArray("None");
}

//Extract values from a parameter dataset file
if(project=="Load") {
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
	project=parameters[1];
	pattern[0]=parameters[2];
	pattern[1]=parameters[3];
	pattern[2]=parameters[4];
	pattern[3]=parameters[5];
	if (project == "Filtering") {
		normalize=parameters[6];
		gaussianNuclei=parameters[7];
		thresholdNuclei=parameters[8];
		erodeNuclei=parameters[9];
		openNuclei=parameters[10];
		watershedNuclei=parameters[11];
		size=parameters[12];
		flat_field[0]=parameters[13];
		flat_field[1]=parameters[14];
		flat_field[2]=parameters[15];
		flat_field[3]=parameters[16];
	} else {
		overlap_threshold=parameters[6];
		size=parameters[7];
		flat_field[0]=parameters[8];
		flat_field[1]=parameters[9];
		flat_field[2]=parameters[10];
		flat_field[3]=parameters[11];
	}
} else {
	//default parameters
	projectName="Project_" + project;
	pattern[0]=channels_with_empty[0];
	pattern[1]=channels_with_empty[0];
	pattern[2]=channels_with_empty[imagesxfield];
	pattern[3]=channels_with_empty[imagesxfield];
	if (project == "Filtering") {
		normalize=true;
		gaussianNuclei=2;
		thresholdNuclei=threshold[6];
		erodeNuclei=2;
		openNuclei=2;
		watershedNuclei=true;
	} else {
		overlap_threshold=0.4;
	}
	size="0-Infinity";
	flat_field[0]="None";
	flat_field[1]="None";
	flat_field[2]="None";
	flat_field[3]="None";
}

//'Select Parameters' dialog box
title = "Select Parameters";
Dialog.create(title);
Dialog.addString("Project", projectName , 40);
Dialog.setInsets(0, 140, 0);
Dialog.addMessage("CHANNEL SELECTION:");
Dialog.addChoice("Nuclei", channels, pattern[0]);
Dialog.addToSameRow();
Dialog.addChoice("Nucleoside analogue", channels, pattern[1]);
Dialog.addChoice("Marker_1", channels_with_empty, pattern[2]);
Dialog.addToSameRow();
Dialog.addChoice("Marker_2", channels_with_empty, pattern[3]);
if (project == "Filtering") {
	Dialog.setInsets(0, 140, 0);
	Dialog.addMessage("SEGMENTATION:");
	Dialog.setInsets(0, 140, 0);
	Dialog.addCheckbox("Normalize", normalize);
	Dialog.addNumber("Gaussian Blur (sigma)", gaussianNuclei);
	Dialog.addChoice("setAutoThreshold", threshold, thresholdNuclei);
	Dialog.addNumber("Erode (iterations)", erodeNuclei);
	Dialog.addNumber("Open (iterations)", openNuclei);
	Dialog.setInsets(0, 140, 0);
	Dialog.addCheckbox("Watershed", watershedNuclei);
} else {
	Dialog.addSlider("Overlap Threshold", 0, 1, overlap_threshold);
}
Dialog.addString("Size", size);
Dialog.setInsets(0, 140, 0);
Dialog.addMessage("ILLUMINATION CORRECTION IMAGES:");
Dialog.addChoice("Nuclei", illumCorrList, flat_field[0]);
Dialog.addToSameRow();
Dialog.addChoice("Nucleoside analogue", illumCorrList, flat_field[1]);
Dialog.addChoice("Marker_1", illumCorrList, flat_field[2]);
Dialog.addToSameRow();
Dialog.addChoice("Marker_2", illumCorrList, flat_field[3]);
html = "<html>"
	+"Check "
	+"<a href=\"https://github.com/paucabar/cell_proliferation_assay\">documentation</a>"
	+" for help";
Dialog.addHelp(html);
Dialog.show()
projectName=Dialog.getString();
pattern[0]=Dialog.getChoice();
pattern[1]=Dialog.getChoice();
pattern[2]=Dialog.getChoice();
pattern[3]=Dialog.getChoice();
if (project == "Filtering") {
	normalize=Dialog.getCheckbox();
	gaussianNuclei=Dialog.getNumber();
	thresholdNuclei=Dialog.getChoice();
	erodeNuclei=Dialog.getNumber();
	openNuclei=Dialog.getNumber();
	watershedNuclei=Dialog.getCheckbox();
} else {
	overlap_threshold=Dialog.getNumber();
}
size=Dialog.getString();
flat_field[0]=Dialog.getChoice();
flat_field[1]=Dialog.getChoice();
flat_field[2]=Dialog.getChoice();
flat_field[3]=Dialog.getChoice();
if (pattern[2]=="Empty" && pattern[3] != "Empty") {
	pattern[2]=pattern[3];
	pattern[3]="Empty";
	flat_field[2]=flat_field[3];
	flat_field[3]="None";
}
pattern_fullname=newArray("Empty", "Empty", "Empty", "Empty");
for (i=0; i<imagesxfield; i++) {
	for (j=0; j<imagesxfield; j++) {
		if (startsWith(channels_fullname[i], pattern[j])) {
			pattern_fullname[j]=channels_fullname[i];
		}
	}
}

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

//Create a parameter dataset file
title1 = "Parameter dataset";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "Title\t" + projectName);
print(f, "Workflow\t" + project);
print(f, "Nuclei\t" + pattern[0]);
print(f, "Nucleoside analogue\t" + pattern[1]);
print(f, "Marker1\t" + pattern[2]);
print(f, "Marker2\t" + pattern[3]);
if (project == "Filtering") {
	print(f, "Enhance (nuclei)\t" + normalize);
	print(f, "Gaussian (nuclei)\t" + gaussianNuclei);
	print(f, "Threshold (nuclei)\t" + thresholdNuclei);
	print(f, "Erode (nuclei)\t" + erodeNuclei);
	print(f, "Open (nuclei)\t" + openNuclei);
	print(f, "Watershed (nuclei)\t" + watershedNuclei);
} else {
	print(f, "Overlap Threshold\t" + overlap_threshold);
}
print(f, "Size\t" + size);
print(f, "Flat-field (nuclei)\t" + flat_field[0]);
print(f, "Flat-field (nucleoside analogue)\t" + flat_field[1]);
print(f, "Flat-field (marker1)\t" + flat_field[2]);
print(f, "Flat-field (marker2)\t" + flat_field[3]);

//save as TXT
saveAs("txt", dir+File.separator+projectName);
selectWindow(title1);
run("Close");

//get min and max sizes
size=min_max_size(size);

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
	measurements=newArray("Area", "Circ.", "AR", "Solidity", "Round", "Mean", "IntDen");
	Dialog.addChoice("Measure", measurements, "Mean");
	Dialog.addNumber("Split threshold", 250);
	Dialog.addNumber("Set Line Width", 3);
}
Dialog.addHelp(html);
Dialog.show();
selectionMode=Dialog.getRadioButton();
if(mode=="Pre-Analysis (parameter tweaking)") {
	maxRandomFields=Dialog.getNumber();
	measure_test=Dialog.getChoice();
	split_test=Dialog.getNumber();
	roi_line_width=Dialog.getNumber();
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
						index1=indexOf(tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i], "wv ");
						index2=lastIndexOf(tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i], " - ");
						current_channel=substring(tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i], index1+3, index2);
						if (current_channel == pattern[0] || current_channel == pattern[1]) {
							open(dir+File.separator+tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i]);
							if (current_channel == pattern[0]) {
								channels_test[0]=getTitle();
							} else {
								channels_test[1]=getTitle();
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

					if (project == "Filtering") {
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
						close("nuclei_mask");
					} else {
						run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'"+channels_test[0]
						+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', "
						+"'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'"+overlap_threshold+"', 'outputType':'ROI Manager', 'nTiles':'1', "
						+"'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', "
						+"'showProbAndDist':'false'], process=[false]");
						sizeSelection(size[0], size[1]);
						excludeEdges();
					}
					displayOutlines(channels_test[0], channels_test[1], measure_test, split_test, roi_line_width);

					// clean up
					close(channels_test[0]);
					close(channels_test[1]);
					roiManager("reset");
					run("Clear Results");

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
	selectWindow("ROI Manager");
	run("Close");
	selectWindow("Results");
	run("Close");
	print("End of process");
}

// ANALYSIS WORKFLOW
if(mode=="Analysis") {
	print("Running analysis");
	setBatchMode(true);
	start=getTime();

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
	count_print=0;
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
	roundness=newArray;
	mean_nucleoside_analogue=newArray;
	intDen_nucleoside_analogue=newArray;
	if (pattern[2] != "Empty") {
		mean_marker1=newArray;
		intDen_marker1=newArray;
		count_m1=0;
		if (pattern[3] != "Empty") {
			mean_marker2=newArray;
			intDen_marker2=newArray;
			count_m2=0;
		}
	}
	
	for (i=0; i<nWells; i++) {
		if (fileCheckbox[i]) {
			for (j=0; j<fieldName.length; j++) {
				print("\\Update1:"+wellName[i]+" (fld " +fieldName[j] + ") " + count_print+1+"/"+total_fields);
				elapsed=round((getTime()-start)/1000);
				expected=elapsed/(count_print+1)*total_fields;
				print("\\Update2:Elapsed time "+hours_minutes_seconds(elapsed));
				print("\\Update3:Estimated time "+hours_minutes_seconds(expected));
				counterstain=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern_fullname[0]+").tif";
				open(dir+File.separator+counterstain);
				nucleoside_analogue=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern_fullname[1]+").tif";
				open(dir+File.separator+nucleoside_analogue);
				if (pattern[2] != "Empty") {
					marker1=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern_fullname[2]+").tif";
					open(dir+File.separator+marker1);
					if (pattern[3] != "Empty") {
						marker2=wellName[i]+"(fld "+fieldName[j]+" wv "+pattern_fullname[3]+").tif";
						open(dir+File.separator+marker2);
					}
				}
				count_print++;
				
				// quality control: blurring
				selectImage(counterstain);
				getStatistics(areaImage, meanImage, minImage, maxImage, stdImage, histogramImage);
				blurring=meanImage/stdImage;

				// quality control: % sat pixels
				selectImage(counterstain);
				run("Duplicate...", "title=QC_sat");
				imageBitDepth=bitDepth();
				if (imageBitDepth != 8) run("8-bit");
				run("Set Measurements...", "area_fraction display redirect=None decimal=2");
				setThreshold(255, 255);
				run("Measure");
				saturated=getResult("%Area", 0);
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
				maxima_ratio=maxCount1/maxCount2;
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

				if (project == "Filtering") {
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
					run("Set Measurements...", "area mean shape integrated display redirect=None decimal=2");
					run("Analyze Particles...", "size="+size[0]+"-"+size[1]+" exclude clear add");
				} else {
					run("Command From Macro", "command=[de.csbdresden.stardist.StarDist2D], args=['input':'"+counterstain
					+"', 'modelChoice':'Versatile (fluorescent nuclei)', 'normalizeInput':'true', 'percentileBottom':'1.0', "
					+"'percentileTop':'99.8', 'probThresh':'0.479071', 'nmsThresh':'"+overlap_threshold+"', 'outputType':'ROI Manager', 'nTiles':'1', "
					+"'excludeBoundary':'2', 'roiPosition':'Automatic', 'verbose':'false', 'showCsbdeepProgress':'false', "
					+"'showProbAndDist':'false'], process=[false]");
					sizeSelection(size[0], size[1]);
					excludeEdges();
				}
				run("Set Measurements...", "area mean shape integrated display redirect=None decimal=2");
				selectImage(nucleoside_analogue);
				roiManager("deselect");
				roiManager("measure");
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

					// store qc measurements
					mean_std_ratio[count]=blurring;
					satPix[count]=saturated;
					maxCount[count]=maxima_ratio;
					count++;
				}
				run("Clear Results");

				// measure additional markers
				if (pattern[2] != "Empty") {
					run("Set Measurements...", "mean integrated display redirect=None decimal=2");
					selectImage(marker1);
					roiManager("deselect");
					roiManager("measure");
					n=nResults;
					for (k=0; k<n; k++) {
						mean_marker1[count_m1]=getResult("Mean", k);
						intDen_marker1[count_m1]=getResult("IntDen", k);
						count_m1++;
					}
					run("Clear Results");
					if (pattern[3] != "Empty") {
						run("Set Measurements...", "mean integrated display redirect=None decimal=2");
						selectImage(marker2);
						roiManager("deselect");
						roiManager("measure");
						n=nResults;
						for (k=0; k<n; k++) {
							mean_marker2[count_m2]=getResult("Mean", k);
							intDen_marker2[count_m2]=getResult("IntDen", k);
							count_m2++;
						}
						run("Clear Results");
					}
				}

				// save ROIs
				if (saveROIs == "Yes" && n != 0) {
					roiManager("deselect");
					roiManager("save", dir+File.separator+wellName[i]+" (fld " +fieldName[j] + ") ROI.zip");
				}

				// clean up
				roiManager("reset");
				close(counterstain);
				close(nucleoside_analogue);	
				close("nuclei_mask");
				if (pattern[2] != "Empty") {
					close(marker1);
					if (pattern[3] != "Empty") {
						close(marker2);
					}
				}
			}
		}
	}
	close("*");
	setBatchMode(false);
	elapsed=round((getTime()-start)/1000);
	print("\\Update0:End of process");
	print("\\Update1:Elapsed time "+hours_minutes_seconds(elapsed));
	print("\\Update2:Saving results");
	print("\\Update3:");

	// results table
	title1 = "Results table";
	title2 = "["+title1+"]";
	f = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	headings="\\Headings:n\tRow\tColumn\tField\tMean/s.d.\t%SatPix\tMaxCountRatio\tArea\tCirc.\tAR\tSolidity\tRound\tMean-"+pattern[1]+"\tIntDen-"+pattern[1];
	if (pattern[2] != "Empty") {
		headings+="\tMean-"+pattern[2]+"\tIntDen-"+pattern[2];
		if (pattern[3] != "Empty") {
			headings+="\tMean-"+pattern[3]+"\tIntDen-"+pattern[3];
		}
	}
	print(f, headings);
	for (i= 0; i<count; i++) {
		n=d2s(i+1, 0);
		rowData=n + "\t" + row[i]+ "\t" + column[i] + "\t" + field[i] + "\t" + mean_std_ratio[i] + "\t" + satPix[i] + "\t"
		+ maxCount[i] + "\t" + area[i] + "\t" + circularity[i] + "\t" + aspect_ratio[i] + "\t" + solidity[i] + "\t"
		+ roundness[i] + "\t" + mean_nucleoside_analogue[i] + "\t" + intDen_nucleoside_analogue[i];
		if (pattern[2] != "Empty") {
			rowData+="\t" + mean_marker1[i] + "\t" + intDen_marker1[i];
			if (pattern[3] != "Empty") {
				rowData+="\t" + mean_marker2[i] + "\t" + intDen_marker2[i];
			}
		}
		print(f, rowData);
	}
	// save as TXT
	saveAs("Text", dir+File.separator+"ResultsTable_"+projectName+".csv");
	selectWindow("Results table");
	run("Close");

	// quality control metrics table
	title1 = "QC_metrics";
	title2 = "["+title1+"]";
	f = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	headings="\\Headings:Row\tColumn\tField\tMean/s.d.\t%SatPix\tMaxCountRatio";
	print(f, headings);
	rowLast="row";
	columnLast="column";
	fieldLast="field";
	for (i= 0; i<count; i++) {
		if (row[i] != rowLast || column[i] != columnLast || field[i] != fieldLast) {
			rowLast=row[i];
			columnLast=column[i];
			fieldLast=field[i];
			rowData=row[i]+ "\t" + column[i] + "\t" + field[i] + "\t" + mean_std_ratio[i] + "\t" + satPix[i] + "\t" + maxCount[i];
			print(f, rowData);
		}
	}
	// save as TXT
	saveAs("Text", dir+File.separator+"QC_metrics_"+projectName+".csv");
	selectWindow("QC_metrics");
	run("Close");
	selectWindow("Results");
	run("Close");
	selectWindow("ROI Manager");
	run("Close");
	print("\\Update2:Analysis successfully completed");
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

function sizeSelection(min, max) {
	roiDiscard=newArray();
	run("Set Measurements...", "area display redirect=None decimal=2");
	roiManager("deselect");
	roiManager("measure");
	nROI=roiManager("count");
	discardCount=0;
	for (i=0; i<nROI; i++) {
		area=getResult("Area", i);
		if (area < min || area > max) {
			roiDiscard[discardCount]=i;
			discardCount++;
		}
	}
	if (discardCount != 0) {
		roiManager("select", roiDiscard);
		roiManager("delete");
	}
	run("Clear Results");
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
	if (roiEdgeCount != 0) {
		roiManager("select", roiEdge);
		roiManager("delete");
	}
	run("Clear Results");
}

function displayOutlines (image1, image2, getMeasure, threshold, line_width) {
	index1=indexOf(image1, "(");
	index2=indexOf(image1, " wv");
	well=substring(image1, 0, index1)+ ")";
	field=substring(image1, index1, index2)+ ")";
	name=well + " " +field;
	run("Merge Channels...", "c1=["+image2+"] c3=["+image1+"] keep");
	rename(name);
	run("Set Measurements...", "area mean shape integrated display redirect=["+image2+"] decimal=2");
	roiManager("deselect");
	roiManager("measure");
	nROI=roiManager("count");
	roiManager("Set Line Width", line_width);
	
	for (a=0; a<nROI; a++) {
		mean=getResult(getMeasure, a);
		if (mean > threshold) {
			roiManager("select", a);
			roiManager("Set Color", "orange");
			roiManager("draw");
		} else {
			roiManager("select", a);
			roiManager("Set Color", "cyan");
			roiManager("draw");
		}
	}
}

function hours_minutes_seconds(seconds) {
	hours=seconds/3600;
	hours_floor=floor(hours);
	remaining_seconds=seconds-(hours_floor*3600);
	remaining_minutes=remaining_seconds/60;
	minutes_floor=floor(remaining_minutes);
	remaining_seconds=remaining_seconds-(minutes_floor*60);
	hours_floor=d2s(hours_floor, 0);
	minutes_floor=d2s(minutes_floor, 0);
	remaining_seconds=d2s(remaining_seconds, 0);
	if (lengthOf(hours_floor) < 2) hours_floor="0"+hours_floor;
	if (lengthOf(minutes_floor) < 2) minutes_floor="0"+minutes_floor;
	if (lengthOf(remaining_seconds) < 2) remaining_seconds="0"+remaining_seconds;
	return hours_floor+":"+minutes_floor+":"+remaining_seconds;
}
}