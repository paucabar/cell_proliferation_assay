/*
 * Cell_proliferationHCS
 * Authors: Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia (Valencia, Spain)
 * 
 * February 2018
 * Last update: September 11, 2018
 */

//This macro is a high-content screening tool for cell proliferation assays of
//adherent cell cultures. It is based on nucleoside analogue pulse alone or in
//combination with up to two additional nuclear markers.


macro "Cell_proliferationHCS" {

//choose a macro mode and a directory
#@ String (label=" ", value="<html><font size=6><b>High Content Screening</font><br><font color=teal>Cell Proliferation</font></b></html>", visibility=MESSAGE, persist=false) heading
#@ String(label="Select mode:", choices={"Analysis", "Pre-Analysis (parameter tweaking)", "Pre-Analysis (visualization)", "Filename Transformation"}, style="radioButtonVertical") mode
#@ File(label="Select a directory:", style="directory") dir
#@ String (label=" ", value="<html><img src=\"http://oi64.tinypic.com/ekrmvs.jpg\"></html>", visibility=MESSAGE, persist=false) logo
#@ String (label=" ", value="<html><font size=2><b>Neuromolecular Biology Lab</b><br>ERI BIOTECMED - Universitat de València (Spain)</font></html>", visibility=MESSAGE, persist=false) message

	requires("1.52e");

	if (mode=="Analysis" || mode=="Pre-Analysis (parameter tweaking)") {
		
		//create an array containing the names of the files in the directory path
		list = getFileList(dir);
		Array.sort(list);
		tiffFiles=0;
	
		//count the number of TIFF files
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "tif")) {
				tiffFiles++;
			}
		}

		//check that the directory contains TIFF files
		if (tiffFiles==0) {
			beep();
			exit("No TIFF files")
		}

		//create a an array containing only the names of the TIFF files in the directory path
		tiffArray=newArray(tiffFiles);
		count=0;
		for (i=0; i<list.length; i++) {
			if (endsWith(list[i], "tif")) {
				tiffArray[count]=list[i];
				count++;
			}
		}
	
		//calculate: number of wells, images per well, images per field and fields per well
		nWells=1;
		nFields=1;
		well=newArray(tiffFiles);
		field=newArray(tiffFiles);
		well0=substring(tiffArray[0],0,6);
		field0=substring(tiffArray[0],11,14);
	
		for (i=0; i<tiffArray.length; i++) {
			well[i]=substring(tiffArray[i],0,6);
			field[i]=substring(tiffArray[i],11,14);
			well1=substring(tiffArray[i],0,6);
			field1=substring(tiffArray[i],11,14);
			if (field0!=field1 || well1!=well0) {
				nFields++;
				field0=substring(tiffArray[i],11,14);
			}
			if (well1!=well0) {
				nWells++;
				well0=substring(tiffArray[i],0,6);
			}
		}
	
		wellName=newArray(nWells);
		imagesxwell = (tiffFiles / nWells);
		imagesxfield = (tiffFiles / nFields);
		fieldsxwell = nFields / nWells;
	
		//create an array containing the names of the channels
		channels=newArray(imagesxfield+1);
		count=0;
		while (channels.length > count+1) {
			index1=indexOf(tiffArray[count], "wv ");
			index2=lastIndexOf(tiffArray[count], " - ");
			channels[count]=substring(tiffArray[count], index1+3, index2);
			count++;
		}
		
		//add an "Empty" option into the channels name array
		for (i=0; i<channels.length; i++) {
			if(i>=imagesxfield) {
				channels[i]="Empty";
			}
		}
	
		//create a channel array without the "Empty" option
		channelsSlice=Array.slice(channels, 0, channels.length-1);

		//browse a parameter dataset file (optional) & define output folder and dataset file names
		dirName="Output - " + File.getName(dir);
		resultsName="ResultsTable - " + File.getName(dir);
		radioButtonItems=newArray("Yes", "No");
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
			+"browse the file to apply the pre-established parameters";
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
	
		//parameter selection (edit)
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
			+"<img src=\"https://upload.wikimedia.org/wikipedia/commons/thumb/7/75/Emblem_of_the_First_Galactic_Empire.svg/220px-Emblem_of_the_First_Galactic_Empire.svg.png\"<br>"
			+"<br>"
			+"<font size=+1>"
			+"<b>Funded by the <font color=red>Galactic Empire</font></b><br>"
			+"<br>"
			+"<font size=-1>"
			+"In ImageJ 1.46b or later, dialog boxes<br>"
			+"can have a <b>Help</b> button that displays<br>"
			+"<font color=red>HTML</font> formatted text.<br>"
			+"</font>";
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

		//create an output directory
		outputFolderPath=dir+"\\"+outputFolder;
		File.makeDirectory(outputFolderPath);
		
		//create parameter dataset
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

		//save as txt
		saveAs("txt", outputFolderPath+"\\"+datasetFile);
		selectWindow(title1);
		run("Close");
	
		//create an array containing the well codes
		for (i=0; i<nWells; i++) {
			wellName[i]=well[i*imagesxwell];
		}
	
		//select wells
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
	}

	if(mode=="Filename Transformation") {
		formats=newArray("Operetta", "NIS Elements");
		Dialog.create("Input Format");
		Dialog.addRadioButtonGroup("Select:", formats, formats.length, 1, formats[0]);
		Dialog.show()
		inputFormat=Dialog.getRadioButton();
	}

	if(mode=="Analysis") {
		//open images
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
					for (i=0; i<imagesxfield; i++) {
						open(dir+"\\"+tiffArray[count]);
						count++;
					}
					count2++;
					count3++;
					wellAndFieldName=wellName[z]+ " fld " +field[count-1];
					print("Analyzing: "+wellAndFieldName+" ("+count3+"/"+fieldsToAnalyze+")");
					
					//check that the correct number of images have been opened
					if (nImages==imagesxfield) { //nImages IF statement beginning
						//channel identification
						channelIdentification(imagesxfield, pattern);
	
						//nuclei & nucleoside analogue ---> 8-bits
						selectImage(pattern[0]);
						run("8-bit");
						selectImage(pattern[1]);
						run("8-bit");
	
						//maxima filter
						aproxN=maximaFilter(pattern[0]);
						if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning
	
							//segmentation
							//nuclei segmentation
							segmentation(pattern[0], rollingNuclei, enhanceNuclei, gaussianNuclei, thresholdNuclei, erodeNuclei, openNuclei, watershedNuclei);
							//nucleoside analogue segmentation
							segmentation(pattern[1], rollingNucleoside, enhanceNucleoside, gaussianNucleoside, thresholdNucleoside, erodeNucleoside, openNucleoside, watershedNucleoside);
							rename("Segmented");
							run("Analyze Particles...", "size="+minNucleoside+"-"+maxNucleoside+" show=Masks");
							rename(pattern[1]);
							close("Segmented");
			
							//One by one nuclei analysis
							//create count masks image
							nFeat=createCountMasks(pattern[0], minNuclei, maxNuclei);
							imageResults=newArray(nFeat);
							meanResult1=newArray(nFeat);
							meanResult2=newArray(nFeat);
							imageDataname=newArray(nFeat);
							//single nucleus segmentation
							for (i=1; i<=nFeat; ++1) { //nucleus by nucleus analysis FOR statement beginning
								nameNucleous=pattern[0]+"-"+i;
								nameM1=pattern[1]+"-"+i;
								//nucleoside analogue
								imageResults[i-1]=nucleosideAnalysis(pattern[0], nameNucleous, i, pattern[1], nameM1);
								//marker1
								meanResult1[i-1]=markerAnalysis(pattern[2], nameNucleous);
								//marker2
								meanResult2[i-1]=markerAnalysis(pattern[3], nameNucleous);
								//close binary images of nucleoside analogue nucleous-to-nucleous loop
								close(nameM1);
								close(nameNucleous);
								
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
						
						//major loops endings
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
		//save as txt
		saveAs("txt", outputFolderPath+"\\"+resultsTableName);
		selectWindow("Results table");
		run("Close");
		print("End of process");
	}

	if(mode=="Pre-Analysis (parameter tweaking)") {
		//open images
		print("Initializing 'Pre-Analysis' mode");
		setBatchMode(true);
		for (z=0; z<nWells; z++) { //nWells FOR statement beginning
			if (fileCheckbox[z]==true) { //checkbox IF statement beginning
				randomArray=newArray(maxRandomFields);
				options=fieldsxwell;
				count=0;
				while (count < randomArray.length) {
					recurrent=false;
					number=round((options-1)*random);
					for(i=count-1; i>=0; i--) {
						if (number==randomArray[i]) {
							recurrent=true;
						}
					}
					if(recurrent==false || count==0) {
						for (i=0; i<imagesxfield; i++) {
							open(dir+"\\"+tiffArray[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)+i]);
						}
						
						print("Pre-Analyzing: "+wellName[z]+" ("+count+1+"/"+randomArray.length+")");

						//check that the correct number of images have been opened
						if (nImages==imagesxfield) { //nImages IF statement beginning
							//channel identification
							channelIdentification(imagesxfield, pattern);
		
							//nuclei & nucleoside analogue ---> 8-bits
							selectImage(pattern[0]);
							run("8-bit");
							selectImage(pattern[1]);
							run("8-bit");
		
							//maxima filter
							aproxN=maximaFilter(pattern[0]);
							if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning
								//merge channels
								run("Merge Channels...", "c1="+pattern[1]+" c3="+pattern[0]+" create keep");
								run("Stack to RGB");
								rename("RGB");
								//segmentation
								//nuclei segmentation
								segmentationPreAnalysis(pattern[0], rollingNuclei, enhanceNuclei, gaussianNuclei, thresholdNuclei, erodeNuclei, openNuclei, watershedNuclei, "RGB", minNuclei, maxNuclei, 0, 255, 255);
								//nucleoside analogue segmentation
								segmentationPreAnalysis(pattern[1], rollingNucleoside, enhanceNucleoside, gaussianNucleoside, thresholdNucleoside, erodeNucleoside, openNucleoside, watershedNucleoside, "RGB", minNucleoside, maxNucleoside, 255, 105, 0);							
								//save as tiff
								saveAs("tiff", outputFolderPath+"\\"+wellName[z]+" fld "+field[(z*fieldsxwell*imagesxfield)+(number*imagesxfield)]);
								cleanUp();
								randomArray[count]=number;
								count++;
							//major loops endings
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
		//visualization
		setVisualization(outputFolderPath);
	}

	if(mode=="Pre-Analysis (visualization)") {
		open(dir+"\\"+"Multi-image.tif");
	}

	if(mode=="Filename Transformation") {
		print("Initializing 'Filename Transformation' mode");
		if(inputFormat=="Operetta") {
			//create an array containing the names of the files in the directory path
			list = getFileList(dir);
			Array.sort(list);
			tiffFiles=0;
		
			//count the number of TIFF files
			for (i=0; i<list.length; i++) {
				if (endsWith(list[i], "tif") || endsWith(list[i], "tiff")) {
					tiffFiles++;
				}
			}
	
			//check that the directory contains TIFF files
			if (tiffFiles==0) {
				beep();
				exit("No TIFF files")
			}
	
			//create a an array containing only the names of the TIFF files in the directory path
			tiffArray=newArray(tiffFiles);
			count=0;
			for (i=0; i<list.length; i++) {
				if (endsWith(list[i], "tif") || endsWith(list[i], "tiff")) {
					tiffArray[count]=list[i];
					count++;
				}
			}
			//create an output directory
			outputFolderPath=dir+"\\Filename Transformation";
			File.makeDirectory(outputFolderPath);

			setBatchMode(true);
			for(i=0; i<tiffArray.length; i++) {
				open(dir+"\\"+tiffArray[i]);
				print("Load: "+tiffArray[i]);
				well=substring(tiffArray[i], 0, 6);
				fIndex=indexOf(tiffArray[i], "f");
				pIndex=indexOf(tiffArray[i], "p");
				field=substring(tiffArray[i], fIndex+1, pIndex);
				while(lengthOf(field)<3) {
					field="0"+field;
				}
				chIndex=indexOf(tiffArray[i], "ch");
				skIndex=indexOf(tiffArray[i], "sk");
				channel=substring(tiffArray[i], chIndex, skIndex);
				saveAs("tiff", outputFolderPath+"\\"+well+"(fld "+field+" wv "+channel+" - "+channel+")");
				close();
				print("Save as: "+well+"(fld "+field+" wv "+channel+" - "+channel+").tif");
			}
			setBatchMode(false);
		}

		if(inputFormat=="NIS Elements") {
			//create an array containing the names of the files in the directory path
			list = getFileList(dir);
			Array.sort(list);
			tiffFiles=0;
		
			//count the number of TIFF files
			for (i=0; i<list.length; i++) {
				if (endsWith(list[i], "tif")) {
					tiffFiles++;
				}
			}
	
			//check that the directory contains TIFF files
			if (tiffFiles==0) {
				beep();
				exit("No TIFF files")
			}
	
			//create a an array containing only the names of the TIFF files in the directory path
			tiffArray=newArray(tiffFiles);
			count=0;
			for (i=0; i<list.length; i++) {
				if (endsWith(list[i], "tif")) {
					tiffArray[count]=list[i];
					count++;
				}
			}
			//create an output directory
			outputFolderPath=dir+"\\Filename Transformation";
			File.makeDirectory(outputFolderPath);

			//dialog box
			Dialog.create("NIS Elements");
			Dialog.addSlider("Digits (field):", 1, 3, 3);
			Dialog.show()
			digits=Dialog.getNumber();

			setBatchMode(true);
			for(i=0; i<tiffArray.length; i++) {
				open(dir+"\\"+tiffArray[i]);
				print("Load: "+tiffArray[i]);
				extensionIndex=indexOf(tiffArray[i], ".tif");
				cLastIndex=lastIndexOf(tiffArray[i], "c");
				channel=substring(tiffArray[i], cLastIndex, extensionIndex);
				field=substring(tiffArray[i], cLastIndex-digits, cLastIndex);
				while(lengthOf(field)<3) {
					field="0"+field;
				}
				if(cLastIndex-digits<=6) {
					well=substring(tiffArray[i], 0, cLastIndex-digits);
					while(lengthOf(well)<6) {
						well+=" ";
					}
				} else {
					well=substring(tiffArray[i], 0, 6);
				}
				saveAs("tiff", outputFolderPath+"\\"+well+"(fld "+field+" wv "+channel+" - "+channel+")");
				close();
				print("Save as: "+well+"(fld "+field+" wv "+channel+" - "+channel+").tif");
			}
			setBatchMode(false);
		}
		print("End of process");
	}

	/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
	//user-defined functions

	function channelIdentification(imageNumber, channels) { //CHANNELIDENTIFICATION function beginning
		fileArray=newArray(imageNumber);
		for (i=1; i<=imageNumber; i++) {
			selectImage(i);
			ima1=getTitle();
			fileArray[i-1]=ima1;
		}

		for (j=1; j<=imageNumber; j++) {
			for (i=1; i<=imageNumber; i++) {
				if (indexOf (fileArray[i-1], channels[j-1])>0) {
					selectImage(fileArray[i-1]);
					rename (channels[j-1]);
				}
			}
		}
	} //CHANNELIDENTIFICATION function ending
	
	function maximaFilter(image) { //MAXIMAFILTER function beginning
		selectImage(image);
		run("Duplicate...", "title="+image+"-MaximaFilter");
		run("Subtract Background...", "rolling=50");
		run("Enhance Contrast...", "saturated=0.4 normalize");
		run("Find Maxima...", "noise=100 output=[Count]");
		localMaxima=getResult("Count", 0);
		run("Clear Results");
		close(image+"-MaximaFilter");
		return localMaxima;
	} //MAXIMAFILTER function ending

	function segmentation(image, rolling, enhance, gaussian, threshold, erode, openArg, watershed) { //SEGMENTATION function beginning
		selectImage(image);
		run("Subtract Background...", rolling);
		if(enhance!="None") {
			run("Enhance Contrast...", "saturated="+enhance+" normalize");
		}
		run("Gaussian Blur...", "sigma="+gaussian);
		setAutoThreshold(threshold+" dark");
		run("Convert to Mask");
		run("Fill Holes");
		run("Options...", "iterations="+erode+" count=1 do=Erode");
		run("Options...", "iterations="+openArg+" count=1 do=Open");
		if(watershed) {
			run("Watershed");
		}
	} //SEGMENTATION function ending

	function createCountMasks(image, min, max) { //CREATECOUNTMASKS function beginning
		selectImage(image);
		run("Analyze Particles...", " size="+min+"-"+max+" show=[Count Masks] display clear");					
		rename(image+"-Count Masks");
		close(image);
		output=nResults;
		run("Clear Results");
		return output;
	} //CREATECOUNTMASKS function ending
	
	function nucleosideAnalysis(nuclei, nucleusIter, iter, nucleoside, nucleosideIter) { //NUCLEOSIDEANALYSIS function beginning
		run("Set Measurements...", "display redirect=None decimal=2");
		selectImage(nuclei+"-Count Masks");
		run("Duplicate...", "title="+nucleusIter);
		setThreshold(iter, iter);
		run("Convert to Mask");
		run("Make Binary");	
		//binary reconstruct of nucleoside analogue
		run("BinaryReconstruct ", "mask="+nucleoside+ " seed="+nucleusIter+" create white");
		rename(nucleosideIter);
		run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
		results=nResults;
		if (results>0) {
			outcome=1;
		} else {
			outcome=0;
		}
		run("Clear Results");
		return outcome;
	} //NUCLEOSIDEANALYSIS function ending

	function markerAnalysis(marker, nucleusIter) { //MARKER function beginning
		if (marker!="Empty") {
			selectImage(nucleusIter);
			run("Set Measurements...", "mean redirect="+marker+" decimal=2");
			run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
			output=getResult("Mean", 0);
			run("Clear Results");
		} else {
			output=0;
		}
		return output;
	} //MARKER function ending

	function resultsTable(title, m1, m2, nameArray, nucleosideArray, m1Array, m2Array) { //RESULTSTABLE function beginning
		title1 = title;
		title2 = "["+title1+"]";
		f = title2;
		run("Table...", "name="+title2+" width=500 height=500");
		print(f, "\\Headings:n\tdataname\tS-phase\t"+m1+"\t"+m2);
		for (i=0; i<nucleosideArray.length; i++) {
			print(f, i+1 + "\t" + nameArray[i]+ "\t" + nucleosideArray[i] + "\t" + m1Array[i] + "\t" + m2Array[i]);
		}
	} //RESULTSTABLE function ending

	function segmentationPreAnalysis(image, rolling, enhance, gaussian, threshold, erode, openArg, watershed, preview, min, max, r, g, b) { //SEGMENTATION function beginning
		selectImage(image);
		run("Subtract Background...", rolling);
		if(enhance!="None") {
			run("Enhance Contrast...", "saturated="+enhance+" normalize");
		}
		run("Gaussian Blur...", "sigma="+gaussian);
		setAutoThreshold(threshold+" dark");
		run("Convert to Mask");
		run("Fill Holes");
		run("Options...", "iterations="+erode+" count=1 do=Erode");
		run("Options...", "iterations="+openArg+" count=1 do=Open");
		if(watershed) {
			run("Watershed");
		}
		run("Analyze Particles...", "size="+min+"-"+max+" show=Masks");
		setThreshold(255, 255);
		run("Create Selection");
		roiManager("Add");
		selectImage(preview);
		setForegroundColor(r, g, b);
		roiManager("draw");
		roiManager("delete");
		run("Select None");
	} //SEGMENTATION function ending

	function cleanUp() { //CLEAN-UP function beginning
		if (isOpen("Results")) {
			selectWindow("Results");
			run("Close");
		}
		if (isOpen("Threshold")) {
			selectWindow("Threshold"); 
			run("Close");
		}
		while (nImages()>0) {
			selectImage(nImages());  
			run("Close");
		}
	} //CLEAN-UP function ending

	function setVisualization(folder) {
		setBatchMode(true);
		run("Image Sequence...", "open=["+folder+"] file=tif sort");
		width=getWidth(); 
		height=getHeight();
		setBackgroundColor(255, 255, 255);
		run("Canvas Size...", "width="+width+width*0.05+" height="+height+" position=Center");
		width=getWidth();
		run("Canvas Size...", "width="+width+" height="+height+height*0.025+" position=Bottom-Center");
		height=getHeight();
		run("Canvas Size...", "width="+width+" height="+height+height*0.10+" position=Top-Center");
		Stack.getDimensions(width, finalHeight, channels, slices, frames);
		for (i=1; i<=slices; i++) {
			Stack.setSlice(i);
			setForegroundColor(0, 255, 255);
			setLineWidth(height*0.005);
			drawLine(width*0.1, height+height*0.033, width*0.2, height+height*0.033);
			setForegroundColor(255, 105, 0);
			drawLine(width*0.1, height+height*0.066, width*0.2, height+height*0.066);
			setForegroundColor(0, 0, 0);
			setFont("SansSerif", height*0.025);
			setJustification("left");
			drawString("Nuclei segmentation outlines", width*0.25, height+(height*0.033)+(height*0.01));
			drawString("Nucleoside analogue segmentation outlines", width*0.25, height+(height*0.066)+(height*0.01));
		}
		Stack.setSlice(1);
		setBatchMode(false);
		saveAs("tiff", folder+"\\Multi-image");
	}
	
}