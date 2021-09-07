/*
Kyle:
Began a partial re-write of this code to speed things up.
The comments below are misleading.  The PNR and KNR do use actual
network skim distances, but the walk link macro has a yes/no toggle
for straight line. It was set to use straight line.  Given that,
there are much faster ways of doing it. The KNR macro also takes
way too long, but does something different.

I have rewritten the Walk portion to be substantially faster.
*/



/*******************************************************************************
* Set Up for Access Link Generations:
* 1. Walk access links:
*    Maximum walk distance 2 miles;
*    Maximum # of walk access links for each centroid is 10.
*    Distances of walk access links are calculated from the shortest walk
*       path, not the direct distance between coords of centroids and stops.
*    Walk network is defined either
* 	(1) by facility type: either AB or BA direction are 2-8 and 12; or
* 	(2) by '*_limita' field: either AB or BA direction are 0,5,6 and 7.
* 	Currently using definition (1).
*    The output walk access links are physically added to the highway network.
*
* 2. Drive access links:
*    KNR access: same setup as walk access links;
* 		 the output KNR access links are represented in matrix format.
*    PNR access: maximum driving distance 5 miles;
*    	  	 maximum # of PNR lots each centroid can access is 3;
*    	  	 the drive network is using AM SOV highway network;
* 		 the output PNR access links are represented in matrix format.
*
* 3. Estimated Transit travel time/speed: now same as highway travel time/speed.
*    The conversion function between highway and transit times/speeds will be
*    implemented when available.
*
* 4. Before running the script, PNR nodes need to be defined in the field "PNR"
*    in the Node Layer.
*
* 5. "Mode_ID": in highway link layer:
*    Mode_ID=11: Transfer walk links, defined either
* 	(1) by facility type: either AB or BA direction are 2-8; or
* 	(2) by '*_limita' field: either AB or BA direction are 0,5,6 and 7.
* 	Currently using definition (1).
*    Mode_ID=12: Walk access links
*
********************************************************************************/

/*
Manual testing macro for transit access links
*/
Macro "test tal"
  scenarioDirectory = "C:\\projects\\Honolulu\\Version6\\OMPORepo\\scenarios\\CMP_2016\\cmp_proj_1"
  hwyfile = scenarioDirectory + "\\inputs\\network\\Scenario Line Layer.dbd"
  rtsfile = scenarioDirectory + "\\inputs\\network\\Scenario Route System.rts"
  nzones = 764
  fixgdwy = 0

  RunMacro("TCB Init")
  RunMacro("Transit Access Links", scenarioDirectory, hwyfile, rtsfile, nzones, fixgdwy)
  ShowMessage("Done")
endMacro

//**********************************************************************************************
//
// This macro creates transit access links
//
//**********************************************************************************************
Macro "Transit Access Links" (scenarioDirectory, hwyfile, rtsfile, nzones,fixgdwy)

    RunMacro("Close All")

    ret_value = RunMacro("Initial Setup",scenarioDirectory, hwyfile, rtsfile,fixgdwy)
    if !ret_value then Throw("Initial setup failed")

    // Kyle - the following three skims from the original script will be used
    ret_value = RunMacro("Walk Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then Throw("Walk time matrix failed")

    ret_value = RunMacro("PNR Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then Throw("PNR time matrix failed")

    ret_value = RunMacro("KNR Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then Throw("KNR Time matrix failed")


    // Realized that the KNR and PNR processes are different.  Leaving them alone.
    // If it is OK to handle them in the same manner, then uncomment the first
    // set of 4 code lines.
    // a_type          = {"Walk","KNR","PNR"}
    // a_maxLinks      = {10,8,4}
    // a_maxRailLinks  = {2,2,8}
    // a_maxLength     = {2,8,}
    a_type          = {"Walk"}
    a_maxLinks      = {10}
    a_maxRailLinks  = {2}
    a_maxLength     = {1}

    for t = 1 to a_type.length do
        type = a_type[t]
        maxLinks = a_maxLinks[t]
        maxRailLinks = a_maxRailLinks[t]        // not used currently
        maxLength = a_maxLength[t]

        // This macro will create walk links based on straight-line distances.
        ret_value = RunMacro("Walk Links",scenarioDirectory, hwyfile, rtsfile,fixgdwy,type,maxLinks,maxLength)
        if !ret_value then do
            ShowMessage("Error connecting " + type + " links.")
            Throw()
        end
    end

    //{maximum number of links, maximum number of KNR to rail links, maximum distance}
    ret_value = RunMacro("KNR Access Link Generation", {8,2,8}, scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then Throw()

    //{maximum number of links, maximum distance}
    ret_value = RunMacro("PNR Access Link Generation", {4,8}, scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then Throw()

    station:
    ret_value = RunMacro("Write Station File",  scenarioDirectory, hwyfile, rtsfile)
    if !ret_value then Throw()

    RunMacro("Close All")

    return(1)



endMacro

/***********************************************************************************************************************************
    Initial Setup
    Initial setup for transit access link generation.  This macro:

    1.  Creates  SP_DIST link field and sets equal to link distance
    2.  Creates WALKTIME link field and sets equal to walking time at 3 MPH
    3.  Creates MODE_ID link field and sets equal to 11 for links that are valid for transfer walk to/from transit (not freeways or ramps)
    4.  Creates AT_TRN node field and sets equal to 1 for nodes that are valid transit stops
    5.  Creates RAIL_STP node field and sets equal to 1 for nodes that are rail stops

***********************************************************************************************************************************/
Macro "Initial Setup" (scenarioDirectory, hwyfile, rtsfile,fixgdwy)

    // RunMacro("TCB Init")

    validlinks="ID>0"
    validtransit="Mode<>null"


    // add the hwyfile, and make the route system refer to it
    baselyrs = GetDBLayers(hwyfile)
    ModifyRouteSystem(rtsfile, {{"Geography", hwyfile, baselyrs[2]}, {"Link ID", "ID"}})

    // create a map and add the route system layer to it, change some display settings
    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    lyrs=AddRouteSystemLayer(cc, "Route System", rtsfile,{})
    RunMacro("Set Default RS Style", lyrs, "True", "True")
    if getlayervisibility(lyrs[5])= "Off" then SetLayerVisibility(lyrs[5], "True")
    SetLayerVisibility(lyrs[4], "True")
    rte_lyr = lyrs[1]
    stp_lyr = lyrs[2]
    node_lyr = lyrs[4]
    link_lyr = lyrs[5]

	  //*********************************Tag Route Stops to Line Layer Nodes*************************************************
    a_fields = {
      {"NODENUMBER", "Integer", 10, ,,,,}
    }
    RunMacro("Add Fields", stp_lyr, a_fields)

   n = TagRouteStopsWithNode(rte_lyr, , "NODENUMBER", .1)
   if n > 0 then Throw(String(n) + " stops not tagged with node ID")



    //********************* Set up a Node field that corresponds to transit stops and a link field for shortest path *********************

    // new link fields for transit in-vehicle times

        NewFlds = {
               {"SP_DIST",	"real"},	// shortest distance between the two endpoints, mainly for walk and drive access links
               {"MODE_ID",	"integer"}}
    // add the new fields to the link layer
    ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})

    // set the link distance to the link length; not sure why this is done?
    //SetDataVector(link_lyr + "|", "SP_DIST", GetDataVector(link_lyr + "|", "LENGTH",),)
    test = GetDataVector(link_lyr + "|", "LENGTH",)
    SetDataVector(link_lyr + "|", "SP_DIST", test,)

    // create a new field called WALKTIME based on walk speed of 3 MPH
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"WALKTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"Length*60/3"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
    if !ret_value then Throw("Fill Dataview Failed")

    // code WALKTIME to 30 seconds for rail access links only if FG in scenario
     if fixgdwy<>0 then do
      	Opts = null
    		Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr, "Selection", "Select * where [Road Name]='Rail Access'"}
   	 		Opts.Global.Fields = {"WALKTIME"}
   	 		Opts.Global.Method = "Value"
   	 		Opts.Global.Parameter = {0.50}
    		ret_value = RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts)
   	 	if !ret_value then Throw("Fill Dataview Failed")
   	 end


    // create a new field called MODE_ID equal to 11 based on facility type,
    // to prohibit walking on freeways, ramps, centroid connectors, HOV lanes, and transit-only links.
    //
    // Facility Type:
    //      1 � Freeways;
    //      2 � Expressways;
    //      3 � Class I arterials;
    //      4 � Class II arterials;
    //      5 � Class III arterials;
    //      6 � Class I collectors;
    //      7 � Class II collectors;
    //      8 � local streets;
    //      9 � High speed Ramps;
    //      10 � Low Speed Ramps;
    //      12 � centroid connectors;
    //      13 � HOV lanes.
    //      14 - Transit-only links

    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr,"transfer walk","Select * where (!([AB FACTYPE]=1 | [AB FACTYPE]=9 | [AB FACTYPE]=10 | [AB FACTYPE]=12 | [AB FACTYPE]=13| [AB FACTYPE]=14) | !([BA FACTYPE]=1 | [BA FACTYPE]=9 | [BA FACTYPE]=10 | [BA FACTYPE]=12 | [BA FACTYPE]=13| [BA FACTYPE]=14))"}
    Opts.Global.Fields = {"MODE_ID"}
    Opts.Global.Method = "Value"
    Opts.Global.Parameter = {11}
    ret_value = RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts)
    if !ret_value then Throw("Fill Dataview Failed")

    // Add a new field AT_TRN to the node layer to indicate if it is a valid transit stop
    NewFlds = {{"AT_TRN","integer"}}
    ret_value = RunMacro("TCB Add View Fields", {node_lyr, NewFlds})


    //************************Determine the nodes that correspond to transit stops************************

    Setlayer(rte_lyr)

    // Select routes that are valid (all routes with a mode field)
    n = Selectbyquery("BaseTransit", "Several", "Select * where "+validtransit,)

    /**********************************************
    Kyle: rewriting this to fix errors and simplify
    **********************************************/

    // Tag each stop with the node ID it is located on
    TagRouteStopsWithNode(rte_lyr,"BaseTransit","NODENUMBER",.05)

    // Get a unique list of node IDs that are route stops
    SetLayer(stp_lyr)
    qry = "Select * where NODENUMBER <> null"
    SelectByQuery("Selection","Several",qry)
    v_nodeIDs = GetDataVector(stp_lyr + "|Selection","NODENUMBER",)
    opts = null
    opts.Unique = "True"
    v_uniqNodeIDs = SortVector(v_nodeIDs,opts)

    // Fill AT_TRN in the node layer with 1 if it is a transit stop
    SetLayer(node_lyr)
    for i = 1 to v_uniqNodeIDs.length do
        id = v_uniqNodeIDs[i]
        qry = "Select * where ID = " + String(id)
        n = SelectByQuery("tstops","More",qry)
    end
    opts = null
    opts.Constant = 1
    v_atTrn = Vector(v_uniqNodeIDs.length,"Long",opts)
    SetDataVector(node_lyr + "|tstops","AT_TRN",v_atTrn,)

    RunMacro("Close All")

    Return( 1 )



endMacro




/*
Kyle: Rewriting to make this portion of the model faster
*/
Macro "Walk Links" (scenarioDirectory, hwyfile, rtsfile,fixgdwy,type,maxLinks,maxLength)

    // Create map of route system
    a_info = GetDBInfo(hwyfile)
    scope = a_info[1]
    opts = null
    opts.Scope = scope
    map = CreateMap("map",opts)
    layers = AddRouteSystemLayer(,"Route System",rtsfile,)
    RunMacro("Set Default RS Style", layers, "True", "True")
    {rLyr,sLyr,pLyr,nLyr,lLyr} = layers


    // Create a selection set of target nodes depending on connection type
    SetLayer(nLyr)
    targetNodeSet = "Target Nodes"
    RunMacro("G30 create set",targetNodeSet)  // sets default display settings
    if type = "Walk" then qry = "Select * where AT_TRN = 1"
    if type = "KNR" then qry = "Select * where AT_TRN = 1"
    if type = "PNR" then qry = "Select * where PNR <> null"
    n = SelectByQuery(targetNodeSet,"Several",qry)

    // Create selection set of centroid nodes
    SetLayer(nLyr)
    centroidSet = "Centroids"
    RunMacro("G30 create set",centroidSet)
    centQry = "Select * where [Zone Centroid] = 'Y'"
    n = SelectByQuery(centroidSet,"Several",centQry)

    // Add some fields used for tagging during the connection step
    NewFlds = {{"ConnectionLink",	"character"}}
    ret_value = RunMacro("TCB Add View Fields", {lLyr, NewFlds})

    // Connect centroids to stop nodes
    // This setup sometimes causes a fatal error and TC closes
    // Unsure why
    SetLayer(lLyr)
    opts = null
    opts.[Snap Distance] = maxLength                   // max distance (mi)
    opts.Slices = maxLinks                             // max connections
    opts.Link = lLyr + ".ConnectionLink"
    opts.[Tag value] = type
    opts.[Split Links] = "False"
    opts.[Target Nodes] = nLyr + "|" + targetNodeSet
    ConnectCentroid(lLyr,nLyr + "|" + centroidSet,opts)

    // Set the field values of the recently-added links
    linkSet = "Walk Links"
    RunMacro("G30 create set",linkSet)
    qry = "Select * where ConnectionLink = 'Walk'"
    SelectByQuery(linkSet,"Several",qry)

    // Kyle: I'm not sure why the original script sets them up as 1-way, but I
    // have done the same for now.
    if type = "Walk" then do
        a_fieldVals = {{"Dir",1},
                      {"[Road Name]", "Walk Access"},
                      {"[AB_LANEA]",1},
                      // {"[BA_LANEA]",1},
                      {"[AB_LANEM]",1},
                      // {"[BA_LANEM]",1},
                      {"[AB_LANEP]",1},
                      // {"[BA_LANEP]",1},
                      {"[AB Capacity]",9999},
                      // {"[BA Capacity]",9999},
                      {"[AB FACTYPE]", 197},
                      {"[BA FACTYPE]", 197},
                      {"MODE_ID", 12}}
        v_id = GetDataVector(lLyr + "|" + linkSet,"ID",)
        v_length = GetDataVector(lLyr + "|" + linkSet,"Length",)
        for fv = 1 to a_fieldVals.length do
            {field,value} = a_fieldVals[fv]

            type = TypeOf(value)
            if type <> "string" then type = "long"
            opts = null
            opts.Constant = value
            v_value = Vector(v_id.length,type,opts)
            SetDataVector(lLyr + "|" + linkSet,field,v_value,)
        end
        SetDataVector(lLyr + "|" + linkSet,"SP_DIST",v_length,)
        v_walktime = v_length / 3 * 60
        SetDataVector(lLyr + "|" + linkSet,"WALKTIME",v_walktime,)

        // I don't think these are needed, but if errors show up,
        // write some looping code to fill them in.
        // {"[From ID]", wlkacclink[2]},
        // {"[To ID]", wlkacclink[3]},

    end
    CloseMap(map)
    Return(1)
EndMacro




/************************************************************************************************************************************************
    Walk Time Matrix
    This macro:
    1.  Creates a highway network
    2.  Skims the network to compute walk length from every centroid to every node that is a valid transit stop, by minimizing the length field.
    3.  Converts the skim to a binary table.

************************************************************************************************************************************************/
Macro "Walk Time Matrix" (scenarioDirectory, hwyfile, rtsfile, nzones)

    // outputs
    hwynet_wlk=scenarioDirectory+"\\outputs\\highway_wlk.net"
    hskim_wlkdist=scenarioDirectory+"\\outputs\\SP_wlkdist.mtx"
    hbin_wlkdist=scenarioDirectory+"\\outputs\\SP_wlkdist.bin"


    validlinks="ID>0"

    // Add highway and transit layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

    // Build a highway network
    Opts = null
    Opts.Input.[Link Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.[Network Options].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
    Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
    Opts.Global.[Network Options].[Turn Penalties] = "Yes"
    Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
    Opts.Global.[Network Options].[Ignore Link Direction] = "TRUE"
    Opts.Global.[Network Options].[Time Unit] = "Minutes"
    Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}},
     	{"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}},
     	{"*_EATIME", {link_lyr+".AB_EATIME", link_lyr+".BA_EATIME", , , "False"}},
     	{"*_AMTIME", {link_lyr+".AB_AMTIME", link_lyr+".BA_AMTIME", , , "False"}},
    	{"*_MDTIME", {link_lyr+".AB_MDTIME", link_lyr+".BA_MDTIME", , , "False"}},
     	{"*_PMTIME", {link_lyr+".AB_PMTIME", link_lyr+".BA_PMTIME", , , "False"}},
     	{"*_EVTIME", {link_lyr+".AB_EVTIME", link_lyr+".BA_EVTIME", , , "False"}},
    	{"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME", , , "False"}}
        }

    // Opts.Global.[Node Options] = {{"[ID:1]", {node_lyr+".[ID:1]", , }},
    Opts.Global.[Node Options] = {{"[ID]", {node_lyr+".[ID]", , }},
        {"X", {node_lyr+".X", , }},
        {"Y", {node_lyr+".Y", , }},
        {"Original_Node_ID", {node_lyr+".Original_Node_ID", , }},
        {"Original", {node_lyr+".Original", , }},
        {"CCSTYLE", {node_lyr+".CCSTYLE", , }},
     	{"ON", {node_lyr+".ON", , }},
     	{"OFF", {node_lyr+".OFF", , }}}
    Opts.Global.[Length Unit] = "Miles"
    Opts.Global.[Time Unit] = "Minutes"
    Opts.Output.[Network File] = hwynet_wlk

    ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    if !ret_value then Throw("Build highway network failed")

    //************Create shortest path for walking distance between centroid and transit stops************
    StraightLine = 1

    if(StraightLine=0) then do
        //  Highway Network Setting (exclude freeways, ramps, HOV lanes, and transit-only links)
        Opts = null
        Opts.Input.Database = hwyfile
        Opts.Input.Network = hwynet_wlk
        Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr, "Selection", "Select * where (([AB FACTYPE]=1 | [AB FACTYPE]=9 | [AB FACTYPE]=10 | [AB FACTYPE]=13| [AB FACTYPE]=14) & ([BA FACTYPE]=1 | [BA FACTYPE]=9 | [BA FACTYPE]=10 | [BA FACTYPE]=13| [AB FACTYPE]=14)) | !("+ validlinks +")"}
        Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
        Opts.Global.[Update Link Options].Type = "Disable"
        Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}	// need to confirm which variable to use, factype or linktype in the highway file
        Opts.Global.[Update Network Fields].Formulas = {}
        ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
        if !ret_value then Throw("Highway network settings failed")

        // Create a skim of shortest path walk length from origin nodes to valid transit stop nodes; also skim the times on the link
        Opts = null
        Opts.Input.Network = hwynet_wlk
        Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "From", "Select * where ID<="+string(nzones)}
        Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "To", "Select * where AT_TRN=1"}
        Opts.Field.Minimize = "Length"
        Opts.Field.Nodes = node_lyr+".ID"
        Opts.Field.[Skim Fields] = {}
        Opts.Output.[Output Matrix].Label = "SP Walk Path"
        Opts.Output.[Output Matrix].Compression = 1
        Opts.Output.[Output Matrix].[File Name] = hskim_wlkdist

        ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
        if !ret_value then Throw("Skimming failed")

        // Save the skim as a table
        m = OpenMatrix(hskim_wlkdist, "True")
        CreateTableFromMatrix(m,hbin_wlkdist,"FFB",{{"Complete","Yes"}})
        view_name = OpenTable("walk length", "FFB", {hbin_wlkdist,})
        SetView(view_name)
        vw_flds = GetTableStructure(view_name)
        flds_name={"Orig","Dest","Length","EATime","AMTime","MDTime","PMTime","EVTime"}
        for i = 1 to vw_flds.length do
            vw_flds[i] = vw_flds[i] + {vw_flds[i][1]}
            vw_flds[i][1] = flds_name[i]
        end
        ModifyTable(view_name, vw_flds)
        CloseView(view_name)
    end

    //option 2 - code distance straight-line distance matrix
    if(StraightLine=1) then do
        SetLayer(node_lyr)
        nnodes = SelectAll(node_lyr)
        nstops = SelectByQuery ("Stops", "Several", "Select * where AT_TRN=1")
        fields = {  {"Orig","Integer",12,0,},
                    {"Dest","Integer",12,0,},
                    {"Length","Float",12,2,}   }

        distanceTable = CreateTable("Walk Distance", hbin_wlkdist, "FFB", fields)

        // read the latitudes and longitudes into an array
        rh = GetFirstRecord(node_lyr+"|", {{"ID","Ascending"}})
        latlong = GetRecordsValues(node_lyr+"|", rh,{"ID","Longitude","Latitude","AT_TRN"},{{"ID","Ascending"}} , nnodes, "Column", )

        CreateProgressBar("Calculating walk distance matrix...", "True")

        //storing results in an array
        dim values[nstops,3]

        // iterate through zone-stop and calculate distance
        for i = 1 to nzones do

            // update status bar
            stat = UpdateProgressBar("", RealToInt(i/nzones*100) )
            stop=0
            for j = 1 to nnodes do

                if latlong[1][i] != i then do
                    ShowMessage("Error! Node layer out of sequence for TAZs")
                    return(0)
                end

                 if(latlong[4][j] = 1) then do

                    stop=stop+1
                    // store latitude, longitude
                    ilat=  latlong[2][i]
                    ilong= latlong[3][i]
                    jlat=  latlong[2][j]
                    jlong= latlong[3][j]

                    x = Abs(ilat - jlat)
	    		    y = Abs(ilong - jlong)

                    // great circle distance is probably more accurate
                    loc1 = Coord(ilat, ilong)
                    loc2 = Coord(jlat, jlong)
                    distance = GetDistance(loc1, loc2)
/*
                    // calculate right-angle distance
                    distance = 0.0
                    if x > 0.0 and y > 0.0 then do
                        distance = ( x + y ) * 0.000068
                    end
*/
                    values[stop][1]=i              //taz
                    values[stop][2]=latlong[1][j]  //stop id
                    values[stop][3]=distance       //distance
                end
            end
            // set records for this izone
            record_handle = AddRecords(distanceTable,
                    {"Orig","Dest","Length"},
                    values, )

        end

        DestroyProgressBar()

    end


    RunMacro("Close All")

    return(1)


endMacro
/************************************************************************************************************************************************
    KNR Time Matrix
    This macro:
    1.  Creates a highway network
    2.  Skims the network to compute drive length from every centroid to every node that is a valid transit stop, by minimizing the length field.
    3.  Converts the skim to a binary table.

************************************************************************************************************************************************/
Macro "KNR Time Matrix" (scenarioDirectory, hwyfile, rtsfile, nzones)

    // outputs
    hwynet_knr=scenarioDirectory+"\\outputs\\highway_knr.net"
    hskim_knrdist=scenarioDirectory+"\\outputs\\SP_knrdist.mtx"
    hbin_knrdist=scenarioDirectory+"\\outputs\\SP_knrdist.bin"

    validlinks="ID>0"

    // Add highway and transit layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

    // Build a highway network
    Opts = null
    Opts.Input.[Link Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.[Network Options].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
    Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
    Opts.Global.[Network Options].[Turn Penalties] = "Yes"
    Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
    Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
    Opts.Global.[Network Options].[Time Unit] = "Minutes"
    Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}},
      	{"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}},
      	{"*_EATIME", {link_lyr+".AB_EATIME", link_lyr+".BA_EATIME", , , "False"}},
      	{"*_AMTIME", {link_lyr+".AB_AMTIME", link_lyr+".BA_AMTIME", , , "False"}},
      	{"*_MDTIME", {link_lyr+".AB_MDTIME", link_lyr+".BA_MDTIME", , , "False"}},
      	{"*_PMTIME", {link_lyr+".AB_PMTIME", link_lyr+".BA_PMTIME", , , "False"}},
      	{"*_EVTIME", {link_lyr+".AB_EVTIME", link_lyr+".BA_EVTIME", , , "False"}},
     	 {"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME", , , "False"}}
        }

    // Opts.Global.[Node Options] = {{"[ID:1]", {node_lyr+".[ID:1]", , }},
    Opts.Global.[Node Options] = {{"[ID]", {node_lyr+".[ID]", , }},
        {"X", {node_lyr+".X", , }},
        {"Y", {node_lyr+".Y", , }},
        {"Original_Node_ID", {node_lyr+".Original_Node_ID", , }},
        {"Original", {node_lyr+".Original", , }},
        {"CCSTYLE", {node_lyr+".CCSTYLE", , }},
     	{"ON", {node_lyr+".ON", , }},
     	{"OFF", {node_lyr+".OFF", , }}}
    Opts.Global.[Length Unit] = "Miles"
    Opts.Global.[Time Unit] = "Minutes"
    Opts.Output.[Network File] = hwynet_knr

    ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    if !ret_value then Throw("Build highway network failed")

    //************Create shortest path for driving distance between centroid and transit stops************

    // Create a skim of shortest path drive length from origin nodes to valid transit stop nodes; also skim the auto times by TOD on the link
    Opts = null
    Opts.Input.Network = hwynet_knr
    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "From", "Select * where ID<="+string(nzones)}
    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "To", "Select * where AT_TRN=1"}
    Opts.Field.Minimize = "*_AMTIME"
    Opts.Field.Nodes = node_lyr+".ID"
     Opts.Field.[Skim Fields] = {{"Length", "All"},{"*_EATIME", "All"},{"*_MDTIME", "All"},{"*_PMTIME", "All"},{"*_EVTIME", "All"}}
    Opts.Output.[Output Matrix].Label = "SP KNR Path"
    Opts.Output.[Output Matrix].Compression = 1
    Opts.Output.[Output Matrix].[File Name] = hskim_knrdist

    ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    if !ret_value then Throw("Skimming failed")

    // Save the skim as a table
    m = OpenMatrix(hskim_knrdist, "True")
    CreateTableFromMatrix(m,hbin_knrdist,"FFB",{{"Complete","Yes"}})
    view_name = OpenTable("knr length", "FFB", {hbin_knrdist,})
    SetView(view_name)
    vw_flds = GetTableStructure(view_name)
    flds_name={"Orig","Dest","AMTime","Length","EATime","MDTime","PMTime","EVTime"}
    for i = 1 to vw_flds.length do
        vw_flds[i] = vw_flds[i] + {vw_flds[i][1]}
        vw_flds[i][1] = flds_name[i]
    end
    ModifyTable(view_name, vw_flds)
    CloseView(view_name)

    RunMacro("Close All")

    return(1)


endMacro

/************************************************************************************************************************************************
    PNR Time Matrix
    This macro:
    1.  Creates a highway network
    2.  Skims the network to compute drive length from every centroid to every node that is a valid PNR lot, by minimizing the length field.
    3.  Converts the skim to a binary table.

************************************************************************************************************************************************/
Macro "PNR Time Matrix" (scenarioDirectory, hwyfile, rtsfile, nzones)

    // outputs
    hwynet_pnr=scenarioDirectory+"\\outputs\\highway_pnr.net"
    hskim_pnrdist=scenarioDirectory+"\\outputs\\SP_pnrdist.mtx"
    hbin_pnrdist=scenarioDirectory+"\\outputs\\SP_pnrdist.bin"

    validlinks="ID>0"
    ab_limita="[AB_LIMITA]"
    ba_limita="[BA_LIMITA]"

    // Add the highway and route layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

    // Create a highway network
    Opts = null
    Opts.Input.[Link Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.[Network Options].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
    Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
    Opts.Global.[Network Options].[Turn Penalties] = "Yes"
    Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
    Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
    Opts.Global.[Network Options].[Time Unit] = "Minutes"
    Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}},
     	{"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}},
     	{"*_EATIME", {link_lyr+".AB_EATIME", link_lyr+".BA_EATIME", , , "False"}},
     	{"*_AMTIME", {link_lyr+".AB_AMTIME", link_lyr+".BA_AMTIME", , , "False"}},
     	{"*_MDTIME", {link_lyr+".AB_MDTIME", link_lyr+".BA_MDTIME", , , "False"}},
     	{"*_PMTIME", {link_lyr+".AB_PMTIME", link_lyr+".BA_PMTIME", , , "False"}},
     	{"*_EVTIME", {link_lyr+".AB_EVTIME", link_lyr+".BA_EVTIME", , , "False"}},
     	{"WALKTIME", {link_lyr+".WALKTIME", link_lyr+".WALKTIME", , , "False"}}
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
    Opts.Output.[Network File] = hwynet_pnr

    ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    if !ret_value then Throw("Buld highway network failed")

    //************Create shortest path for driving distance between centroid and PNR lots (Using SOV Non-Toll Path) ************
    Opts = null
    Opts.Input.Database = hwyfile
    Opts.Input.Network = hwynet_pnr
    Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr, "Selection", "Select * where !(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=6 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=6)" + " & " + validlinks + ")"} //using AM SOV network
    Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
    Opts.Global.[Update Link Options].Type = "Disable"
    Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    Opts.Global.[Update Network Fields].Formulas = {}
    ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    if !ret_value then Throw("Highway network settings failed")

    Opts = null
    Opts.Input.Network = hwynet_pnr
    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+string(nzones)}
    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "PNR", "Select * where PNR<> null"}
    Opts.Field.Minimize = "*_AMTIME"
    Opts.Field.Nodes = node_lyr+".ID"
    Opts.Field.[Skim Fields] = {{"Length", "All"},{"*_EATIME", "All"},{"*_MDTIME", "All"},{"*_PMTIME", "All"},{"*_EVTIME", "All"}}
    Opts.Output.[Output Matrix].Label = "SP AM SOV Drive Path"
    Opts.Output.[Output Matrix].Compression = 1
    Opts.Output.[Output Matrix].[File Name] = hskim_pnrdist

    ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    if !ret_value then Throw("Skimming failed")

    // convert matrix to table
    m = OpenMatrix(hskim_pnrdist, "True")
    CreateTableFromMatrix(m,hbin_pnrdist,"FFB",{{"Complete","Yes"}})
    view_name = OpenTable("drive length", "FFB", {hbin_pnrdist,})
    SetView(view_name)
    vw_flds = GetTableStructure(view_name)
    flds_name={"Orig","Dest","AMTime","Length","EATime","MDTime","PMTime","EVTime"}
    for i = 1 to vw_flds.length do
        vw_flds[i] = vw_flds[i] + {vw_flds[i][1]}
        vw_flds[i][1] = flds_name[i]
    end
    ModifyTable(view_name, vw_flds)
    CloseView(view_name)

    RunMacro("Close All")

    return(1)


endMacro



/************************************************************************************************************************************************
    KNR Access Link Generation
        Args:
            1.  Maximum number of links
            2.  Maximum distance
    This macro:
        1.  Opens the centroid-stop table created in the KNR Link Generation macro
        2.  Sorts the table in ascending order by origin and length
        3.  Iterates through records in the table, adding them as records in a view, up to maximum number of links per origin
        4.  Skims the table to create a skim from centroid to KNR node of length, Time by TOD

************************************************************************************************************************************************/

Macro "KNR Access Link Generation" (cond, scenarioDirectory, hwyfile, rtsfile, nzones)

    //inputs
    hbin_knrdist=scenarioDirectory+"\\outputs\\SP_knrdist.bin"

    // outputs
    tempfile3 = scenarioDirectory+"\\outputs\\temp_valid3.bin"
    tempfile4 = scenarioDirectory+"\\outputs\\temp_valid4.bin"
    tempfile5 = scenarioDirectory+"\\outputs\\temp_valid5.bin"
    tempfile6 = scenarioDirectory+"\\outputs\\temp_valid6.bin"
    KNRfile=scenarioDirectory+"\\outputs\\knracc.mtx"

    maxLinks=cond[1]
    maxRailLinks=cond[2]
    maxLength=cond[3]

    //Add the highway, route layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

   // Open the knr to transit stop table in binary format (one record per origin to stop node pair).  Fields include length, time by TOD
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
    ExportView(view_name+"|", "FFB", tempfile4, {"Orig","Dest","Length","Route_ID","EATime","AMTime","MDTime","PMTime","EVTime","Mode"},)
    CloseView(vw_name)

    /* Open the walk-transit temp file file temp_valid4.bin:
        Orig:  Origin TAZ
        Dest:  Node with transit stop
        Length: Distance based on walk path
        EATime: Early AM auto time
        AMTime: AM peak auto time
        MDTime: Midday auto time
        PMTime: PM peak auto time
        EVTime: Evening auto time
        Mode: Mode type
    */
    // view_name = OpenTable("valid knr length", "FFB", {tempfile4,})
    view_name = OpenTable("valid knr", "FFB", {tempfile4,})

    //Iterate through the centroid->KNR nodes, sorted in ascending order by length from origin
    counter=0
    nrec = GetRecordCount(view_name, )
    record = GetFirstRecord(view_name+ "|", {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    numberConnected=0
    railConnected=0
/*
    //
    // Kyle: Rewriting to speed up the process
    //

    // Create an array of attribute information wanted
    a_fields = {"Orig","Dest","Length","Route_ID","EATime","AMTime","MDTime","PMTime","EVTime","Mode"}

    // Get unique list of Origins
    v_allOrigs = GetDataVector(view_name + "|","Orig",)
    opts = null
    opts.Unique = "True"
    v_uniqOrigs = SortVector(v_allOrigs,opts)

    // loop over each unique origin
    CreateProgressBar("Generating KNR links...", "True")
    for o = 1 to v_uniqOrigs.length do
        origin = v_uniqOrigs[o]

        // Update the status bar
        status = UpdateProgressBar("Generating KNR links...", RealToInt(o/v_uniqOrigs.length*100) )
        if status = "True" then do
            ShowMessage("User pressed cancel.  Throwing error.")
            ShowMessage(1)
        end

        // initialize counters
        numSelected = 0
        numRail = 0

        // Select all records for current origin
        SetView(view_name)
        origSet = "current origin"
        SelectByQuery(origSet,"Several","Select * where Orig = " + String(origin))

        // For the current origin, get the column of route IDs in order of
        // distance away. The route IDs are frequently repeated, so only
        // process the first occurence.
        opts = null
        opts.[Sort Order] = {{"Length", "Ascending"}}
        v_allRouteIDs = GetDataVector(view_name + "|" + origSet,"Route_ID", opts)
        prev_route_id = ""
        for r = 1 to v_allRouteIDs.length do
            routeID = v_allRouteIDs[r]
            if routeID = prev_route_id then continue

            // Select all records for current origin and route id (use "Source And" to reduce search space for speed)
            oNrSet = "current origin and route"
            // SelectByQuery(oNrSet,"Several","Select * where Orig = " + String(origin) + " and Route_ID = " + String(routeID))
            opts = null
            opts.[Source And] = origSet
            SelectByQuery(oNrSet,"Several","Select * where Route_ID = " + String(routeID),opts)

            // Get data for all records with the same origin and route and store in data array
            data = null
            opts = null
            opts.[Sort Order] = {{"Length", "Ascending"}}
            a_data = GetDataVectors(view_name + "|" + oNrSet,a_fields,opts)
            for i = 1 to a_fields.length do
                data.(a_fields[i]) = a_data[i]
            end

            // for each row of the orig+route set (which moves from shortest distance to longest),
            // find the first/nearest suitable KNR node.
            for onr = 1 to data.Orig.length do

                // check to make sure that, if the current record is rail, that the max rail connections
                // haven't been made.
                if (data.Mode = 7 and numRail < maxRailLinks) or data.Mode <> 7 then do
                    // fill the result array with the record data
                    for i = 1 to a_fields.length do
                        temp = data.(a_fields[i])       // needed because data.(a_fields[i])[onr] didn't work
                        result.(a_fields[i]) = result.(a_fields[i]) + {temp[onr]}
                    end

                    if data.Mode = 7 then numRail = numRail + 1
                    onr = data.Orig.length + 1                              // stop looping once a suitable record has been found
                end
            end

            prev_route_id = routeID
            numSelected = numSelected + 1
            if numSelected = maxLinks then r = v_allRouteIDs.length + 1    // stop looping once max connections are made
        end
    end
    DestroyProgressBar()

    // Create tempfile6 to hold the results
    a_strct = GetViewStructure(view_name)
    CloseView(view_name)
    tbl6 = CreateTable("tempfile6",tempfile6,"FFB",a_strct)
    view_name = OpenTable("valid", "FFB", {tempfile6,})
    opts = null
    opts.[Empty Records] = result.(a_fields[1]).length
    AddRecords(view_name,,,opts)

    // Convert the data subarrays of 'result' into vectors for SetDataVectors()
    for f = 1 to a_fields.length do
        result.(a_fields[f]) = A2V(result.(a_fields[f]))
    end

    // Set Values
    SetDataVectors(view_name + "|",result,)
*/



//  Iterate through the zone -> stop list
//  EnableProgressBar("Generating KNR links...", 1)     // Allow only a single progress bar
    CreateProgressBar("Generating KNR links...", "True")

// Kyle: this while loop iterates over 2+ million records to remove the travel times
// from ~90% of the records.

    while record<>null do
        counter = counter + 1

        // update status bar
        stat = UpdateProgressBar("Generating KNR links...", RealToInt(counter/nrec*100) )

    	rec_vals = GetRecordValues(view_name, record, {"Orig", "Dest", "Length", "Route_ID","EATime","AMTime","MDTime","PMTime","EVTime","Mode"})

        //If first stop for this origin, reset numberConnected
        if numberConnected<>0 then do
	    	    if (rec_vals[1][2]<>org) then do
	    	        numberConnected=0
	    	        railConnected=0
	    	    end
      	end

    	//If not first stop for this origin, and numberConnected less than maxLinks, and this route hasn't been added to rout array, add it to the array
        if numberConnected<>0 then do
            // If the number connected is less than maximum link
           if ((numberConnected<maxLinks) or (railConnected<maxRailLinks)) then do
               //If the route hasn't been added to the rout array yet
               if ((ArrayPosition(rout,{rec_vals[4][2]},) = 0) or rec_vals[5][2]=7) then do
    	       	    rout=rout+{rec_vals[4][2]}

    	       	    //If this is a new KNR node, increase the numberConnected counter
    	       	    if (rec_vals[2][2]<>dst) then do
    	      	        dst=rec_vals[2][2]
	        	          numberConnected=numberConnected+1
			                if(rec_vals[5][2]=7) then do                // Kyle: this is wrong, mode field is rec_vals[10][2]
			                   railConnected = railConnected + 1
			                end
       	    	    end
             	    else do
             	        //If not a new KNR node, set the times in the centroid->KNR node record to null
		                  SetRecordValues(view_name, record , {{"EATime",null},{"AMTime",null},{"MDTime",null},{"PMTime",null},{"EVTime",null}})
             	    end
               	end
      	    	 else do
          	        //If the route hasn't been added, set the times in the centroid->KNR node record to null
	    	            SetRecordValues(view_name, record , {{"EATime",null},{"AMTime",null},{"MDTime",null},{"PMTime",null},{"EVTime",null}})
               end
       	    end
       	    else do
       	        // If the number connected is not less than the maximum number of links,  set the times in the centroid->KNR node record to null
                SetRecordValues(view_name, record , {{"EATime",null},{"AMTime",null},{"MDTime",null},{"PMTime",null},{"EVTime",null}})
       	    end
        end
	    	// If it is the first link for this KNR node, set the origin, destination, and route array, and increment numberConnected up by one
        else do
	    	    org=rec_vals[1][2]
	    	    dst=rec_vals[2][2]
	    	    rout={rec_vals[4][2]}
		        numberConnected=numberConnected+1
            if(rec_vals[5][2]=7) then do
                railConnected = railConnected + 1
            end
        end
        record = GetNextRecord(view_name+ "|", record, {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    end
    DestroyProgressBar()


    // Select rows from the table where knr time is valid and export to a temp file (temp_valid6.bin)
    SetView(view_name)
    n= SelectByQuery("ValidLink", "Several", "Select * where AMTime != null",)
    ExportView(view_name+"|ValidLink", "FFB", tempfile6,,)
    CloseView(view_name)

    //*********************** Convert to KNR Matrix ***********************
    view_name = OpenTable("valid", "FFB", {tempfile6,})
    SetView(view_name)
    m = CreateMatrixFromView("KNR Matrix", view_name+"|", "Orig", "Dest", {"Length", "EATime", "AMTime", "MDTime", "PMTime", "EVTime"}, {{ "File Name", KNRfile},{ "Sparse", "No"}})

    RunMacro("Close All")
    return(1)


EndMacro

/****************************************************************************************************************
    PNR Access Link Generation
    This macro:
        1.  Opens the SP_pnrdist.bin file, which contains one record per origin/PNR pair, with fields for length, pktime and optime
        2.  Selects links within the maximum drive distance
        3.  Adds links up to the maximum number allowed for each origin zone
        4.  Creates a matrix of length, pktime, and optime for each zone (rows) -> Pnr lot (cols) pair within the maximum distance and maximum number of links

****************************************************************************************************************/
Macro "PNR Access Link Generation" (cond, scenarioDirectory, hwyfile, rtsfile, nzones)

    //inputs
    hbin_pnrdist=scenarioDirectory+"\\outputs\\SP_pnrdist.bin"

    //output
    PNRfile=scenarioDirectory+"\\outputs\\pnracc.mtx"

    maxLinks=cond[1]
    maxLength=cond[2]

    //Add the highway, route layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

    /* Open the SP_pnrdist.bin
        Orig:  Origin TAZ
        Dest:  Node with transit stop
        Length: Distance based on walk path
        EATime: Early AM auto time
        AMTime: AM peak auto time
        MDTime: Midday auto time
        PMTime: PM peak auto time
        EVTime: Evening auto time
    */
    view_name = OpenTable("drive length", "FFB", {hbin_pnrdist,})
    SetView(view_name)

    // Select drive connectors within maximum drive distance
    n= SelectByQuery("ValidDRLength", "Several", "Select * where Length <= "+string(maxLength),)

    // Iterate through records, sorted by origin zone and length
    record = GetFirstRecord(view_name+ "|ValidDRLength", {{"Orig", "Ascending"},{"Length", "Ascending"}})
    numberConnected=0
     counter=0
    nrec = GetRecordCount(view_name, )

//    EnableProgressBar("Generating knr links...", 1)     // Allow only a single progress bar
    CreateProgressBar("Generating pnr links...", "True")
    while record<>null do
        counter = counter + 1

        // update status bar
        stat = UpdateProgressBar("Generating pnr links...", RealToInt(counter/nrec*100) )
    	rec_vals = GetRecordValues(view_name, record, {"Orig", "Dest", "Length", "EATime", "AMTime", "MDTime", "PMTime", "EVTime"})

        if numberConnected<>0 then do

            // If not the first connected, but new origin, reset numberConnected
            if orig<>rec_vals[1][2] then numberConnected=0

            // If numberConnected less than maxLinks, increment up numberConnected
            if numberConnected<maxLinks then do
		        numberConnected=numberConnected+1
            end
            // If numberConnected equal to maxLinks, set the record
            else do
	    	    SetRecordValues(view_name, record , {{"EATime",null},{"AMTime",null},{"MDTime",null},{"PMTime",null},{"EVTime",null}})
            end
        end
        // If numberConnected equals 0, set the origin and increment numberConnected
        else do
            orig=rec_vals[1][2]
	        numberConnected=numberConnected+1
	    end
	    record = GetNextRecord(view_name+ "|ValidDRLength", record, {{"Orig", "Ascending"},{"Length", "Ascending"}})
    end
    DestroyProgressBar()

    // set the links over the max length to 0
    n= SelectByQuery("InValidDRLength", "Several", "Select * where Length > "+string(maxLength),)
    invalidRecords = GetRecords(view_name+ "|InValidDRLength", {{"Sort Order",{{"Orig", "Ascending"}}}} )
	SetRecordsValues(view_name+ "|InValidDRLength", { {"EATime","AMTime","MDTime","PMTime","EVTime"},invalidRecords}, "Value", {null,null,null,null,null},)

    //*********************** Convert to PNR Matrix ***********************
    SetView(view_name)
    m = CreateMatrixFromView("PNR Matrix", view_name+"|", "Orig", "Dest", {"Length", "EATime","AMTime","MDTime","PMTime","EVTime"}, {{ "File Name", PNRfile},{ "Sparse", "No"}})

    RunMacro("Close All")

    return(1)


endMacro

/***************************************************************
*
* A macro to write the station file
*
*
***************************************************************/
Macro "Write Station File" (scenarioDirectory, hwyfile, rtsfile)

   //open the station file
    ptr = OpenFile(scenarioDirectory+"\\outputs\\PNRLots.dat", "w")

    // create a map and add the route system layer to it, change some display settings
    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    lyrs=AddRouteSystemLayer(cc, "Route System", rtsfile,{})

    rte_lyr = lyrs[1]
    stp_lyr = lyrs[2]
    node_lyr = lyrs[4]
    link_lyr = lyrs[5]

    Setlayer(node_lyr)

    // Select PNR Lots
    n = Selectbyquery("PNRLots", "Several", "Select * where PNR=1",)

    // Iterate through the lots and write out data
    PNRLot = GetFirstRecord(node_lyr + "|PNRLots", null)
     while PNRLot <> null do

        nodeNumber = IntToString(node_lyr.ID)

        //pad the lot number if it has four digits
        if(node_lyr.ID<=9999) then nodeNumber = " "+nodeNumber

        // assume unlimited spaces and no cost
        spaces = " 9999"
        cost   = "    0"
        blank  = "     "
        lotName = node_lyr.[PNR Lot Name]

        writeString = nodeNumber + spaces + blank + cost + blank + blank + lotName

        WriteLine(ptr,writeString )

        PNRLot = GetNextRecord(node_lyr + "|PNRLots", null, null)

     end

    CloseFile(ptr)

    RunMacro("Close All")

    return(1)



EndMacro
