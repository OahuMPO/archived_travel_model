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
    
    
    scenarioDirectory="c:\\projects\\ompo\\conversion\\application\\2005_base"
    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    rtsfile=scenarioDirectory+"\\inputs\\network\\Scenario Route System.rts"
    rstopfile=scenarioDirectory+"\\inputs\\network\\Scenario Route SystemS.dbd"
    modefile=scenarioDirectory+"\\inputs\\other\\modes.bin"
    xferfile=scenarioDirectory+"\\inputs\\other\\transfer.bin"
    nzones=764
    iteration=3
    
    ret_value = RunMacro("Transit Time Update", scenarioDirectory, hwyfile, iteration)
    if !ret_value then Throw()
 
    skim:
    ret_value = RunMacro("Transit Skim", scenarioDirectory, hwyfile, rtsfile, rstopfile, modefile, xferfile, nzones)  
    if !ret_value then Throw()


    ret_value = RunMacro("Close All")
    if !ret_value then Throw()
    
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
	    
	    AB_Pk_Time = "AB_PKTIME"
	    BA_Pk_Time = "BA_PKTIME"
	    AB_OP_Time = "AB_OPTIME"
	    BA_OP_Time = "BA_OPTIME"
        
        Opts = null
        Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr,link_lyr}
        Opts.Global.Fields = {"AB_PKTRNTIME","BA_PKTRNTIME","AB_OPTRNTIME","BA_OPTRNTIME"}
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {AB_Pk_Time+" * AB_PKTRNFAC",BA_Pk_Time+" * BA_PKTRNFAC",AB_OP_Time+" * AB_OPTRNFAC",BA_OP_Time+" * BA_OPTRNFAC"}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()
        
          
        end
    // if not iteration 1, use msa times in flow table
    else do
    
	    AB_Pk_Time = "AB_MSA_TIME"
	    BA_Pk_Time = "BA_MSA_TIME"
	    AB_OP_Time = "AB_MSA_TIME"
	    BA_OP_Time = "BA_MSA_TIME"
	    
	    pkflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\AM2HourFlow"+String(iteration-1)+".bin"
	    opflowtable = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\OffpeakFlow"+String(iteration-1)+".bin"
	    

        Opts = null
        Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,pkflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
        Opts.Global.Fields = {"AB_PKTRNTIME","BA_PKTRNTIME"}
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {AB_Pk_Time+" * AB_PKTRNFAC",BA_Pk_Time+" * BA_PKTRNFAC"}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()
    

        Opts = null
        Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr,opflowtable,  {"ID"}, {"ID1"}}, "joinedvw"}
        Opts.Global.Fields = {"AB_OPTRNTIME","BA_OPTRNTIME"}
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {AB_OP_Time+" * AB_OPTRNFAC",BA_OP_Time+" * BA_OPTRNFAC"}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()
        
    end 
    
    //Code transit-only links (Facility-type = 14) with time based on Tran_Only_Spd field
    AB_FACTYPE = "[AB FACTYPE]"
    SetLayer(link_lyr) //Line Layer
    n1 = SelectByQuery("TranOnly", "Several", "Select * where" +AB_FACTYPE+"=14",)
    
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr,link_lyr,"TranOnly"}
    Opts.Global.Fields = {"AB_PKTRNTIME","BA_PKTRNTIME","AB_OPTRNTIME","BA_OPTRNTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60","(Length/Tran_Only_Spd)*60",}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then Throw()
    
    ret_value = RunMacro("Close All")
    if !ret_value then Throw()


        RunMacro("Recode Values", hwyfile, {"MODE_ID","WALKTIME","AB_PKTRNTIME","BA_PKTRNTIME","AB_OPTRNTIME","BA_OPTRNTIME"},
                                           {     null,      null,          null,          null,          null,          null},  //from
                                           {       99,         0,        0.0001,        0.0001,        0.0001,        0.0001},  //to
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
    PNRfile=scenarioDirectory+"\\outputs\\pnracc.mtx"
    KNRfile=scenarioDirectory+"\\outputs\\knracc.mtx"
    
    /*
    Opts = null
    Opts.Input.[Matrix Currency] = { PNRfile, "PKTime", "Orig", "Dest"}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if([PKTime]=0) then null else [PKTime]"
    Opts.Global.[Force Missing] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    if !ret_value then Throw()

    Opts = null
    Opts.Input.[Matrix Currency] = { PNRfile, "OPTime", "Orig", "Dest"}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if([OPTime]=0) then null else [OPTime]"
    Opts.Global.[Force Missing] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    if !ret_value then Throw()
    
    Opts = null
    Opts.Input.[Matrix Currency] = { KNRfile, "PKTime", "Orig", "Dest"}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if([PKTime]=0) then null else [PKTime]"
    Opts.Global.[Force Missing] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    if !ret_value then Throw()

    Opts = null
    Opts.Input.[Matrix Currency] = { KNRfile, "OPTime", "Orig", "Dest"}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if([OPTime]=0) then null else [OPTime]"
    Opts.Global.[Force Missing] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    if !ret_value then Throw()
*/
    // outputs
    // transit networks
    trn_pk=scenarioDirectory+"\\outputs\\transit_pk.tnw"
    trn_op=scenarioDirectory+"\\outputs\\transit_op.tnw"

    trn_wloc_pk=scenarioDirectory+"\\outputs\\trn_wloc_pk.tnw"
    trn_wexp_pk=scenarioDirectory+"\\outputs\\trn_wexp_pk.tnw"
    trn_wfxg_pk=scenarioDirectory+"\\outputs\\trn_wfxg_pk.tnw"
    trn_pnr_pk=scenarioDirectory+"\\outputs\\trn_pnr_pk.tnw"
    trn_knr_pk=scenarioDirectory+"\\outputs\\trn_knr_pk.tnw"
 
    trn_wloc_op=scenarioDirectory+"\\outputs\\trn_wloc_op.tnw"
    trn_wexp_op=scenarioDirectory+"\\outputs\\trn_wexp_op.tnw"
    trn_wfxg_op=scenarioDirectory+"\\outputs\\trn_wfxg_op.tnw"
    trn_pnr_op=scenarioDirectory+"\\outputs\\trn_pnr_op.tnw"
    trn_knr_op=scenarioDirectory+"\\outputs\\trn_knr_op.tnw"

    //output skims
    trnskm_wloc_pk=scenarioDirectory+"\\outputs\\transit_wloc_pk.mtx"
    trnskm_wexp_pk=scenarioDirectory+"\\outputs\\transit_wexp_pk.mtx"
    trnskm_wfxg_pk=scenarioDirectory+"\\outputs\\transit_wfxg_pk.mtx"
    trnskm_pnr_pk=scenarioDirectory+"\\outputs\\transit_pnr_pk.mtx"
    trnskm_knr_pk=scenarioDirectory+"\\outputs\\transit_knr_pk.mtx"
    
    trnskm_wloc_op=scenarioDirectory+"\\outputs\\transit_wloc_op.mtx"
    trnskm_wexp_op=scenarioDirectory+"\\outputs\\transit_wexp_op.mtx"
    trnskm_wfxg_op=scenarioDirectory+"\\outputs\\transit_wfxg_op.mtx"
    trnskm_pnr_op=scenarioDirectory+"\\outputs\\transit_pnr_op.mtx"
    trnskm_knr_op=scenarioDirectory+"\\outputs\\transit_knr_op.mtx"

    transitSkims = {    trnskm_wloc_pk,
                        trnskm_wexp_pk,
                        trnskm_wfxg_pk,
                        trnskm_pnr_pk,
                        trnskm_knr_pk,
                        trnskm_wloc_op,
                        trnskm_wexp_op,
                        trnskm_wfxg_op,
                        trnskm_pnr_op,
                        trnskm_knr_op
                    }


    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    {rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )   
    
    SetLayer(node_lyr)
    n = SelectByQuery("centroid", "Several","Select * where ID <= "+String(nzones),)

    //4: Local Bus; 5: Express Bus; 6: Limited Bus; 7: Fixed-Guideway 8: Ferry 11: Transfer Walk; 12: Walk Access
    // Build PK Network
    Opts = null
    Opts.Input.[Drive Set] = {hwyfile+"|"+link_lyr, link_lyr, "drive", "Select * where MODE_ID = 99"}
    Opts.Input.[Transit RS] = rtsfile
    Opts.Input.[RS Set] = {rtsfile+"|"+rte_lyr, rte_lyr, "PK Routes", "Select * where AM_Headway>0 & Mode<>null"}
    Opts.Input.[Walk Set] = {hwyfile+"|"+link_lyr, link_lyr, "all walk link", "Select * where MODE_ID=11 | MODE_ID=12"}
    Opts.Input.[Stop Set] = {rstopfile+"|"+stp_lyr, stp_lyr}
    Opts.Global.[Network Label] = "Based on 'Route System'"
    Opts.Global.[Network Options].Walk = "Yes"
    Opts.Global.[Network Options].[Mode Field] = rte_lyr+".Mode"
    Opts.Global.[Network Options].[Walk Mode] = {link_lyr+".Mode_ID", link_lyr+".Mode_ID"}

    Opts.Global.[Network Options].[Link Attributes] = {
        {"Length", {link_lyr+".Length", link_lyr+".Length"}, "SUMFRAC"}, 
        {"Dir", {link_lyr+".Dir", link_lyr+".Dir"}, "SUMFRAC"}, 
        {"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME"}, "SUMFRAC"},
        {"[AB_PKTIME / BA_PKTIME]", {link_lyr+".AB_PKTIME", link_lyr+".BA_PKTIME"}, "SUMFRAC"},
        {"[AB_OPTIME / BA_OPTIME]", {link_lyr+".AB_OPTIME", link_lyr+".BA_OPTIME"}, "SUMFRAC"},
        {"[AB_PKTRNTIME / BA_PKTRNTIME]", {link_lyr+".AB_PKTRNTIME", link_lyr+".BA_PKTRNTIME"}, "SUMFRAC"},
        {"[AB_OPTRNTIME / BA_OPTRNTIME]", {link_lyr+".AB_OPTRNTIME", link_lyr+".BA_OPTRNTIME"}, "SUMFRAC"},
        {"MODE_ID", {link_lyr+".MODE_ID", link_lyr+".MODE_ID"}, "SUMFRAC"}
        }
     
     //must have the same number of street and link attributes
     Opts.Global.[Network Options].[Street Attributes] = {
        {"Length", {link_lyr+".Length", link_lyr+".Length"}}, 
        {"Dir", {link_lyr+".Dir", link_lyr+".Dir"}}, 
        {"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME"}},
        {"[AB_PKTIME / BA_PKTIME]", {link_lyr+".AB_PKTIME", link_lyr+".BA_PKTIME"}}, 
        {"[AB_OPTIME / BA_OPTIME]", {link_lyr+".AB_OPTIME", link_lyr+".BA_OPTIME"}}, 
        {"[AB_PKTRNTIME / BA_PKTRNTIME]", {link_lyr+".AB_PKTRNTIME", link_lyr+".BA_PKTRNTIME"}}, 
        {"[AB_OPTRNTIME / BA_OPTRNTIME]", {link_lyr+".AB_OPTRNTIME", link_lyr+".BA_OPTRNTIME"}}, 
        {"MODE_ID", {link_lyr+".MODE_ID", link_lyr+".MODE_ID"}}
        }
     	
    Opts.Global.[Network Options].[Route Attributes].Route_ID = {rte_lyr+".Route_ID"}
    Opts.Global.[Network Options].[Route Attributes].Mode = {rte_lyr+".Mode"}
    Opts.Global.[Network Options].[Route Attributes].AM_Headway = {rte_lyr+".AM_Headway"}
    Opts.Global.[Network Options].[Route Attributes].MD_Headway = {rte_lyr+".MD_Headway"}
    Opts.Global.[Network Options].[Route Attributes].PM_Headway = {rte_lyr+".PM_Headway"}
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
    Opts.Output.[Network File] = trn_pk

    ret_value = RunMacro("TCB Run Operation", "Build Transit Network", Opts, &Ret)
    if !ret_value then Throw()
    
    // Build OP Network
    Opts.Input.[RS Set] = {rtsfile+"|"+rte_lyr, rte_lyr, "OP Routes", "Select * where MD_Headway>0 & Mode<>null"}
    Opts.Output.[Network File] = trn_op

    ret_value = RunMacro("TCB Run Operation", "Build Transit Network", Opts, &Ret)
    if !ret_value then Throw()

    pth = SplitPath(modefile)
    modes_vw = pth[3]
    pth = SplitPath(xferfile)
    xfer_vw = pth[3]
    
    //  PEAK Walk Access Transit Network Setting PF
    CopyFile(trn_pk, trn_wloc_pk)
    Opts = null
    Opts.Input.[Transit RS] = rtsfile
    Opts.Input.[Transit Network] = trn_wloc_pk
    Opts.Input.[Mode Table] = {modefile}
    Opts.Input.[Mode Cost Table] = {xferfile}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_PKTRNTIME / BA_PKTRNTIME]"
    Opts.Field.[Route Headway] = "AM_Headway"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_PKTime"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Local"
    Opts.Field.[Mode Access] = modes_vw+".Access"
    Opts.Field.[Mode Egress] = modes_vw+".Egress"
    Opts.Field.[Mode Imp Weight]   = modes_vw + ".Local_Weight" 
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Global.[Global Fare Value] = 68
    Opts.Global.[Global Xfer Fare] = 0
    Opts.Global.[Global Fare Weight] = 1
    Opts.Global.[Global Imp Weight] = 1
    Opts.Global.[Global Xfer Weight] = 1
    Opts.Global.[Global IWait Weight] = 2
    Opts.Global.[Global XWait Weight] = 2
    Opts.Global.[Global Dwell Weight] = 1
    Opts.Global.[Global Dwell Time] = 0.3
    Opts.Global.[Global Headway] = 15
    Opts.Global.[Global Xfer Time] = 10
    Opts.Global.[Global Max IWait] = 60
    Opts.Global.[Global Min IWait] = 2
    Opts.Global.[Global Max XWait] = 60
    Opts.Global.[Global Min XWait] = 2
    Opts.Global.[Global Layover Time] = 3
//    Opts.Global.[Global Max WACC Path] = 4
    Opts.Global.[Global Max Access] = 30
    Opts.Global.[Global Max Egress] = 30
    Opts.Global.[Global Max Transfer] = 10
    Opts.Global.[Global Max Imp] = 999
    Opts.Global.[Path Method] = 3
    Opts.Global.[Value of Time] = 0.2
    Opts.Global.[Max Xfer Number] = 2
    Opts.Global.[Max Trip Time] = 999
    Opts.Global.[Walk Weight] = 2
    Opts.Global.[Zonal Fare Method] = 1
    Opts.Global.[Interarrival Para] = 0.5       //Half the headway
    Opts.Global.[Path Threshold] = 0.1          //Combination Factor
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
    if !ret_value then Throw()

    // Settings for Peak Walk-Express
    CopyFile(trn_wloc_pk, trn_wexp_pk)
    Opts.Input.[Transit Network] = trn_wexp_pk
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".Express_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Express"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Peak Walk-Fixed Guideway
    CopyFile(trn_wloc_pk, trn_wfxg_pk)
    Opts.Input.[Transit Network] = trn_wfxg_pk
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_FixedGuideway"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Off-Peak Walk-Local
    CopyFile(trn_op, trn_wloc_op)
    Opts.Input.[Transit Network] = trn_wloc_op
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_OPTRNTIME / BA_OPTRNTIME]"
    Opts.Field.[Route Headway] = "MD_Headway"
    Opts.Field.[Mode Imp Weight] = modes_vw+".Local_Weight"
    Opts.Field.[Mode Impedance] = "modes.Mode_OPTime"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Local"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Off-Peak Walk-Express
    CopyFile(trn_wloc_op, trn_wexp_op)
    Opts.Input.[Transit Network] = trn_wexp_op
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".Express_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Express"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Off-Peak Walk-Fixed Guideway
    CopyFile(trn_wloc_op, trn_wfxg_op)
    Opts.Input.[Transit Network] = trn_wfxg_op
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_FixedGuideway"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Peak PNR
    CopyFile(trn_wloc_pk, trn_pnr_pk)
    Opts.Input.[Transit Network] = trn_pnr_pk
    Opts.Input.[OP Time Currency] = {PNRfile, "PKTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {PNRfile, "Length", "Orig", "Dest"}
 //   Opts.Input.[Drive Set] = {hwyfile+"|"+link_lyr, link_lyr, "drive", "Select * where Length>0"}  //needed in this version of transcad to connect centroids to transit network for drive
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_PKTRNTIME / BA_PKTRNTIME]"
    Opts.Field.[Link Drive Time] = "[AB_PKTIME / BA_PKTIME]"
    Opts.Field.[Route Headway] = "AM_Headway"
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_PKTime"
    Opts.Field.[Mode Used] = modes_vw+".PNR"
//    Opts.Global.[Global Max PACC] = 5
    Opts.Global.[Drive Time Weight] = 2
//    Opts.Global.[Max Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Peak KNR
    CopyFile(trn_pnr_pk, trn_knr_pk)
    Opts.Input.[Transit Network] = trn_knr_pk
    Opts.Input.[OP Time Currency] = {KNRfile, "PKTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {KNRfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_PKTRNTIME / BA_PKTRNTIME]"
    Opts.Field.[Link Drive Time] = "[AB_PKTIME / BA_PKTIME]"
    Opts.Field.[Route Headway] = "AM_Headway"
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_PKTime"
    Opts.Field.[Mode Used] = modes_vw+".KNR"
//    Opts.Global.[Global Max PACC] = 5
    Opts.Global.[Drive Time Weight] = 2
//    Opts.Global.[Max Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Off-Peak PNR
    CopyFile(trn_wloc_op, trn_pnr_op)
    Opts.Input.[Transit Network] = trn_pnr_op
    Opts.Input.[OP Time Currency] = {PNRfile, "OPTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {PNRfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_OPTRNTIME / BA_OPTRNTIME]"
    Opts.Field.[Link Drive Time] = "[AB_OPTIME / BA_OPTIME]"
    Opts.Field.[Route Headway] = "MD_Headway"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_OPTime"
    Opts.Field.[Mode Used] = modes_vw+".PNR"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // Settings for Off-Peak KNR
    CopyFile(trn_pnr_op, trn_knr_op)
    Opts.Input.[Transit Network] = trn_knr_op
    Opts.Input.[OP Time Currency] = {KNRfile, "OPTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {KNRfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Link Impedance] = "[AB_OPTRNTIME / BA_OPTRNTIME]"
    Opts.Field.[Link Drive Time] = "[AB_OPTIME / BA_OPTIME]"
    Opts.Field.[Route Headway] = "MD_Headway"
    Opts.Field.[Mode IWait Weight] = modes_vw + ".IWait_Weight" 
    Opts.Field.[Mode XWait Weight] = modes_vw + ".XWait_Weight" 
    Opts.Field.[Inter-Mode Xfer From] = xfer_vw+".FROM"
    Opts.Field.[Inter-Mode Xfer To] = xfer_vw+".TO"
    Opts.Field.[Inter-Mode Xfer Stop] = xfer_vw+".STOP"
    Opts.Field.[Inter-Mode Xfer Fare] = xfer_vw+".FARE"
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_OPTime"
    Opts.Field.[Mode Used] = modes_vw+".KNR"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then Throw()

    // the output pnr node tables
    pnr_pk_pnrNode = scenarioDirectory+"\\outputs\\pnr_pk_pnrNode.mtx"
    pnr_op_pnrNode = scenarioDirectory+"\\outputs\\pnr_op_pnrNode.mtx"

    // an array of networks
    trnnet_scen={trn_wloc_pk, trn_wexp_pk, trn_wfxg_pk, trn_pnr_pk,    trn_knr_pk, trn_wloc_op, trn_wexp_op, trn_wfxg_op, trn_pnr_op, trn_knr_op}
       
    out_pnr_skm={           ,            ,            , pnr_pk_pnrNode,        ,            ,            ,             , pnr_op_pnrNode,       }
    
    skim_var = {{"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers"},			//walk local pk
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers","[AB_PKTRNTIME / BA_PKTRNTIME]"},	//walk express pk
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers","[AB_PKTRNTIME / BA_PKTRNTIME]"},	//walk fixed-guidway pk
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Number of Transfers","[AB_PKTRNTIME / BA_PKTRNTIME]","Drive Distance"},	//pnr PK
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Number of Transfers","[AB_PKTRNTIME / BA_PKTRNTIME]","Drive Distance"},	//knr PK
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers"},			//walk local op
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers","[AB_OPTRNTIME / BA_OPTRNTIME]"},	//walk express op
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Access Walk Time", "Egress Walk Time", "Number of Transfers","[AB_OPTRNTIME / BA_OPTRNTIME]"},	//walk fixed-guideway op
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Number of Transfers","[AB_OPTRNTIME / BA_OPTRNTIME]","Drive Distance"},	//pnr op
	            {"Fare", "In-Vehicle Time", "Initial Wait Time", "Transfer Wait Time", "Transfer Walk Time", "Egress Walk Time", "Access Drive Time","Number of Transfers","[AB_OPTRNTIME / BA_OPTRNTIME]","Drive Distance"}}	//knr op
    skim_modes = {null,{4,5,6,8},{4,5,6,7,8},{4,5,6,7},{4,5,6,7},null,{4,5,6,8},{4,5,6,7,8},{4,5,6,7},{4,5,6,7}}
    label_scen = {"Peak Walk Local","Peak Walk Express","Peak Walk Fixed Guideway","Peak PNR","Peak KNR",
                 "Off-Peak Walk Local","Off-Peak Walk Express","Off-Peak Walk Fixed Guideway","Off-Peak PNR","Off-Peak KNR"}
    trnskm_scen={trnskm_wloc_pk, trnskm_wexp_pk, trnskm_wfxg_pk, trnskm_pnr_pk, trnskm_knr_pk, 
                 trnskm_wloc_op, trnskm_wexp_op, trnskm_wfxg_op, trnskm_pnr_op, trnskm_knr_op}
    
    for i=1 to trnnet_scen.length do
   	    Opts = null
   	    Opts.Input.Database = hwyfile
   	    Opts.Input.Network = trnnet_scen[i]
   	    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
   	    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
   	    Opts.Global.[Skim Var] = skim_var[i]
   	    Opts.Global.[OD Layer Type] = 2
	    if skim_modes[i] <> null then Opts.Global.[Skim Modes] = skim_modes[i]
   	    Opts.Output.[Skim Matrix].Label = "Skim "+label_scen[i]
   	    Opts.Output.[Skim Matrix].Compression = 1
   	    Opts.Output.[Skim Matrix].[File Name] = trnskm_scen[i]
   	    
   	    if(out_pnr_skm[i] != null) then do
   	      Opts.Output.[Parking Matrix].[File Name] = out_pnr_skm[i]
          Opts.Output.[Parking Matrix].Compression = 1
   	      Opts.Output.[Parking Matrix].Label = label_scen[i]+ " PNR node"
   	    end
        
   	    ret_value = RunMacro("TCB Run Procedure", "Transit Skim PF", Opts, &Ret)
        if !ret_value then Throw()
   	    
   	    // Add the parking node matrix to the drive transit skims
   	    if(out_pnr_skm[i] != null) then do
            parkingMatrix = OpenMatrix( out_pnr_skm[i],)
            parkingMatrixName = GetMatrixCore(parkingMatrix) 
            parkingCurrency = CreateMatrixCurrency(parkingMatrix, parkingMatrixName, , , )
            skimMatrix = OpenMatrix( trnskm_scen[i],)
   	        AddMatrixCore(skimMatrix, parkingMatrixName)
		    parkingCopy = CreateMatrixCurrency(skimMatrix, parkingMatrixName, , , )
            parkingCopy := parkingCurrency
        end
   	    
   	    if !ret_value then Throw()
   end

    ret_value = RunMacro("Close All")
    if !ret_value then Throw()
    
    convert:
    ret_value = RunMacro("Convert Matrices To Binary", transitSkims)
    if !ret_value then Throw()


    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

