// networkmanager.rsc
//
// TransCAD Macro used to extract a highway and transit network 
// from a master line layer. Developed for OMPO, based on work
// by Ory for PTRM.
//
// 06December2007 [dto]
// 18January2008 [jef]
// 28October2009 [ARF]
//
Macro "Create Network"(path, Options, year)

//    RunMacro("TCB Init")
    // Set the Year
    currentYear = year
   
    // Set the folder name
    ScenarioDirectory = path[2]
    
    // Set the temporary directory
    tempDirectory = path[10]
    // Kyle: reset the temp directory to be inside the scenario directory
    tempDirectory = ScenarioDirectory + "/outputs/temp/"
    
    // Set the master network directory
    masterNetworkDirectory =path[4]
    
    // Set the turn penalty directory
    turnPenaltyDirectory = path[5]
    
    // Set the other inputs directory
    otherDirectory = path[6]

    // Set the programs directory
    programsDirectory = path[9]
    
    // Set the controls directory
    controlsDirectory = path[8]

    // Set the scripts directory
    scriptsDirectory = path[11]
    
    // Set the DTA directory
    DTADirectory = path[12]

    // Set the output network directory
    ModelDirectory=path[3]
    
    // Set the master highway line network
    masterLineFile="Oahu Network 102907.dbd"
    
    // Set the master route file
    masterRouteFile="Oahu Route System 102907.rts"
    
    // The scenario network directory is based on the folderName - could change this convention
    scenarioNetworkDirectory=ScenarioDirectory + "\\inputs\\network"
    
    // The scenario turn penalty directory is based on the folderName - could change this convention
    scenarioTurnsDirectory=ScenarioDirectory + "\\inputs\\turns"
    
    // The scenario other inputs directory is based on the folderName - could change this convention
    scenarioOtherDirectory=ScenarioDirectory + "\\inputs\\other"
    
    // The scenario programs directory is based on the folderName - could change this convention
    scenarioProgramsDirectory=ScenarioDirectory + "\\programs"
    
    // The scenario controls directory is based on the folderName - could change this convention
    scenarioControlsDirectory=ScenarioDirectory + "\\controls"
    
    // The scenario scripts directory is based on the folderName - could change this convention
    scenarioScriptsDirectory=ScenarioDirectory + "\\scripts"
    
     // The scenario DTA directory is based on the folderName - could change this convention
    scenarioDTADirectory=ScenarioDirectory + "\\DTA"
        
    // The scenario DTA directory is based on the folderName - could change this convention
    scenarioDTAfactorsDirectory=ScenarioDirectory + "\\DTA\\FactorTripTables"
    
    // Copy the Master line layer to a temporary location for safety
    originalMasterLine = masterNetworkDirectory + masterLineFile
    masterLine = tempDirectory + "Master Line Layer.dbd"
    CopyDatabase(originalMasterLine,masterLine)
    
    masterRoute = masterNetworkDirectory + masterRouteFile
    
    //copy turns
    RunMacro("Copy Files",turnPenaltyDirectory,scenarioTurnsDirectory)
    
    //copy other inputs
    RunMacro("Copy Files",otherDirectory,scenarioOtherDirectory)
    
    // Find the groth factor for the current year
    visitorGFTable = ScenarioDirectory + "\\inputs\\other\\Visitor Growth Factors.bin"
    visitorGF = OpenTable("visitorGF", "FFB", {visitorGFTable})
    SetView("visitorGF")
		rh = LocateRecord("visitorGF|", "Year", {currentYear}, )
		GF = GetRecordValues("visitorGF", rh, {"[Growth Factor]"})
		temp11 = GF[1][2] 
    CloseView("visitorGF")

    // Modify the observed visitor trips based on the groth factors
    Opts = null
		Opts.Input.[Matrix Currency] = {ScenarioDirectory + "\\inputs\\other\\visobs.mtx", "Table 1", , }
		Opts.Global.Method = 5
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix Range] = 1
		Opts.Global.[Matrix List] = {"Table 1"}
		Opts.Global.[Value] = GF[1][2]
		Opts.Global.[Force Missing] = "Yes"
		
		ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 


    //copy programs
    RunMacro("Copy Files",programsDirectory,scenarioProgramsDirectory)
    
    //copy control files
    RunMacro("Copy Files",controlsDirectory,scenarioControlsDirectory)

    //copy scripts
    RunMacro("Copy Files",scriptsDirectory,scenarioScriptsDirectory)
    
    //copy DTA files
    RunMacro("Copy Files",DTADirectory,scenarioDTADirectory)
    
    //copy DTAfactors files
    RunMacro("Copy Files",DTADirectory +"\\FactorTripTables",scenarioDTAfactorsDirectory)

		//check for directory of DTA output
    if GetDirectoryInfo(scenarioDTADirectory + "\\outputs", "Directory")=null then do
        CreateDirectory(scenarioDTADirectory + "\\outputs")
    end
    
    //check for directory of output network
    if GetDirectoryInfo(scenarioNetworkDirectory, "Directory")=null then do
        CreateDirectory( scenarioNetworkDirectory)   
    end

    //check for directory of outputs 
    if GetDirectoryInfo(ScenarioDirectory + "\\outputs", "Directory")=null then do
        CreateDirectory(ScenarioDirectory + "\\outputs")   
    end

    //check for directory of reports 
    if GetDirectoryInfo(ScenarioDirectory + "\\reports", "Directory")=null then do
        CreateDirectory(ScenarioDirectory + "\\reports")   
    end

   // Set the location of the output network
    scenarioLineFile = scenarioNetworkDirectory + "\\"+"Scenario Line Layer.dbd"
   
    // Set the extraction parameters
    extractLineString = "not (year>"+String(currentYear)+" and [future link]='a') and not (year<="+String(currentYear)+" and [future link]='d')"
    
    // Run the generic Create Highway Line Layer Macro
    tempFile = RunMacro("Select from Master Line Layer",masterLine,extractLineString,tempDirectory)
    
    // Run the Change Lanes macro
    tempFile = RunMacro("Change Lanes",tempFile,year)

    extractPNRString = "("+String(currentYear)+">=[Start Year_PNR Lot] & "+String(currentYear)+"<=[End Year_PNR Lot])"
    //Assign the parking lots based on the start and end year
    tempFile = RunMacro("Assign PNR Lots",tempFile,currentYear,extractPNRString)

    // Export the highway line layer with the fields I want
    RunMacro("Export Highway Line Layer",tempFile,scenarioLineFile)
    
    // Kyle: once exported, delete the temp directory
    DeleteDatabase(tempFile)
    DeleteDatabase(masterLine)      // this is the copy in the temp folder
    RemoveDirectory(tempDirectory)
    
    extractRouteString = "[begin year] <= "+String(currentYear)+" and [end year]>= "+String(currentYear)
   
   // Select the transit routes, and copy the transit layer to the scenario directory
    
    RunMacro("Export Transit Routes",masterRoute,originalMasterLine,scenarioLineFile,scenarioNetworkDirectory,extractRouteString)
    
    RunMacro("Fill Stop Attributes" , hwyfile, scenarioNetworkDirectory+"\\Scenario Route System.rts", scenarioNetworkDirectory+"\\Scenario Route SystemS.bin")

    RunMacro("Copy Layer Settings", originalMasterLine,scenarioLineFile)
    
    Return(1)
   
EndMacro

Macro "Select from Master Line Layer" (masterLine,extractString,tempDirectory)

    // Check that the files exist
    //		- master line
    if GetFileInfo(masterLine) = null then do
        ShowMessage("File not found: " + masterLine)
        Return()
    end

    // Use the master line scope to create a temporary map
    dbInfo = GetDBInfo(masterLine)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})
    // Get the layer names
    dbLayers = GetDBLayers(masterLine)
   
    // Add the Nodes layer to the map and make it visible
    nodeLayer = AddLayer("TempMap","Nodes",masterLine,dbLayers[1])
    SetLayerVisibility(nodeLayer,"True")
    SetLayer(nodeLayer)
   
    // Prepare the node field names for the new geography
    nodeFields = GetFields(,"All")
    newNodeFields = null
    for j = 1 to nodeFields[1].length do
        newNodeFields = newNodeFields + {"Nodes." + (nodeFields[1][j])}
    end
    
    // Add the Network Roads layer to the map and make it visible
    lineLayer = AddLayer("TempMap","Links",masterLine,dbLayers[2])
    SetLayerVisibility(lineLayer,"True")
    SetLayer(lineLayer)
   
    // Prepare the field names for the new layer
    linkFields = GetFields(,"All")
    newLinkFields = null
    for j = 1 to linkFields[1].length do
        newLinkFields = newLinkFields + {"Links." + (linkFields[1][j])}
    end
   
    // Extract the projects for this year
    SetLayer(lineLayer)
    queryString = "Select * where " + extractString
    recordsReturned = SelectByQuery("YearSpecific","Several",queryString, )
   
    // Export Geography to a temporary file
    tempFile = tempDirectory + "temp.dbd"
    ExportGeography(lineLayer+"|YearSpecific",tempFile,
                  { {"Layer Name","Links"}, {"Field Spec",newLinkFields},
                  	{"Node Name","Nodes"}, {"Node Field Spec",newNodeFields} })
          
    CloseMap("TempMap")
    
    
    Return(tempFile)

EndMacro


Macro "Change Lanes" (tempFile, currentYear)
    
    // Check that the files exist
    //		- master line
    if GetFileInfo(tempFile) = null then do
        ShowMessage("File not found: " + tempFile)
        Return()
    end

   // Get the link layer
   {nodeLayer,linkLayer} = RunMacro("TCB Add DB Layers", tempFile,,)

    futureLink = GetDataVector(linkLayer+"|","[future link]",)
    year = GetDataVector(linkLayer+"|","year",)
         
    //AB LANEA
    futureVector = GetDataVector(linkLayer+"|","[futureAB LaneA]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LANEA]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LANEA]",newVector,) 

    //BA LANEA
    futureVector = GetDataVector(linkLayer+"|","[futureBA LaneA]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LANEA]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LANEA]",newVector,) 

    //AB LANEM
    futureVector = GetDataVector(linkLayer+"|","[futureAB LaneM]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LANEM]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LANEM]",newVector,) 

    //BA LANEM
    futureVector = GetDataVector(linkLayer+"|","[futureBA LaneM]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LANEM]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LANEM]",newVector,) 

    //AB LANEP
    futureVector = GetDataVector(linkLayer+"|","[futureAB LaneP]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LANEP]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LANEP]",newVector,) 

    //BA LANEP
    futureVector = GetDataVector(linkLayer+"|","[futureBA LaneP]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LANEP]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LANEP]",newVector,) 

    //AB LIMITA
    futureVector = GetDataVector(linkLayer+"|","[future AB limitA]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LIMITA]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LIMITA]",newVector,) 

    //BA LIMITA
    futureVector = GetDataVector(linkLayer+"|","[future BA limitA]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LIMITA]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LIMITA]",newVector,) 

    //AB LIMITM
    futureVector = GetDataVector(linkLayer+"|","[future AB limitM]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LIMITM]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LIMITM]",newVector,) 

    //BA LIMITM
    futureVector = GetDataVector(linkLayer+"|","[future BA limitM]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LIMITM]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LIMITM]",newVector,) 

    //AB LIMITP
    futureVector = GetDataVector(linkLayer+"|","[future AB limitP]",)
    currentVector = GetDataVector(linkLayer+"|","[AB LIMITP]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB LIMITP]",newVector,) 

    //BA LIMITP
    futureVector = GetDataVector(linkLayer+"|","[future BA limitP]",)
    currentVector = GetDataVector(linkLayer+"|","[BA LIMITP]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA LIMITP]",newVector,) 

    //AB FNCLASS
    futureVector = GetDataVector(linkLayer+"|","[future AB funcclass]",)
    currentVector = GetDataVector(linkLayer+"|","[AB FNCLASS]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[AB FNCLASS]",newVector,) 

    //BA FNCLASS
    futureVector = GetDataVector(linkLayer+"|","[future BA funcclass]",)
    currentVector = GetDataVector(linkLayer+"|","[BA FNCLASS]",)
    newVector = if ((futureLink='c' or futureLink='a' or futureLink='l')and (year<=currentYear)) then futureVector else currentVector
    SetDataVector(linkLayer+"|","[BA FNCLASS]",newVector,) 

    CloseView(linkLayer)
    CloseView(nodeLayer)
    Return(tempFile)

EndMacro

Macro "Export Highway Line Layer" (tempFile,scenarioFile)
    
   // Use the temp line scope to create a temporary map
   dbInfo = GetDBInfo(tempFile)
   newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})
   // Add the Network Roads layer to the map and make it visible
   linkLayer = AddLayer("TempMap","NewLinks",tempFile,"Links")
   SetLayerVisibility(linkLayer,"True")
   SetLayer(linkLayer)
   
   // Prepare the line field names for the new geography
   newLinkFields = null
   fields = GetFields(,"All")
   for j = 1 to fields[1].length do
   
      fieldName = fields[1][j]
   
      // Exclude the year-specific fields
      temp = Position(fieldName,"future")

        //save the future link field
      if(fieldName="[future link]") then temp=0
      
      // Update the newFields array
      if temp=0 then newLinkFields = newLinkFields + {linkLayer+"." + (fields[1][j])}
   
   end
   
   // Add the Nodes layer to the map and make it visible
   nodeLayer = AddLayer("TempMap","Nodes",tempFile,"Nodes")
   SetLayerVisibility(nodeLayer,"True")
   SetLayer(nodeLayer)
   
   // Prepare the node field names for the new geography
   nodeFields = GetFields(,"All")
   
   // Export geography to the highway line layer
   ExportGeography("NewLinks|",scenarioFile,
                  { {"Layer Name","Oahu Links"}, {"Field Spec",newLinkFields},
                  	{"Node Name","Oahu Nodes"}, {"Node Field Spec",nodeFields[2]} })
                  		
   CloseMap("TempMap")
   
   
    Return(1)

EndMacro

Macro "Copy Layer Settings" (originFile,scenarioFile)
    
    path = SplitPath(originFile)
    originFiles = { path[1]+path[2]+path[3]+".st1",
                    path[1]+path[2]+path[3]+".sty" }
 
    path = SplitPath(scenarioFile)
    destFiles = { path[1]+path[2]+path[3]+".st1",
                  path[1]+path[2]+path[3]+".sty" }
    
    for i = 1 to originFiles.length do
        CopyFile(originFiles[i],destFiles[i])
    end

    arrayOpts = {
        "Alignment",                    //1   
        "Color",                        //2
        "Font",                         //3
        "Framed",                       //4
        "Kern To Fill",                 //5
        "Left/Right",                   //6
        "Priority Expression",          //7
        "Rotation",                     //8
        "Set Priority",                 //9
        "Smart",                        //10
        "Uniqueness",                   //11
        "Visibility"                    //12
    }
    
    arrayOpts = {
        "Alignment",
        "Alternate Field",
        "Color",
        "Font",
        "Format",
        "Frame Border Style",
        "Frame Border Color",
        "Frame Border Width",
        "Frame Fill Color",
        "Frame Fill Style",
        "Frame Shield",
        "Frame Type",
        "Framed",
        "Kern To Fill",
        "Left/Right",
        "Line Length Limit",
        "Priority Expression",
        "Rotation",
        "Scale",
        "Set Priority",
        "Smart",
        "Uniqueness",
        "Visibility"
    }
 
    // Use the temp line scope to create a temporary map
    dbInfo = GetDBInfo(originFile)
    newmap = CreateMap("OriginMap",{{"Scope",dbInfo[1]}})
   // Get the layer names
    dbLayers = GetDBLayers(originFile)
    
    // Add the master Roads layer to the map and make it visible
    link_lyr = AddLayer("OriginMap","Links",originFile,dbLayers[2])    
    label_exp = GetLabelExpression(link_lyr+"|")
    opts = GetLabelOptions(link_lyr+"|", arrayOpts)

    // Create a new map
    dbInfo_dest = GetDBInfo(scenarioFile)
    destmap = CreateMap("DestMap",{{"Scope",dbInfo_dest[1]}})
    dbLayers_dest = GetDBLayers(scenarioFile)
    
   // Add the scenario Roads layer to the map and make it visible
    link_lyr_dest = AddLayer("DestMap","Links",scenarioFile,dbLayers_dest[2])    
    SetLabels(link_lyr_dest+"|", label_exp, opts)
    SetLabelOptions(link_lyr_dest+"|", opts)

    RunMacro("Close All")
    
    Return(1)
EndMacro 

 /*
Macro "Select Transit Routes" (masterLine,routeFile,future)

    // Check that the files exist
    if GetFileInfo(routeFile) = null then do
        ShowMessage("File not found: " + routeFile)
        Return()
    end
    
    // Check that the files exist
    if GetFileInfo(masterLine) = null then do
        ShowMessage("File not found: " + masterLine)
        Return()
    end
        
    // Use the master line scope to create a temporary map
    dbInfo = GetDBInfo(masterLine)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})

    dbLayers = GetDBLayers(masterLine)
        
    // Add the Nodes layer to the map and make it visible
    nodeLayer = AddLayer("TempMap","Nodes",masterLine,dbLayers[1])
    SetLayerVisibility(nodeLayer,"True")
   
    // Add the Network Roads layer to the map and make it visible
    lineLayer = AddLayer("TempMap","Links",masterLine,dbLayers[2])
    SetLayerVisibility(lineLayer,"True")

    // Make sure route system references master line layer
    ModifyRouteSystem(routeFile, {{"Geography", masterLine, dbLayers[2]}})
    
    info = GetRouteSystemInfo(routeFile)
    	 
     // Add the route system to it
    routeLayer = AddRouteSystemLayer("TempMap", "Route System", routeFile,)
    routes = routeLayer[1]
    stops = routeLayer[2]
    SetLayerVisibility(routes,"True")

    // Get the names of all of the routes in the route system
    names = GetRouteNames(routes)

    // Get the name of the route system fields
    routeFields= GetRouteSystemFields(routes)
    
    // Iterate through the route system fields, find the "[future year flag]" field
    for i = 1 to routeFields[1][1].length do
        if routeFields[1][1][i] = "[future year flag]" then futureYearField=i
    end
    
    // There are two fixed route fields, so the extra attribute field is i - 2
    futureYearField = futureYearField - 2 
    
    //Cycle through the routes, check if it is future, if so delete it
    for i = 1 to names.length do
        attr = GetRouteAttributes(routes, names[i])
        if attr[futureYearField] = "y" and future="False" then DeleteRoute(routes,names[i])
        if attr[futureYearField] = null and future="True" then DeleteRoute(routes,names[i])
        
    end

   CloseMap("TempMap")

    Return(1)

EndMacro
*/
Macro "Export Transit Routes" (masterRouteFile,masterLineFile,scenarioLineFile,scenarioNetworkDirectory,extractString)


     // Make sure route system references master line layer
     // Kyle: Never modify the master networks from the script.  Instead, check and throw error.
     //       User must fix manually if there is an issue (so they know about the change).
    dbLayers = GetDBLayers(masterLineFile)
    // ModifyRouteSystem(masterRouteFile, {{"Geography", masterLineFile, dbLayers[2]}})
    a_rsInfo = GetRouteSystemInfo(masterRouteFile)
    if a_rsInfo[1] <> masterLineFile then do
        ShowMessage("The master route system is not based on the master highway network. Use 'Route Systems' -> 'Utilities' -> 'Move' to fix. ")
        ShowMessage(1)
    end
    
    
    // Add the transit layers
    {rs_lyr, stop_lyr, ph_lyr} = RunMacro("TCB Add RS Layers",masterRouteFile, "ALL",)
    
    // The new route file name
    scenarioRouteFile=scenarioNetworkDirectory+"\\Scenario Route System"
    
   // Create the selection set of relevant routes   
    setname = "routesquery"
    queryString = "Select * where " + extractString
    n = SelectByQuery(setname,  "Several", queryString,) 
    
    // Copy the selected routes in the transit layer to the new directory
    RunMacro("TC40 create Route System subset ex", rs_lyr, setname, null, null, 1, False, null, scenarioRouteFile)
    
     // Make sure route system references scenario line layer
    dbLayers = GetDBLayers(scenarioLineFile)
    ModifyRouteSystem(scenarioRouteFile, {{"Geography", scenarioLineFile, dbLayers[2]}})

    // close all maps
    maps = GetMapNames()
    for i = 1 to maps.length do
     CloseMap(maps[i])
    end

    // Add the transit layers
    {rs_lyr, stop_lyr, ph_lyr} = RunMacro("TCB Add RS Layers",scenarioRouteFile, "ALL",)

    n = SelectByQuery(setname,  "Several", "Select * where Route_ID>0",) 
    n = SelectByQuery(setname,  "Less", queryString,) 
    if n > 0 then DeleteRecordsInSet(setname)

    // close all maps
    maps = GetMapNames()
    for i = 1 to maps.length do
     CloseMap(maps[i])
    end
        
   //ShowMessage("Please reload scenario route system and verify to ensure that there are no errors!")

    Return(1)

EndMacro

Macro "Fill Stop Attributes" (hwyfile, rtsfile, rstopfile)

    // RunMacro("TCB Init")

    path = SplitPath(rtsfile)
    rtsfile1=path[1]+path[2]+path[3]+"R.bin"
    
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    {rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )   

    rtsfile1_nm=ParseString(rtsfile1,"\\.")
 
    Opts = null
    Opts.Input.[Dataview Set] = {{stp_lyr, rtsfile1, {"Route_ID"}, {"Route_ID"}}, "joinedvw111"}             
            Opts.Global.Fields = {stp_lyr+".RTE_NUMBER",
        	                    stp_lyr+".RTE_NAME",
        	                    stp_lyr+".MODE",
        	                    stp_lyr+".EA_HEADWAY",
        	                    stp_lyr+".AM_HEADWAY",
        	                    stp_lyr+".MD_HEADWAY",
        	                    stp_lyr+".PM_HEADWAY",
        	                    stp_lyr+".EV_HEADWAY"}                           // the field to fill
    Opts.Global.Method = "Formula"                                          // the fill method
    Opts.Global.Parameter = {"["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".RouteNumber",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".Route_Name",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".Mode",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".EA_Headway",
     	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".AM_Headway",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".MD_Headway",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".PM_Headway",
    	                       "["+rtsfile1_nm[rtsfile1_nm.length-1]+"]"+".EV_Headway"}                                
    
    
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit   
                
    Opts = null
    
    Opts.Input.[Dataview Set] = {{stp_lyr, rtsfile1, {"Route_ID"}, {"Route_ID"}}, "joinedvw111"}               
        Opts.Global.Fields = {stp_lyr+".STOP_FLAG"}                           // the field to fill
    Opts.Global.Method = "Value"                                          // the fill method
    Opts.Global.Parameter = {1}                                // the column in the fspdfile
    
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit   
     
    // close all maps
    maps = GetMapNames()
    for i = 1 to maps.length do
     CloseMap(maps[i])
    end

    Return(1)           
    
    quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro      

Macro "Assign PNR Lots" (tempFile,currentYear,extractPNRString)    

    // Check that the files exist
    //		- master line
    if GetFileInfo(tempFile) = null then do
        ShowMessage("File not found: " + tempFile)
        Return()
    end

		//currentYear = stringtoint(currentYear)
		
   // Get the Node layer
   {nodeLayer,linkLayer} = RunMacro("TCB Add DB Layers", tempFile,,)
   
    SetLayer(nodeLayer) //Node Layer   
    queryString = "Select * where " + extractPNRString
   
    n1 = SelectByQuery("PNR", "Several", queryString,)
	    if n1 > 0 then do
            Opts = null
            Opts.Input.[Dataview Set] = {tempFile+"|"+nodeLayer, nodeLayer, "PNR"}	
            Opts.Global.Fields = {"PNR"}
            Opts.Global.Method = "Value"
            Opts.Global.Parameter = {"1"}
            ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
            if !ret_value then goto quit
			end   
    CloseView(linkLayer)
    CloseView(nodeLayer)
    Return(tempFile)           
    
    quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )
   
EndMacro        