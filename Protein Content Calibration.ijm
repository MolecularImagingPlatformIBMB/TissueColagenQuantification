//////////////////////////////////////////////////////////////////////////////////////////////////
//
// Name:	Protein Content Calibration
// Author: 	Elena Rebollo (MIP/IBMB)
// Date:	21-07-2021	
// Fiji Lifeline 22 Dec 2015
//	
// Description: This macro obtaines the raw intensity density of a protein dot polimerized and immunostained, and acquired as a 3D mosaic. 
// The macro works as follows:
//		1. It projects the Z stack (max)
//		2. It subtracts the background (chosen by the user as a roi)
//		3. It creates a mask containing the relevant polimerized protein signal
//		3. It creates a selection with the masked pixels within the manual roi
//		5. It measures the raw intensity density and delivers a log file with the image name and the intensity value

//////////////////////////////////////////////////////////////////////////////////////////////////



// GET IMAGE NAME
rawName = getTitle;
name = File.nameWithoutExtension;

//PROJECT Zs AND CLOSE ORIGINAL IMAGE
run("Z Project...", "projection=[Max Intensity]");
rename("projection");
run("Duplicate...", "title=signal");
selectWindow(rawName);
run("Close");

//SELECT BACKGROUND ROI MANUALLY
setTool("rectangle");
waitForUser("paint background region");
roiManager("Add");

//REMOVE BACKGROUND 
selectWindow("signal");
roiManager("Select", 0);
run("Set Measurements...", "mean integrated redirect=None decimal=2");
roiManager("measure");
BG_mean = getResult("Mean", 0);
selectWindow("signal");
run("Select All");
run("Subtract...", "value="+BG_mean);
roiManager("reset");
run("Clear Results");

//CREATE "SIGNAL" IMAGE AND CLOSE PROJECTION
selectWindow("signal");
run("Select All");
run("Duplicate...", "title=mask");
selectWindow("projection");
run("Close");

//SELECT ANALYSIS REGION MANUALLY
setTool("polygon");
waitForUser("paint calibration dot region");
roiManager("Add");

//PREPROCESS AND CREATE MASK
selectWindow("mask");
run("Select All");
run("Enhance Local Contrast (CLAHE)", "blocksize=30 histogram=100 maximum=3 mask=*None*");
run("Subtract Background...", "rolling=20");
run("Median...", "radius=3");
run("8-bit");
setAutoThreshold("Otsu dark");
setOption("BlackBackground", false); 
run("Convert to Mask");

//CREATE SELECTION
roiManager("Select", 0);
setBackgroundColor(255, 255, 255);
run("Clear Outside");
run("Select All");
run("Create Selection");
roiManager("reset");
roiManager("Add");
selectWindow("mask");
run("Close");

//MEASURE RAW INTENSITY DENSITY
selectWindow("signal");
run("Set Measurements...", "area mean integrated redirect=None decimal=2");
roiManager("Select", 0);
roiManager("Measure");
int=getResult("RawIntDen", 0);
print(name);
print(int);

//CLOSE WINDOWS
selectWindow("signal");
close();
selectWindow("ROI Manager");
run("Close");



