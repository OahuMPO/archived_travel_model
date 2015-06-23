/*******************************************************************************
* 		
* Set Up for Transit Skim Process:	
* 1. Mode Table and Mode Transfer Table are set up for the transit skim process;
* 	
* 2. Transit skims are only set up for local(incl. limited) bus and express bus 
*    by walk, PNR and KNR access; skims for rail mode haven't set up yet.
* 
********************************************************************************/

Macro "Transit Network and Skim" (scenarioDirectory, hwyfile, rtsfile, rstopfile, modefile, xferfile, nzones, iteration)
    
    ret_value = RunMacro("Transit Time Update", scenarioDirectory, hwyfile, iteration)
    if !ret_value then goto quit
 
    skim:
    ret_value = RunMacro("Transit Skim", scenarioDirectory, hwyfile, rtsfile, rstopfile, modefile, xferfile, nzones)  
    if !ret_value then goto quit

    ret_value = RunMacro("Close All")
    if !ret_value then goto quit
    
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

 
/**********************************************************************************************************************************
*  Transit Time Update
*  Function of this macro:
*    1. Update highway congested time from previous highway assignment procedure, and
*    2. Use the new highway congested time to updated transit travel time including all the highway links.
*
************************************************************************************************************************************/
Macro "Transit Time Update" (scenarioDirectory, hwyfile, iteration)

	aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    node_lyr=AddLayer(cc,"Oahu Nodes",hwyfile,"Oahu Nodes")
    link_lyr=AddLayer(cc,"Oahu Links",hwyfile,"Oahu Links")

    // if iteration 1, use first iteration times in line layer
    if(iteration <= 1) then do
	       
        Opts = null
        Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr,link_lyr}
        Opts.Global.Fields = {"AB_EATRNTIME","BA_EATRNTIME",
        	                    "AB_AMTRNTIME","BA_AMTRNTIME",
        	                    "AB_MDTRNTIME","BA_MDTRNTIME",
        	                    "AB_PMTRNTIME","BA_PMTRNTIME",
        	                    "AB_EVTRNTIME","BA_EVTRNTIME"}
        	                    
        	                    
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {"AB_EATIME * AB_OPTRNFAC", "BA_EATIME * BA_OPTRNFAC",
        	                       "AB_AMTIME * AB_PKTRNFAC", "BA_AMTIME * BA_PKTRNFAC",
        	                       "AB_MDTIME * AB_OPTRNFAC", "BA_MDTIME * BA_OPTRNFAC",
        	                       "AB_PMTIME * AB_PKTRNFAC", "BA_PMTIME * BA_PKTRNFAC",
        	                       "AB_EVTIME * AB_OPTRNFAC", "BA_EVTIME * BA_OPTRNFAC"}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then goto quit
        
          
        end
    // if not iteration 1, use msa times in flow table
    else do
      
	    eaflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\EAFlow"+String(iteration-1)+".bin"
	    amflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\AMFlow"+String(iteration-1)+".bin"
	    mdflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\MDFlow"+String(iteration-1)+".bin"
	    pmflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\PMFlow"+String(iteration-1)+".bin"
      evflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\EVFlow"+String(iteration-1)+".bin"
  	    

      // Early AM (Use Midday for now)
      Opts = null
      Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,eaflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
      Opts.Global.Fields = {"AB_EATRNTIME","BA_EATRNTIME" }
      Opts.Global.Method = "Formula"
      Opts.Global.Parameter = {"AB_MSA_TIME * AB_OPTRNFAC","BA_MSA_TIME * BA_OPTRNFAC"}
      ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
      if !ret_value then goto quit

      // AM peak
      Opts = null
      Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,amflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
      Opts.Global.Fields = {"AB_AMTRNTIME","BA_AMTRNTIME"}
      Opts.Global.Method = "Formula"
      Opts.Global.Parameter = {"AB_MSA_TIME * AB_PKTRNFAC","BA_MSA_TIME * BA_PKTRNFAC"}
      ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
      if !ret_value then goto quit
    
      // Midday
      Opts = null
      Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,mdflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
      Opts.Global.Fields = {"AB_MDTRNTIME","BA_MDTRNTIME" }
      Opts.Global.Method = "Formula"
      Opts.Global.Parameter = {"AB_MSA_TIME * AB_OPTRNFAC","BA_MSA_TIME * BA_OPTRNFAC"}
      ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
      if !ret_value then goto quit
      	
      // PM peak
      Opts = null
      Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,pmflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
      Opts.Global.Fields = {"AB_PMTRNTIME","BA_PMTRNTIME"}
      Opts.Global.Method = "Formula"
      Opts.Global.Parameter = {"AB_MSA_TIME * AB_PKTRNFAC","BA_MSA_TIME * BA_PKTRNFAC"}
      ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
      if !ret_value then goto quit
    
      // Evening
      Opts = null
      Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,evflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
      Opts.Global.Fields = {"AB_EVTRNTIME","BA_EVTRNTIME" }
      Opts.Global.Method = "Formula"
      Opts.Global.Parameter = {"AB_MSA_TIME * AB_OPTRNFAC","BA_MSA_TIME * BA_OPTRNFAC"}
      ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
      if !ret_value then goto quit
        
    end 
    
    //Code transit-only links (Facility-type = 14) with time based on Tran_Only_Spd field
    AB_FACTYPE = "[AB FACTYPE]"
    SetLayer(link_lyr) //Line Layer
    n1 = SelectByQuery("TranOnly", "Several", "Select * where" +AB_FACTYPE+"=14",)
    
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr,link_lyr,"TranOnly"}
    Opts.Global.Fields = {"AB_EATRNTIME","BA_EATRNTIME",
    	                    "AB_AMTRNTIME","BA_AMTRNTIME",
   	                      "AB_MDTRNTIME","BA_MDTRNTIME",
    	                    "AB_PMTRNTIME","BA_PMTRNTIME",
    	                    "AB_EVTRNTIME","BA_EVTRNTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60",
    	                       "(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60",
    	                       "(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60",
    	                       "(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60",
    	                       "(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60"}
    	                       
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit


    RunMacro("Recode Values", hwyfile, {"MODE_ID","WALKTIME","AB_EATRNTIME","BA_EATRNTIME","AB_AMTRNTIME","BA_AMTRNTIME"},
                                       {     null,      null,          null,          null,          null,          null},  //from
                                       {       99,         0,        0.0001,        0.0001,        0.0001,        0.0001},  //to
            {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})
                
 
    RunMacro("Recode Values", hwyfile, {"AB_MDTRNTIME","BA_MDTRNTIME","AB_PMTRNTIME","BA_PMTRNTIME","AB_EVTRNTIME","BA_EVTRNTIME"},
                                      {           null,          null,          null,          null,          null,          null},  //from
                                      {         0.0001,        0.0001,        0.0001,        0.0001,        0.0001,        0.0001},  //to
           {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})
               
    RunMacro("Recode Values", hwyfile, {"MODE_ID"},
                                       {        0},  //from
                                       {       99},  //to
            {1,2,3,4,5,6,7,8,9,10,11,12,13,14,197})

    Return(1)
	quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro

Macro "Transit Skim" (scenarioDirectory, hwyfile, rtsfile, rstopfile, modefile, xferfile, nzones)  
    
    // hardcoded inputs 
    PNRAccfile=scenarioDirectory+"\\outputs\\pnracc.mtx"
    KNRAccfile=scenarioDirectory+"\\outputs\\knracc.mtx"
    
    // Create transposed PNR matrix (for egress)
    parts = SplitPath(PNRAccfile)
    PNREgrfile = parts[1]+parts[2]+"pnregr.mtx"
    Opts = null
		Opts.Input.[Input Matrix] = PNRAccfile
		Opts.Output.[Transposed Matrix].Label = "PNR Egress"
		Opts.Output.[Transposed Matrix].[File Name] = PNREgrfile
		ret_value = RunMacro("TCB Run Operation", "Transpose Matrix", Opts) 

    // Create transposed KNR matrix (for egress)
    parts = SplitPath(KNRAccfile)
    KNREgrfile = parts[1]+parts[2]+"knregr.mtx"
    Opts = null
		Opts.Input.[Input Matrix] = KNRAccfile
		Opts.Output.[Transposed Matrix].Label = "KNR Egress"
		Opts.Output.[Transposed Matrix].[File Name] = KNREgrfile
		ret_value = RunMacro("TCB Run Operation", "Transpose Matrix", Opts) 
    
    periods = {"EA","AM","MD","PM","EV"}
 
  	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
  	{rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )   
    
    // Kyle: tag stops with node id
    n = TagRouteStopsWithNode(rte_lyr,,"NODENUMBER",.2)        // 50-foot search radius
    
  	SetLayer(node_lyr)
   	n = SelectByQuery("centroid", "Several","Select * where ID <= "+String(nzones),)

    pth = SplitPath(modefile)
    modes_vw = pth[3]
    pth = SplitPath(xferfile)
    xfer_vw = pth[3]


    for i = 1 to periods.length do
    
    	// outputs
    	// transit networks
    	trn=scenarioDirectory+"\\outputs\\transit_"+periods[i]+".tnw"
    	
    	trn_wloc=scenarioDirectory+"\\outputs\\trn_wloc_"+periods[i]+".tnw"
    	trn_wexp=scenarioDirectory+"\\outputs\\trn_wexp_"+periods[i]+".tnw"
    	trn_wfxg=scenarioDirectory+"\\outputs\\trn_wfxg_"+periods[i]+".tnw"
    	trn_ptw=scenarioDirectory+"\\outputs\\trn_ptw_"+periods[i]+".tnw"
    	trn_ktw=scenarioDirectory+"\\outputs\\trn_ktw_"+periods[i]+".tnw"
    	trn_wtp=scenarioDirectory+"\\outputs\\trn_wtp_"+periods[i]+".tnw"
    	trn_wtk=scenarioDirectory+"\\outputs\\trn_wtk_"+periods[i]+".tnw"
    	
    	
    	
    	//output skims
    	trnskm_wloc=scenarioDirectory+"\\outputs\\transit_wloc_"+periods[i]+".mtx"
    	trnskm_wexp=scenarioDirectory+"\\outputs\\transit_wexp_"+periods[i]+".mtx"
    	trnskm_wfxg=scenarioDirectory+"\\outputs\\transit_wfxg_"+periods[i]+".mtx"
    	trnskm_ptw=scenarioDirectory+"\\outputs\\transit_ptw_"+periods[i]+".mtx"
    	trnskm_ktw=scenarioDirectory+"\\outputs\\transit_ktw_"+periods[i]+".mtx"
    	trnskm_wtp=scenarioDirectory+"\\outputs\\transit_wtp_"+periods[i]+".mtx"
    	trnskm_wtk=scenarioDirectory+"\\outputs\\transit_wtk_"+periods[i]+".mtx"
   	
    	transitSkims = {    trnskm_wloc,
    	                    trnskm_wexp,
    	                    trnskm_wfxg,
    	                    trnskm_ptw,
    	                    trnskm_ktw,
    	                    trnskm_wtp,
    	                    trnskm_wtk
    	                }
    	
    	
    	//4: Local Bus; 5: Express Bus; 6: Limited Bus; 7: Fixed-Guideway 8: Ferry 11: Transfer Walk; 12: Walk Access
    	// Build Network
    	Opts = null
    	Opts.Input.[Drive Set] = {hwyfile+"|"+link_lyr, link_lyr, "drive", "Select * where MODE_ID = 99"}
    	Opts.Input.[Transit RS] = rtsfile
    	Opts.Input.[RS Set] = {rtsfile+"|"+rte_lyr, rte_lyr, periods[i]+" Routes", "Select * where "+periods[i]+"_Headway>0 & Mode<>null"}
    	Opts.Input.[Walk Set] = {hwyfile+"|"+link_lyr, link_lyr, "all walk link", "Select * where MODE_ID=11 | MODE_ID=12"}
    	Opts.Input.[Stop Set] = {rstopfile+"|"+stp_lyr, stp_lyr}
    	Opts.Global.[Network Label] = "Based on 'Route System'"
    	Opts.Global.[Network Options].Walk = "Yes"
    	Opts.Global.[Network Options].[Mode Field] = rte_lyr+".Mode"
    	Opts.Global.[Network Options].[Walk Mode] = {link_lyr+".Mode_ID", link_lyr+".Mode_ID"}
   
      ab_time = "AB_"+periods[i]+"TIME"
      ba_time = "BA_"+periods[i]+"TIME"
    	abba_time = "["+ab_time+" / "+ba_time+"]"
    	
      ab_trntime = "AB_"+periods[i]+"TRNTIME"
      ba_trntime = "BA_"+periods[i]+"TRNTIME"
    	abba_trntime = "["+ab_trntime+" / "+ba_trntime+"]"

    	Opts.Global.[Network Options].[Link Attributes] = {
        {"Length", {link_lyr+".Length", link_lyr+".Length"}, "SUMFRAC"}, 
        {"Dir", {link_lyr+".Dir", link_lyr+".Dir"}, "SUMFRAC"}, 
        {"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME"}, "SUMFRAC"},
        {abba_time, {link_lyr+"."+ab_time, link_lyr+"."+ba_time}, "SUMFRAC"},
        {abba_trntime, {link_lyr+"."+ab_trntime, link_lyr+"."+ba_trntime}, "SUMFRAC"},
        {"MODE_ID", {link_lyr+".MODE_ID", link_lyr+".MODE_ID"}, "SUMFRAC"}
        }
     
     //must have the same number of street and link attributes
     Opts.Global.[Network Options].[Street Attributes] = {
        {"Length", {link_lyr+".Length", link_lyr+".Length"}}, 
        {"Dir", {link_lyr+".Dir", link_lyr+".Dir"}}, 
        {"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME"}},
        {abba_time, {link_lyr+"."+ab_time, link_lyr+"."+ba_time}, "SUMFRAC"},
        {abba_trntime, {link_lyr+"."+ab_trntime, link_lyr+"."+ba_trntime}, "SUMFRAC"},
        {"MODE_ID", {link_lyr+".MODE_ID", link_lyr+".MODE_ID"}}
        }
     	
    Opts.Global.[Network Options].[Route Attributes].Route_ID = {rte_lyr+".Route_ID"}
    Opts.Global.[Network Options].[Route Attributes].Mode = {rte_lyr+".Mode"}
    Opts.Global.[Network Options].[Route Attributes].Headway = {rte_lyr+"."+periods[i]+"_Headway"}
    Opts.Global.[Network Options].[Route Attributes].Fare = {rte_lyr + ".Fare"}
     Opts.Global.[Network Options].[Stop Attributes].ID = {stp_lyr+".ID"}
    Opts.Global.[Network Options].[Stop Attributes].Longitude = {stp_lyr+".Longitude"}
    Opts.Global.[Network Options].[Stop Attributes].Latitude = {stp_lyr+".Latitude"}
    Opts.Global.[Network Options].[Stop Attributes].Route_ID = {stp_lyr+".Route_ID"}
    Opts.Global.[Network Options].[Stop Attributes].Pass_Count = {stp_lyr+".Pass_Count"}
    Opts.Global.[Network Options].[Stop Attributes].Milepost = {stp_lyr+".Milepost"}
    Opts.Global.[Network Options].[Stop Attributes].STOP_ID = {stp_lyr+".STOP_ID"}
 //   Opts.Global.[Network Options].[Stop Attributes].UserID = {stp_lyr+".UserID"}
    Opts.Global.[Network Options].[Stop Attributes].RTE_NUMBER = {stp_lyr+".RTE_NUMBER"}
    Opts.Global.[Network Options].[Stop Attributes].MODE = {stp_lyr+".MODE"}
    Opts.Global.[Network Options].[Stop Attributes].STOP_FLAG = {stp_lyr+".STOP_FLAG"}
    Opts.Global.[Network Options].[Stop Attributes].NODENUMBER = {stp_lyr+".NODENUMBER"}
    Opts.Global.[Network Options].Overide = {stp_lyr+".ID", stp_lyr+".NODENUMBER"}
    Opts.Global.[Network Options].TagField = "NODENUMBER"
    Opts.Output.[Network File] = trn

    ret_value = RunMacro("TCB Run Operation", "Build Transit Network", Opts, &Ret)
    if !ret_value then goto quit
    
    
    //  PEAK Walk Access Transit Network Setting PF
    CopyFile(trn, trn_wloc)
    Opts = null
    Opts.Input.[Transit RS] = rtsfile
    Opts.Input.[Transit Network] = trn_wloc
    Opts.Input.[Mode Table] = {modefile}
    Opts.Input.[Mode Cost Table] = {xferfile}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = abba_trntime
    Opts.Field.[Route Headway] = "Headway"
    Opts.Field.[Route Fare] = "Fare"
    Opts.Field.[Mode Impedance] = "Mode_"+periods[i]+"Time"
    Opts.Field.[Mode Used] = "Walk_Local"
    Opts.Field.[Mode Access] = "Access"
    Opts.Field.[Mode Egress] = "Egress"
    Opts.Field.[Mode Imp Weight]   = "Local_Weight" 
    Opts.Field.[Mode IWait Weight] = "IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = "XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Global.[Global Fare Value] = .68
    Opts.Global.[Global Xfer Fare] = 0
    Opts.Global.[Global Fare Weight] = 1    // Fare will be entered in dollars on the RTS
    Opts.Global.[Global Imp Weight] = 1
    Opts.Global.[Global Xfer Weight] = 1
    Opts.Global.[Global IWait Weight] = 2
    Opts.Global.[Global XWait Weight] = 2
    Opts.Global.[Global Dwell Weight] = 1
    Opts.Global.[Global Dwell On Time] = 0.17
    Opts.Global.[Global Dwell Off Time] = 0.17
    Opts.Global.[Global Dwell Time] = 0.17
    Opts.Global.[Global Headway] = 15
    Opts.Global.[Global Xfer Time] = 4
    Opts.Global.[Global Max IWait] = 60
    Opts.Global.[Global Min IWait] = 1.5
    Opts.Global.[Global Max XWait] = 60
    Opts.Global.[Global Min XWait] = 2
    Opts.Global.[Global Layover Time] = 3
    Opts.Global.[Global Max WACC Path] = 10
    Opts.Global.[Global Max Access] = 40
    Opts.Global.[Global Max Egress] = 40
    Opts.Global.[Global Max Transfer] = 30
    Opts.Global.[Global Max Imp] = 9999
    Opts.Global.[Path Method] = 3
    Opts.Global.[Value of Time] = 0.125 //$7.50/hr - half of the auto vot, assuming transit users have a lower vot - though it doesn't matter since there is no fare differentiation
    Opts.Global.[Max Xfer Number] = 6
    Opts.Global.[Max Trip Time] = 999
    Opts.Global.[Walk Weight] = 2
    Opts.Global.[Zonal Fare Method] = 1
    Opts.Global.[Interarrival Para] = 0.5       //Half the headway
    Opts.Global.[Path Threshold] = 0.15          //Combination Factor
    Opts.Flag.[Use All Walk Path] = "False"
    Opts.Flag.[Use Stop Access] = "False"   //?
    Opts.Flag.[Use Mode] = "True"
    Opts.Flag.[Use Mode Cost] = "True"
    Opts.Flag.[Combine By Mode] = "True"        //Only combine paths for same mode
    Opts.Flag.[Fare By Mode] = "False"
    Opts.Flag.[M2M Fare Method] = 2
    Opts.Flag.[Fare System] = 1
    Opts.Flag.[Use Park and Ride] = "No"
    Opts.Flag.[Use P&R Walk Access] = "No"

    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // Settings for Walk-Express
    CopyFile(trn_wloc, trn_wexp)
    Opts.Input.[Transit Network] = trn_wexp
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".Express_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Express"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // Settings for Walk-Fixed Guideway
    CopyFile(trn_wloc, trn_wfxg)
    Opts.Input.[Transit Network] = trn_wfxg
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_FixedGuideway"
    Opts.Field.[Mode IWait Weight] = null
    Opts.Field.[Mode XWait Weight] = null 
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // Settings for PTW
    CopyFile(trn_wloc, trn_ptw)
    Opts.Input.[Transit Network] = trn_ptw
    Opts.Input.[OP Time Currency] = {PNRAccfile, periods[i]+"Time", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {PNRAccfile, "Length", "Orig", "Dest"}
 //   Opts.Input.[Drive Set] = {hwyfile+"|"+link_lyr, link_lyr, "drive", "Select * where Length>0"}  //needed in this version of transcad to connect centroids to transit network for drive
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = abba_trntime
    Opts.Field.[Link Drive Time] = abba_time
    Opts.Field.[Route Headway] = "Headway"
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_"+periods[i]+"Time"
    Opts.Field.[Mode Used] = modes_vw+".PNR"
//    Opts.Global.[Global Max PACC] = 5
    Opts.Global.[Drive Time Weight] = 2
//    Opts.Global.[Max Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit
    	
    // Settings for KTW
    CopyFile(trn_ptw, trn_ktw)
    Opts.Input.[Transit Network] = trn_ktw
    Opts.Input.[OP Time Currency] = {KNRAccfile, periods[i]+"Time", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {KNRAccfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = abba_trntime
    Opts.Field.[Link Drive Time] = abba_time
    Opts.Field.[Route Headway] = "Headway"
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_"+periods[i]+"Time"
    Opts.Field.[Mode Used] = modes_vw+".KNR"
//    Opts.Global.[Global Max PACC] = 5
    Opts.Global.[Drive Time Weight] = 2
//    Opts.Global.[Max Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // Settings for WTP
    CopyFile(trn_ptw, trn_wtp)
    Opts.Input.[Transit Network] = trn_wtp
    Opts.Input.[PD Time Currency] = {PNREgrfile, periods[i]+"Time", "Dest", "Orig"}
    Opts.Input.[PD Dist Currency] = {PNREgrfile, "Length", "Dest", "Orig"}
 //  Opts.Input.[PD Cost Currency] = {"c:\\temp\\SPMAT.mtx", "WALKT (Skim)", "Origin", "Destination"}
    Opts.Global.[Max Egre Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "No"
    Opts.Flag.[Use Egress Park and Ride] = "Yes"
    Opts.Flag.[Use P&R Walk Access] = "No"
    Opts.Flag.[Use P&R Walk Egress] = "No"
    Opts.Flag.[Use Parking Capacity] = "No"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit
    	
    // Settings for WTK
    CopyFile(trn_ktw, trn_wtk)
    Opts.Input.[Transit Network] = trn_wtk
    Opts.Input.[PD Time Currency] = {KNREgrfile, periods[i]+"Time", "Dest", "Orig"}
    Opts.Input.[PD Dist Currency] = {KNREgrfile, "Length", "Dest", "Orig"}
 //  Opts.Input.[PD Cost Currency] = {"c:\\temp\\SPMAT.mtx", "WALKT (Skim)", "Origin", "Destination"}
    Opts.Global.[Max Egre Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "No"
    Opts.Flag.[Use Egress Park and Ride] = "Yes"
    Opts.Flag.[Use P&R Walk Access] = "No"
    Opts.Flag.[Use P&R Walk Egress] = "No"
    Opts.Flag.[Use Parking Capacity] = "No"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // the output pnr acc node tables
    pnr_pnrAccNode = scenarioDirectory+"\\outputs\\pnr_"+periods[i]+"_pnrAccNode.mtx"
    knr_knrAccNode = scenarioDirectory+"\\outputs\\knr_"+periods[i]+"_knrAccNode.mtx"
   // pnr_pnrEgrNode = scenarioDirectory+"\\outputs\\pnr_"+periods[i]+"_pnrEgrNode.mtx"  --Doesn't work

    // an array of networks
    trnnet_scen={trn_wloc   ,    trn_wexp,    trn_wfxg,        trn_ptw,       trn_ktw,  trn_wtp,     trn_wtk}
       
    out_pnr_skm={           ,            ,            , pnr_pnrAccNode,knr_knrAccNode,         ,            }
    
    skim_var = {
    	        {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time","Number of Transfers"},			//walk local
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time","Number of Transfers",abba_trntime},	//walk express
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Dwelling Time","Number of Transfers",abba_trntime},	//walk fixed-guidway
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Dwelling Time","Number of Transfers",abba_trntime,"Access Drive Distance"},	//pnr-trn-wlk
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Dwelling Time","Number of Transfers",abba_trntime,"Access Drive Distance"}, //knr-trn-wlk
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Drive Time","Dwelling Time","Number of Transfers",abba_trntime,"Egress Drive Distance"},	//wlk-trn-pnr
	            {"Fare", "In-Vehicle Time",  "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Drive Time","Dwelling Time","Number of Transfers",abba_trntime,"Egress Drive Distance"}	//wlk-trn-knr
	          } 
	               skim_modes = {null,{4,5,6,8},{4,5,6,7,8},{4,5,6,7},{4,5,6,7},{4,5,6,7},{4,5,6,7}}
    label_scen = {periods[i]+" Walk Local",periods[i]+" Walk Express",periods[i]+" Walk Fixed Guideway",periods[i]+" PTW",periods[i]+" KTW",periods[i]+" WTP",periods[i]+" WTK"}
    trnskm_scen={trnskm_wloc, trnskm_wexp, trnskm_wfxg, trnskm_ptw, trnskm_ktw, trnskm_wtp, trnskm_wtk}
    
    for j=1 to trnnet_scen.length do
   	    Opts = null
   	    Opts.Input.Database = hwyfile
   	    Opts.Input.Network = trnnet_scen[j]
   	    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
   	    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
   	    Opts.Global.[Skim Var] = skim_var[j]
   	    Opts.Global.[OD Layer Type] = 2
	      if skim_modes[j] <> null then Opts.Global.[Skim Modes] = skim_modes[j]
   	    Opts.Output.[Skim Matrix].Label = "Skim "+label_scen[j]
   	    Opts.Output.[Skim Matrix].Compression = 1
   	    Opts.Output.[Skim Matrix].[File Name] = trnskm_scen[j]
   	    
   	    if(out_pnr_skm[j] != null) then do
   	      Opts.Output.[Parking Matrix].[File Name] = out_pnr_skm[j]
          Opts.Output.[Parking Matrix].Compression = 1
   	      Opts.Output.[Parking Matrix].Label = label_scen[j]+ " PNR node"
   	    end
        
   	    ret_value = RunMacro("TCB Run Procedure", "Transit Skim PF", Opts, &Ret)
        if !ret_value then goto quit
   	    
   	    // Add the parking node matrix to the drive transit skims
   	    if(out_pnr_skm[j] != null) then do
            parkingMatrix = OpenMatrix( out_pnr_skm[j],)
            parkingMatrixName = GetMatrixCore(parkingMatrix) 
            parkingCurrency = CreateMatrixCurrency(parkingMatrix, parkingMatrixName, , , )
            skimMatrix = OpenMatrix( trnskm_scen[j],)
   	        AddMatrixCore(skimMatrix, parkingMatrixName)
		        parkingCopy = CreateMatrixCurrency(skimMatrix, parkingMatrixName, , , )
            parkingCopy := parkingCurrency
        end
   	    
   	    if !ret_value then goto quit
   end
 
 convert:
    ret_value = RunMacro("Convert Matrices To Binary", transitSkims)
    if !ret_value then goto quit

	end
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit
    
   

    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

