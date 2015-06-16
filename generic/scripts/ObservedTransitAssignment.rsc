/***********************************************************************************************************************
*
* Observed Transit Assignment
*
* This macro assigns observed transit trip tables to transit networks.  The transit networks and trip tables must exist in the 
* scenarioDirectory\outputs folder.  Transit network settings assumed set already (for skim-building).
*
* 4/08 - jef - pb
*
* Arguments:
*   scenarioDirectory   Directory of scenario
*   rtsfile             Transit route file
*
**********************************************************************************************************************/
Macro "Observed Transit Assignment" 

    RunMacro("TCB Init")
    scenarioDirectory = "c:\\projects\\ompo\\conversion\\application\\2005_base"
    observedDirectory = "c:\\projects\\ompo\\conversion\\data\\observed_trips"
    
    trn_pk=observedDirectory+"\\outputs\\transit_pk_obs.tnw"
    trn_op=observedDirectory+"\\outputs\\transit_op_obs.tnw"

    trn_wloc_pk=observedDirectory+"\\outputs\\trn_wloc_pk_obs.tnw"
    trn_wexp_pk=observedDirectory+"\\outputs\\trn_wexp_pk_obs.tnw"
    trn_wfxg_pk=observedDirectory+"\\outputs\\trn_wfxg_pk_obs.tnw"
    trn_pnr_pk=observedDirectory+"\\outputs\\trn_pnr_pk_obs.tnw"
    trn_knr_pk=observedDirectory+"\\outputs\\trn_knr_pk_obs.tnw"
 
    trn_wloc_op=observedDirectory+"\\outputs\\trn_wloc_op_obs.tnw"
    trn_wexp_op=observedDirectory+"\\outputs\\trn_wexp_op_obs.tnw"
    trn_wfxg_op=observedDirectory+"\\outputs\\trn_wfxg_op_obs.tnw"
    trn_pnr_op=observedDirectory+"\\outputs\\trn_pnr_op_obs.tnw"
    trn_knr_op=observedDirectory+"\\outputs\\trn_knr_op_obs.tnw"

    trn_obtrips = observedDirectory+"\\trn_observed05.mtx"

    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    rtsfile=scenarioDirectory+"\\inputs\\network\\Scenario Route System.rts"
    rstopfile=scenarioDirectory+"\\inputs\\network\\Scenario Route SystemS.dbd"
    modefile=scenarioDirectory+"\\inputs\\other\\modes.bin"
    xferfile=scenarioDirectory+"\\inputs\\other\\transfer.bin"
    PNRfile=scenarioDirectory+"\\outputs\\pnracc.mtx"
    KNRfile=scenarioDirectory+"\\outputs\\knracc.mtx"
    nzones=764
  
   
    // an array of networks
    trnnet={trn_wloc_pk, trn_wexp_pk, trn_pnr_pk, trn_knr_pk, trn_wloc_op, trn_wexp_op, trn_pnr_op, trn_knr_op}

    // an array of trip tables
    trntrip={trn_obtrips, trn_obtrips, trn_obtrips, trn_obtrips, trn_obtrips, trn_obtrips, trn_obtrips, trn_obtrips}
    
    // an array of core names
    trnname={"Peak Walk Local", "Peak Walk Express", "Peak PNR", "Peak KNR", "Off-Peak Walk Local", "Off-Peak Walk Express", "Off-Peak PNR", "Off-Peak KNR" }
    
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    {rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )   
    
    SetLayer(node_lyr)
    n = SelectByQuery("centroid", "Several","Select * where ID <= "+String(nzones),)

    //4: Local Bus; 5: Limited Bus; 6: Express Bus; 11: Transfer Walk; 12: Walk Access
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
    if !ret_value then goto quit

    // Build OP Network
    Opts.Input.[RS Set] = {rtsfile+"|"+rte_lyr, rte_lyr, "OP Routes", "Select * where MD_Headway>0 & Mode<>null"}
    Opts.Output.[Network File] = trn_op

    ret_value = RunMacro("TCB Run Operation", "Build Transit Network", Opts, &Ret)
    if !ret_value then goto quit

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
    Opts.Global.[Global Dwell Time] = 0.2
    Opts.Global.[Global Headway] = 15
    Opts.Global.[Global Xfer Time] = 10
    Opts.Global.[Global Max IWait] = 60
    Opts.Global.[Global Min IWait] = 2
    Opts.Global.[Global Max XWait] = 60
    Opts.Global.[Global Min XWait] = 2
    Opts.Global.[Global Layover Time] = 3
    Opts.Global.[Global Max WACC Path] = 4
    Opts.Global.[Global Max Access] = 30
    Opts.Global.[Global Max Egress] = 30
    Opts.Global.[Global Max Transfer] = 10
    Opts.Global.[Global Max Imp] = 240
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
    if !ret_value then goto quit

    // Settings for Peak Walk-Express
    CopyFile(trn_wloc_pk, trn_wexp_pk)
    Opts.Input.[Transit Network] = trn_wexp_pk
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".Express_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Express"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

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
    if !ret_value then goto quit

    // Settings for Off-Peak Walk-Express
    CopyFile(trn_wloc_op, trn_wexp_op)
    Opts.Input.[Transit Network] = trn_wexp_op
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Imp Weight] = modes_vw+".Express_Weight"
    Opts.Field.[Mode Used] = modes_vw+".Walk_Express"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

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
    Opts.Field.[Mode Imp Weight] = modes_vw+".FixedGuideway_Weight"
    Opts.Field.[Mode Impedance] = modes_vw+".Mode_PKTime"
    Opts.Field.[Mode Used] = modes_vw+".PNR"
    Opts.Global.[Global Max PACC] = 5
    Opts.Global.[Drive Time Weight] = 3
    Opts.Global.[Max Drive Time] = 30
    Opts.Flag.[Use Park and Ride] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

    // Settings for Peak KNR
    CopyFile(trn_pnr_pk, trn_knr_pk)
    Opts.Input.[Transit Network] = trn_knr_pk
    Opts.Input.[OP Time Currency] = {KNRfile, "PKTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {KNRfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Used] = modes_vw+".KNR"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit

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
    if !ret_value then goto quit

    // Settings for Off-Peak KNR-Local
    CopyFile(trn_pnr_op, trn_knr_op)
    Opts.Input.[Transit Network] = trn_knr_op
    Opts.Input.[OP Time Currency] = {KNRfile, "OPTime", "Orig", "Dest"}
    Opts.Input.[OP Dist Currency] = {KNRfile, "Length", "Orig", "Dest"}
    Opts.Input.[Centroid Set] = {hwyfile+"|"+node_lyr, node_lyr, "centroid"}
    Opts.Field.[Mode Used] = modes_vw+".KNR"
    ret_value = RunMacro("TCB Run Operation", "Transit Network Setting PF", Opts, &Ret)
    if !ret_value then goto quit
    
    dim onOffTables[trnnet.length]
    
    // for every network
    for i = 1 to trnnet.length do
    
        path = SplitPath(trntrip[i])
        tripFileName = path[3]
        path = SplitPath(trnname[i])
        tripCoreName = path[3]
        
        //output file path/names
        outputFlowTable = observedDirectory+"\\outputs\\"+tripFileName+"_"+tripCoreName+"_FLOW.bin"
        outputWalkFlowTable = observedDirectory+"\\outputs\\"+tripFileName+"_"+tripCoreName+"_WLKFLOW.bin"
        outputOnOffTable = observedDirectory+"\\outputs\\"+tripFileName+"_"+tripCoreName+"_ONOFF.bin"
        onOffTables[i] = outputOnOffTable
        
        // assign
        Opts = null
        Opts.Input.[Transit RS] = rtsfile
        Opts.Input.Network = trnnet[i]
        Opts.Input.[OD Matrix Currency] = {trntrip[i], trnname[i], , }
        Opts.Output.[Flow Table] = outputFlowTable
        Opts.Output.[Walk Flow Table] = outputWalkFlowTable
        Opts.Output.[OnOff Table] = outputOnOffTable

        ret_value = RunMacro("TCB Run Procedure", 1, "Transit Assignment PF", Opts)
        if !ret_value then goto quit

    end
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit
    
    ret_value = RunMacro("Collapse OnOffs By Route", onOffTables, hwyfile, rtsfile)
    if !ret_value then goto quit

    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
//*************************************************************
//
// A utility macro that will close all open map windows
//
//*************************************************************
Macro "Close All"
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
/*************************************************************
*
* A macro that will collapse transit on-offs by route and append
* route name.
* 
* Arguments
*   onOffTables     An array of on-off tables
*   hwyfile         A highway line layer
*   rtsfile         A transit route file
*
*************************************************************/
Macro "Collapse OnOffs By Route" (onOffTables, hwyfile, rtsfile)
    
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    {rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )   

    fields = {
        {"On","Sum",},
        {"Off","Sum",},
        {"DriveAccessOn","Sum",},
        {"WalkAccessOn","Sum",},
        {"DirectTransferOn","Sum",},
        {"WalkTransferOn","Sum",},
        {"DirectTransferOff","Sum",},
        {"WalkTransferOff","Sum",},
        {"EgressOff","Sum",}
    }
    
    // for all on off tables
    for i = 1 to onOffTables.length do

        onOffView = OpenTable("OnOffTable", "FFB", {onOffTables[i], null})
        path = SplitPath(onOffTables[i])
        outFile = path[1]+path[2]+path[3]+"_COLL.bin"
        
        fields = GetFields(onOffView, "All")
        
        //include all fields in each table except for STOP and ROUTE
        collFields = null
        for j = 1 to fields[1].length do 
            
            if(fields[1][j] !="STOP" and fields[1][j]!= "ROUTE") then do
            
                collFields = collFields + {{fields[1][j],"Sum",}}
            
            end
       end 
        
        // Collapse stops out of the table by collapsing on ROUTE
        rslt = AggregateTable("CollapsedView", onOffView+"|", "FFB", outFile, "ROUTE", collFields, )

        CloseView(onOffView)
        
        // Join the route layer for route name and other potentially useful data
        onOffCollView = OpenTable("OnOffTableColl", "FFB", {outFile})
        joinedView = JoinViews("OnOffJoin", onOffCollView+".Route", rte_lyr+".Route_ID",)

        // Write the joined data to a binary file
        outJoinFile = path[1]+path[2]+path[3]+"_COLL_JOIN.bin"
        ExportView(joinedView+"|","FFB", outJoinFile , , )
        outJoinFile = path[1]+path[2]+path[3]+"_COLL_JOIN.csv"
        ExportView(joinedView+"|","CSV", outJoinFile , , )
    end

    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
