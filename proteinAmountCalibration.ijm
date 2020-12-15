
rawName = getTitle;
name = File.nameWithoutExtension;

run("Z Project...", "projection=[Max Intensity]");
run("Duplicate...", "title=mask");
selectWindow(rawName);
run("Close");

//select region manually
setTool("polygon");
waitForUser("paint region");
roiManager("Add");

//PREPROCESS AND CREATE MASK
selectWindow("mask");
run("Select All");
run("Enhance Contrast", "saturated=0.35");
run("Apply LUT");
run("Enhance Local Contrast (CLAHE)", "blocksize=120 histogram=256 maximum=3 mask=*None*");
run("Subtract Background...", "rolling=10");
run("Median...", "radius=4");
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
roiManager("Add");
selectWindow("mask");
run("Close");

//MEASURE
selectWindow("MAX_"+rawName);
run("Set Measurements...", "area mean integrated redirect=None decimal=2");
roiManager("Select", 1);
roiManager("Measure");
int=getResult("RawIntDen", 0);
area=getResult("Area", 0);
print(name);
print(int);
print(area);
