/*****************************************************************************************************************************************
* Macro "Highway Assignment" (scenarioDirectory)
* 
* 
*    (1) Highway links used in the assignment:								
* 	    Non-Toll Skims: 
*           SOV Skims:                  limit=0,1,6 
*           HOV2 Skims:                 limit=0,1,2,6
*           HOV3+ Skims:                limit=0,1,2,3,6				
* 	    Toll Skims: 
*           SOV NT:                     limit=0,1,6 
*           HOV2 NT:                    limit=0,1,2,6,11 
*           HOV3+ NT:                   limit=0,1,2,3,6,11,12		
* 		    SOV Toll:                   limit=0,1,6,10,11,12 
*           HOV2 Toll:                  limit=0,1,2,6,10,11,12 			
* 		    HOV3+ Toll:                 limit=0,1,2,3,6,10,11,12							
* 
* 
* 
* 
* 
/****************************************************************************************************************************************/
Macro "testassignment"
    scenarioDirectory = "C:\\projects\\Honolulu\\Version6\\2012_6_calibration"
    nzones = 764
    iteration = 1
    RunMacro("Highway Assignment",scenarioDirectory, nzones, iteration)
EndMacro

Macro "Highway Assignment" (scenarioDirectory, nzones, iteration)
    RunMacro("TCB Init")
    
      periods = {"EA","AM","MD","PM","EV"}
 			
 			for i = 1 to periods.length do
 
 					ODMatrix = scenarioDirectory+"\\outputs\\auto_"+periods[i]+".mtx"
    	  	period = periods[i]
    
    			ret_value = RunMacro("Perform Assignment",scenarioDirectory, ODMatrix, period, nzones, iteration)
    			if !ret_value then goto quit
			end
		
    Return(1)

    quit:
    ShowMessage("Error running assignment for period "+period+" iteration "+String(iteration))
    Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro 
/*****************************************************************************************************************************************
* Macro "Final Highway Assignment" (scenarioDirectory)
* 
* Performs an AM 4-Hour and PM 4-Hour highway assignment.
* 
* NOT CURRENTLY USED IN TOUR BASED MODEL
* 
/****************************************************************************************************************************************/
Macro "Final Highway Assignment" (scenarioDirectory, nzones)
    
    iteration = 1
    //assign 4-hour AM peak
    ODMatrix = scenarioDirectory+"\\outputs\\hwyAM4Hour.mtx"
    period = "AM4Hour"
    
    ret_value = RunMacro("Perform Assignment",scenarioDirectory, ODMatrix, period, nzones, iteration)
    if !ret_value then goto quit

    //assign 4-hour PM peak
    ODMatrix = scenarioDirectory+"\\outputs\\hwyPM4Hour.mtx"
    period = "PM4Hour"

    ret_value = RunMacro("Perform Assignment",scenarioDirectory, ODMatrix, period, nzones, iteration)
    if !ret_value then goto quit

    Return(1)

    quit:
    ShowMessage("Error running assignment for period "+period+" iteration "+String(iteration))
    Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro 
 
 
Macro "Perform Assignment" (scenarioDirectory,ODMatrix, period, nzones, iteration) 
   
    //input files
    highway_db=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    highway_net=scenarioDirectory+"\\outputs\\hwy"+period+".net"

    tpen={scenarioDirectory+"\\inputs\\turns\\am turn penalties.bin",
    	  scenarioDirectory+"\\inputs\\turns\\md turn penalties.bin",
    	  scenarioDirectory+"\\inputs\\turns\\pm turn penalties.bin",
    	  scenarioDirectory+"\\inputs\\turns\\link type turn penalties.bin"}
    	  
    //period
    outtable = scenarioDirectory+"\\outputs\\"+period+"Flow"+String(iteration)+".bin"
    if (period = "EA") then do
        turns = tpen[1]
        ab_limit = "[AB LIMITM]"
        ba_limit = "[BA LIMITM]"
        ab_capacity = "AB_CAP_EA3HR"
        ba_capacity = "BA_CAP_EA3HR"
        end
    else if (period = "AM") then do
        
        turns = tpen[1]
        ab_limit = "[AB LIMITA]"
        ba_limit = "[BA LIMITA]"
        ab_capacity = "AB_CAP_AM3HR"
        ba_capacity = "BA_CAP_AM3HR"
        end
    else if (period = "MD") then do

        turns = tpen[2]
        ab_limit = "[AB LIMITM]"
        ba_limit = "[BA LIMITM]"
        ab_capacity = "AB_CAP_MD6HR"
        ba_capacity = "BA_CAP_MD6HR"
        end
    else if (period = "PM") then do

        turns = tpen[3]
        ab_limit = "[AB LIMITP]"
        ba_limit = "[BA LIMITP]"
        ab_capacity = "AB_CAP_PM4HR"
        ba_capacity = "BA_CAP_PM4HR"
        end
    else if (period = "EV") then do

        turns = tpen[3]
        ab_limit = "[AB LIMITM]"
        ba_limit = "[BA LIMITM]"
        ab_capacity = "AB_CAP_EV8HR"
        ba_capacity = "BA_CAP_EV8HR"
        end
    else do
        ShowMessage("Error in Highway Assignment: Period "+String(period)+" not recognized")
        goto quit 
    end


    if(iteration = 1) then do

        RunMacro("Recode Values", highway_db, {ab_capacity,ba_capacity},
                                                   {        null,        null},
                                                   {          99,          99},
                {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})

        RunMacro("Recode Values", highway_db, {ab_capacity,ba_capacity},
                                                   {         0,            0},
                                                   {        99,           99},
                {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})

        RunMacro("Recode Values", highway_db, {"AB_FFTIME", "BA_FFTIME", "AB_ALPHA","BA_ALPHA"},
                                                   {     null,     null,      null,     null},
                                                   {          0,           0,         99,        99},
        {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})
      end
     
     //add the layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", highway_db,,)  
     SetLayer(link_lyr) //Line Layer  
  
    if(iteration = 1) then do
        NewFlds = {{"COST_DANT", "real"},
                   {"COST_S2NT", "real"},
                   {"COST_S3NT", "real"},
                   {"COST_DATL", "real"},
                   {"COST_S2TL", "real"},
                   {"COST_S3TL", "real"}}     
    
        // add the new fields to the link layer
         ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
        if !ret_value then goto quit

        costpermile=0.12
        Opts = null
        Opts.Input.[Dataview Set] = {highway_db+"|"+link_lyr, link_lyr}	
        Opts.Global.Fields = {"COST_DANT",
                              "COST_S2NT",
                              "COST_S3NT",
                              "COST_DATL",
                              "COST_S2TL",
                              "COST_S3TL"}
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {"Length * "+String(costpermile),
                                 "Length * "+String(costpermile),   
                                 "Length * "+String(costpermile),
                                 "Length * "+String(costpermile), // delete this toll cost for a test; take half of hte toll cost in path-building since VOT in assignment is low
                                 "Length * "+String(costpermile),
                                 "Length * "+String(costpermile)}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then goto quit
    
    end

    m = OpenMatrix(ODMatrix,)
    matrixCores = GetMatrixCoreNames(GetMatrix())
    coreName = matrixCores[1]
        
    LayerInfo = {highway_db + "|" + link_lyr, link_lyr}
    validlink = "(([AB FACTYPE]  between 1 and 13 ) or ([BA FACTYPE] between 1 and 13))"
    
    exists = GetFileInfo(highway_net)
    if(exists = null or iteration = 1) then do
        //*************************************************** Create Highway Network ***************************************************

        Opts = null
        Opts.Input.[Link Set] = {highway_db+"|"+link_lyr, link_lyr}
        Opts.Input.[Toll Set] = {highway_db+"|"+link_lyr, link_lyr}
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
     				  {"*_LIMITA", {link_lyr+".[AB LIMITA]", link_lyr+".[BA LIMITA]", , , "False"}}, 
     				  {"*_LIMITM", {link_lyr+".[AB LIMITM]", link_lyr+".[BA LIMITM]", , , "False"}}, 
     				  {"*_LIMITP", {link_lyr+".[AB LIMITP]", link_lyr+".[BA LIMITP]", , , "False"}}, 
     				  {"*_FFTIME", {link_lyr+".AB_FFTIME", link_lyr+".BA_FFTIME", , , "False"}}, 
     				  {"*_CAPACITY", {link_lyr+"."+ab_capacity, link_lyr+"."+ba_capacity, , , "False"}},
     				  {"*_ALPHA", {link_lyr+".[AB_ALPHA]", link_lyr+".[BA_ALPHA]", , , "False"}},
     				  {"*_COST_DANT", {link_lyr+".COST_DANT", link_lyr+".COST_DANT", , , "False"}},
     				  {"*_COST_S2NT", {link_lyr+".COST_S2NT", link_lyr+".COST_S2NT", , , "False"}},
     				  {"*_COST_S3NT", {link_lyr+".COST_S3NT", link_lyr+".COST_S3NT", , , "False"}},
     				  {"*_COST_DATL", {link_lyr+".COST_DATL", link_lyr+".COST_DATL", , , "False"}},
     				  {"*_COST_S2TL", {link_lyr+".COST_S2TL", link_lyr+".COST_S2TL", , , "False"}},
     				  {"*_COST_S3TL", {link_lyr+".COST_S3TL", link_lyr+".COST_S3TL", , , "False"}}
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
     end
    
    // Set turn penalties for the time period
     // First enable all links, and set the line layer and network properties
    Opts = null
    Opts.Input.Database = highway_db
    Opts.Input.Network = highway_net
    Opts.Input.[Centroids Set] = {highway_db+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+String(nzones)}
    Opts.Input.[Toll Set] = {highway_db+"|"+link_lyr, link_lyr}
    
    // Kyle: Don't need to update the link attributes
    // Opts.Input.[Update Link Set] = {highway_db+"|"+link_lyr, link_lyr}
    // Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
    // Opts.Global.[Update Link Options].Type = "Enable"
    // Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    // Opts.Global.[Update Network Fields].Formulas = {}
    
    // Kyle: Corrected turn penalty options
    //Opts.Input.[Link Type Turn Penalties] = tpen[4]
    // Opts.Input.[Spc Turn Pen Table] = {turns}
    Opts.Global.[Global Turn Penalties] = {0, 0, 0, 0}
    Opts.Input.[Def Turn Pen Table] = {tpen[4]}
    Opts.Input.[Spc Turn Pen Field] = {turns, "PENALTY"}
    Opts.Global.[Spc Turn Pen Method] = 3
    Opts.Local.[Spc Turn Pen Fields] = {"PENALTY"}
    Opts.Local.[Spc Turn Pen Default Field] = "PENALTY"
    
    Opts.Flag.[Use Link Types] = "True"
    ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    if !ret_value then do
        ShowMessage("Highway network settings failed.")
        ShowMessage(1)    
        goto quit
    end
    // Link selection for assignment:
    //
    // Limit field:
    //  0 = All vehicles can use
    //  1 = All vehicles can use
    //  2 = No SOV or trucks  (HOV 2+ Lanes)
    //  3 = No SOV, HOV2, or trucks (HOV 3+ Lanes)
    //  6 = No Trucks
    // 10 = toll facility - SOV, HOV2, and HOV3+ pay
    // 11 = HOT facility - SOV pays, HOV2 and HOV3+ free
    // 12 = HOT facility - SOV and HOV2 pay, HOV3+ free
    //
    // FACTYPE field: 14 = transit-only links
    //
    // The selection will result in a set of links that will be disabled in the Highway Network Setting step
    //

    // 6 sets of links: SOV-NT, HOV-NT, HOV3+ NT, SOV-TOLL, HOV2-TOLL, HOV3+ TOLL
    excl_qry={    
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=6 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=6)" + ")",
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=2 | "+ab_limit+"=6 | "+ab_limit+"=11 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=2 | "+ba_limit+"=6 | "+ba_limit+"=11)" + ")",
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=2 | "+ab_limit+"=3 | "+ab_limit+"=6 | "+ab_limit+"=11 | "+ab_limit+"=12| "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=2 | "+ba_limit+"=3 | "+ba_limit+"=6 | "+ba_limit+"=11 | "+ba_limit+"=12)" + ")",
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=6 | "+ab_limit+"=10 | "+ab_limit+"=11 | "+ab_limit+"=12 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=6 | "+ba_limit+"=10 | "+ba_limit+"=11 | "+ba_limit+"=12)" + ")",
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=2 | "+ab_limit+"=6 | "+ab_limit+"=10 | "+ab_limit+"=11 | "+ab_limit+"=12 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=2 | "+ba_limit+"=6 | "+ba_limit+"=10 | "+ba_limit+"=11 | "+ba_limit+"=12)" + ")",
    	          "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+ab_limit+"=1 | "+ab_limit+"=2 | "+ab_limit+"=3 | "+ab_limit+"=6 | "+ab_limit+"=10 | "+ab_limit+"=11 | "+ab_limit+"=12 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+ba_limit+"=2 | "+ba_limit+"=3 | "+ba_limit+"=6 | "+ba_limit+"=10 | "+ba_limit+"=11 | "+ba_limit+"=12)" + ")"
    	     }
    
	Dim Excl_set[8]     
	
	Excl_set[1] = LayerInfo + {"SOV -FREE",excl_qry[1]}     //SOV   - FREE
	Excl_set[2] = LayerInfo + {"HOV2-FREE",excl_qry[2]}     //HOV2  - FREE
	Excl_set[3] = LayerInfo + {"HOV3-FREE",excl_qry[3]}     //HOV3+ - FREE
	Excl_set[4] = LayerInfo + {"SOV -PAY",excl_qry[4]}      //SOV   - PAY
	Excl_set[5] = LayerInfo + {"HOV2-PAY",excl_qry[5]}      //HOV2  - PAY
	Excl_set[6] = LayerInfo + {"HOV3-PAY",excl_qry[6]}      //HOV3+ - PAY
	Excl_set[7] = LayerInfo + {"TRCK-FREE",excl_qry[1]}     //TRCK  - FREE
	Excl_set[8] = LayerInfo + {"TRCK-PAY",excl_qry[4]}      //TRCK  - PAY
	
    Opts = null
    Opts.Input.Database = highway_db
    Opts.Input.Network = highway_net
    Opts.Input.[OD Matrix Currency] = {ODMatrix, coreName, , }
    Opts.Input.[Exclusion Link Sets] = Excl_set
    
    // Class information
    Opts.Field.[Vehicle Classes] = {1,2,3,4,5,6,7,8}
    Opts.Global.[Number of Classes] = 8
    Opts.Global.[Class PCEs] = {1,1,1,1,1,1,1.5,1.5}
    Opts.Global.[Class VOIs] = {0.25,0.25,0.25,0.25,0.25,0.25,0.25,0.25}
    Opts.Field.[Fixed Toll Fields] = {"*_COST_DANT","*_COST_S2NT","*_COST_S3NT","*_COST_DATL","*_COST_S2TL","*_COST_S3TL","*_COST_DANT","*_COST_DATL"}
    Opts.Field.[Turn Attributes] = {"PENALTY", "PENALTY", "PENALTY", "PENALTY", "PENALTY", "PENALTY", "PENALTY", "PENALTY"}
    
    Opts.Field.[VDF Fld Names] = {"*_FFTIME", "*_CAPACITY", "*_ALPHA",  "None"}  // JL Added for Conical Function
    Opts.Field.[MSA Flow] = "_MSAFlow" + period
    Opts.Field.[MSA Cost] = "_MSACost" + period
    Opts.Global.[MSA Iteration] = iteration
    Opts.Global.[Load Method] = "NCFW" 
    // Opts.Global.[Load Method] = "BFW"
    if (Opts.Global.[Load Method] = "NCFW") then Opts.Global.[N Conjugate] = 2
    if (Opts.Global.[Load Method] = "NCFW") then do
        Opts.Global.[N Conjugate] = 2
        Opts.Global.[T2 Iterations] = 100
    end
    Opts.Global.[Loading Multiplier] = 1
    Opts.Global.Convergence = 0.0001
    Opts.Global.Iterations = 300
    Opts.Global.[Cost Function File] = "emme2.vdf"
    Opts.Global.[VDF Defaults] = {, , 4, }
    // Opts.Flag.[Do Share Report] = 1
    Opts.Output.[Flow Table] = outtable
    // Select link options
    // Opts.Global.[Critical Query File] = scenarioDirectory + "\\outputs\\8287.qry"
    // Opts.Global.[Critical Set Names] = { "Select" }
    // Opts.Flag.[Do Critical] = 1
    // Opts.Output.[Critical Matrix].[File Name] = scenarioDirectory + "\\outputs\\select.mtx"
    // Opts.Output.[Critical Matrix].Label = "Critical Matrix"
    
    ret_value = RunMacro("TCB Run Procedure", 1, "MMA", Opts)
    
    if !ret_value then do
        ShowMessage("Highway assignment failed.")
        // ShowMessage(1)
        goto quit
    end

    RunMacro("Close All")
    
    Return(1)
	
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
