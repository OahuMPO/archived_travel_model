/***********************************************************************************************************************
*
* Transit Assignment
*
* This macro assigns transit trip tables to transit networks.  The transit networks and trip tables must exist in the
* scenarioDirectory\outputs folder.  Transit network settings assumed set already (for skim-building).
*
* 4/08 - jef - pb
*
* Arguments:
*   scenarioDirectory   Directory of scenario
*   rtsfile             Transit route file
*
**********************************************************************************************************************/
Macro "Transit Assignment Test" (scenarioDirectory, rtsfile)

    RunMacro("TCB Init")

    scenarioDirectory = "F:\\projects\\OMPO\\ORTP2009\\C_Model\\2030MOSJ_setdist_110503"
    rtsfile = scenarioDirectory + "\\inputs\\taz\\Scenario Route System.rts"

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

    trn_pktrips = scenarioDirectory+"\\outputs\\trnPeak.mtx"
    trn_optrips = scenarioDirectory+"\\outputs\\trnOffPeak.mtx"

    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"

    // an array of networks
    trnnet={trn_wloc_pk, trn_wexp_pk, trn_wfxg_pk,  trn_pnr_pk, trn_knr_pk, trn_knr_pk, trn_wloc_op, trn_wexp_op,  trn_wfxg_op, trn_pnr_op, trn_knr_op, trn_knr_op}

    // an array of trip tables
    trntrip={trn_pktrips, trn_pktrips, trn_pktrips, trn_pktrips, trn_pktrips, trn_pktrips, trn_optrips, trn_optrips, trn_optrips, trn_optrips,trn_optrips, trn_optrips}

    // an array of core names
    trnname={"WLK-LOC", "WLK-EXP", "WLK-GDWY", "PNR-FRM", "PNR-INF", "KNR" ,"WLK-LOC", "WLK-EXP", "WLK-GDWY", "PNR-FRM", "PNR-INF", "KNR" }

     dim onOffTables[trnnet.length]

   // for every network
    for i = 1 to trnnet.length do

        path = SplitPath(trntrip[i])
        tripFileName = path[3]
        path = SplitPath(trnname[i])
        tripCoreName = path[3]

        //output file path/names
        outputFlowTable = scenarioDirectory+"\\outputs2\\"+tripFileName+"_"+tripCoreName+"_FLOW.bin"
        outputWalkFlowTable = scenarioDirectory+"\\outputs2\\"+tripFileName+"_"+tripCoreName+"_WLKFLOW.bin"
        outputOnOffTable = scenarioDirectory+"\\outputs2\\"+tripFileName+"_"+tripCoreName+"_ONOFF.bin"
        outputLinkFlow = scenarioDirectory+"\\outputs2\\"+tripFileName+"_"+tripCoreName+"_LINKFLOW.bin"
        onOffTables[i] = outputOnOffTable

        // assign
        Opts = null
        Opts.Input.[Transit RS] = rtsfile
        Opts.Input.Network = trnnet[i]
        Opts.Input.[OD Matrix Currency] = {trntrip[i], trnname[i], , }
        Opts.Output.[Flow Table] = outputFlowTable
        Opts.Output.[Walk Flow Table] = outputWalkFlowTable
        Opts.Output.[OnOff Table] = outputOnOffTable
        Opts.Output.[Aggre Table] = outputLinkFlow

        ret_value = RunMacro("TCB Run Procedure", 1, "Transit Assignment PF", Opts)
        if !ret_value then goto quit
    end

    RunMacro("Close All")

    ret_value = RunMacro("Collapse OnOffs By Route", onOffTables, hwyfile, rtsfile)
    if !ret_value then goto quit

    ret_value = RunMacro("Produce MOA FG table", onOffTables, hwyfile, rtsfile)
    if !ret_value then goto quit


    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

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
/*************************************************************
*
* A macro that will output file necessary to produce MOA report.
* First need to merge node file information to on/off table.
*
* Arguments
*   onOffTables     An array of on-off tables
*   hwyfile         A highway line layer
*   rtsfile         A transit route file
*
*************************************************************/
Macro "Produce MOA FG table" (onOffTables, hwyfile, rtsfile)

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    {rte_lyr,stp_lyr,} = RunMacro("TCB Add RS Layers", rtsfile, "ALL", )
    highway_db=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    LayerInfo = {highway_db + "|" + link_lyr, link_lyr}

   for i = 1 to onOffTables.length do

        onOffView = OpenTable("OnOffTable", "FFB", {onOffTables[i], null})
        path = SplitPath(onOffTables[i])
        outFile = path[1]+path[2]+path[3]+"_MOA.bin"

        // Join the route layer for route name and other potentially useful data
        joinedView = JoinViews("OnOffMOAJoin", onOffView+".Route", rte_lyr+".Route_ID",)
        // Write the joined data to a binary file
        outJoinFile = path[1]+path[2]+path[3]+"_MOA_JOIN.bin"
        ExportView(joinedView+"|","FFB", outJoinFile , , )
        outJoinFile = path[1]+path[2]+path[3]+"_MOA_JOIN.csv"
        ExportView(joinedView+"|","CSV", outJoinFile , , )
    end

    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
