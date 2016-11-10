Macro "DTA to TAZ"(scenarioDirectory,DTA_DBD)
    
    RunMacro("TCB Init")
   scenarioDirectory = "F:\\projects\\ompo\\ORTP2009\\A_Model\\2007_100709"
	 DTA_DBD= scenarioDirectory + "\\DTA\\Outputs\\DTAhighway.dbd"
 	    
    //these are the fields that will be added or replaced in the taz file, and the corresponding TAZs
    newHwyFields = {"6TO8AMDTA_Downtown", "6TO8AMDTA_Kapolei", "6TO8AMDTA_Ewa", "6TO8AMDTA_Airport", "6TO8AMDTA_Waikiki","6TO8AMDTA_Mililani"} 
    plotZones =    {  240,           596,           551,            762,           118,            494         }

    dim hwyFound[newHwyFields.length]
   
    // Set the TAZ table, file
    tazTable = scenarioDirectory +"\\inputs\\taz\\Scenario TAZ Layer.bin"
    tazFile = scenarioDirectory +"\\inputs\\taz\\Scenario TAZ Layer.dbd"
    
    // First open taz file and see if the fields are already in the file
    view_name = OpenTable("TAZ View", "FFB", {tazTable, null}, {{"Shared", "False"}})
    strct = GetTableStructure(view_name)
    for i = 1 to strct.length do
        // Copy the current name to the end of strct
         strct[i] = strct[i] + {strct[i][1]}
         for k = 1 to hwyFound.length do
            if strct[i][1] = newHwyFields[k] then hwyFound[k] = "True"
         end
    end


    //add hwy fields that don't exist    
    for i = 1 to newHwyFields.length do
        if hwyFound[i] <> "True" then do
            strct = strct + {{newHwyFields[i], "Real", 12, 2, "True", , , , , , , null}}
        end
    end
 
    // Modify the table
    ModifyTable(view_name, strct)
    CloseView(view_name)
        
    //open DTA auto skim
    autoskim = scenarioDirectory + "\\DTA\\outputs\\DADynSkim.mtx"
    autoMatrix = OpenMatrix(autoskim, "True")
    autoTime = CreateMatrixCurrency(autoMatrix, "\"6:00\" -- \"8:00 AM\"", null, null, )
    
    //add fields to TAZ layer
    dbInfo = GetDBInfo(tazFile)
    dbLayers = GetDBLayers(tazFile)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})
   
    // Add the taz layer to the map and make it visible
    taz_layer=AddLayer("TempMap","Oahu_TAZs", tazFile,dbLayers[1])
    SetLayerVisibility(taz_layer,"True")

    for i = 1 to newHwyFields.length do 
        vec = GetMatrixVector(autoTime, {{"Column", plotZones[i]}}) 
        SetDataVector(taz_layer + "|", newHwyFields[i], vec, {{"Sort Order", {{"TAZ", "A"}} }}) 
    end
   
    
    
    
    


EndMacro