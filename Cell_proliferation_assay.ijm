/*
 * Pau Carrillo-Barberà, José M. Morante-Redolat, José F. Pertusa
 * Department of Cellular & Functional Biology
 * University of Valencia
 * 
 * February 2018
 */

//This macro is a non-supervised, high-throughput image analysis tool for ex vivo
//cell proliferation assays based on nucleoside analogue pulse alone or in combi-
//nation with other nuclear markers (it requires several changes in the macro, de-
//pending on the extra markers).

macro "Cell_proliferation_assay" { //BEGING (Macro:Cell_proliferation_assay.ijm)

	requires("1.51u");
	patern=newArray(2);
	firstRound=true;

	//Name the channels
	title = "Analysis";
	Dialog.create(title);
	Dialog.addMessage("Channels:");
	Dialog.addString("Nuclei", "DAPI", 5);
	Dialog.addString("Nucleoside analogue", "Cy3", 5);
	Dialog.show();
	patern[0]=Dialog.getString();
	patern[1]=Dialog.getString();

	//choose a directory
	dir = getDirectory("Choose a Directory");
	list = getFileList(dir);
	tiffFiles=0;
	for (i=0; i<list.length; i++) {
		if (endsWith(list[i], "tif")) {
			tiffFiles++;
		}
	}

	//check that the directory contains pictures
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
		if (well1!=well0) {
			nWells++;
			well0=substring(list[i],0,6);
		}
		if (field0!=field1) {
			nFields++;
			field0=substring(list[i],11,14);
		}
	}

	wellName=newArray(nWells);
	picturesxwell = (tiffFiles / nWells);
	picturesxfield = (tiffFiles / nFields);
	fieldsxwell = nFields / nWells;

	for (i=0; i<nWells; i++) {
		wellName[i]=well[i*picturesxwell];
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

	//open pictures
	count=0;
	for (z=0; z<nWells; z++) { //nWells FOR statement beginning
		count2=0;
		while (count2 < fieldsxwell) { //count2 WHILE  statement beginning
			if (fileCheckbox[z]==true) { //checkbox IF statement beginning
				for (i=0; i<picturesxfield; i++) {
					open(list[count]);
					count++;
				}
				count2++;
				
				//check that the correct number of pictures have been opened
				if (nImages==picturesxfield) { //nImages IF statement beginning
					fileArray=newArray(picturesxfield);

					//channel identification
					for (i=1; i<=picturesxfield; i++) {
						selectImage(i);
						ima1=getTitle();
						fileArray[i-1]=ima1;
					}

					for (j=1; j<=picturesxfield; j++) {
						for (i=1; i<=picturesxfield; i++) {
							if (indexOf (fileArray[i-1], patern[j-1])>0) {
								selectImage(fileArray[i-1]);
								rename (patern[j-1]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
								run("8-bit");
							}
						}
					}

					//maxima filter
					selectImage(patern[0]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
					run("Subtract Background...", "rolling=50");
					run("Enhance Contrast...", "saturated=0.4 normalize");
					run("Find Maxima...", "noise=100 output=[Count]");
					aproxN=getResult("Count", 0);
					run("Clear Results");					
					if (aproxN>10 && aproxN<=255) { //maxima filter IF statement beginning
						//nuclei segmentation
						selectImage(patern[0]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
						run("Gaussian Blur...", "sigma=2");
						setAutoThreshold("MaxEntropy dark");
						setOption("BlackBackground", false);
						run("Convert to Mask");
						run("Fill Holes");
						run("Options...", "iterations=2 count=1 do=Erode");
						run("Options...", "iterations=2 count=1 do=Open");
						run("Watershed");
				
						//nucleoside analogue segmentation
						selectImage(patern[1]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
						rename(patern[1]);
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
		
						//nucleus to nucleus analysis
						selectImage(patern[0]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
						run("Analyze Particles...", " size=20-300 show=[Count Masks] display clear");					
						rename(patern[0]+"-Count Masks");
						run("8-bit");
						close(patern[0]+ " (" +wellName[z]+ " fld " +field[count-1]+ ")");
						nFeat=nResults;
						run("Clear Results");
						pictureResults=newArray(nFeat);
						pictureDataname=newArray(nFeat);
						//single nucleus segmentation
						for (i=1; i<=nFeat; ++1) { //nucleus to nucleus analysis FOR statement beginning
							nameNucleous=patern[0]+"-"+i;
							nameM1=patern[1]+"-"+i;
							run("Set Measurements...", "display redirect=None decimal=2");
							selectImage(patern[0]+"-Count Masks");
							run("Duplicate...", "title="+nameNucleous);
							setThreshold(i, i);
							run("Convert to Mask");
							run("Make Binary");
	
							//binary reconstruct of nucleoside analogue
							run("BinaryReconstruct ", "mask="+patern[1]+ " seed="+nameNucleous+" create white");
							rename(nameM1);
							run("Analyze Particles...", " size=0-Infinity show=Nothing display clear");
							
							//store results
							results=nResults;
							if (results>0) {
								pictureResults[i-1]=1;
							} else {
								pictureResults[i-1]=0;
							}
							run("Clear Results");
							close(nameM1);
							close(nameNucleous);
							pictureDataname[i-1]=wellName[z]+ " fld " +field[count-1];
							if(i==nFeat) {
								if(firstRound==true) {
									marker1=pictureResults;
									dataname=pictureDataname;
									firstRound=false;
								} else {
									marker1=Array.concat(marker1, pictureResults);
									dataname=Array.concat(dataname, pictureDataname);
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
				count += picturesxwell;
				count2 = fieldsxwell;
			} //checkbox IF-ELSE statement ending
		} //count2 WHILE  statement ending
	} //nWells FOR statement ending

	//results table
	title1 = "Results table";
	title2 = "["+title1+"]";
	f = title2;
	run("Table...", "name="+title2+" width=500 height=500");
	print(f, "\\Headings:n\tdataname\tmarker1");
	for (i=0; i<marker1.length; i++) {
		print(f, i+1 +"\t" + dataname[i]+"\t" + marker1[i]);
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