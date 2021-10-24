//////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	Tissue Intensities Measurement 
// Author: 	Elena Rebollo (MIP/IBMB)
// Date:	24-07-2021	
// Fiji Lifeline 22 Dec 2015
//	
// Description: This macro measures the raw intensity density of four extracelular matrix markers (collagen, fibronectin, etc.) 
// on a representative region of interest obtained by segmentation. It then converts the intensities into protein content (ug) 
// according to the linear regression calibration calculated in advanced (macro Protein Concentration Calibration.ijm)
// The original image is a four channels + Z-stack. For each channel, the macro measures the raw intensity density of the maz projection 
// The macro analyses a set of images automatically and delivers a *.txt data sheet containing all the measurements 
// for the n images
//
//////////////////////////////////////////////////////////////////////////////////////////////////

//CALL ORIGEN AND DESTINATION FOLDERS
imagesFolder=getDirectory("Choose directory containing images");
resultsFolder=getDirectory("Choose directory to save results");
list=getFileList(imagesFolder);
File.makeDirectory(resultsFolder);

//CREATE ARRAYS TO STORE RESULTS
names=newArray(list.length);
areas=newArray(list.length);
intensityC1=newArray(list.length);
intensityC2=newArray(list.length);
intensityC3=newArray(list.length);
intensityC4=newArray(list.length);
concentrationC1=newArray(list.length);
concentrationC2=newArray(list.length);
concentrationC3=newArray(list.length);
concentrationC4=newArray(list.length);


//CREATE INTERACTIVE DIALOG TO IDENTIFY THE CHANNELS
Dialog.create("My channels");
Dialog.addMessage("Name the channels by order 1 to 4: 1.e.coI, coIII, coIV or fib");
Dialog.addString("Enter name for channel 1", "coI");
Dialog.addNumber("Enter channel 1 background", 194);
Dialog.addNumber("Enter slope", 2956230194);
Dialog.addString("Enter name for channel 2", "coIII");
Dialog.addNumber("Enter channel 2 background", 1390);
Dialog.addNumber("Enter slope", 1710565752);
Dialog.addString("Enter name for channel 3", "coIV");
Dialog.addNumber("Enter channel 3 background", 2471);
Dialog.addNumber("Enter slope", 1325273423);
Dialog.addString("Enter name for channel 4", "fib");
Dialog.addNumber("Enter channel 4 background", 1060);
Dialog.addNumber("Enter slope", 1606301793);
Dialog.show();
C1=Dialog.getString();
C1BG=Dialog.getNumber();
C1a=Dialog.getNumber();
C2=Dialog.getString();
C2BG=Dialog.getNumber();
C2a=Dialog.getNumber();
C3=Dialog.getString();
C3BG=Dialog.getNumber();
C3a=Dialog.getNumber();
C4=Dialog.getString();
C4BG=Dialog.getNumber();
C4a=Dialog.getNumber();



//CREATE LOOP TO ANALYZE ALL IMAGES
for(i=0; i<list.length; i++){
	showProgress(i+1, list.length);
	//OPEN IMAGE i FROM IMAGES FOLDER
	open(imagesFolder+list[i]);
	//GET IMAGE NAME 
	rawName = getTitle;
	name = File.nameWithoutExtension;
	//SEPARATE CHANNELS, Z-PROJECT AND RENAME
	prepareImages(rawName);
	//REMO0VE BACKGROUND
	removeBG(C1, C1BG);
	removeBG(C2, C2BG);
	removeBG(C3, C3BG);
	removeBG(C4, C4BG);
	//PREPROCESS IMAGES AND CREATE MASKS
	createMask(C1);
	createMask(C2);
	createMask(C3);
	createMask(C4);
	createROI(C1+"_mask", C2+"_mask", C3+"_mask", C4+"_mask");
	//MEASURE AREA AND RAW INTENSITY DENSITY
	area=measureArea();
	C1y=measureInt(C1);
	C2y=measureInt(C2);
	C3y=measureInt(C3);
	C4y=measureInt(C4);
	//CONVERT INTENSITIES INTO PROTEIN CONCENTRATION
	cncC1=C1y/C1a;
	cncC2=C2y/C2a;
	cncC3=C3y/C3a;
	cncC4=C4y/C4a;
	//ADD MEASUREMENTS TO ARRAYS
	names[i] = name;
	areas[i] = area;
	intensityC1[i] = C1y;
	intensityC2[i] = C2y;
	intensityC3[i] = C3y;
	intensityC4[i] = C4y;
	concentrationC1[i] = cncC1;
	concentrationC2[i] = cncC2;
	concentrationC3[i] = cncC3;
	concentrationC4[i] = cncC4;
	//CREATE VERIFICATION IMAGE
	verificationImage(C1, C2, C3, C4);
	//Save verification image to results folder
	saveAs("TIFF", resultsFolder+name+"_processed.tif");
	close();
}

//CREATE RESULTS TABLE
title1 = "Results";
title2 = "["+title1+"]";
f=title2;
run("New... ", "name="+title2+" type=Table");
print(f,"\\Headings:"+"Image \t Area \t Intensity_"+C1+" \t Intensity_"+C2+" \t Intensity_"+C3+" \t Intensity_"+C4+" \t Concentration_"+C1+" \t Concentration_"+C2+" \t Concentration_"+C3+" \t Concentration_"+C4);

for(i=0; i<list.length; i++){
print(f,names[i]+"\t"+areas[i]+"\t"+intensityC1[i]+"\t"+intensityC2[i]+"\t"+intensityC3[i]+"\t"+intensityC4[i]+"\t"+concentrationC1[i]+"\t"+concentrationC2[i]+"\t"+concentrationC3[i]+"\t"+concentrationC4[i]);
}

//SAVE RESULTS TABLE AS .XLS IN RESULTS FOLDER
selectWindow("Results");
saveAs("Text", resultsFolder+"Results.txt");
run("Close");


//LIST OF USER-DEFINED FUNCTIONS///////////////

	function prepareImages(title){
		selectWindow(title);
		run("Z Project...", "projection=[Max Intensity]");
		selectWindow("MAX_"+rawName);
		run("Split Channels");
		selectWindow("C4-MAX_"+title);
		rename(C4);
		selectWindow("C3-MAX_"+title);
		rename(C3);
		selectWindow("C2-MAX_"+title);
		rename(C2);
		selectWindow("C1-MAX_"+title);
		rename(C1);
		selectWindow(rawName);
		run("Close");
	}

	function removeBG(title, BG) {
		selectWindow(title);
		run("Subtract...", "value="+BG);
		}
	
	function createMask(image){
		selectWindow(image);
		run("Duplicate...", "title="+image+"_mask");
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT");
		run("Enhance Local Contrast (CLAHE)", "blocksize=30 histogram=100 maximum=3 mask=*None* fast_(less_accurate)");
		run("Subtract Background...", "rolling=20");
		run("Median...", "radius=3");
		run("8-bit");
		setAutoThreshold("Huang dark");
		setOption("BlackBackground", false);
		run("Convert to Mask");
	}

	function createROI(image1, image2, image3, image4) {
		selectWindow(image1);
		rename("mask");
		imageCalculator("OR", "mask", image2);
		rename("mask");
		selectWindow(image2);
		close();
		imageCalculator("OR", "mask", image3);
		rename("mask");
		selectWindow(image3);
		close();
		imageCalculator("OR", "mask", image4);
		rename("mask");
		selectWindow(image4);
		close();
		//clean mask
		//run("Options...", "iterations=2 count=1 do=Erode");
		run("Options...", "iterations=3 count=1 do=Dilate");
		run("Options...", "iterations=3 count=1 do=Close");
		//create selection
		run("Create Selection");
		roiManager("Add");
		selectWindow("mask");
		close();
		}
			
	function measureArea(){
		run("Set Measurements...", "area mean integrated redirect=None decimal=2");
		roiManager("Select", 0);
		roiManager("measure");
		area=getResult("Area", 0);
		run("Clear Results");
		return area;
	}

	function measureInt(image){
		run("Set Measurements...", "area mean integrated redirect=None decimal=2");
		selectWindow(image);
		roiManager("Select", 0);
		roiManager("measure");
		int=getResult("RawIntDen", 0);
		run("Clear Results");
		return int;
	}

	function verificationImage(image1, image2, image3, image4){
		selectWindow(image1);
		run("Select All");
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT");
		selectWindow(image2);
		run("Select All");
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT");
		selectWindow(image3);
		run("Select All");
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT");
		selectWindow(image4);
		run("Select All");
		run("Enhance Contrast", "saturated=0.35");
		run("Apply LUT");
		//merge RGB
		run("Merge Channels...", "c1="+image1+" c2="+image2+" c3="+image3+" c4="+image4+" create");
		run("RGB Color");
		//Draw selections into image
		setForegroundColor(255, 255, 0);
		roiManager("Set Line Width", 3);
		roiManager("select", 0);
		roiManager("draw");
		roiManager("Show None");
		//Close windows & reset ROI Manager
		selectWindow("Composite");
		close();
		selectWindow("ROI Manager");
		run("Close");
	}
