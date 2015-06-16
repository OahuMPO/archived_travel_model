Macro "Convert TAZ to ASC" (scenarioDirectory)

//    RunMacro("TCB Init")
//    scenarioDirectory="f:\\projects\\ompo\\ortp2009\\c_model\\2030MOSJ_setdist_110503"
    
    // Get the master TAZ layer
    scenarioTAZFile = scenarioDirectory + "\\inputs\\taz\\Scenario TAZ Layer.DBD"
    dbInfo = GetDBInfo(scenarioTAZFile)
    dbLayers = GetDBLayers(scenarioTAZFile)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})
   
   // Add the taz layer to the map and make it visible
   tazLayer=AddLayer("TempMap","Oahu_TAZs",scenarioTAZFile,dbLayers[1])
   SetLayerVisibility(tazLayer,"True")
    
    strct = GetTableStructure(tazLayer)
    fields = null
    for i = 1 to strct.length do

        // Any 8 byte real gets changed to a 4 byte float
        if(strct[i][2]="Real") then do
            strct[i][2] = "Float"
            strct[i][3] = 12
            strct[i][4] = 2
        end

        // Any 4 byte int gets changed to a 4 byte float
        if(strct[i][2]="Integer") then do
            strct[i][2] = "Float"
            strct[i][3] = 12
            strct[i][4] = 2
        end
        
        // Any float changes to 2 decimals, width of 12
        if(strct[i][2]="Float") then do
            strct[i][3] = 12
            strct[i][4] = 2
        end
        
        // Any 2-byte integer changes to width of 12
        if(strct[i][2]="Short") then do
            strct[i][3] = 12
        end
        
        // an array of field names to open in the editor includes all fields except for character fields
        if(strct[i][2] != "String") then do
            fields = fields + {strct[i][1]}
        end
        
        strct[i] = strct[i] + {strct[i][1]}

    end
    
    // Modify the table
    ModifyTable(tazLayer, strct)

    path = SplitPath(scenarioTAZFile)

    shared d_edit_options
    ed = CreateEditor("ed", tazLayer + "|",fields,d_edit_options) 
    SetRowOrder(ed, {{"TAZ", "Ascending"}}) 
    ExportEditor(ed, "FFA",  path[1]+path[2]+path[3],)
    CloseEditor(ed)

    Return(1)    
    
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

    
EndMacro
