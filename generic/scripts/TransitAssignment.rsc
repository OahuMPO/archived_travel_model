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
Macro "Transit Assignment" (scenarioDirectory, rtsfile)


		periods = {"EA", "AM", "MD", "PM", "EV"}

		// note - PNR and KNR trips are assigned in home->lot direction (including inbound trips).  Also, KNR network used for PNR-INF trips.
		networks = {"trn_wloc", "trn_wexp", "trn_wfxg", "trn_ptw","trn_ktw","trn_ktw" }

    // an array of core names
    modes={"WLK-LOC", "WLK-EXP", "WLK-GDWY", "PNR-FML", "PNR-INF", "KNR" }

    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"

    dim onOffTables[networks.length * periods.length]

		trnassn = 0

   // for every period
    for period = 1 to periods.length do

        // for every mode
    		for mode = 1 to modes.length do

        	trnassn = trnassn + 1

        	//output file path/names
        	outputFlowTable = scenarioDirectory+"\\outputs\\"+modes[mode]+"_"+periods[period]+"_FLOW.bin"
        	outputWalkFlowTable = scenarioDirectory+"\\outputs\\"+modes[mode]+"_"+periods[period]+"_WLKFLOW.bin"
        	outputOnOffTable = scenarioDirectory+"\\outputs\\"+modes[mode]+"_"+periods[period]+"_ONOFF.bin"
        	outputLinkFlow = scenarioDirectory+"\\outputs\\"+modes[mode]+"_"+periods[period]+"_LINKFLOW.bin"
        	onOffTables[trnassn] = outputOnOffTable

					transitNetwork = scenarioDirectory+"\\outputs\\"+networks[mode]+"_"+periods[period]+".tnw"
					tripTable = scenarioDirectory+"\\outputs\\transit_"+periods[period]+".mtx"

        	// assign
        	Opts = null
        	Opts.Input.[Transit RS] = rtsfile
        	Opts.Input.Network = transitNetwork
        	Opts.Input.[OD Matrix Currency] = {tripTable, modes[mode], , }
        	Opts.Output.[Flow Table] = outputFlowTable
        	Opts.Output.[Walk Flow Table] = outputWalkFlowTable
        	Opts.Output.[OnOff Table] = outputOnOffTable
        	Opts.Output.[Aggre Table] = outputLinkFlow

       	 	ret_value = RunMacro("TCB Run Procedure", 1, "Transit Assignment PF", Opts)
        	if !ret_value then Throw()
    	end
    end

    RunMacro("Close All")

    ret_value = RunMacro("Collapse OnOffs By Route", onOffTables, hwyfile, rtsfile)
    if !ret_value then Throw()

    ret_value = RunMacro("Produce MOA FG table", onOffTables, hwyfile, rtsfile)
    if !ret_value then Throw()


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
    
        
EndMacro
