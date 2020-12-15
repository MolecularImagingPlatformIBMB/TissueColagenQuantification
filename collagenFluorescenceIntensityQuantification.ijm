// Name: tissueCollagenIntensities.ijm
// Author: E. Rebollo, Molecular Imaging Platform IBMB
// Fiji version: lifeline 30 May 2017
// Date: 26 August 2020
/* This macro calculates the raw intensity density of tissue markers in 
   multichannel 3D fluorescence images from fixed tissues stained against 
   validated collagen and fibronectin markers. It analyses automatically 
   all images contained in a source forder and saves verification images 
   and the results text file in a folder of choice. 
   For each image the macro performs the following steps:
   - maximum projection 
   - channel separation and renaming
   - create mask for each channel
   - create a global mask containing the significant signal for all channels
   - apply the selected region to the original channel images and calculate area and raw intensity density
   - store all values in a general database .xls
   - deliver a composite image where the selected area has been highlighted, to be used for segmentation verification*/
   
// Press run & choose origen and destination folders.

//CALL ORIGEN AND DESTINATION FOLDERS
imagesFolder=getDirectory("Choose directory containing images");
resultsFolder=getDirectory("Choose directory to save results");
list=getFileList(imagesFolder);
File.makeDirectory(resultsFolder);

//CREATE ARRAYS TO STORE RESULTS
names=newArray(list.length);
areas=newArray(list.length);
intCollagenI=newArray(list.length);
intFibronectin=newArray(list.length);
intCollagenIV=newArray(list.length);

//CREATE LOOP TO ANALYZE ALL IMAGES
for(i=0; i<list.length; i++){
	
	showProgress(i+1, list.length);
	
	//OPEN IMAGE i FROM IMAGES FOLDER
	open(imagesFolder+list[i]);
	
	//GET IMAGE NAME 
	rawName = getTitle;
	name = File.nameWithoutExtension;

	//DESCALIBRAR IMAGEN (para medir en pixels)
	//run("Properties...", "channels=4 slices=13 frames=1 unit=pixel pixel_width=1 pixel_height=1 voxel_depth=1");
	
	//SEPARATE CHANNELS, Z-PROJECT AND RENAME
	prepareImages(rawName);

	//PREPROCESS IMAGES FOR MASK
	createMask("collagenI");
	createMask("collagenIV");
	createMask("fibronectin");

	//CREATE FINAL MASK AND SELECT ANALYSIS REGION
	imageCalculator("OR create", "collagenI_mask","collagenIV_mask");
	imageCalculator("OR create", "Result of collagenI_mask","fibronectin_mask");
	selectWindow("Result of collagenI_mask");
	run("Close");
	selectWindow("collagenI_mask");
	run("Close");
	selectWindow("collagenIV_mask");
	run("Close");
	selectWindow("fibronectin_mask");
	run("Close");
	selectWindow("Result of Result of collagenI_mask");
	rename("mask");
	run("Options...", "iterations=3 count=1 do=Erode");
	run("Options...", "iterations=6 count=1 do=Dilate");
	run("Options...", "iterations=2 count=1 do=Close");
	run("Create Selection");
	roiManager("Add");
	selectWindow("mask");
	run("Close");

	//MEASURE PARAMETERS
	area=measureArea();
	intCollI=measureInt("collagenI");
	intFibro=measureInt("fibronectin");
	intCollIV=measureInt("collagenIV");

	//ADD MEASUREMENTS TO ARRAYS
	names[i] = name;
	areas[i] = area;
	intCollagenI[i] = intCollI;
	intFibronectin[i] = intFibro;
	intCollagenIV[i] = intCollIV;
	
	//CREATE VERIFICATION IMAGE
	verificationImage("collagenIV", "fibronectin", "collagenI");
	//Save verification image to results folder
	saveAs("TIFF", resultsFolder+name+"_processed.tif");
	close();

}

//CREATE RESULTS TABLE
title1 = "Results";
title2 = "["+title1+"]";
f=title2;
run("New... ", "name="+title2+" type=Table");
print(f,"\\Headings:"+"Image \t Area \t IntCollagenI \t IntFibronectin \t IntCollagenIV");

for(i=0; i<list.length; i++){
print(f,names[i]+"\t"+areas[i]+"\t"+intCollagenI[i]+"\t"+intFibronectin[i]+"\t"+intCollagenIV[i]);
}

//SAVE RESULTS TABLE AS .XLS IN RESULTS FOLDER
selectWindow("Results");
saveAs("Text", resultsFolder+"Results.xls");
run("Close");


//LIST OF USER-DEFINED FUNCTIONS///////////////

function prepareImages(title){
	selectWindow(title);
	run("Z Project...", "projection=[Max Intensity]");
	selectWindow(rawName);
	run("Close");
	selectWindow("MAX_"+rawName);
	run("Split Channels");
	selectWindow("C4-MAX_"+title);
	rename("fibronectin");
	selectWindow("C3-MAX_"+title);
	rename("collagenIV");
	selectWindow("C2-MAX_"+title);
	run("Close");
	selectWindow("C1-MAX_"+title);
	rename("collagenI");
	run("Blue");
}

function createMask(image){
	selectWindow(image);
	run("Duplicate...", "title="+image+"_mask");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	run("Enhance Local Contrast (CLAHE)", "blocksize=50 histogram=100 maximum=3 mask=*None*");
	run("Subtract Background...", "rolling=100");
	run("Median...", "radius=10");
	run("8-bit");
	setAutoThreshold("Huang dark");
	setOption("BlackBackground", false);
	run("Convert to Mask");
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
	
function verificationImage(image1, image2, image3){
	selectWindow(image1);
	//run("Select All");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	selectWindow(image2);
	//run("Select All");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	selectWindow(image3);
	//run("Select All");
	run("Enhance Contrast", "saturated=0.35");
	run("Apply LUT");
	run("Merge Channels...", "c1="+image1+" c2="+image2+" c3="+image3+" create");
	run("RGB Color");
	//Draw selections into image
	setForegroundColor(255, 255, 255);
	roiManager("Set Line Width", 2);
	roiManager("select", 0);
	roiManager("draw");
	roiManager("Show None");
	//Close windows & reset ROI Manager
	selectWindow("Composite");
	close();
	selectWindow("ROI Manager");
	run("Close");
}
