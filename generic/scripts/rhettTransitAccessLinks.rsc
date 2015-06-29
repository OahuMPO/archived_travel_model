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
*    implemented when available.  IS THIS STILL TRUE???
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
//**********************************************************************************************
//
// This macro creates transit access links
//
//**********************************************************************************************
Macro "Transit Access Links" (scenarioDirectory, hwyfile, rtsfile, nzones)

    ret_value = RunMacro("Initial Setup",scenarioDirectory, hwyfile, rtsfile)
    if !ret_value then goto quit
    
    ret_value = RunMacro("Walk Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit
    
    ret_value = RunMacro("PNR Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit
    
    ret_value = RunMacro("KNR Time Matrix", scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit

    //{maximum number of links, maximum distance}
    ret_value = RunMacro("Walk Access Link Generation", {10,2}, scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit
    ret_value = RunMacro("KNR Access Link Generation", {6,8}, scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit
    ret_value = RunMacro("PNR Access Link Generation", {4,8}, scenarioDirectory, hwyfile, rtsfile, nzones)
    if !ret_value then goto quit
   
    station:
    ret_value = RunMacro("Write Station File",  scenarioDirectory, hwyfile, rtsfile)
    if !ret_value then goto quit

    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)

    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

/***********************************************************************************************************************************
    Initial Setup
    Initial setup for transit access link generation.  This macro:
    
    1.  Creates  SP_DIST link field and sets equal to link distance
    2.  Creates WALKTIME link field and sets equal to walking time at 3 MPH
    3.  Creates MODE_ID link field and sets equal to 11 for links that are valid for transfer walk to/from transit (not freeways or ramps)
    4.  Creates AT_TRN node field and sets equal to 1 for nodes that are valid transit stops
    
***********************************************************************************************************************************/
Macro "Initial Setup" (scenarioDirectory, hwyfile, rtsfile)

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
	  Opts = null
  
   	Opts.Input.[Dataview Set] = {rtsfile+"|Route Stops", "Route Stops"}  																															//Fill Layer is the Route Stops
   	Opts.Input.[Tag View Set] = {hwyfile+"|Oahu Nodes", "Oahu Nodes"}       																													//Tag with the Node #
   	Opts.Global.Fields = {"[Route Stops].NODENUMBER"}																																									//Put in the field NODENUMBER
   	Opts.Global.Method = "Tag"
   	Opts.Global.Parameter = {"Value", "Oahu Nodes", "[Oahu Nodes].ID"}
 
   ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
 
   if !ret_value then goto quit
    //********************* Set up a Node field that corresponds to transit stops and a link field for shortest path *********************

    // new link fields for transit in-vehicle times
        
        NewFlds = {
               {"SP_DIST",	"real"},	// shortest distance between the two endpoints, mainly for walk and drive access links
               {"MODE_ID",	"integer"}}     
    // add the new fields to the link layer
    ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})

    // set the link distance to the link length; not sure why this is done?
    SetDataVector(link_lyr + "|", "SP_DIST", GetDataVector(link_lyr + "|", "LENGTH",),)

    // create a new field called WALKTIME based on walk speed of 3 MPH
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"WALKTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"Length*60/3"}
    ret_value = RunMacro("TCB Run Operation", 1, "Fill Dataview", Opts)
    if !ret_value then goto quit

    // create a new field called MODE_ID equal to 11 based on facility type,
    // to prohibit walking on freeways, ramps, centroid connectors, HOV lanes, and transit-only links.
    // 
    // Facility Type:
    //      1 – Freeways; 
    //      2 – Expressways; 
    //      3 – Class I arterials; 
    //      4 – Class II arterials; 
    //      5 – Class III arterials; 
    //      6 – Class I collectors; 
    //      7 – Class II collectors; 
    //      8 – local streets;
    //      9 – High speed Ramps; 
    //      10 – Low Speed Ramps; 
    //      12 – centroid connectors; 
    //      13 – HOV lanes.
    //      14 - Transit-only links

    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr,"transfer walk","Select * where (!([AB FACTYPE]=1 | [AB FACTYPE]=9 | [AB FACTYPE]=10 | [AB FACTYPE]=12 | [AB FACTYPE]=13| [AB FACTYPE]=14) | !([BA FACTYPE]=1 | [BA FACTYPE]=9 | [BA FACTYPE]=10 | [BA FACTYPE]=12 | [BA FACTYPE]=13| [BA FACTYPE]=14))"}
    Opts.Global.Fields = {"MODE_ID"}
    Opts.Global.Method = "Value"
    Opts.Global.Parameter = {11}
    ret_value = RunMacro("TCB Run Operation", 2, "Fill Dataview", Opts)
    if !ret_value then goto quit

    // Add a new field AT_TRN to the node layer to indicate if it is a valid transit stop
    NewFlds = {{"AT_TRN","integer"}}     
    ret_value = RunMacro("TCB Add View Fields", {node_lyr, NewFlds})


    //************************Determine the nodes that correspond to transit stops************************

    Setlayer(rte_lyr)
    
    // Select routes that are valid (all routes with a mode field)
    n = Selectbyquery("BaseTransit", "Several", "Select * where "+validtransit,)     
    
    //In the following section all highway nodes that have bus stops associated with them have AT_TRN equal to 1
    //The AT_TRN field is filled one-by-one only because the limitation of the length of query in TransCAD
    if n<>0 then do
    	rec = GetFirstRecord(rte_lyr+"|BaseTransit",{{"Route_ID", "Ascending"}})
    	i =1
        // Iterate through the routes
    	while rec <> null do
    	    // get the route ID, store it in the transit_id array
            rec_vals = GetRecordValues(rte_lyr, rec, {"Route_ID"})
	        if i >1 then do
    		    if ArrayPosition(transit_id,{rec_vals[1][2]},) = 0 then transit_id = transit_id+{rec_vals[1][2]}
    	        end
            else transit_id={rec_vals[1][2]}
    	    i = i+1
    	    rec= GetNextRecord(rte_lyr+"|BaseTransit",rec ,{{"Route_ID", "Ascending"}})
    	end
    
        // set the layer to stops
    	SetLayer(stp_lyr)
    	rec = GetFirstRecord(stp_lyr+"|", {{"NODENUMBER", "Ascending"}}) 
    	i=1
    	
    	//Iterate through transit stops
    	while rec <> null do
            rec_vals = GetRecordValues(stp_lyr, rec, {"Route_ID","NODENUMBER"})
            if ArrayPosition(transit_id,{rec_vals[1][2]},) <> 0 then do
	    	
	    	// get the stop id, add it to the stop_id array
	    	if i >1 then do
            	    if arrayposition(stop_id,{rec_vals[2][2]},) = 0 then do
            	    	stop_id =stop_id+{rec_vals[2][2]}
		    	        
		    	        //set the AT_TRN field to 1 if it has an associated transit stop
    		    	    Opts = null
     		    	    Opts.Input.[Dataview Set] = {hwyfile+"|"+node_lyr, node_lyr, "Selection", "Select * where ID="+string(rec_vals[2][2])}
     		    	    Opts.Global.Fields = {"AT_TRN"}
     		    	    Opts.Global.Method = "Value"
     		   	        Opts.Global.Parameter = {1}
		    	        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     		    	    if !ret_value then goto quit
     	    	    end
    	        end
    	    else do
    	    	stop_id ={rec_vals[2][2]}
		    	//fill the AT_TRN field of the node layer with the stop ID field
    		    Opts = null
     		    Opts.Input.[Dataview Set] = {hwyfile+"|"+node_lyr, node_lyr, "Selection", "Select * where ID="+string(rec_vals[2][2])}
     		    Opts.Global.Fields = {"AT_TRN"}
     		    Opts.Global.Method = "Value"
     		    Opts.Global.Parameter = {1}
		        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
     		    if !ret_value then goto quit
    	        end
    	    end
    	    i = i+1
    	    rec= GetNextrecord(stp_lyr+"|",rec ,{{"NODENUMBER", "Ascending"}})
    	end    
    end
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    Return( 1 )
    
    quit:
         Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

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
     	{"*_PKTIME", {link_lyr+".AB_PKTIME", link_lyr+".BA_PKTIME", , , "False"}}, 
     	{"*_OPTIME", {link_lyr+".AB_OPTIME", link_lyr+".BA_OPTIME", , , "False"}}, 
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
    if !ret_value then goto quit

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
        if !ret_value then goto quit
        
        // Create a skim of shortest path walk length from origin nodes to valid transit stop nodes; also skim the transit time (PK and OP) on the link
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
        if !ret_value then goto quit
        
        // Save the skim as a table
        m = OpenMatrix(hskim_wlkdist, "True")
        CreateTableFromMatrix(m,hbin_wlkdist,"FFB",{{"Complete","Yes"}})
        view_name = OpenTable("walk length", "FFB", {hbin_wlkdist,})
        SetView(view_name)
        vw_flds = GetTableStructure(view_name)
        flds_name={"Orig","Dest","Length","PKTime","OPTime"}
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
        
  //      m = CreateMatrixFromView(distanceTable, distanceTable+"|", "Orig", "Dest",
  //      {"Length","PKTime","OPTime"}, {{ "File Name", hskim_wlkdist+"2" }})
        
    end


    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
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
     	{"*_PKTIME", {link_lyr+".AB_PKTIME", link_lyr+".BA_PKTIME", , , "False"}}, 
     	{"*_OPTIME", {link_lyr+".AB_OPTIME", link_lyr+".BA_OPTIME", , , "False"}}, 
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
    if !ret_value then goto quit

    //************Create shortest path for driving distance between centroid and transit stops************
    
    // Create a skim of shortest path drive length from origin nodes to valid transit stop nodes; also skim the auto time (PK and OP) on the link
    Opts = null
    Opts.Input.Network = hwynet_knr
    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "From", "Select * where ID<="+string(nzones)}
    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "To", "Select * where AT_TRN=1"}
    Opts.Field.Minimize = "Length"
    Opts.Field.Nodes = node_lyr+".ID"
     Opts.Field.[Skim Fields] = {{"*_PKTIME", "All"},{"*_OPTIME", "All"}}
    Opts.Output.[Output Matrix].Label = "SP KNR Path"
    Opts.Output.[Output Matrix].Compression = 1
    Opts.Output.[Output Matrix].[File Name] = hskim_knrdist
    
    ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    if !ret_value then goto quit

    // Save the skim as a table
    m = OpenMatrix(hskim_knrdist, "True")
    CreateTableFromMatrix(m,hbin_knrdist,"FFB",{{"Complete","Yes"}})
    view_name = OpenTable("knr length", "FFB", {hbin_knrdist,})
    SetView(view_name)
    vw_flds = GetTableStructure(view_name)
    flds_name={"Orig","Dest","Length","PKTime","OPTime"}
    for i = 1 to vw_flds.length do
        vw_flds[i] = vw_flds[i] + {vw_flds[i][1]}
        vw_flds[i][1] = flds_name[i]
    end
    ModifyTable(view_name, vw_flds)
    CloseView(view_name)

    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
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
    ab_limita="[AB LIMITA]"
    ba_limita="[AB LIMITA]"

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
     	{"*_PKTIME", {link_lyr+".AB_PKTIME", link_lyr+".BA_PKTIME", , , "False"}}, 
     	{"*_OPTIME", {link_lyr+".AB_OPTIME", link_lyr+".BA_OPTIME", , , "False"}}, 
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
    if !ret_value then goto quit

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
    if !ret_value then goto quit

    Opts = null
    Opts.Input.Network = hwynet_pnr
    Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+string(nzones)}
    Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "PNR", "Select * where PNR<> null"}
    Opts.Field.Minimize = "Length"
    Opts.Field.Nodes = node_lyr+".ID"
    Opts.Field.[Skim Fields] = {{"*_PKTIME", "All"},{"*_OPTIME", "All"}}
    Opts.Output.[Output Matrix].Label = "SP AM SOV Drive Path"
    Opts.Output.[Output Matrix].Compression = 1
    Opts.Output.[Output Matrix].[File Name] = hskim_pnrdist
    
    ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    if !ret_value then goto quit

    // convert matrix to table
    m = OpenMatrix(hskim_pnrdist, "True")
    CreateTableFromMatrix(m,hbin_pnrdist,"FFB",{{"Complete","Yes"}})
    view_name = OpenTable("drive length", "FFB", {hbin_pnrdist,})
    SetView(view_name)
    vw_flds = GetTableStructure(view_name)
    flds_name={"Orig","Dest","Length","PKTime","OPTime"}
    for i = 1 to vw_flds.length do
        vw_flds[i] = vw_flds[i] + {vw_flds[i][1]}
        vw_flds[i][1] = flds_name[i]
    end
    ModifyTable(view_name, vw_flds)
    CloseView(view_name)
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro    

/************************************************************************************************************************************************
    Walk Access Link Generation
        Args:
            1.  Maximum number of links
            2.  Maximum distance
    This macro:
    1.  Selects records from the walk-transit table (one record per origin-stop pair) that are less than the maximum distance
    2.  Joins those records to the transit stop table, sorts the table in ascending length from origin to stops
    2.  Iterates through the joined table, adds walk links to the line layer for each stop up to maximum number of links, from shortest to longest
    4.  Writes out unconnected TAZs to unconn_taz.log

************************************************************************************************************************************************/
Macro "Walk Access Link Generation" (cond, scenarioDirectory, hwyfile, rtsfile, nzones)

    //inputs
    hbin_wlkdist=scenarioDirectory+"\\outputs\\SP_wlkdist.bin"

    // outputs
    tempfile1 = scenarioDirectory+"\\outputs\\temp_valid1.bin"
    tempfile2 = scenarioDirectory+"\\outputs\\temp_valid2.bin"
    
    maxLinks=cond[1]
    maxLength=cond[2]

    ab_lanea="[AB LaneA]"
    ab_lanem="[AB LaneM]"
    ab_lanep="[AB LaneP]"

    //Add the highway, route layers
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    rte_lyr = RunMacro("TCB Add RS Layers", rtsfile, , )           
    stp_lyr = GetStopsLayerFromRS(rte_lyr)

    // Open the walk to transit stop table in binary format (one record per origin to stop node pair).  Fields include length, PKTime and OPTime
    vw_name = OpenTable("walk length", "FFB", {hbin_wlkdist,})

    // Select rows from the table where walk distance is less than the maximum walk length, and export to a temp file (temp_valid1.bin)
    SetView(vw_name)
    n= SelectByQuery("ValidWKLength", "Several", "Select * where Length <=" + string(maxLength),)
    ExportView(vw_name+"|ValidWKLength", "FFB", tempfile1,,)
    CloseView(vw_name) 
    
    // Open the file of records with centroid and stop node, and join it to the stop layer using the destination (stop node) field, export to a temp file (temp_valid2.bin)
    vw_name = OpenTable("valid walk length", "FFB", {tempfile1,})
    view_name = JoinViews("joined view", vw_name+".Dest", stp_lyr+".NODENUMBER",{{"O",}})
    ExportView(view_name+"|", "FFB", tempfile2, {"Orig","Dest","Length","Route_ID"},)

    // Iterate through the zone -> stop list
//    EnableProgressBar("Generating walk links...", 1)     // Allow only a single progress bar
    CreateProgressBar("Generating walk links...", "True")

    connectedtaz=null
    counter=0
    record = GetFirstRecord(view_name+ "|", {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    records = GetRecords(view_name+ "|", {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}}) // can't use GetRecordCount on joined view
    nrec = records.length
    numberConnected=0
    while record<>null do
    
        counter = counter + 1
        
        // update status bar
        stat = UpdateProgressBar("", RealToInt(counter/nrec*100) )

    	rec_vals = GetRecordValues(view_name, record, {"Orig", "Dest", "Length", "Route_ID"})
        
        // reset the numberConnected if new origin
        if numberConnected<>0 then do
    	    if (rec_vals[1][2]<>org) then do
    	        numberConnected=0
    	    end
    	end
        
        // if not first stop for origin, and numberConnected less than maxLinks, and route not in rout array, add destination to rout array
        if numberConnected<>0 then do
            if numberConnected<maxLinks then do
                if (ArrayPosition(rout,{rec_vals[4][2]},) = 0) then do
    	       	    rout=rout+{rec_vals[4][2]}
    	       	    
    	       	    // if a new destination, get the coordinates of the origin and the stop node and add a new walk-access link to the line layer
    	       	    if (rec_vals[2][2]<>dst) then do
    	      	        dst=rec_vals[2][2]
               	        SetLayer(node_lyr)
               	        cencoord = GetPoint(rec_vals[1][2])
	       	            stopcoord = GetPoint(rec_vals[2][2])
               	        SetLayer(link_lyr)
               	        
               	        //add walk access link to highway network
               	        wlkacclink = AddLink({cencoord,stopcoord}, , {{"Snap Node", "True"}, {"Snap Link", "False"}})
              	        Setlayer(link_lyr)
               	        wlkaccrec = ID2RH(wlkacclink[1])    //converts an ID to a record handle
	      	            SetRecordValues(link_lyr, wlkaccrec, {{"SP_DIST",rec_vals[3][2]},
	      	                {"Dir",1},
	      	                {"[Road Name]", "Walk Access"},
	      	                {ab_lanea,1},
	      	                {ab_lanem,1},
	      	                {ab_lanep,1},
	      	                {"[AB Capacity]",9999},
	      	        	    {"[AB FACTYPE]", 197},
	      	        	    {"[BA FACTYPE]", 197},
	      	        	    {"[From ID]", wlkacclink[2]},
	      	        	    {"[To ID]", wlkacclink[3]},
	      	        	    {"WALKTIME", rec_vals[3][2]/3*60},
	      	        	    {"MODE_ID", 12}})
	        	            numberConnected=numberConnected+1
       	    	    end
               	end
       	    end
    	end
    	else do                         // first stop for origin, add destination to rout array
    	    org=rec_vals[1][2]          // get the coordinates of the origin and the stop node and add a new walk-access link to the line layer
    	    dst=rec_vals[2][2]
    	    rout={rec_vals[4][2]}
       	    SetLayer(node_lyr)
       	    cencoord = GetPoint(rec_vals[1][2])
  	        stopcoord = GetPoint(rec_vals[2][2])
       	    SetLayer(link_lyr)
       	    //add walk access link to highway network
       	    wlkacclink = addlink({cencoord,stopcoord}, , {{"Snap Node", "True"}, {"Snap Link", "False"}})
       	    Setlayer(link_lyr)
      	    wlkaccrec = ID2RH(wlkacclink[1])
	        SetRecordValues(link_lyr, wlkaccrec, {{"SP_DIST",rec_vals[3][2]},
	            {"Dir",1},
	            {"[Road Name]", "Walk Access"},
	            {ab_lanea,1},
	            {ab_lanem,1},
	            {ab_lanep,1},
	            {"[AB Capacity]",9999},
	      	    {"[AB FACTYPE]", 197},
	      	    {"[BA FACTYPE]", 197},
	      	    {"[From ID]", wlkacclink[2]},
	      	    {"[To ID]", wlkacclink[3]},
	      	    {"WALKTIME", rec_vals[3][2]/3*60},
	      	    {"MODE_ID", 12}})
	        numberConnected=numberConnected+1
	        connectedtaz=connectedtaz+{org}
        end
        record = GetNextRecord(view_name+ "|", record, {{"Orig", "Ascending"},{"Length", "Ascending"},{"Dest", "Ascending"}})
    end	
    DestroyProgressBar()
   
    //************ For reporting purpose only: non-connected centroids by walk access links ************
    nonconn_cen=null
    SetView(node_lyr)
    
    // get a selection set of all zones
    n= SelectByQuery("centroid", "Several", "Select * where ID <="+string(nzones),)
    
    // Iterate through the set, and if it isn't in the connectedtaz array, add it to the nonconn_cenn array
    orec = GetFirstRecord(node_lyr+"|centroid", {{"ID", "Ascending"}}) 
    while orec <> null do
       	orec_vals = GetRecordValues(node_lyr, orec, {"ID"})
       	if arrayposition(connectedtaz,{orec_vals[1][2]},) = 0 then do
       	    nonconn_cen =nonconn_cen+{orec_vals[1][2]}
       	end
      	orec= GetNextrecord(node_lyr+"|centroid",orec ,{{"ID", "Ascending"}})
    end

    // print the nonconn_cenn array to a log file
    if nonconn_cen<>null then do
    	ptr = OpenFile(scenarioDirectory+"\\reports\\unconn_taz.log", "w")
    	WriteArraySeparated(ptr,nonconn_cen, ",", "\"")
    	closefile(ptr)
    end

    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
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
        4.  Skims the table to create a skim from centroid to KNR node of length, PKTime and OPTime

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

    // Select rows from the table where knr time is valid and export to a temp file (temp_valid6.bin)
    SetView(view_name)
    n= SelectByQuery("ValidLink", "Several", "Select * where PKTime != null",)
    ExportView(view_name+"|ValidLink", "FFB", tempfile6,,)
    CloseView(view_name) 

    //*********************** Convert to KNR Matrix ***********************
    view_name = OpenTable("valid", "FFB", {tempfile6,})
    SetView(view_name)
    m = CreateMatrixFromView("KNR Matrix", view_name+"|", "Orig", "Dest", {"Length", "PKTime", "OPTime"}, {{ "File Name", KNRfile},{ "Sparse", "No"}})
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
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
        PKTime: Peak time (auto)
        OPTime: Offpeak time (auto)
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
        stat = UpdateProgressBar("", RealToInt(counter/nrec*100) )
    	rec_vals = GetRecordValues(view_name, record, {"Orig", "Dest", "Length", "PKTime", "OPTime"})
        
        if numberConnected<>0 then do
    
            // If not the first connected, but new origin, reset numberConnected 
            if orig<>rec_vals[1][2] then numberConnected=0

            // If numberConnected less than maxLinks, increment up numberConnected
            if numberConnected<maxLinks then do
		        numberConnected=numberConnected+1
            end
            // If numberConnected equal to maxLinks, set the record
            else do
	    	    SetRecordValues(view_name, record , {{"PKTime",null},{"OPTime",null}})
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
	SetRecordsValues(view_name+ "|InValidDRLength", { {"PKTime","OPTime"},invalidRecords}, "Value", {0,0},)
    
    //*********************** Convert to PNR Matrix ***********************
    SetView(view_name)
    m = CreateMatrixFromView("PNR Matrix", view_name+"|", "Orig", "Dest", {"Length", "PKTime", "OPTime"}, {{ "File Name", PNRfile},{ "Sparse", "No"}})

    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
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
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
