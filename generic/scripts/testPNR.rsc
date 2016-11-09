/************************************************************************************************************************************************
    KNR Access Link Generation
        Args:
            1.  Maximum number of links
            2.  Maximum distance
    This macro:
        1.  Opens the centroid-stop table created in the KNR Link Generation macro
        2.  Sorts the table in ascending order by origin and length
        3.  Iterates through records in the table, adding them as records in a view, up to maximum number of links per origin
        4.  Skims the table to create a skim from centroid to KNR node of length, PKTime and OPTime

************************************************************************************************************************************************/

Macro "KNR Access Link Generation" (cond, scenarioDirectory, hwyfile, rtsfile, nzones)

    cond = {6,8}
    scenarioDirectory = "c:\\projects\\ompo\\conversion\\application\\2005_base"
    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    rtsfile=scenarioDirectory+"\\inputs\\network\\Scenario Route System.rts"
    nzones = 764

    //inputs
    hbin_knrdist=scenarioDirectory+"\\outputs\\SP_knrdist.bin"

    // outputs
    tempfile3 = scenarioDirectory+"\\outputs\\temp_valid3.bin"
    tempfile4 = scenarioDirectory+"\\outputs\\temp_valid4.bin"
    tempfile5 = scenarioDirectory+"\\outputs\\temp_valid5.bin"
    KNRfile=scenarioDirectory+"\\outputs\\knracc.mtx"

    maxLinks=cond[1]
    maxLength=cond[2]

    //Add the highway, route layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

   // Open the knr to transit stop table in binary format (one record per origin to stop node pair).  Fields include length, PKTime and OPTime
    vw_name = OpenTable("knr length", "FFB", {hbin_knrdist,})

    // Select rows from the table where knr distance is over the maximum knr length, and export to a temp file (temp_valid5.bin)
    SetView(vw_name)
    n= SelectByQuery("InValidKRLength", "Several", "Select * where Length >" + string(maxLength),)
    ExportView(vw_name+"|InValidKRLength", "FFB", tempfile5,,)

    // Select rows from the table where knr distance is less than the maximum knr length, and export to a temp file (temp_valid3.bin)
    SetView(vw_name)
    n= SelectByQuery("ValidKRLength", "Several", "Select * where Length <=" + string(maxLength),)
    ExportView(vw_name+"|ValidKRLength", "FFB", tempfile3,,)
    CloseView(vw_name)

    // Open the file of records with centroid and stop node, and join it to the stop layer using the destination (stop node) field, export to a temp file (temp_valid4.bin)
    vw_name = OpenTable("valid knr length", "FFB", {tempfile3,})
    view_name = JoinViews("joined view", vw_name+".Dest", stp_lyr+".NODENUMBER",{{"O",}})
    ExportView(view_name+"|", "FFB", tempfile4, {"Orig","Dest","Length","Route_ID","PKTime","OPTime"},)


    /* Open the walk-transit temp file file temp_valid4.bin:
        Orig:  Origin TAZ
        Dest:  Node with transit stop
        Length: Distance based on walk path
        PKTime: Peak auto time
        OPTime: Off-peak auto time
    */
    view_name = OpenTable("valid knr length", "FFB", {tempfile4,})

    //Iterate through the centroid->KNR nodes, sorted in ascending order by length from origin
    counter=0
    nrec = GetRecordCount(view_name, )
    record = GetFirstRecord(view_name+ "|", {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    numberConnected=0

    // Iterate through the zone -> stop list
//    EnableProgressBar("Generating KNR links...", 1)     // Allow only a single progress bar
    CreateProgressBar("Generating KNR links...", "True")

    while record<>null do
        counter = counter + 1

        // update status bar
        stat = UpdateProgressBar("", RealToInt(counter/nrec*100) )

    	rec_vals = GetRecordValues(view_name, record, {"Orig", "Dest", "Length", "Route_ID","PKTime","OPTime"})

        //If first stop for this origin, reset numberConnected
        if numberConnected<>0 then do
    	    if (rec_vals[1][2]<>org) then do
    	        numberConnected=0
    	    end
    	end

    	//If not first stop for this origin, and numberConnected less than maxLinks, and this route hasn't been added to rout array, add it to the array
        if numberConnected<>0 then do
            // If the number connected is less than maximum links
            if numberConnected<maxLinks then do
                //If the route hasn't been added to the rout array yet
                if (ArrayPosition(rout,{rec_vals[4][2]},) = 0) then do
    	       	    rout=rout+{rec_vals[4][2]}

    	       	    //If this is a new KNR node, increase the numberConnected counter
    	       	    if (rec_vals[2][2]<>dst) then do
    	      	        dst=rec_vals[2][2]
	        	        numberConnected=numberConnected+1
       	    	    end
               	    else do
               	        //If not a new KNR node, set the PKTime and OPTime in the centroid->KNR node record to null
			            SetRecordValues(view_name, record , {{"PKTime",null},{"OPTime",null}})
               	    end
               	end
      	    	else do
          	        //If the route hasn't been added, set the PKTime and OPTime in the centroid->KNR node record to null
	    	        SetRecordValues(view_name, record , {{"PKTime",null},{"OPTime",null}})
               	end
       	    end
       	    else do
       	        // If the number connected is less than the maximum number of links,  set the PKTime and OPTime in the centroid->KNR node record to null
	    	    SetRecordValues(view_name, record , {{"PKTime",null},{"OPTime",null}})
       	    end
    	end
    	// If it is the first link for this KNR node, set the origin, destination, and route array, and increment numberConnected up by one
    	else do
    	    org=rec_vals[1][2]
    	    dst=rec_vals[2][2]
    	    rout={rec_vals[4][2]}
	        numberConnected=numberConnected+1
        end
        record = GetNextRecord(view_name+ "|", record, {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    end
    DestroyProgressBar()

    // set the links over the max length to 0
    invalid_view = OpenTable("invalid knr length", "FFB", {tempfile5,})
    record = GetFirstRecord(invalid_view+ "|", {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    while record<>null do
      	rec_vals = GetRecordValues(invalid_view, record, {"Orig", "Dest"})

        rh = AddRecord(view_name, {
            {"Orig", rec_vals[1][2]},
            {"Dest", rec_vals[2][2]},
            {"PKTime", 0},
            {"OPTime", 0}
            })

        record = GetNextRecord(invalid_view+ "|", record, {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    end

    //*********************** Convert to KNR Matrix ***********************
    SetView(view_name)
    m = CreateMatrixFromView("KNR Matrix", view_name+"|", "Orig", "Dest", {"Length", "PKTime", "OPTime"}, {{ "File Name", KNRfile},{ "Sparse", "No"}})

    RunMacro("Close All")

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro
