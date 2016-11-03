// tazmanager.rsc
//
// TransCAD Macro used to create a TAZ data file and copy it to a directory.
// Developed for OMPO

// 18January2008 [jef]
//
// Macro "Set Parameters"(path, Options, year)
Macro "Set Parameters"(path, Options)

	RunMacro("TCB Init")

    // Set the model directory - might replace this with just asking for user to define output directory
//    modelDirectory = "c:\\projects\\ompo\\conversion\\application\\"

    // Set the master TAZ file
    masterTAZFile=path[7]+"Master TAZ Layer.dbd"

    // Set the Baes Year HH distribution file
    baseYearHHFile=path[7]+"baseyear_hhdistrib.bin"

    // The scenario directory is based on the folderName - could change this convention
    scenarioDirectory=path[2]+ "\\inputs\\taz"

    //check for directory of output TAZ data
    if GetDirectoryInfo(scenarioDirectory, "Directory")=null then do
        CreateDirectory( scenarioDirectory)
    end

    returnArray = {masterTAZFile,scenarioDirectory,baseYearHHFile}

    Return(returnArray)


EndMacro

Macro "Create TAZ File"
    shared path, Options, year, seYear
        if TypeOf(year) <> "string" then year = String(year)
        if TypeOf(seYear) <> "string" then seYear = String(seYear)

    // Set the Year
    // currentYear = year

    // Set the folder name
    folderName = seYear

    TAZDataFile = path[7]+seYear+"\\y"+seYear+"tazdata.csv"
    // Set the parameters
    // {masterTAZFile,scenarioDirectory,baseYearHHFile}= RunMacro("Set Parameters",path, Options, year)
    {masterTAZFile,scenarioDirectory,baseYearHHFile}= RunMacro("Set Parameters",path, Options)


    // Create and export the TAZ data
    RunMacro("Export TAZ Data",masterTAZFile,TAZDataFile,scenarioDirectory)

    // Run the "Distribute Households only for Base year"
    //if year = "2005" then do
        RunMacro("Distribute Households", baseYearHHFile,scenarioDirectory)
//        ShowMessage("2005")
    //end

    //copy airgen control file (AIRGEN5.CTL) from generic\inputs\taz directory to scenario\controls directory
    baseControlFile = path[7]+seYear+"\\AIRGEN5.CTL"
    scenarioControlFile = path[2]+"\\controls\\AIRGEN5.CTL"
    CopyFile(baseControlFile,scenarioControlFile)


    //synthetic population
    basePersonFile = path[7]+seYear+"\\persons.csv"
    scenarioPersonFile = path[2]+"\\inputs\\taz\\persons.csv"
    CopyFile(basePersonFile,scenarioPersonFile)

     baseHouseholdFile = path[7]+seYear+"\\households.csv"
    scenarioHouseholdFile = path[2]+"\\inputs\\taz\\households.csv"
    CopyFile(baseHouseholdFile,scenarioHouseholdFile)


     //taz file
    // baseTazFile = path[7]+seYear+"\\tazData.csv"
    baseTazFile = TAZDataFile
    scenarioTazFile = path[2]+"\\inputs\\taz\\tazData.csv"
    CopyFile(baseTazFile,scenarioTazFile)


    year = StringToInt(year)
    seYear = StringToInt(seYear)
EndMacro
/*
Macro "Create 2015 TAZ File"

    // Set the Year
    // currentYear = "2015"

    // Set the folder name
    folderName = "2015_Medium_Range"

    TAZDataFile = "c:\\projects\\ompo\\conversion\\application\\generic\\inputs\\taz\\2015\\z15hct6p(071128)modified547548.csv"

    // Set the parameters
    {masterTAZFile,scenarioDirectory,baseYearHHFile}= RunMacro("Set Parameters",folderName)

    // Create and export the TAZ data
    RunMacro("Export TAZ Data",masterTAZFile,TAZDataFile,scenarioDirectory)
EndMacro
Macro "Create 2030 TAZ File"

    // Set the Year
    // currentYear = "2030"

    // Set the folder name
    folderName = "2030_Long_Range"

    //
    TAZDataFile = "c:\\projects\\ompo\\conversion\\application\\generic\\inputs\\taz\\2030\\z30hct6p(071128)modified547548.csv"

    // Set the parameters
    {masterTAZFile,scenarioDirectory,baseYearHHFile}= RunMacro("Set Parameters",folderName)

    // Create and export the TAZ data
    RunMacro("Export TAZ Data",masterTAZFile,TAZDataFile,scenarioDirectory)
EndMacro
 */
Macro "Export TAZ Data" (masterTAZFile,TAZDataFile,scenarioDirectory)

    // Check that the files exist
    if GetFileInfo(masterTAZFile) = null then do
        ShowMessage("File not found: " + masterTAZFile)
        Return()
    end

    // Check that the files exist
    if GetFileInfo(TAZDataFile) = null then do
        ShowMessage("File not found: " + TAZDataFile)
        Return()
    end

    // Get the master TAZ layer
    dbInfo = GetDBInfo(masterTAZFile)
    dbLayers = GetDBLayers(masterTAZFile)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})

   // Add the taz layer to the map and make it visible
   tazLayer=AddLayer("TempMap","Oahu_TAZs",masterTAZFile,dbLayers[1])
   SetLayerVisibility(tazLayer,"True")

    yearView = OpenTable("Year", "CSV", {TAZDataFile,}, {{"Shared", "True"}})

    joinedView = JoinViews("Scenario_TAZs", tazLayer+".TAZ", yearView+".TAZ",)
    RenameField("Year.TAZ", "DROP")
    RenameField("Oahu_TAZs.TAZ", "TAZ")

    // Display the result in an editor
    editor_name = CreateEditor("Joined TAZ Data", joinedView + "|",null, )
    fields = GetFields(joinedView,"All")
    newFields=null
    for i = 1 to fields[1].length do

         // Drop the extra TAZ field
        temp = Position(fields[1][i],"DROP")

        if temp=0 then newFields = newFields + {joinedView+"." + (fields[1][i])}

    end

   // Set the location of the output TAZ data
    scenarioTAZFile = scenarioDirectory + "\\"+"Scenario TAZ Layer.dbd"

   // Export geography to the TAZ layer
    ExportGeography(tazLayer,scenarioTAZFile,
                      { {"Layer Name","Oahu TAZs"}, {"Field Spec",newFields}})

    CloseEditor(editor_name)

    // recode the scenario fields to real
    path = SplitPath(scenarioTAZFile)
    tazdata = OpenTable("TazData", "FFB", {path[1]+path[2]+path[3]+".bin",null}, {{"Shared", "False"}})
    strct = GetTableStructure(tazdata)
    for i = 1 to strct.length do

        // Any 4 byte int gets changed to a 4 byte real
        if(strct[i][2]="Integer") then do
            strct[i][2] = "Float"
            strct[i][4] = 2
        end

        // Any float or real changes to 2 decimals, width of 12
        if(strct[i][2]="Float" or strct[i][2]="Real") then do
            strct[i][3] = 12
            strct[i][4] = 2
        end

        // Any 2-byte integer changes to width of 5
        if(strct[i][2]="Short") then do
            strct[i][3] = 5
        end

        strct[i] = strct[i] + {strct[i][1]}
    end

    // Modify the table
    ModifyTable(tazdata, strct)

    RunMacro("Close All-1")

EndMacro

/***********************************************************************************************************************************
*
* Distribute Households
* This macro will factor a base-year household distribution by TAZ, income, size, and workers, to a future-year distribution,
* using the base-year distribution and a future-year total of households.
*
***********************************************************************************************************************************/
Macro "Distribute Households"(baseYearHHFile, scenarioDirectory)

   // Set the location of the output TAZ data
    scenarioTAZFile = scenarioDirectory + "\\"+"Scenario TAZ Layer.bin"

    // Check that the files exist
    if GetFileInfo(scenarioTAZFile) = null then do
        ShowMessage("File not found: " + scenarioTAZFile)
        Return()
    end

    // Check that the files exist
    if GetFileInfo(baseYearHHFile) = null then do
        ShowMessage("File not found: " + baseYearHHFile)
        Return()
    end

    futureYearHHFile = scenarioDirectory+"\\hhdistrib.bin"

    //Copy the base-year file to the scenario directory
    CopyFile(baseYearHHFile,futureYearHHFile)

    // Copy the dictionary file
    basePath = SplitPath(baseYearHHFile)
    futurePath = SplitPath(futureYearHHFile)
    CopyFile(basePath[1]+basePath[2]+basePath[3]+".DCB",futurePath[1]+futurePath[2]+futurePath[3]+".DCB")

    // Open the data tables
    futureYearData  = OpenTable("FutureYearData", "FFB", {scenarioTAZFile,null}, {{"Shared", "True"}})
    baseYearDistrib = OpenTable("BaseYearDistrib", "FFB", {baseYearHHFile,null}, {{"Shared", "True"}})
    futureYearDistrib = OpenTable("FutureYearDistrib", "FFB", {futureYearHHFile,null}, {{"Shared", "True"}})

    // Get the vector of total households
    futureHHTAZ = GetDataVector(futureYearData+"|", "TOTALHH", {{"Sort Order", {{"TAZ", "Ascending"}}}})

    // Get the vectors of households by type
    dataFields = GetFields(baseYearDistrib, "All")
    dim baseVectors[dataFields[1].length - 1]

    //Iterate through the fields, and get the data vectors for each
    for i = 2 to dataFields[1].length do
        baseVectors[i-1]= GetDataVector(baseYearDistrib+"|", dataFields[1][i], {{"Sort Order", {{"TAZ", "Ascending"}}}})
    end

    // Calculate total base-year households, base-year regional distribution
    dim baseHHTAZ[baseVectors[1].length]
    dim baseYearRegDist[dataFields[1].length - 1]
    totalBaseHH = 0

    // initialize arrays to 0
    for i = 1 to baseHHTAZ.length do
        baseHHTAZ[i] = 0
    end
    for i = 1 to baseYearRegDist.length do
        baseYearRegDist[i]=0
    end

    // skip the TAZ column, which should be first
    for i = 2 to dataFields[1].length do
        for j = 1 to baseVectors[i-1].length do
            baseHHTAZ[j] = baseHHTAZ[j] + baseVectors[i-1][j]
            baseYearRegDist[i-1] = baseYearRegDist[i-1] + baseVectors[i-1][j]
            totalBaseHH = totalBaseHH + baseVectors[i-1][j]
        end
    end

    // Now calculate future year hhs by category
    futureVectors = CopyArray(baseVectors)
    factor = 0.0
    for i = 1 to baseHHTAZ.length do
        for j = 2 to dataFields[1].length do

            // if there are future HHs in the TAZ and no base HH in the TAZ, set HH equal to reg distribution
            if(futureHHTAZ[i] > 0 and baseHHTAZ[i] = 0) then do
                futureVectors[j-1][i] = baseYearRegDist[j-1]/totalBaseHH * futureHHTAZ[i]
                end
            // if there are no future HHs in the TAZ, set the future distribution to 0
            else if futureHHTAZ[i] = 0 then do
                futureVectors[j-1][i] = 0
                end
            // if there are future HHs and base HHs, set the future distribution to a factored up base distribution
            else do
                factor = futureHHTAZ[i]/baseHHTAZ[i]
                futureVectors[j-1][i] = factor * baseVectors[j-1][i]
            end
        end
    end

    // Finally, set the data vectors in the future distribution
    for i = 2 to dataFields[1].length do
            SetDataVector(futureYearDistrib+"|", dataFields[1][i], futureVectors[i-1],
                                {{"Sort Order", {{"TAZ", "Ascending"}}}} )
    end

    // Export the table to text format for the trip generation program
    ExportView(futureYearDistrib+"|", "FFA", futurePath[1]+futurePath[2]+futurePath[3], null, {
        {"Force Numeric Type","Float"}}

        )
    RunMacro("Close All-1")

EndMacro
/***********************************************************************************************************************************
*
* Close All
* Macro to close all open maps and views
*
***********************************************************************************************************************************/
Macro "Close All-1"
    maps = GetMapNames()
    for i = 1 to maps.length do
	CloseMap(maps[i])
    end

    views = GetViewNames()
    for i = 1 to views.length do
	CloseView(views[i])
    end
EndMacro
