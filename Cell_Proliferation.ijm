/*
 * Cell_Proliferation
 * Authors: Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia (Valencia, Spain)
 */

//This macro is a high-content screening tool for cell proliferation assays of
//adherent cell cultures. It is based on nucleoside analogue pulse alone or in
//combination with up to two additional nuclear markers.

//choose a macro mode and a directory
#@ String (label=" ", value="<html><font size=6><b>High Content Screening</font><br><font color=teal>Cell Proliferation</font></b></html>", visibility=MESSAGE, persist=false) heading
#@ String(label="Select mode:", choices={"Analysis", "Pre-Analysis (parameter tweaking)"}, style="radioButtonVertical") mode
#@ File(label="Select a directory:", style="directory") dir
#@ String (label="<html>Save ROIs:</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") saveROIs
#@ String (label="<html>Load llumination<br>correction refe-<br>rence image?</html>", choices={"No", "Yes"}, value="Yes", persist=true, style="radioButtonHorizontal") illumCorr
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

wellName=newArray(nWells);
imagesxwell = (tifFiles / nWells);
imagesxfield = (tifFiles / nFields);
fieldsxwell = nFields / nWells;

//Extraction of the ‘channel’ information from the images’ filenames
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


//‘Pre-Analysis (parameter tweaking)’ and ‘Analysis’ parameterization
//browse a parameter dataset file (optional) & define output folder and dataset file names
dirName="Output - " + File.getName(dir);
resultsName="ResultsTable - " + File.getName(dir);
radioButtonItems=newArray("Yes", "No");
//‘Input & Output’ dialog box
Dialog.create("Input & Output");
Dialog.addRadioButtonGroup("Browse a pre-established parameter dataset:", radioButtonItems, 1, 2, "No");
Dialog.addMessage("Output folder:");
Dialog.addString("", dirName, 40);
Dialog.addMessage("Output parameter dataset file (txt):");
Dialog.addString("", "parameter_dataset", 40);
if(mode=="Analysis") {
	Dialog.addMessage("Results table:");
	Dialog.addString("", resultsName, 40);
}
html = "<html>"
	+"Having generated a <b><font color=black>parameter dataset</font></b> txt file using the<br>"
	+"<b><font color=red>Pre-Analysis (parameter tweaking)</font></b> mode it is possible to<br>"
	+"browse the file to apply the pre-established parameters<br>"
	+"<br>"
	+"Check "
	+"<a href=\"https://github.com/paucabar/cell_proliferation_assay/wiki\">documentation</a>"
	+" for help";
Dialog.addHelp(html);
Dialog.show()
browseDataset=Dialog.getRadioButton();
outputFolder=Dialog.getString();
datasetFile=Dialog.getString();
if(mode=="Analysis") {
	resultsTableName=Dialog.getString();
}

//set some parameter menu arrays
enhanceContrastOptions=newArray("0", "0.1", "0.2", "0.3", "0.4", "None");
threshold=getList("threshold.methods");
pattern=newArray(4);

//Extract values from a parameter dataset file
if(browseDataset=="Yes") {
	parametersDatasetPath=File.openDialog("Choose the parameter dataset file to Open:");
	//parameter selection (pre-established)
	parametersString=File.openAsString(parametersDatasetPath);
	parameterRows=split(parametersString, "\n");
	parameters=newArray(parameterRows.length);
	for(i=0; i<parameters.length; i++) {
		parameterColumns=split(parameterRows[i],"\t"); 
		parameters[i]=parameterColumns[1];
	}
	pattern[0]=parameters[0];
	pattern[1]=parameters[1];
	pattern[2]=parameters[2];
	pattern[3]=parameters[3];
	rollingNuclei=parameters[4];
	enhanceNuclei=parameters[5];
	gaussianNuclei=parameters[6];
	thresholdNuclei=parameters[7];
	erodeNuclei=parameters[8];
	openNuclei=parameters[9];
	watershedNuclei=parameters[10];
	rollingNucleoside=parameters[11];
	enhanceNucleoside=parameters[12];
	gaussianNucleoside=parameters[13];
	thresholdNucleoside=parameters[14];
	erodeNucleoside=parameters[15];
	openNucleoside=parameters[16];
	watershedNucleoside=parameters[17];
	minNuclei=parameters[18];
	maxNuclei=parameters[19];
	minNucleoside=parameters[20];
	maxNucleoside=parameters[21];
} else {
	//default parameters
	pattern[0]=channelsSlice[0];
	pattern[1]=channelsSlice[0];
	pattern[2]=channels[imagesxfield];
	pattern[3]=channels[imagesxfield];
	rollingNuclei=50;
	enhanceNuclei=enhanceContrastOptions[4];
	gaussianNuclei=2;
	thresholdNuclei=threshold[6];
	erodeNuclei=2;
	openNuclei=2;
	watershedNuclei=true;
	rollingNucleoside=50;
	enhanceNucleoside=enhanceContrastOptions[1];
	gaussianNucleoside=5;
	thresholdNucleoside=threshold[6];
	erodeNucleoside=2;
	openNucleoside=2;
	watershedNucleoside=true;
	minNuclei=20;
	maxNuclei=300;
	minNucleoside=0;
	maxNucleoside=300;
}

//'Select Parameters' dialog box
//edit parameters
title = "Select Parameters";
Dialog.create(title);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("CHANNEL SELECTION:");
Dialog.addChoice("Nuclei", channelsSlice, pattern[0]);
Dialog.addToSameRow();
Dialog.addChoice("Nucleoside analogue", channelsSlice, pattern[1]);
Dialog.addChoice("Marker_1", channels, pattern[2]);
Dialog.addToSameRow();
Dialog.addChoice("Marker_2", channels, pattern[3]);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("NUCLEI WORKFLOW:");
Dialog.addNumber("Subtract Background (rolling)", rollingNuclei);
Dialog.addToSameRow();
Dialog.addChoice("Enhance Contrast", enhanceContrastOptions, enhanceNuclei);
Dialog.addNumber("Gaussian Blur (sigma)", gaussianNuclei);
Dialog.addToSameRow();
Dialog.addChoice("setAutoThreshold", threshold, thresholdNuclei);
Dialog.addNumber("Erode (iterations)", erodeNuclei);
Dialog.addToSameRow();
Dialog.addNumber("Open (iterations)", openNuclei);
Dialog.setInsets(0, 174, 0);
Dialog.addCheckbox("Watershed", watershedNuclei);
Dialog.addNumber("Size (min)", minNuclei);
Dialog.addToSameRow();
Dialog.addNumber("Size (max)", maxNuclei);
Dialog.setInsets(0, 170, 0);
Dialog.addMessage("NUCLEOSIDE ANALOGUE WORKFLOW:");
Dialog.addNumber("Subtract Background (rolling)", rollingNucleoside);
Dialog.addToSameRow();
Dialog.addChoice("Enhance Contrast", enhanceContrastOptions, enhanceNucleoside);
Dialog.addNumber("Gaussian Blur (sigma)", gaussianNucleoside);
Dialog.addToSameRow();
Dialog.addChoice("setAutoThreshold", threshold, thresholdNucleoside);
Dialog.addNumber("Erode (iterations)", erodeNucleoside);
Dialog.addToSameRow();
Dialog.addNumber("Open (iterations)", openNucleoside);
Dialog.setInsets(0, 174, 0);
Dialog.addCheckbox("Watershed", watershedNucleoside);
Dialog.addNumber("Size (min)", minNucleoside);
Dialog.addToSameRow();
Dialog.addNumber("Size (max)", maxNucleoside);
html = "<html>"
	+"Check "
	+"<a href=\"https://github.com/paucabar/cell_proliferation_assay/wiki\">documentation</a>"
	+" for help";
Dialog.addHelp(html);
Dialog.show()
pattern[0]=Dialog.getChoice();
pattern[1]=Dialog.getChoice();
pattern[2]=Dialog.getChoice();
pattern[3]=Dialog.getChoice();
rollingNuclei=Dialog.getNumber();
enhanceNuclei=Dialog.getChoice();
gaussianNuclei=Dialog.getNumber();
thresholdNuclei=Dialog.getChoice();
erodeNuclei=Dialog.getNumber();
openNuclei=Dialog.getNumber();
watershedNuclei=Dialog.getCheckbox();
minNuclei=Dialog.getNumber();
maxNuclei=Dialog.getNumber();
rollingNucleoside=Dialog.getNumber();
enhanceNucleoside=Dialog.getChoice();
gaussianNucleoside=Dialog.getNumber();
thresholdNucleoside=Dialog.getChoice();
erodeNucleoside=Dialog.getNumber();
openNucleoside=Dialog.getNumber();
watershedNucleoside=Dialog.getCheckbox();
minNucleoside=Dialog.getNumber();
maxNucleoside=Dialog.getNumber();

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

//Create an output folder
outputFolderPath=dir+"\\"+outputFolder;
File.makeDirectory(outputFolderPath);

//Create a parameter dataset file
title1 = "Parameter dataset";
title2 = "["+title1+"]";
f = title2;
run("Table...", "name="+title2+" width=500 height=500");
print(f, "Nuclei\t" + pattern[0]);
print(f, "Nucleoside analogue\t" + pattern[1]);
print(f, "Marker1\t" + pattern[2]);
print(f, "Marker2\t" + pattern[3]);
print(f, "Rolling (nuclei)\t" + rollingNuclei);
print(f, "Enhance (nuclei)\t" + enhanceNuclei);
print(f, "Gaussian (nuclei)\t" + gaussianNuclei);
print(f, "Threshold (nuclei)\t" + thresholdNuclei);
print(f, "Erode (nuclei)\t" + erodeNuclei);
print(f, "Open (nuclei)\t" + openNuclei);
print(f, "Watershed (nuclei)\t" + watershedNuclei);
print(f, "Rolling (nucleoside)\t" + rollingNucleoside);
print(f, "Enhance (nucleoside)\t" + enhanceNucleoside);
print(f, "Gaussian (nucleoside)\t" + gaussianNucleoside);
print(f, "Threshold (nucleoside)\t" + thresholdNucleoside);
print(f, "Erode (nucleoside)\t" + erodeNucleoside);
print(f, "Open (nucleoside)\t" + openNucleoside);
print(f, "Watershed (nucleoside)\t" + watershedNucleoside);
print(f, "Size-Min (nuclei)\t" + minNuclei);
print(f, "Size-Max (nuclei)\t" + maxNuclei);
print(f, "Size-Min (nucleoside)\t" + minNucleoside);
print(f, "Size-Max (nucleoside)\t" + maxNucleoside);

//save as TXT
saveAs("txt", outputFolderPath+"\\"+datasetFile);
selectWindow(title1);
run("Close");

//create an array containing the well codes
for (i=0; i<nWells; i++) {
	wellName[i]=well[i*imagesxwell];
}

//'Well Selection' dialog box
fileCheckbox=newArray(nWells);
selection=newArray(nWells);
title = "Select Wells";
Dialog.create(title);
Dialog.addCheckbox("Select All", true);
Dialog.addCheckboxGroup(8, 12, wellName, selection);
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
selectAll=Dialog.getCheckbox();
for (i=0; i<nWells; i++) {
	fileCheckbox[i]=Dialog.getCheckbox();
	if (selectAll==true) {
		fileCheckbox[i]=true;
	}
}
if(mode=="Pre-Analysis (parameter tweaking)") {
	maxRandomFields=Dialog.getNumber();
}

//check that at least one well have been selected
checkSelection = 0;
for (i=0; i<nWells; i++) {
	checkSelection += fileCheckbox[i];
}

if (checkSelection == 0) {
	exit("There is no well selected");
}

setOption("BlackBackground", false);





//Pre-Analysis workflow
if(mode=="Pre-Analysis (parameter tweaking)") {
	print("Initializing 'Pre-Analysis' mode");
	setBatchMode(true);
	for (z=0; z<nWells; z++) { //nWells FOR statement beginning
		if (fileCheckbox[z]==true) { //checkbox IF statement beginning
			randomArray=newArray(maxRandomFields);
			options=fieldsxwell;
			count=0;
			//Random selection of fields
			while (count < randomArray.length) {
				recurrent=false;
				number=round((options-1)*random);
				for(i=count-1; i>=0; i--) {
					if (number==randomArray[i]) {
						recurrent=true;
					}
				}
				if(recurrent==false || count==0) {
					//Open images
					for (i=0; i<imagesxfield; i++) {
						open(dir+"\\"+tifArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i]);
					}
					
					print("Pre-Analyzing: "+wellName[z]+" ("+count+1+"/"+randomArray.length+")");

					//Channel images checkpoint
					if (nImages==imagesxfield) { //nImages IF statement beginning
						//Channel identification
						channelIdentification(imagesxfield, pattern);
	
						//8-bits conversion (nuclei & nucleoside analogue)
						selectImage(pattern[0]);
						run("8-bit");
						selectImage(pattern[1]);
						run("8-bit");
	
						//maximaFilter checkpoint
						aproxN=maximaFilter(pattern[0]);
						if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning
							//Merge channels
							run("Merge Channels...", "c1="+pattern[1]+" c3="+pattern[0]+" create keep");
							run("Stack to RGB");
							rename("RGB");
							//Draw the outlines of the nuclei and nucleoside analogue binary masks
							//Nuclei segmentation
							segmentationPreAnalysis(pattern[0], rollingNuclei, enhanceNuclei, gaussianNuclei, thresholdNuclei, erodeNuclei, openNuclei, watershedNuclei, "RGB", minNuclei, maxNuclei, 0, 255, 255);
							//Nucleoside analogue segmentation
							segmentationPreAnalysis(pattern[1], rollingNucleoside, enhanceNucleoside, gaussianNucleoside, thresholdNucleoside, erodeNucleoside, openNucleoside, watershedNucleoside, "RGB", minNucleoside, maxNucleoside, 255, 105, 0);							
							//Save the image
							saveAs("tif", outputFolderPath+"\\"+wellName[z]+" fld "+field[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)]);
							//Clean up
							cleanUp();
							randomArray[count]=number;
							count++;
						} else { //maxima filter ELSE statement
							beep();
							cleanUp();
						} //maxima filter IF-ELSE statement ending
						cleanUp();
					} else { //nImages ELSE statement
						beep();
						cleanUp();
					} //nImages IF-ELSE statement ending
				}
			}
		}
	} //nWells FOR statement ending
	
	setBatchMode(false);
	print("End of process");
	print("Find the output at:");
	print(outputFolderPath);
	//Visualization
	setVisualization(outputFolderPath);
}

//Analysis workflow
if(mode=="Analysis") {
	print("Initializing 'Analysis' mode");
	wellsToAnalyze=0;
	for(i=0; i<fileCheckbox.length; i++) {
		if(fileCheckbox[i]==true) {
			wellsToAnalyze++;
		}
	}
	fieldsToAnalyze=fieldsxwell*wellsToAnalyze;
	setBatchMode(true);
	count=0;
	count3=0;
	firstRound=true;
	for (z=0; z<nWells; z++) { //nWells FOR statement beginning
		count2=0;
		while (count2 < fieldsxwell) { //count2 WHILE  statement beginning
			if (fileCheckbox[z]==true) { //checkbox IF statement beginning
				//Open images
				for (i=0; i<imagesxfield; i++) {
					open(dir+"\\"+tifArray[count]);
					count++;
				}
				count2++;
				count3++;
				wellAndFieldName=wellName[z]+ " fld " +field[count-1];
				print("\\Clear");
				print("Analyzing: "+wellAndFieldName+" ("+count3+"/"+fieldsToAnalyze+")");
				progress=count3/fieldsToAnalyze*100;
				progressString=d2s(progress, 0);
				progressBar="|";
				for (i=2; i<=100; i+=2) {
					if (progress>=i) {
						progressBar+="*";
					} else {
						progressBar+="-";
					}
				}
				progressBar+="|";
				print(progressBar, progressString, "%");
				
				//Channel images checkpoint
				if (nImages==imagesxfield) { //nImages IF statement beginning
					//Channel identification
					channelIdentification(imagesxfield, pattern);

					//8-bits conversion (nuclei & nucleoside analogue)
					selectImage(pattern[0]);
					run("8-bit");
					selectImage(pattern[1]);
					run("8-bit");

					//maximaFilter checkpoint
					aproxN=maximaFilter(pattern[0]);
					if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning

						//Nuclei segmentation
						segmentation(pattern[0], rollingNuclei, enhanceNuclei, gaussianNuclei, thresholdNuclei, erodeNuclei, openNuclei, watershedNuclei);
						//Nucleoside analogue segmentation
						segmentation(pattern[1], rollingNucleoside, enhanceNucleoside, gaussianNucleoside, thresholdNucleoside, erodeNucleoside, openNucleoside, watershedNucleoside);
						rename("Segmented");
						//Nucleoside analogue size selection
						run("Analyze Particles...", "size="+minNucleoside+"-"+maxNucleoside+" show=Masks");
						rename(pattern[1]);
						close("Segmented");
		
						//One by one nuclei analysis
						//Create a nuclei ‘Count Masks’ image
						nFeat=createCountMasks(pattern[0], minNuclei, maxNuclei);
						imageResults=newArray(nFeat);
						meanResult1=newArray(nFeat);
						meanResult2=newArray(nFeat);
						imageDataname=newArray(nFeat);
						//Single nucleus segmentation
						for (i=1; i<=nFeat; ++1) { //nucleus by nucleus analysis FOR statement beginning
							nameNucleous=pattern[0]+"-"+i;
							nameM1=pattern[1]+"-"+i;
							//Nucleoside analogue analysis
							imageResults[i-1]=nucleosideAnalysis(pattern[0], nameNucleous, i, pattern[1], nameM1);
							//Additional marker 1 analysis
							meanResult1[i-1]=markerAnalysis(pattern[2], nameNucleous);
							//Additional marker 2 analysis
							meanResult2[i-1]=markerAnalysis(pattern[3], nameNucleous);
							//Close binary images of nucleoside analogue nucleous-by-nucleous loop
							close(nameM1);
							close(nameNucleous);

							//Results storage
							imageDataname[i-1]=wellAndFieldName;
							if(i==nFeat) {
								if(firstRound==true) {
									nucleosideAnalogue=imageResults;
									marker1=meanResult1;
									marker2=meanResult2;
									dataname=imageDataname;
									firstRound=false;
								} else {
									nucleosideAnalogue=Array.concat(nucleosideAnalogue, imageResults);
									marker1=Array.concat(marker1, meanResult1);
									marker2=Array.concat(marker2, meanResult2);
									dataname=Array.concat(dataname, imageDataname);
								}
								
							}
						} //nucleus by nucleus analysis FOR statement ending
						cleanUp();
					
					} else { //maxima filter ELSE statement
						beep();
						cleanUp();
					} //maxima filter IF-ELSE statement ending
					cleanUp();
				} else { //nImages ELSE statement
					beep();
					cleanUp();
				} //nImages IF-ELSE statement ending
			} else { //checkbox ELSE statement
				count += imagesxwell;
				count2 = fieldsxwell;
			} //checkbox IF-ELSE statement ending
		} //count2 WHILE  statement ending
	} //nWells FOR statement ending
	
	setBatchMode(false);
	
	//results table
	resultsTable("Results table", pattern[2], pattern[3], dataname, nucleosideAnalogue, marker1, marker2);
	//save as TXT
	saveAs("txt", outputFolderPath+"\\"+resultsTableName);
	selectWindow("Results table");
	run("Close");
	// From ImageJ website (macro examples GetDateAndTime.txt)
	// This macro demonstrates how to use the getDateAndTime() 
	// function, available in ImageJ 1.34n or later.
	MonthNames = newArray("Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec");
	DayNames = newArray("Sun", "Mon","Tue","Wed","Thu","Fri","Sat");
	getDateAndTime(year, month, dayOfWeek, dayOfMonth, hour, minute, second, msec);
	TimeString ="Date: "+DayNames[dayOfWeek]+" ";
	if (dayOfMonth<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+dayOfMonth+"-"+MonthNames[month]+"-"+year+"\nTime: ";
	if (hour<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+hour+":";
	if (minute<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+minute+":";
	if (second<10) {TimeString = TimeString+"0";}
	TimeString = TimeString+second;
	title1 = "Info";
	title2 = "["+title1+"]";
	fInfo = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	print(fInfo, "ImageJ "+getVersion());
	print(fInfo, TimeString);
	saveAs("txt", outputFolderPath+"\\Info");
	selectWindow("Info");
	run("Close");
	print("\\Clear");
	print("ImageJ "+getVersion());
	print(TimeString);
	print("");
	print("End of process");
	print("Find the results table at:");
	print(outputFolderPath);
	print("");
}