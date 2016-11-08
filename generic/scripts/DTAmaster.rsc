/***********************************************************************************
*
* DTA Model
*
* * PB- ARF 10/28/09
*
* This is the script for running the DTA model.  It copies the scenario line layer
* and creates a DTA network instead of adding additional fields/data to the 
* scenario line layer. plots should use the DTA network located in the DTA output folder
*
************************************************************************************/


Macro "OahuMPO DTA"(path, options)

 //    RunMacro("TCB Init")
    scenarioDirectory = path[2]
    //scenarioDirectory = "C:\\currentlaptop\\OMPO_ORTP\\2035baseline_WH092409NCFix"

    
     // Model SetUP
     
     period = "AM4Hour"
     highway_db=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
     highway_net=scenarioDirectory+"\\DTA\\outputs\\hwy"+period+".net"
     odMatrix = scenarioDirectory+"\\DTA\\FactorTripTables\\DTA_TT_AM_4Hrs.mtx"
     flowTable = scenarioDirectory+"\\DTA\\outputs\\DALinkFlow.bin"
     turnPenalty = scenarioDirectory+"\\inputs\\turns\\am turn penalties.bin"
     skimMatrix = scenarioDirectory+"\\DTA\\outputs\\DADynSkim.mtx"
	 DTA_DBD= scenarioDirectory + "\\DTA\\Outputs\\DTAhighway.dbd"
 	  turnPenalty = scenarioDirectory+"\\inputs\\turns\\am turn penalties.bin"
		
		
	 CopyDatabase(highway_db, DTA_DBD)

		ret_value = RunMacro("Prepare DTA Trip Table", scenarioDirectory, odMatrix) 
    if !ret_value then goto quit
  
  	ret_value = RunMacro("Process HighwayFile", scenarioDirectory,DTA_DBD,odMatrix) 
    if !ret_value then goto quit
    
    ret_value = RunMacro("Set 4Hr AM Peak Network",scenarioDirectory, period, highway_net, DTA_DBD)
    if !ret_value then goto quit

     // STEP 1: Highway Network Setting
     Opts = null
     Opts.Input.Database = DTA_DBD
     Opts.Input.Network = highway_net
     Opts.Input.[Spc Turn Pen Table] = {turnPenalty}
     Opts.Global.[Global Turn Penalties] = {0, 0, 0, 0}
     Opts.Flag.[Centroids in Network] = 1
     
     ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
     if !ret_value then goto quit    // DTA Settings

     
     Opts = null
     Opts.Input.Database = DTA_DBD
     Opts.Input.Network  = highway_net
     Opts.Input.[OD Matrix Currency] = {odMatrix, "\"3:00\" -- \"3:15 AM\"", "Rows", "Columns"}
     Opts.Field.[Storage Capacity] = "*_AM15Min_SCAP"
     Opts.Field.[VDF Fld Names] = {"*_FFTIME", "*_CAPACITY", "*_ALPHA", "None"}
     Opts.Global.[Load Method] = "UE"
     Opts.Global.[Loading Multiplier] = 1
     Opts.Global.[Alpha Value] = 0.15
     Opts.Global.[Beta Value] = 4
     Opts.Global.Convergence = 0.005
     Opts.Global.[Time Minimum] = 0
     Opts.Global.Iterations = 50
     Opts.Global.[Interval Length] = 15
     Opts.Global.[Outer Iterations] = 20
     Opts.Global.[Node Time Intervals] = 0.01
     Opts.Global.[Depart Intervals] = 32
     Opts.Global.[All Intervals] = 32
     Opts.Global.[FIFO Interval Fraction] = 0.5
     Opts.Global.[Capacity Adjustment Lowerbound] = 0.1
     Opts.Global.[Save Memory] = 0
     Opts.Global.Spillback = 1
     Opts.Global.[Do Theme] = 1
     Opts.Global.[Cost Function File] = "emme2.vdf"
     Opts.Global.[VDF Defaults] = {, , 6, 0}
     Opts.Output.[Flow Table] = flowTable
     Opts.Output.[Dynamic Skim Matrix].Label = "Dynamic Skim Matrix"
     Opts.Output.[Dynamic Skim Matrix].[File Name] = skimMatrix


     ret_value = RunMacro("TCB Run Procedure", "Dynamic Assignment", Opts, &Ret)
     if !ret_value then goto quit
     	
     SkimSummary:
     	
     ret_value = RunMacro("DTA Skim Summary",scenarioDirectory,DTA_DBD)
    if !ret_value then goto quit
     	
     	  Return(1)
	
	   quit:
         Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro



/***********************************************************************************
*
* DTA Trip Tables
*
* PB - Ram 05/20/09
* PB- ARF 09/09/09
*
* Script factors the trips tables from the Hawaii 5 model run into the proper DTA travel matrices.
* It also processes the highway file by calculating new 15 min capacities for each link if the 
* network.  It creates the 15 cap field if network doesnt doesnt already have those fields. 
*  If fields exists they are overwritten with new capacities.
*
* You must already have the odMatrix matrix created or the script will not work.  Assure that
* the travel timematrix is in the right folder before running/
*  It will be zeroed out and overwritten by the script.
*
************************************************************************************/
Macro "Prepare DTA Trip Table"(scenarioDirectory,odMatrix)

//			RunMacro("TCB Init")
			
			TimePeriods = {{1,"AM"},{2,"MD"},{3,"PM"},{4,"Night"}}
			StudyPeriods = {{1,4},{2,4},{3,4},{4,4},{5,4},{6,4},{7,4},{8,1},{9,1},{10,1},{11,1},{12,1},{13,1},{14,1},{15,1},{16,1},{17,1},{18,1},{19,1},{20,1},{21,1},{22,1},{23,1},{24,1},{25,2},{26,2},{27,2},{28,2},{29,2},{30,2},{31,2},{32,2}}
			
			AM_TT    = scenarioDirectory + "\\outputs\\hwyAM4Hour.mtx"			
			MD_TT    = scenarioDirectory + "\\outputs\\hwyMidday.mtx"			
			PM_TT    = scenarioDirectory + "\\outputs\\hwyPM4Hour.mtx"			
			Night_TT = scenarioDirectory + "\\outputs\\hwyNight.mtx"			

			DTA_AM_TT    = scenarioDirectory + "\\DTA\\outputs\\DTA_hwyAMPeak.mtx"			
			DTA_MD_TT    = scenarioDirectory + "\\DTA\\outputs\\DTA_hwyMidday.mtx"			
			DTA_PM_TT    = scenarioDirectory + "\\DTA\\outputs\\DTA_hwyPMPeak.mtx"			
			DTA_Night_TT = scenarioDirectory + "\\DTA\\outputs\\DTA_hwyNight.mtx"			
			sourceMatrix = {{DTA_AM_TT,"DTA_AM_TT"},{DTA_MD_TT,"DTA_MD_TT"},{DTA_PM_TT,"DTA_PM_TT"},{DTA_Night_TT,"DTA_Night_TT"}}
			
			Factors_TAZ  = scenarioDirectory + "\\DTA\\FactorTripTables\\Factors By Origin TAZ.bin"

      CopyFile(AM_TT, DTA_AM_TT)
      CopyFile(MD_TT, DTA_MD_TT)
      CopyFile(PM_TT, DTA_PM_TT)
      CopyFile(Night_TT, DTA_Night_TT)

   //Resets the values to zero to assure new factors are being created for each run   
     Opts = null
     Opts.Input.[Matrix Currency] = {odMatrix, "\"3:00\" -- \"3:15 AM\"", "Rows", "Columns"}
     Opts.Global.Method = 1
     Opts.Global.Value = 0
     Opts.Global.[Cell Range] = 2
     Opts.Global.[Matrix Range] = 3
     Opts.Global.[Matrix List] = {"\"3:00\" -- \"3:15 AM\"", "\"3:15\" -- \"3:30 AM\"", "\"3:30\" -- \"3:45 AM\"", "\"3:45\" -- \"4:00 AM\"", "\"4:00\" -- \"4:15 AM\"", "\"4:15\" -- \"4:30 AM\"", "\"4:30\" -- \"4:45 AM\"", "\"4:45\" -- \"5:00 AM\"", "\"5:00\" -- \"5:15 AM\"", "\"5:15\" -- \"5:30 AM\"", "\"5:30\" -- \"5:45 AM\"", "\"5:45\" -- \"6:00 AM\"", "\"6:00\" -- \"6:15 AM\"", "\"6:15\" -- \"6:30 AM\"", "\"6:30\" -- \"6:45 AM\"", "\"6:45\" -- \"7:00 AM\"", "\"7:00\" -- \"7:15 AM\"", "\"7:15\" -- \"7:30 AM\"", "\"7:30\" -- \"7:45 AM\"", "\"7:45\" -- \"8:00 AM\"", "\"8:00\" -- \"8:15 AM\"", "\"8:15\" -- \"8:30 AM\"", "\"8:30\" -- \"8:45 AM\"", "\"8:45\" -- \"9:00 AM\"", "\"9:00\" -- \"9:15 AM\"", "\"9:15\" -- \"9:30 AM\"", "\"9:30\" -- \"9:45 AM\"", "\"9:45\" -- \"10:00 AM\"", "\"10:00\" -- \"10:15 AM\"", "\"10:15\" -- \"10:30 AM\"", "\"10:30\" -- \"10:45 AM\"", "\"10:45\" -- \"11:00 AM\"", "diff730rhett_ram", "AMPEAK", "ampeakDiff"}

     ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts, &Ret)
		 if !ret_value then goto quit


			Opts = null
			Opts.Input.[Input Currency] =    {DTA_AM_TT, , , }
			ret_value = RunMacro("TCB Run Operation", "Matrix QuickSum", Opts) 
			if !ret_value then goto quit
			
			Opts = null
			Opts.Input.[Input Currency] =    {DTA_MD_TT, , , }
			ret_value = RunMacro("TCB Run Operation", "Matrix QuickSum", Opts) 
			if !ret_value then goto quit
			
			Opts = null
			Opts.Input.[Input Currency] =    {DTA_PM_TT, , , }
			ret_value = RunMacro("TCB Run Operation", "Matrix QuickSum", Opts) 
			if !ret_value then goto quit
			
			Opts = null
			Opts.Input.[Input Currency] =    {DTA_Night_TT, , , }
			ret_value = RunMacro("TCB Run Operation", "Matrix QuickSum", Opts) 
      if !ret_value then goto quit 
      
      m = OpenMatrix(DTA_AM_TT, )
			matrix_cores = GetMatrixCoreNames(m)
			for i = 1 to matrix_cores.length do
					
					if(matrix_cores[i]!="QuickSum") then do
							DropMatrixCore(m, matrix_cores[i])
					end
					else do
							SetMatrixCoreName(m, matrix_cores[i], "DTA_AM_TT")
					end
			
			end

      m = OpenMatrix(DTA_MD_TT, )
			matrix_cores = GetMatrixCoreNames(m)
			for i = 1 to matrix_cores.length do
					
					if(matrix_cores[i]!="QuickSum") then do
							DropMatrixCore(m, matrix_cores[i])
					end
					else do
							SetMatrixCoreName(m, matrix_cores[i], "DTA_MD_TT")
					end
			
			end

      m = OpenMatrix(DTA_PM_TT, )
			matrix_cores = GetMatrixCoreNames(m)
			for i = 1 to matrix_cores.length do
					
					if(matrix_cores[i]!="QuickSum") then do
							DropMatrixCore(m, matrix_cores[i])
					end
					else do
							SetMatrixCoreName(m, matrix_cores[i], "DTA_PM_TT")
					end
			
			end

      m = OpenMatrix(DTA_Night_TT, )
			matrix_cores = GetMatrixCoreNames(m)
			for i = 1 to matrix_cores.length do
					
					if(matrix_cores[i]!="QuickSum") then do
							DropMatrixCore(m, matrix_cores[i])
					end
					else do
							SetMatrixCoreName(m, matrix_cores[i], "DTA_Night_TT")
					end
			
			end  
			
			DTA_Factors = OpenTable("DTA_Factors", "FFB", {Factors_TAZ})                                                                                                                                                                                                                                                                                                                                                                                                                                          
			{Flds,} = GetFields(DTA_Factors, "All")
			
			for i = 1 to StudyPeriods.length do
						
						coreName = Flds[13+i]
						a = GetDataVectors(DTA_Factors+"|", {Flds[13+i]}, {{"Sort Order", {{"TAZ", "Ascending"}}}} )
						
			     Opts = null
			     Opts.Input.[Matrix Currency] = {odMatrix, "\""+Substring(coreName,2,Position(coreName,"--")-3)+"\" -- \""+Substring(coreName,Position(coreName,"--")+3,Len(coreName)-(Position(coreName,"--")+3))+"\"", , }
			     Opts.Input.[Source Matrix Currency] = {sourceMatrix[StudyPeriods[i][2]][1], sourceMatrix[StudyPeriods[i][2]][2], , }
			     Opts.Input.[Data Set] = {Factors_TAZ, DTA_Factors}
			     Opts.Global.Method = 12
			     Opts.Global.[Fill Option].[ID Field] = DTA_Factors+".TAZ"
			     Opts.Global.[Fill Option].[Value Field] = DTA_Factors+"."+coreName
			     Opts.Global.[Fill Option].[Apply by Rows] = "No"
			     Opts.Global.[Fill Option].[Missing is Zero] = "Yes"
			
			     ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts, &Ret)
			 		 if !ret_value then goto quit

			end
						
			
			

	  Return(1)
	
	  quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )
      
      
EndMacro


Macro "Process HighwayFile"(scenarioDirectory,DTA_DBD,odMatrix)

//			RunMacro("TCB Init")
			TimePeriod = 15
			StorageCapacity = 210
			//DTA_DBD= scenarioDirectory + "\\DTA\\Outputs\\DTAhighway.dbd"
			{node_lyr,link_lyr} = RunMacro("TCB Add DB Layers", DTA_DBD,,)
	    if link_lyr = null then goto quit
	    
	    {_Flds,} = GetFields(link_lyr, "All")
	    if !ArrayPosition(_Flds, {"AB_CAP_AM15Min"},) then do                // if group field not exists yet
        NewFlds = {{"AB_CAP_AM15Min", "integer"},{"BA_CAP_AM15Min", "integer"},{"AB_2hr_AM_SC", "integer"},{"BA_2hr_AM_SC", "integer"}}       // specify new field
        ok = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})   // add new field
			end

    Opts = null
    Opts.Input.[Dataview Set] = {DTA_DBD + "|" + link_lyr, link_lyr,"AB Links","Select * where Dir<>-1"}
    Opts.Global.Fields = {"AB_CAP_AM15Min", "AB_2hr_AM_SC"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"AB_CAP_AM2HR*"+I2S(TimePeriod)+"/120", "Max(1,"+I2S(StorageCapacity)+"*Length*[AB_LANE])"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
		if !ret_value then goto quit
		
    Opts = null
    Opts.Input.[Dataview Set] = {DTA_DBD + "|" + link_lyr, link_lyr,"BA Links","Select * where Dir<>1"}
    Opts.Global.Fields = {"BA_CAP_AM15Min", "BA_2hr_AM_SC"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"BA_CAP_AM2HR*"+I2S(TimePeriod)+"/120", "Max(1,"+I2S(StorageCapacity)+"*Length*[BA_LANE])"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
    if !ret_value then goto quit

    Opts = null
    Opts.Input.[Dataview Set] = {DTA_DBD + "|" + link_lyr, link_lyr,"BA Links","Select * where [AB FACTYPE]=13"}
    Opts.Global.Fields = {"AB_CAP_AM15Min", "AB_2hr_AM_SC"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"AB_CAP_AM15Min*2/3", "AB_2hr_AM_SC*2/3"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
    if !ret_value then goto quit

    Opts = null
    Opts.Input.[Dataview Set] = {DTA_DBD + "|" + link_lyr, link_lyr,"BA Links","Select * where [BA FACTYPE]=13"}
    Opts.Global.Fields = {"BA_CAP_AM15Min", "BA_2hr_AM_SC"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"BA_CAP_AM15Min*2/3", "BA_2hr_AM_SC*2/3"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
    if !ret_value then goto quit

	  Return(1)
	
	  quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro

/***********************************************************************************
*
* DTA  Set AM Peak Network
*
* PB - Ram 05/20/09
* PB - ARF 08/21/09
*
* Script takes the AM network and recodes the null capacities and FF times to zero so the model will operate.
* Note: Excludes walk access and transit only links
*
************************************************************************************/
Macro "Set 4Hr AM Peak Network"(scenarioDirectory, period, highway_net, DTA_DBD)

//		RunMacro("TCB Init")
    //scenarioDirectory = "D:\\Honolulu\\ORTP_Runs\\2035baselineDTA"
   // period = "AM4Hour"


   // highway_db=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
   // highway_net=scenarioDirectory+"\\outputs\\hwy"+period+".net"


     //add the layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", DTA_DBD,,)  
     SetLayer(link_lyr) //Line Layer  


        turns = scenarioDirectory+"\\inputs\\turns\\am turn penalties.bin"
        ab_capacity = "AB_CAP_AM15Min"
        ba_capacity = "BA_CAP_AM15Min"
        ab_scapacity = "AB_2hr_AM_SC"
        ba_scapacity = "BA_2hr_AM_SC"

        RunMacro("Recode Values", DTA_DBD, {ab_capacity,ba_capacity,ab_scapacity,ba_scapacity},
                                                   {        null,        null,        null,        null},
                                                   {          99,          99,          99,          99},
                {1,2,3,4,5,6,7,8,9,10,11,12,13})
        
        RunMacro("Recode Values", DTA_DBD, {ab_capacity,ba_capacity,ab_scapacity,ba_scapacity},
                                                   {         0,            0,         0,            0},
                                                   {        99,           99,        1,           1},
                {1,2,3,4,5,6,7,8,9,10,11,12,13})
        
        RunMacro("Recode Values", DTA_DBD, {"AB_FFTIME", "BA_FFTIME", "AB_ALPHA","BA_ALPHA"},
                                                   {     null,     null,      null,     null},
                                                   {          0,           0,         99,        99},
				        {1,2,3,4,5,6,7,8,9,10,11,12,13})


		    // Create a selection set to exclude the transit only links and walk connectors while creating a highway network for highway skimming 
        {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", DTA_DBD,,)  
        SetLayer(link_lyr) //Line Layer  
		    Auto_Links = SelectByQuery("AutoLinks", "Several", "Select * where ([AB FACTYPE] != 14 & [AB FACTYPE] != 197)",)


        Opts = null
        Opts.Input.[Link Set] = {DTA_DBD+"|"+link_lyr, link_lyr, "AutoLinks"}
        Opts.Input.[Toll Set] = {DTA_DBD+"|"+link_lyr, link_lyr}
        Opts.Global.[Network Options].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
        Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
        Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
        Opts.Global.[Network Options].[Turn Penalties] = "Yes"
        Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
        Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
        Opts.Global.[Network Options].[Time Unit] = "Minutes"
        Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}}, 
                      {"*_Speed", {link_lyr+".[AB Speed]", link_lyr+".[BA Speed]", , , "False"}}, 
     				  {"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}}, 
     				  {"*_LIMITA", {link_lyr+".[AB_LIMITA]", link_lyr+".[BA_LIMITA]", , , "False"}}, 
     				  {"*_LIMITM", {link_lyr+".[AB_LIMITM]", link_lyr+".[BA_LIMITM]", , , "False"}}, 
     				  {"*_LIMITP", {link_lyr+".[AB_LIMITP]", link_lyr+".[BA_LIMITP]", , , "False"}}, 
     				  {"*_FFTIME", {link_lyr+".AB_FFTIME", link_lyr+".BA_FFTIME", , , "False"}}, 
     				  {"*_CAPACITY", {link_lyr+"."+ab_capacity, link_lyr+"."+ba_capacity, , , "False"}},
     				  {"*_ALPHA", {link_lyr+".[AB_ALPHA]", link_lyr+".[BA_ALPHA]", , , "False"}},
     				  {"*_COST_DANT", {link_lyr+".COST_DANT", link_lyr+".COST_DANT", , , "False"}},
     				  {"*_AM15Min_SCAP", {link_lyr+"."+ab_scapacity, link_lyr+"."+ba_scapacity, , , "False"}}
     				  }

        // Opts.Global.[Node Options] = {{"[ID:1]", {node_lyr+".[ID:1]", , }}, 
        Opts.Global.[Node Options] = {{"[ID]", {node_lyr+".[ID]", , }}, 
            {"X", {node_lyr+".X", , }}, {"Y", {node_lyr+".Y", , }}, 
            {"Original_Node_ID", {node_lyr+".Original_Node_ID", , }}, 
            {"Original", {node_lyr+".Original", , }}, 
            {"CCSTYLE", {node_lyr+".CCSTYLE", , }}, 
     	    {"ON", {node_lyr+".ON", , }}, 
     	    {"OFF", {node_lyr+".OFF", , }}}
        Opts.Global.[Length Unit] = "Miles"
        Opts.Global.[Time Unit] = "Minutes"
        Opts.Output.[Network File] = highway_net

        ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
        if !ret_value then goto quit

	  Return(1)
	
	  quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro

/********************************************************************************************************************************
*
* Recode Null Values
*
* Recodes null values in line layer to 0.  Logs number of cases with null values by facility type to logger before recoding.
*
* Arguments:
*       hwyfile             Highway line layer
*       fields              An array of field strings
*       fromValues          An array of values to recode from, one per fields
*       toValues            An array of values to recode missing to, one per fields
*       factilityTypes      An array of facility types to recode
*
********************************************************************************************************************************/
Macro "Recode Values" (hwyfile, fields, fromValues, toValues, facilityTypes)

    // RunMacro("TCB Init")
	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile)
    LayerInfo = {hwyfile + "|" + link_lyr, link_lyr}
    SetLayer(link_lyr) 
    
    for i = 1 to fields.length do
        
        field = fields[i]
        dir = Left(field, 2)
            
        if(dir = "AB") then do
            dirQuery = "(dir = 0 | dir = 1)"
            end
        else do
            dirQuery = "(dir = 0 | dir = -1)"
        end
        
        for j = 1 to facilityTypes.length do
        
            facilityType = String(facilityTypes[j])

            if(dir = "AB") then do
                ftQuery = "([AB FACTYPE] = "+facilityType+")"
                end
            else do
                ftQuery = "([BA FACTYPE] = "+facilityType+")"
            end
            
            if(fromValues[i] = null) then do
                queryString = dirQuery+" and "+ftQuery+ " and "+field+" = null"
                end
            else do
                queryString = dirQuery+" and "+ftQuery+ " and "+field+" = "+String(fromValues[i])
            end
            
            nSelected = SelectByQuery("SelectFieldFacttype","Several","Select * where "+queryString,)
            
            on notfound do
                AppendToLogFile(0, "Number where "+queryString+ " is 0")
                goto next
            end

            AppendToLogFile(0, "Number where "+queryString+ " is "+String(nSelected))
            if(nSelected > 0) then do
                Opts = null
        	    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr, "SelectFieldFacttype"}
    	        Opts.Global.Fields = {field}                               // the field to fill                   
    	        Opts.Global.Method = "Value"                               // fill with a single value
    	        Opts.Global.Parameter = {toValues[i]}                        // fill with value from array
    	        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	        if !ret_value then goto quit
            end
            
            next:    
            on notfound default
        end
    end
    
   // RunMacro("Close All")
    
    Return(1)
    
    quit:
        Return( RunMacro("TCB Closing", 0, True ) )

EndMacro
/*****************************************************************************************************************************************
* Macro "Skim Summary" (scenarioDirectory,DTA_DBD)
* 
* Summarizes values from DTA skims and puts them in the taz layer for subsequent mapping 
*
*****************************************************************************************************************************************/
Macro "DTA Skim Summary"(scenarioDirectory,DTA_DBD)
    
//    RunMacro("TCB Init")

 	    
    //these are the fields that will be added or replaced in the taz file, and the corresponding TAZs
    newHwyFields = {"7:30DTA_Downtown", "7:30DTA_Kapolei", "7:30DTA_Ewa", "7:30DTA_Airport", "7:30DTA_Waikiki","7:30DTA_Mililani"} 
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
    autoTime = CreateMatrixCurrency(autoMatrix, "\"7:30\" -- \"7:45 AM\"", null, null, )
    
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
    
    ret_value = RunMacro("DTA Summaries",scenarioDirectory,DTA_DBD)
    if !ret_value then goto quit
    	
    RunMacro("Close All")
    Return(1)    
    
    
    
    quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )


EndMacro
/***********************************************************************************
*
* DTA Summaries
*
*
* PB - Ram 05/20/09
* PB- ARF 09/09/09
*
* Script runs travel time and flow summaries on assignment flow tables, using network data.
* Summary file written to scenarioDirectory\DTA\outputs.
*
*Also merges the countdatabase file to the linelayer-must have the countmerge.bin file in
*the scenario root directory
*
************************************************************************************/
Macro "DTA Summaries"(scenarioDirectory, DTA_DBD)

//			RunMacro("TCB Init")
			 //scenarioDirectory = "C:\\currentlaptop\\OMPO_ORTP\\2035baseline_WH092409NCFix"
			//DTA_DBD= scenarioDirectory + "\\DTA\\Outputs\\DTAhighway.dbd"
			highwayDatabase = DTA_DBD			
			linkFlows = scenarioDirectory + "\\DTA\\outputs\\DALinkFlow.bin"
			 
			
			//add in the count,corridor,segment,To_DT and count fields
			{node_lyr,link_lyr} = RunMacro("TCB Add DB Layers", highwayDatabase,,)
	    if link_lyr = null then goto quit
		
		{_Flds,} = GetFields(link_lyr, "All")
	  if !ArrayPosition(_Flds, {"15Min_Count"},) then do                // if group field not exists yet
       NewFlds = {{"Corridor", "Character"},{"Segment", "integer"},{"To_DT", "integer"},{"15Min_Count","integer"},{"TD","integer"}}      // specify new field
       ok = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})   // add new field
			end
			
			//Fill the new fields with the count join file
		Opts = null
     Opts.Input.[Dataview Set] = {{highwayDatabase + "|" + link_lyr, scenarioDirectory + "\\DTA\\countmerge_toScenario.bin", {"ID"}, {"ID"}}, "Oahu Links+countmerge_toScenari"}
     Opts.Global.Fields = {"[Oahu Links].Corridor"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "countmerge_toScenario.Corridor"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit
     	
		 Opts = null
     Opts.Input.[Dataview Set] = {{highwayDatabase + "|" + link_lyr, scenarioDirectory + "\\DTA\\countmerge_toScenario.bin", {"ID"}, {"ID"}}, "Oahu Links+countmerge_toScenari"}
     Opts.Global.Fields = {"[Oahu Links].Segment"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "countmerge_toScenario.Segment"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)

     if !ret_value then goto quit


     Opts = null
     Opts.Input.[Dataview Set] = {{highwayDatabase + "|" + link_lyr, scenarioDirectory + "\\DTA\\countmerge_toScenario.bin", {"ID"}, {"ID"}}, "Oahu Links+countmerge_toScenari"}
     Opts.Global.Fields = {"[Oahu Links].To_DT"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "countmerge_toScenario.To_DT"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)

     if !ret_value then goto quit
     	
     Opts = null
     Opts.Input.[Dataview Set] = {{highwayDatabase + "|" + link_lyr, scenarioDirectory + "\\DTA\\countmerge_toScenario.bin", {"ID"}, {"ID"}}, "Oahu Links+countmerge_toScenari"}
     Opts.Global.Fields = {"[Oahu Links].15Min_Count"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "countmerge_toScenario.[15Min_Count]"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)

     if !ret_value then goto quit
     	
     Opts = null
     Opts.Input.[Dataview Set] = {{highwayDatabase + "|" + link_lyr, scenarioDirectory + "\\DTA\\countmerge_toScenario.bin", {"ID"}, {"ID"}}, "Oahu Links+countmerge_toScenari"}
     Opts.Global.Fields = {"[Oahu Links].TD"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "countmerge_toScenario.TD"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)

     if !ret_value then goto quit
			
			// Join the flow table and network data base and export the file
				llayers = GetDBLayers(highwayDatabase)                                                                                                                                                                                                                                                                                                                                                                                                                                               
				map = RunMacro("G30 new map",highwayDatabase, "False")                                                                                                                                                                                                                                                                                                                                                                                                                               
				SetLayer(llayers[2])                                                                                                                                                                                                                                                                                                                                                                                                                                                                
				DTA_Asn = OpenTable("Asn", "FFB", {linkFlows})                                                                                                                                                                                                                                                                                                                                                                                                                                          
				VIEW1 = JoinViews("VIEW1", llayers[2]+".ID", DTA_Asn + ".ID1",)                                                                                                                                                                                                                                                                                                                                                                                                                         

			// Export the table for counts, travel time
		    outJoinFile = scenarioDirectory + "\\DTA\\outputs\\DTA_Flows.bin"
			  ExportView(VIEW1+"|","FFB", outJoinFile , , )    
						
			
			// Produce the traffic flow summary
			  RunMacro("Flow Summaries", scenarioDirectory, outJoinFile)
			
			// Produce the travel time summary
				RunMacro("TT Summaries", scenarioDirectory, outJoinFile)
			
				RunMacro("Close All")  
			
			quit:
    Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro


Macro "Flow Summaries" (scenarioDirectory, outJoinFile)

			// Calculate facility type, area type, and combined flow
       NewFlds = {{"FACTYPE", "integer"},{"ATYPE", "integer"},{"FFTIME", "real"}}     
      
			DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
      
      // add the new fields
      ret_value = RunMacro("TCB Add View Fields", {DTA_Flows, NewFlds})
      if !ret_value then goto quit
              
      Setview(DTA_Flows)
      Opts = null                                                                                                                                                                                                                                                                                                                                                                                                  
      Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir<>1"}                                                                                                                                                                                                                                                                                                                                                                        
      Opts.Global.Fields = {"FACTYPE", "ATYPE", "FFTIME"}// the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      Opts.Global.Method = "Formula"                                                                                                                                                                                                                                                                                                                                                                
      Opts.Global.Parameter = {"[BA FACTYPE]","[BA ATYPE]","[BA_FFTIME]"}                                                                                                                                                                                                                                                                                                                                    
      ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                       
  	  if !ret_value then goto quit            				
      
			RunMacro("Close All")
			DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
      
      Setview(DTA_Flows)
      Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir<>-1"}                                                                                                                                                                                                                                                                                                                                                                        
      Opts.Global.Fields = {"FACTYPE", "ATYPE", "FFTIME"}// the field to fill                                                                                                                                                                                                                                                                                                                        
      Opts.Global.Method = "Formula"                                                                                                                                                                                                                                                                                                                                                                                               
      Opts.Global.Parameter = {"[AB FACTYPE]", "[AB ATYPE]","[AB_FFTIME]"}                                                                                                                                                                                                                                                                                                                                                                    
      ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                       
  	  if !ret_value then goto quit            				
      
			RunMacro("Close All")
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          

        {Flds,} = GetFields(DTA_Flows, "All")
        
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "AB_Flow")
        		
        		if (pos <> 0) then do
        				
        				// Add the bi-directional flow field
        				NewFlds = {{"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7), "real"}}
				        ret_value = RunMacro("TCB Add View Fields", {DTA_Flows, NewFlds})
				        if !ret_value then goto quit
				        //i = i + 80
        		end
        
        end

				RunMacro("Close All")
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
				
				exportFields = {"FACTYPE","ATYPE"}
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "AB_Flow")
        		
        		if (pos <> 0) then do
        				
        				//Fill the AB-directional flow field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=1"}                                         // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}// the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                  // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i]}                                               // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

        				//Fill the BA-directional flow field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=-1"}                                         // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}// the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                  // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i+1]}                                             // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

        				//Fill the bi-directional flow field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=0"}                                         // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}// the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                  // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i]+ " + " + Flds[i+1]}                            // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

          	    exportFields = InsertArrayElements(exportFields,exportFields.length,{"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)})		
          	    //i = i + 80       
        		end
        
        end

				RunMacro("Close All")
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Flows)

        n = SelectByQuery("DTA_Estimated_Flows", "Several", "Select * where [15Min_Count]<>null",)
        estimatedFlows = scenarioDirectory + "\\DTA\\outputs\\DTA_Estimated_Flows.bin"
				ExportView(DTA_Flows+"|DTA_Estimated_Flows", "FFB", estimatedFlows, exportFields,)

				RunMacro("Close All")
				DTA_Estimated_Flows = OpenTable("DTA_Estimated_Flows", "FFB", {estimatedFlows})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Estimated_Flows)


				shared d_matrix_options
				d_matrix_options.[File Name] = scenarioDirectory + "\\DTA\\outputs\\summaryMatrix.mtx"
				d_matrix_options.Label = "Highway Flows"
				d_matrix_options.Type = "Float"
				d_matrix_options.Tables = exportFields
				d_matrix_options.[Column Major] = "No"
				d_matrix_options.[File Based] = "Yes"
				d_matrix_options.Compression = True
				d_matrix_options.[Add Duplicates] = "Yes"
				d_matrix_options.Compression = "Yes"
				
				new_matrix = CreateMatrixFromView("Highway Flows", "DTA_Estimated_Flows|", "FACTYPE", "ATYPE", exportFields, d_matrix_options)



			  Return(1)
			
			  quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )


EndMacro


Macro "TT Summaries" (scenarioDirectory, outJoinFile)

			// Calculate weighted travel time
			
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          

        {Flds,} = GetFields(DTA_Flows, "All")
        
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "AB_Time")
        		posAVG = Position(Flds[i], "_AB_Time")
        		
        		if (pos <> 0 & posAVG = 0) then do
        				
        				// Add the bi-directional flow field
        				NewFlds = {{"Wgt_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7), "real"},{"Wgt_FFTIME" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7), "real"}}
				        ret_value = RunMacro("TCB Add View Fields", {DTA_Flows, NewFlds})
				        if !ret_value then goto quit
				        //i = i + 63
        		end
        
        end

				RunMacro("Close All")
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
				
				exportFields = {"FACTYPE","ATYPE","FFTIME"}
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "AB_Time")
        		posAVG = Position(Flds[i], "_AB_Time")
        		if (pos <> 0 & posAVG = 0) then do
        				
        				//Fill the AB-directional weighted TT field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=1"}                                           // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Wgt_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                                                 // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i] + " \* " + "AB_Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                            // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

        				//Fill the BA-directional weighted TT field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=-1"}                                           // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Wgt_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                                                  // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                                                                        // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i+1] + " \* " + "BA_Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                           // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

        				//Fill the bi-directional weighted TT field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows", "Selection", "Select * where Dir=0"}                                           // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Wgt_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                                                 // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {Flds[i] + " \* " + "AB_Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7) + "\+" + Flds[i+1] + " \* " + "BA_Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                            // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  

        				//Fill the bi-directional weighted FFTT field
              	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
              	Opts.Input.[Dataview Set] = {outJoinFile,"DTA_Flows"}                                           // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
              	Opts.Global.Fields = {"Wgt_FFTIME" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                                                 // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
              	Opts.Global.Method = "Formula"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
              	Opts.Global.Parameter = {"FFTIME" + " \* " + "Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)}                            // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
              	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
          	    if !ret_value then goto quit  


          	    exportFields = InsertArrayElements(exportFields,exportFields.length,{"Flow" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)})		
          	    exportFields = InsertArrayElements(exportFields,exportFields.length,{"Wgt_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)})		
          	    exportFields = InsertArrayElements(exportFields,exportFields.length,{"Wgt_FFTIME" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7)})		
          	    //i = i + 63       
        		end
        
        end

				RunMacro("Close All")
				DTA_Flows = OpenTable("DTA_Flows", "FFB", {outJoinFile})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Flows)

        estimatedTravelTime = scenarioDirectory + "\\DTA\\outputs\\DTA_Estimated_TT.bin"
				ExportView(DTA_Flows+"|", "FFB", estimatedTravelTime, exportFields,)

        RunMacro("Collapse TT", scenarioDirectory)
			  Return(1)
			
			  quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
			


EndMacro


// Collapse by Facility Type

Macro "Collapse TT" (scenarioDirectory)

//				RunMacro("TCB Init")
				//scenarioDirectory = "C:\\Projects\\ompo\\DTA\\tcad_051309.2005.test_210"
				
				cleanTT = scenarioDirectory + "\\DTA\\outputs\\DTA_Estimated_TT.bin"
				DTA_Flows = OpenTable("DTA_Clean_TT", "FFB", {cleanTT})                                                                                                                                                                                                                                                                                                                                                                                                                                          

        {Flds,} = GetFields(DTA_Flows, "All")
				collapseFields = {{"ATYPE", "sum", }}
        
        for i = 1 to Flds.length do
        		
        		posFlow = Position(Flds[i], "Flow")
        		posTime = Position(Flds[i], "_Time")
        		posFFTIME = Position(Flds[i], "_FFTIME")
        		
        		if (posFlow<>0 or posTime<>0 or posFFTIME<>0) then do
        		      tempFields = {Flds[i]}
        		      tempFields = InsertArrayElements(tempFields,2,{"sum"})
        		      tempFields = InsertArrayElements(tempFields,3,{})
       	    			collapseFields = InsertArrayElements(collapseFields,collapseFields.length+1,{tempFields})		
       	    end
        
        end
				collapsedTT = scenarioDirectory + "\\DTA\\outputs\\DTA_Collapsed_TT.bin"
				rslt = AggregateTable("DTA_Collapsed_TT",DTA_Flows+ "|", "FFB", collapsedTT, "FACTYPE", collapseFields, null)
				
				RunMacro("Close All")
				DTA_Collapsed_TT = OpenTable("DTA_Collapsed_TT", "FFB", {collapsedTT})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Collapsed_TT)

        // add the new facility type field which will combine the 15 facility types into 5 categories
				NewFlds = {{"New_FACTYPE", "integer"}}
	      ret_value = RunMacro("TCB Add View Fields", {DTA_Collapsed_TT, NewFlds})
	      if !ret_value then goto quit
	      
				//Fill the Freeways with 1
      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      	Opts.Input.[Dataview Set] = {collapsedTT,"DTA_Collapsed_TT", "Selection", "Select * where (FACTYPE=1) | (FACTYPE=13)"}                // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
      	Opts.Global.Fields = {"New_FACTYPE"}                                                                                               // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      	Opts.Global.Method = "Value"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
      	Opts.Global.Parameter = {1}                                                                                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
  	    if !ret_value then goto quit  
	      
				//Fill the Expressways with 2
      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      	Opts.Input.[Dataview Set] = {collapsedTT,"DTA_Collapsed_TT", "Selection", "Select * where (FACTYPE=2)"}                // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
      	Opts.Global.Fields = {"New_FACTYPE"}                                                                                               // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      	Opts.Global.Method = "Value"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
      	Opts.Global.Parameter = {2}                                                                                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
  	    if !ret_value then goto quit  

				//Fill the Arterials with 3
      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      	Opts.Input.[Dataview Set] = {collapsedTT,"DTA_Collapsed_TT", "Selection", "Select * where (FACTYPE=3 | FACTYPE=4 | FACTYPE=5)"}    // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
      	Opts.Global.Fields = {"New_FACTYPE"}                                                                                               // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      	Opts.Global.Method = "Value"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
      	Opts.Global.Parameter = {3}                                                                                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
  	    if !ret_value then goto quit  

				//Fill the Collectors with 4
      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      	Opts.Input.[Dataview Set] = {collapsedTT,"DTA_Collapsed_TT", "Selection", "Select * where (FACTYPE=6 | FACTYPE=7)"}                 // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
      	Opts.Global.Fields = {"New_FACTYPE"}                                                                                               // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      	Opts.Global.Method = "Value"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
      	Opts.Global.Parameter = {4}                                                                                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
  	    if !ret_value then goto quit  
	      
				//Fill the Local Streets with 5
      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
      	Opts.Input.[Dataview Set] = {collapsedTT,"DTA_Collapsed_TT", "Selection", "Select * where (FACTYPE=8)"}                              // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
      	Opts.Global.Fields = {"New_FACTYPE"}                                                                                               // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
      	Opts.Global.Method = "Value"                                                                                                       // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
      	Opts.Global.Parameter = {5}                                                                                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
  	    if !ret_value then goto quit  

				compressedTT = scenarioDirectory + "\\DTA\\outputs\\DTA_Compressed_TT.bin"
				rslt = AggregateTable("DTA_Compressed_TT",DTA_Collapsed_TT+ "|", "FFB", compressedTT, "New_FACTYPE", collapseFields, null)


				RunMacro("Close All")
				DTA_Compressed_TT = OpenTable("DTA_Compressed_TT", "FFB", {compressedTT})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Compressed_TT)
        {Flds,} = GetFields(DTA_Compressed_TT, "All")
        
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "Flow")
        		
        		if (pos <> 0) then do
        				
        				// Add the bi-directional flow field
        				NewFlds = {{"C_Fact" + SubString(Flds[i],pos+4,StringLength(Flds[i])-4), "real"}}
				        ret_value = RunMacro("TCB Add View Fields", {DTA_Compressed_TT, NewFlds})
				        if !ret_value then goto quit

				        //i = i + 63
        		end
        
        end

				RunMacro("Close All")
				DTA_Compressed_TT = OpenTable("DTA_Compressed_TT", "FFB", {compressedTT})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(DTA_Compressed_TT)
        {Flds,} = GetFields(DTA_Compressed_TT, "All")

        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "Flow")
        		
        		if (pos <> 0) then do
        				
								//Fill the Local Streets with 5
				      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
				      	Opts.Input.[Dataview Set] = {compressedTT,"DTA_Compressed_TT"}                              // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
				      	Opts.Global.Fields = {"C_Fact" + SubString(Flds[i],pos+4,StringLength(Flds[i])-4)}       // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
				      	Opts.Global.Method = "Formula"                                                           // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
				      	Opts.Global.Parameter = {"Wgt_Time"+SubString(Flds[i],pos+4,StringLength(Flds[i])-4)+"\/"+"Wgt_FFTIME"+SubString(Flds[i],pos+4,StringLength(Flds[i])-4)}                                                              // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
				      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
				  	    if !ret_value then goto quit  

				        //i = i + 63
        		end
        
        end


			  Return(1)
			
			  quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
				


EndMacro               

Macro "Corridor TT" (scenarioDirectory,DTA_DBD)

//			RunMacro("TCB Init")
			
			
			
			highwayDatabase = DTA_DBD		
			linkFlows = scenarioDirectory + "\\DTA\\outputs\\DALinkFlow.bin"
			
			// Join the flow table and network data base and export the file
				llayers = GetDBLayers(highwayDatabase)                                                                                                                                                                                                                                                                                                                                                                                                                                               
				map = RunMacro("G30 new map",highwayDatabase, "False")                                                                                                                                                                                                                                                                                                                                                                                                                               
				SetLayer(llayers[2])                                                                                                                                                                                                                                                                                                                                                                                                                                                                
				DTA_Asn = OpenTable("Asn", "FFB", {linkFlows})                                                                                                                                                                                                                                                                                                                                                                                                                                          
				VIEW1 = JoinViews("VIEW1", llayers[2]+".ID", DTA_Asn + ".ID1",) 
				Setview(VIEW1)                                                                                                                                                                                                                                                                                                                                                                                                                        

			// Export the table for counts, travel time
        n = SelectByQuery("CorridorTT", "Several", "Select * where [Corridor]<>null",)
        Corridor_TT = scenarioDirectory + "\\DTA\\outputs\\Corridor_TT.bin"
				ExportView(VIEW1+"|CorridorTT", "FFB", Corridor_TT,,)
				
				
       	RunMacro("Close All")
				CorridorTT = OpenTable("Corridor_TT", "FFB", {Corridor_TT})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(CorridorTT)
        {Flds,} = GetFields(CorridorTT, "All")
       	
        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "AB_Time")
        		posAVG = Position(Flds[i], "_AB_Time")
        		
        		if (pos <> 0 & posAVG = 0) then do
        				
        				// Add the bi-directional flow field
        				NewFlds = {{"Corridor_Time" + SubString(Flds[i],pos+7,StringLength(Flds[i])-7), "real"}}
				        ret_value = RunMacro("TCB Add View Fields", {CorridorTT, NewFlds})
				        if !ret_value then goto quit
				        //i = i + 63
        		end
        
        end
       	
				RunMacro("Close All")
				CorridorTT = OpenTable("CorridorTT", "FFB", {Corridor_TT})                                                                                                                                                                                                                                                                                                                                                                                                                                          
        Setview(CorridorTT)
        {Flds,} = GetFields(CorridorTT, "All")

        for i = 1 to Flds.length do
        		
        		pos = Position(Flds[i], "Corridor_Time")
        		
        		if (pos <> 0) then do
        				
								//Fill the Local Streets with 5
				      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
				      	Opts.Input.[Dataview Set] = {Corridor_TT,"CorridorTT", "Selection", "Select * where ((To_DT=null)&(Dir=1))|(To_DT=1)"}                    // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
				      	Opts.Global.Fields = {"Corridor_Time" + SubString(Flds[i],pos+13,StringLength(Flds[i])-13)}                                   // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
				      	Opts.Global.Method = "Formula"                                                                                                // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
				      	Opts.Global.Parameter = {"AB_Time"+SubString(Flds[i],pos+13,StringLength(Flds[i])-13)}                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
				      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
				  	    if !ret_value then goto quit  

								//Fill the Local Streets with 5
				      	Opts = null                                                                                                                                                                                                                                                                                                                                                                                                                                                                   
				      	Opts.Input.[Dataview Set] = {Corridor_TT,"CorridorTT", "Selection", "Select * where ((To_DT=null)&(Dir=-1))|(To_DT=-1)"}                    // fill layer is a table                                                                                                                                                                                                                                                                                                                                                                        
				      	Opts.Global.Fields = {"Corridor_Time" + SubString(Flds[i],pos+13,StringLength(Flds[i])-13)}                                   // the field to fill                                                                                                                                                                                                                                                                                                                                                                                         
				      	Opts.Global.Method = "Formula"                                                                                                // fill by formula                                                                                                                                                                                                                                                                                                                                                                                            
				      	Opts.Global.Parameter = {"BA_Time"+SubString(Flds[i],pos+13,StringLength(Flds[i])-13)}                                        // the value to fill with is the taz layer District                                                                                                                                                                                                                                                                                                                                                      
				      	ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)                                                                                                                                                                                                                                                                                                                                                                                                        
				  	    if !ret_value then goto quit  

				        //i = i + 63
        		end
        
        end


			  Return(1)
			
			  quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro

//*************************************************************
//
// A utility macro that will close all open map windows
//
//*************************************************************
Macro "Close All"
    // RunMacro("TCB Init")
    maps = GetMapNames()
    
    if(maps = null) then goto view
    for i = 1 to maps.length do
	    CloseMap(maps[i])
    end
    
    view:
    views = GetViewNames()
    if(views = null) then goto quit
    for i = 1 to views.length do
        if( !Left(views[i],2)="c:") then CloseView(views[i])
    end

    return(RunMacro("G30 File Close All"))

    quit:
    Return(1)
EndMacro