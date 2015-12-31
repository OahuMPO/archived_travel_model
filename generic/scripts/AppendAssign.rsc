/* AppendAssign.rsc
*  
*  Append highway assignment results to line layer for the 
*  following scenarios:
*       EA, AM, MD, PM, EV
*/
Macro "AppendAssign" (scenarioDirectory, iteration)
//    RunMacro("TCB Init")

   iteration = IntToString(iteration)
   //iteration = IntToString(3)
    //scenarioDirectory = "C:\\currentlaptop\\OMPO_ORTP\\heathertest"
    //input files
    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"

    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    node_lyr=AddLayer(cc,"Oahu Nodes",hwyfile,"Oahu Nodes")
    link_lyr=AddLayer(cc,"Oahu Links",hwyfile,"Oahu Links")
    
    periods = {"EA", "AM", "MD", "PM", "EV" }
    	
  	for period = 1 to periods.length do
	  
		// Kyle: modifying this part to also add/update a time field
    	//add the fields
        NewFlds = {
            {"AB_FLOW_"+periods[period], "real"},
            {"BA_FLOW_"+periods[period], "real"},
            {"TOT_FLOW_"+periods[period], "real"},
            {"AB_SPD_"+periods[period], "real"},
            {"BA_SPD_"+periods[period], "real"},
            {"AB_TIME_"+periods[period], "real"},
            {"BA_TIME_"+periods[period], "real"},
            {"AB_VOC_"+periods[period], "real"},
            {"BA_VOC_"+periods[period], "real"}}
        // add the new fields to the link layer
        ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
        if !ret_value then goto quit
 
        flowTable = scenarioDirectory+"\\outputs\\"+periods[period]+"Flow"+iteration+".bin"
    
    	//fill fields with AM2 Assignment Results
     	Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, flowTable, {"ID"}, {"ID1"}}, "joinedvw"+periods[period]}	
    	Opts.Global.Fields = {"AB_FLOW_"+periods[period],
    	                    "BA_FLOW_"+periods[period],
    	                    "TOT_FLOW_"+periods[period],
    	                    "AB_SPD_"+periods[period],
    	                    "BA_SPD_"+periods[period],
    	                    "AB_TIME_"+periods[period],
    	                    "BA_TIME_"+periods[period],
    	                    "AB_VOC_"+periods[period],
    	                    "BA_VOC_"+periods[period]} // the fields to fill        
    	Opts.Global.Method = "Formula"                                         // the fill method          
    	Opts.Global.Parameter = {"AB_Flow","BA_Flow","TOT_Flow","AB_Speed","BA_Speed","AB_Time", "BA_Time", "AB_VOC", "BA_VOC"}                               
    	ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	if !ret_value then goto quit
	end

    //add the fields
        NewFlds = {
            {"AB_FLOW_DAILY", "real"},
            {"BA_FLOW_DAILY", "real"},
            {"TOT_FLOW_DAILY", "real"}}
        // add the new fields to the link layer
        ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
        if !ret_value then goto quit
   
//fill fields with total Assignment Results
 Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}	
    Opts.Global.Fields = {"AB_FLOW_DAILY","BA_FLOW_DAILY"} // the fields to fill        
    Opts.Global.Method = "Formula"                                         // the fill method          
    Opts.Global.Parameter = {"AB_FLOW_EA + AB_FLOW_AM + AB_FLOW_MD + AB_FLOW_PM + AB_FLOW_EV","BA_FLOW_EA + BA_FLOW_AM + BA_FLOW_MD + BA_FLOW_PM + BA_FLOW_EV"}                         // the column in the conicalsfile file
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit
    	
// change null to zero 
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"AB_FLOW_DAILY"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "If (AB_FLOW_DAILY>0) then AB_FLOW_DAILY else 0"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

     Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
     Opts.Global.Fields = {"BA_FLOW_DAILY"}
     Opts.Global.Method = "Formula"
     Opts.Global.Parameter = "If (BA_FLOW_DAILY>0) then BA_FLOW_DAILY else 0"

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     if !ret_value then goto quit

   
    //fill fields with total Assignment Results
    
    
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}	
    Opts.Global.Fields = {"TOT_FLOW_DAILY"} // the fields to fill        
    Opts.Global.Method = "Formula"                                         // the fill method          
    Opts.Global.Parameter = {"AB_FLOW_DAILY + BA_FLOW_DAILY"}
                                                           // the column in the conicalsfile file
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro