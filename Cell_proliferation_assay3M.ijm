/*
 * Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia
 * 
 * August 2018
 */

//This macro is a non-supervised, high-throughput image analysis tool for ex vivo
//cell proliferation assays based on nucleoside analogue pulse alone or in combi-
//nation with other nuclear markers (it requires several changes in the macro, de-
//pending on the extra markers).

macro "Cell_proliferation_assay" { //BEGING (Macro:Cell_proliferation_assay.ijm)

	requires("1.52e");
	pattern=newArray(4);
	firstRound=true;

	//Name the channels
	title = "Cell proliferation assay";
	Dialog.create(title);
	Dialog.addMessage("Channels:");
	Dialog.addString("Nuclei", "DAPI", 5);
	Dialog.addString("Nucleoside analogue", "Cy3", 5);
	Dialog.addString("Marker_1", "FITC", 5);
	Dialog.addString("Marker_2", "Cy5", 5);
	Dialog.show();
	pattern[0]=Dialog.getString();
	pattern[1]=Dialog.getString();
	pattern[2]=Dialog.getString();
	pattern[3]=Dialog.getString();

	//choose a directory
	dir = getDirectory("Choose a Directory");
	list = getFileList(dir);
	Array.sort(list);
	tiffFiles=0;
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "tif")) {
			tiffFiles++;
		}
	}

	//check that the directory contains images
	if (tiffFiles==0) {
		beep();
		waitForUser("Error", "No tiff files");
		exit;
	}

	//manage files
	nWells=1;
	nFields=1;
	well=newArray(tiffFiles);
	field=newArray(tiffFiles);
	well0=substring(list[0],0,6);
	field0=substring(list[0],11,14);

	for (i=0; i<tiffFiles; i++) {
		well[i]=substring(list[i],0,6);
		field[i]=substring(list[i],11,14);
		well1=substring(list[i],0,6);
		field1=substring(list[i],11,14);
		if (field0!=field1 || well1!=well0) {
			nFields++;
			field0=substring(list[i],11,14);
		}
		if (well1!=well0) {
			nWells++;
			well0=substring(list[i],0,6);
		}
	}

	wellName=newArray(nWells);
	imagesxwell = (tiffFiles / nWells);
	imagesxfield = (tiffFiles / nFields);
	fieldsxwell = nFields / nWells;

	//print(nWells, imagesxwell, imagesxfield, fieldsxwell);
	//exit;

	for (i=0; i<nWells; i++) {
		wellName[i]=well[i*imagesxwell];
	}

	//select wells to be analysed
	fileCheckbox=newArray(nWells);
	selection=newArray(nWells);
	title = "Select Wells";
	Dialog.create(title);
	Dialog.addCheckbox("Select All", true);
	Dialog.addCheckboxGroup(8,12,wellName,selection);
	Dialog.show();
	selectAll=Dialog.getCheckbox();
	for (i=0; i<nWells; i++) {
		fileCheckbox[i]=Dialog.getCheckbox();
		if (selectAll==true) {
			fileCheckbox[i]=true;
		}
	}

	//check that at least one well have been selected
	checkSelection = 0;
	for (i=0; i<nWells; i++) {
		checkSelection += fileCheckbox[i];
	}

	if (checkSelection == 0) {
		waitForUser("Error", "There is no well selected");
		exit;
	}

	//open images
	setBatchMode(true);
	count=0;
	for (z=0; z<nWells; z++) { //nWells FOR statement beginning
		count2=0;
		while (count2 < fieldsxwell) { //count2 WHILE  statement beginning
			if (fileCheckbox[z]==true) { //checkbox IF statement beginning
				for (i=0; i<imagesxfield; i++) {
					open(list[count]);
					count++;
				}
				count2++;
				
				//check that the correct number of images have been opened
				if (nImages==imagesxfield) { //nImages IF statement beginning
					fileArray=newArray(imagesxfield);

					//channel identification
					for (i=1; i<=imagesxfield; i++) {
						selectImage(i);
						ima1=getTitle();
						fileArray[i-1]=ima1;
					}

					for (j=1; j<=imagesxfield; j++) {
						for (i=1; i<=imagesxfield; i++) {
							if (indexOf (fileArray[i-1], pattern[j-1])>0) {
								selectImage(fileArray[i-1]);
								rename (pattern[j-1]);
								run("8-bit");
							}
						}
					}

					//maxima filter
					selectImage(pattern[0]);
					run("Subtract Background...", "rolling=50");
					run("Enhance Contrast...", "saturated=0.4 normalize");
					run("Find Maxima...", "noise=100 output=[Count]");
					aproxN=getResult("Count", 0);
					run("Clear Results");					
					if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning
						//nuclei segmentation
						selectImage(pattern[0]);
						run("Gaussian Blur...", "sigma=2");
						setAutoThreshold("MaxEntropy dark");
						setOption("BlackBackground", false);
						run("Convert to Mask");
						run("Fill Holes");
						run("Options...", "iterations=2 count=1 do=Erode");
						run("Options...", "iterations=2 count=1 do=Open");
						run("Watershed");
				
						//nucleoside analogue segmentation
						selectImage(pattern[1]);
						run("Gaussian Blur...", "sigma=5");
						run("Subtract Background...", "rolling=50");
						run("Enhance Contrast...", "saturated=0.1 normalize");
						setAutoThreshold("MaxEntropy dark");
						setOption("BlackBackground", false);
						run("Convert to Mask");
						run("Fill Holes");
						run("Watershed");
						run("Options...", "iterations=2 count=1 do=Erode");
						run("Options...", "iterations=2 count=1 do=Open");	
		
						//nucleus-to-nucleus analysis
						selectImage(pattern[0]);
						run("Analyze Particles...", " size=20-300 show=[Count Masks] display clear");					
						rename(pattern[0]+"-Count Masks");
						run("8-bit");
						close(pattern[0]);
						nFeat=nResults;
						run("Clear Results");
						imageResults=newArray(nFeat);
						meanResult1=newArray(nFeat);
						meanResult2=newArray(nFeat);
						imageDataname=newArray(nFeat);
						//single nucleus segmentation
						for (i=1; i<=nFeat; ++1) { //nucleus to nucleus analysis FOR statement beginning
							nameNucleous=pattern[0]+"-"+i;
							nameM1=pattern[1]+"-"+i;
							run("Set Measurements...", "display redirect=None decimal=2");
							selectImage(pattern[0]+"-Count Masks");
							run("Duplicate...", "title="+nameNucleous);
							setThreshold(i, i);
							run("Convert to Mask");
							run("Make Binary");
	
							//binary reconstruct of nucleoside analogue
							run("BinaryReconstruct ", "mask="+pattern[1]+ " seed="+nameNucleous+" create white");
							rename(nameM1);
							run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
							results=nResults;
							if (results>0) {
								imageResults[i-1]=1;
							} else {
								imageResults[i-1]=0;
							}
							run("Clear Results");

							//marker1
							selectImage(nameNucleous);
							run("Set Measurements...", "mean redirect="+pattern[2]+" decimal=2");
							run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
							meanResult1[i-1]=getResult("Mean", 0);
							run("Clear Results");

							//marker2
							selectImage(nameNucleous);
							run("Set Measurements...", "mean redirect="+pattern[3]+" decimal=2");
							run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
							meanResult2[i-1]=getResult("Mean", 0);
							run("Clear Results");

							//close binary images of nucleoside analogue nucleous-to-nucleous loop
							close(nameM1);
							close(nameNucleous);
							
							imageDataname[i-1]=wellName[z]+ " fld " +field[count-1];
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
						} //nucleus to nucleus analysis FOR statement ending
					
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
	title1 = "Results table";
	title2 = "["+title1+"]";
	f = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	print(f, "\\Headings:n\tdataname\tS-phase\tmarker1\tmarker2");
	for (i=0; i<nucleosideAnalogue.length; i++) {
		print(f, i+1 + "\t" + dataname[i]+ "\t" + nucleosideAnalogue[i] + "\t" + marker1[i] + "\t" + marker2[i]);
	}

	//user-defined functions
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
	
} //END (Macro:Cell_proliferation_assay.ijm)