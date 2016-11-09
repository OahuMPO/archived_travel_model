/**************************************************************
   tripgen.rsc
 
  TransCAD Macro used to run trip generation

**************************************************************/
Macro "Trip Generation" (scenarioDirectory, iftoll, fixgdwy)

    RunMacro("TCB Init")
    
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

    RunMacro("Close All")

    program:
    
    //truck trips
    executableString = ".\\programs\\HNL5SPGN.exe"
    controlString =    ".\\controls\\TRKGEN5.ctl"
   
   	ret_value = RunMacro("Run Program",scenarioDirectory,executableString,controlString)
    if(!ret_value) then Throw()   
    
      //airport trips
    executableString = ".\\programs\\HNL5SPGN.exe"
    controlString =    ".\\controls\\AIRGEN5.ctl"

   	ret_value = RunMacro("Run Program",scenarioDirectory,executableString,controlString)
    if(!ret_value) then Throw()   
   	
    Return(1)    
    
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

    
EndMacro
/***********************************************************************************************************************************
*
* Run Program
* Runs the program for a set of control files 
*
***********************************************************************************************************************************/

Macro "Run Program" (scenarioDirectory, executableString, controlString)


        // Pause for 3 seconds
				Pause(3000)
				
				//drive letter
				path = SplitPath(scenarioDirectory)
				
        //open the batch file to run
        fileString = scenarioDirectory+"\\programs\\source.bat"
        ptr = OpenFile(fileString, "w")

        // Pause for 3 seconds
				Pause(3000)
       
        WriteLine(ptr,path[1])
        WriteLine(ptr,"cd "+scenarioDirectory )
    
        runString = "call "+executableString + " " + controlString
        WriteLine(ptr,runString)
        
        //write the return code check
        failString = "IF NOT ERRORLEVEL = 0 ECHO "+controlString+" > failed.txt"
        WriteLine(ptr,failString) 
        // WriteLine(ptr,"pause")
        CloseFile(ptr)
        
        // Pause for 3 seconds
				Pause(3000)
		
        // Before running the program, clear out any previous error files
        if GetFileInfo(scenarioDirectory+"\\failed.txt") <> null then DeleteFile(scenarioDirectory+"\\failed.txt")
		
        status = RunProgram(fileString, {{"Minimize", "True"}})
       
        info = GetFileInfo(scenarioDirectory+"\\failed.txt")
        if(info != null) then do
            ret_value=0
            Throw()
        end

    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro

