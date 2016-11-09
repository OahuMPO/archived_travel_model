/**************************************************************************************************************
* The Setup of the highway network update and skim procedure:
*
* 1. All the input and output files are defined in the beginning of the macro named "Highway Skims".
*
* 2. Before running this script, make sure the highway geographic file has correct values for and consistency
*    between key fields, e.g., facility type, limita/m/p, lanea/m/p for AB and BA directions, etc.
*
* 3. Before using this script, make sure that the input files including the following fields:
*
*    (1) TAZ file: base year:
*       POP                             Total zonal population (input)
*       TOTALEMP		                Total zonal employment (input)
*       AREA                            Total zonal area (input)
*       POP_DEN                         Zonal population density (calculated)
*       EMP_DEN                         Zonal employment density (calculated)
*       ATYPE                           Zonal area type 1-8 (calculated)
*    (2) Link layer:
*       [AB FACTYPE],[BA FACTYPE]       Link facility type (input)
*    	[AB_LIMITA],[BA_LIMITA]         AM Peak period limit field (input)
*    	[AB_LIMITM],[BA_LIMITM]         Midday period limit field (input)
*    	[AB_LIMITP],[BA_LIMITP]         PM Peak period limit field (input)
*       [AB_LANEA],[BA_LANEA]           AM Number of lanes (input)
*       [AB_LANEM],[BA_LANEM]           Midday number of lanes (input)
*       [AB_LANEP],[BA_LANEP]	        PM Number of lanes (input)
*       AB_ATYPE,BA_ATYPE           Link area type 1-8 (calculated based on zone that link is in)
* 	    [AB Speed],[BA Speed]           Free-flow speed (calculated based on fspd file)
*       AB_FFTIME,BA_FFTIME             Free-flow time (calculated)
*		[AB CSPDC],[BA CSPDC]	        Initial congested speed (calculated based on cspd file)
* 	    AB_CTIME, BA_CTIME              Initial congested time (calculated)
* 	    [AB Capacity],[BA Capacity]	    Capacity per lane/per hour (calculated based on capacity file)
* 	    AB_AMCAP,BA_AMCAP               AM peak period capacity (calculated)
*       AB_MDCAP,BA_MDCAP               Midday period capacity (calculated)
*       AB_PMCAP,BA_PMCAP			    PM peak period capacity (calculated)
* 	    AB_PKTIME,BA_PKTIME             AM Peak period congested travel time from highway assignment (calculated from CTIME)
*       AB_OPTIME,BA_OPTIME             Midday period congested travel time from highway assignment	(calculated from FFTIME)
* 	    TOLL1                           Length if GP toll facility (TODO: calculate)
*       TOLL2                           Length if SR2+ toll facility (TODO: calculate)
*       TOLL3							Length if SR3+ toll facility (TODO: calculate)
*
* 4. Highway skim setup:
*    (1) Highway links used in the different skims:
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
*    (2) Skimmed variables:
* 	    Non-Toll Skims:
*           Congested travel time
*           length
*           Initial congested travel time
* 	    Toll Skims
*           Congested travel time
*           length
*           Initial congested travel time
*           TOLL1-3
*           lengths on different toll facilities.
*
*       The variable "iftoll" is used to identify if toll facilities are included and the toll skims are created.
*
**************************************************************************************************************/

Macro "Highway Skims" (scenarioDirectory, hwyfile, tpen, nzones, iftoll)
    // RunMacro("TCB Init")
    shared args

    scenarioDirectory="C:\\projects\\ompo\\conversion\\application\\2005_base"

    //the following files are relative to the scenario directory

    outputDirectory = scenarioDirectory+"\\outputs"

    //check for directory of output network
    if GetDirectoryInfo(outputDirectory, "Directory")=null then do
        CreateDirectory( outputDirectory)
    end

    //add the slash to the output directory
    outputDirectory = outputDirectory+"\\"

    hnetfile=outputDirectory+"hwy.net"

    if iftoll=0 then
    	hskimfile={outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx",
    		   outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_hov2.mtx",outputDirectory+"hwymd_hov3.mtx"}
    else
    	hskimfile={outputDirectory+"hwyam_sovnt.mtx",outputDirectory+"hwyam_hov2nt.mtx",outputDirectory+"hwyam_hov3nt.mtx",
    		   outputDirectory+"hwyam_sovt.mtx",outputDirectory+"hwyam_hov2t.mtx",outputDirectory+"hwyam_hov3t.mtx",
    		   outputDirectory+"hwymd_sovnt.mtx",outputDirectory+"hwymd_hov2nt.mtx",outputDirectory+"hwymd_hov3nt.mtx",
    		   outputDirectory+"hwymd_sovt.mtx",outputDirectory+"hwymd_hov2t.mtx",outputDirectory+"hwymd_hov3t.mtx"}


    ret_value = RunMacro("Highway Skim",hwyfile, hnetfile, hskimfile, tpen, nzones, iftoll)
    if !ret_value then goto quit
    ret_value = RunMacro("Intrazonal Impedance", hskimfile)
    if !ret_value then goto quit
    ret_value = RunMacro("Convert Matrices To Binary", hskimfile)
    if !ret_value then goto quit

    nonmotorized:
    ret_value = RunMacro("Non-Motorized Matrix", scenarioDirectory, hwyfile, nzones)
    if !ret_value then goto quit

    ones:
    ret_value = RunMacro("Ones Matrix", scenarioDirectory, nzones)
    if !ret_value then goto quit

    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
/**********************************************************************************************************************
*
*   Highway Skim
*   Creates peak and off-peak highway skims.
*
*   This macro will create a highway skims for the peak and off-peak time periods.  Skims are described above.
*   Arguments:
*       hwyfile     The highway line layer
*       hnetfile    The highway network
*       hskimfile   An array of skim files (6 for non-toll, 12 for toll, by occupancy)
*       tpen        An array of 3 files: AM turn penalties, Midday turn penalties, linktype turn penalties
*       nzones      Number of TAZs
*       iftoll      0 for no toll skims, 1 for toll skims
*
**********************************************************************************************************************/
Macro "Highway Skim" (hwyfile, hnetfile, hskimfile, tpen, nzones, iftoll)

    linktypeturns = tpen[3]

    ab_limita="[AB_LIMITA]"
    ab_limitm="[AB_LIMITM]"
    ab_limitp="[AB_LIMITP]"
    ba_limita="[BA_LIMITA]"
    ba_limitm="[BA_LIMITM]"
    ba_limitp="[BA_LIMITP]"

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)
    hwy_node_lyr = hwyfile + "|" + node_lyr
    hwy_link_lyr = hwyfile + "|" + link_lyr

    // Link selection for skimming:
    //
    // Limit field:
    //  0 = All vehicles can use
    //  1 = All vehicles can use
    //  2 = No SOV or trucks  (HOV 2+ Lanes)
    //  3 = No SOV, HOV2, or trucks (HOV 3+ Lanes)
    //  6 = No Trucks
    //
    // The selection will result in a set of links that will be disabled in the Highway Network Setting step
    //
    if iftoll=0 then do
        // No toll, 6 sets of skims: AM-SOV, AM-HOV2, AM-HOV3+,
        //                           MD-SOV, MD-HOV2, MD-HOV3+
    	excl_qry={"!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=6 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=6)" +  ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=6 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=6)"  + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=3 | "+ab_limita+"=6 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=3 | "+ba_limita+"=6)" + ")",
		          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=6 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=6)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=6 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=6)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=3 | "+ab_limitm+"=6 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=3 | "+ba_limitm+"=6)" + ")"}
    	// minimizing cost field
    	CostFld = {"*_PKTIME","*_PKTIME","*_PKTIME",
    	           "*_OPTIME","*_OPTIME","*_OPTIME"}
    	skmmode={"SOV AM","HOV2 AM","HOV3 AM",
    	         "SOV MD","HOV2 MD","HOV3 MD"}
    	turns={tpen[1],tpen[1],tpen[1],tpen[2],tpen[2],tpen[2]}
    end
    else do
        // Link selection for skimming:
        // toll, 12 sets of skims: AM SOV-NT, AM HOV-NT, AM HOV3+ NT, AM SOV-TOLL, AM HOV2-TOLL, AM HOV3+ TOLL
        //                         MD SOV-NT, MD HOV-NT, MD HOV3+ NT, MD SOV-TOLL, MD HOV2-TOLL, MD HOV3+ TOLL
    	excl_qry={"!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=6 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=6)" + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=6 | "+ab_limita+"=11 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=6 | "+ba_limita+"=11)" + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=3 | "+ab_limita+"=6 | "+ab_limita+"=11 | "+ab_limita+"=12| "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=3 | "+ba_limita+"=6 | "+ba_limita+"=11 | "+ba_limita+"=12)" + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=6 | "+ab_limita+"=10 | "+ab_limita+"=11 | "+ab_limita+"=12 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=6 | "+ba_limita+"=10 | "+ba_limita+"=11 | "+ba_limita+"=12)" + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=6 | "+ab_limita+"=10 | "+ab_limita+"=11 | "+ab_limita+"=12 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=6 | "+ba_limita+"=10 | "+ba_limita+"=11 | "+ba_limita+"=12)" + ")",
    	          "!(("+ab_limita+"=0 | "+ab_limita+"=1 | "+ab_limita+"=2 | "+ab_limita+"=3 | "+ab_limita+"=6 | "+ab_limita+"=10 | "+ab_limita+"=11 | "+ab_limita+"=12 | "+ba_limita+"=0 | "+ba_limita+"=1 | "+ba_limita+"=2 | "+ba_limita+"=3 | "+ba_limita+"=6 | "+ba_limita+"=10 | "+ba_limita+"=11 | "+ba_limita+"=12)" + ")",
		          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=6 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=6)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=6 | "+ab_limitm+"=11 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=6 | "+ba_limitm+"=11)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=3 | "+ab_limitm+"=6 | "+ab_limitm+"=11 | "+ab_limitm+"=12| "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=3 | "+ba_limitm+"=6 | "+ba_limitm+"=11 | "+ba_limitm+"=12)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=6 | "+ab_limitm+"=10 | "+ab_limitm+"=11 | "+ab_limitm+"=12 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=6 | "+ba_limitm+"=10 | "+ba_limitm+"=11 | "+ba_limitm+"=12)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=6 | "+ab_limitm+"=10 | "+ab_limitm+"=11 | "+ab_limitm+"=12 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=6 | "+ba_limitm+"=10 | "+ba_limitm+"=11 | "+ba_limitm+"=12)" + ")",
    	          "!(("+ab_limitm+"=0 | "+ab_limitm+"=1 | "+ab_limitm+"=2 | "+ab_limitm+"=3 | "+ab_limitm+"=6 | "+ab_limitm+"=10 | "+ab_limitm+"=11 | "+ab_limitm+"=12 | "+ba_limitm+"=0 | "+ba_limitm+"=1 | "+ba_limitm+"=2 | "+ba_limitm+"=3 | "+ba_limitm+"=6 | "+ba_limitm+"=10 | "+ba_limitm+"=11 | "+ba_limitm+"=12)" + ")"}
    	// minimizing cost field
    	CostFld = {"*_PKTIME","*_PKTIME","*_PKTIME","*_PKTIME","*_PKTIME","*_PKTIME",
    	           "*_OPTIME","*_OPTIME","*_OPTIME","*_OPTIME","*_OPTIME","*_OPTIME"}
     	SkimVar = {"TOLL1","TOLL2","TOLL3"}
        SkimVar = {"TOLL1","TOLL2","TOLL3"}
    	skmmode={"SOVNT AM","HOV2NT AM","HOV3NT AM","SOVT AM","HOV2T AM","HOV3T AM",
    	         "SOVNT MD","HOV2NT MD","HOV3NT MD","SOVT MD","HOV2T MD","HOV3T MD"}
    	// array of turn penalty files
    	turns={tpen[1],tpen[1],tpen[1],tpen[1],tpen[1],tpen[1],tpen[2],tpen[2],tpen[2],tpen[2],tpen[2],tpen[2]}

    	dim skimset1[3],skimset2[3]

    	//
    	set = "am tdist1"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limita+"=10 | "+ba_limita+"=10",)
    	if n = 0 then skimset1[1]=null    //reset value if no selection records
    	else skimset1[1]={vw_set, {"Length"}}

    	set = "am tdist2"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limita+"=11 | "+ba_limita+"=11",)
    	if n = 0 then skimset1[2]=null    //reset value if no selection records
    	else skimset1[2]={vw_set, {"Length"}}

    	set = "am tdist3"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limita+"=12 | "+ba_limita+"=12",)
    	if n = 0 then skimset1[3]=null    //reset value if no selection records
    	else skimset1[3]={vw_set, {"Length"}}

    	set = "md tdist1"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limitm+"=10 | "+ba_limitm+"=10",)
    	if n = 0 then skimset2[1]=null    //reset value if no selection records
    	else skimset2[1]={vw_set, {"Length"}}

    	set = "md tdist2"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limitm+"=11 | "+ba_limitm+"=11",)
    	if n = 0 then skimset2[2]=null    //reset value if no selection records
    	else skimset2[2]={vw_set, {"Length"}}

    	set = "md tdist3"
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)
    	n = SelectByQuery(set, "Several","Select * where "+ab_limitm+"=12 | "+ba_limitm+"=12",)
    	if n = 0 then skimset2[3]=null    //reset value if no selection records
    	else skimset2[3]={vw_set, {"Length"}}
    end

    //*************************************************** Highway Network Setting ***************************************************

    // for each set of skims (Time periods * occupancy * toll choice if applicable)
    for i=1 to excl_qry.length do

        // First enable all links, and set the line layer and network properties
    	Opts = null
    	Opts.Input.Database = hwyfile
    	Opts.Input.Network = hnetfile
     	Opts.Input.[Centroids Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+String(nzones)}
     	Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr}
     	Opts.Input.[Spc Turn Pen Table] = {turns[i]}
     	Opts.Input.[Link Type Turn Penalties] = linktypeturns
     	Opts.Flag.[Use Link Types] = "True"
     	Opts.Global.[Global Turn Penalties] = {0, 0, 0, 0}
     	Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
     	Opts.Global.[Update Link Options].Type = "Enable"
     	Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
     	Opts.Global.[Update Network Fields].Formulas = {}
    	ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    	if !ret_value then goto quit

    	set = "exclusivelinks"

    	// vw_set is the toll set
    	vw_set = link_lyr + "|" + set
    	SetLayer(link_lyr)

    	// now create a selection set of the links to disable
    	n = SelectByQuery(set, "Several","Select * where "+excl_qry[i],)

    	// and disable the links that aren't relevant for this mode (occupancy/toll)
    	if n <> 0 then do
    	    Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr, "Selection", "Select * where "+excl_qry[i]}
    	    Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
    	    Opts.Global.[Update Link Options].Type = "Disable"
     	    Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
     	    Opts.Global.[Update Network Fields].Formulas = {}
    	    ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    	    if !ret_value then goto quit
    	end

        //*************************************************** Highway Skim ***************************************************

    	// Set options for TCSPMAT:  Multiple shortest paths
    	Opts = null
    	Opts.Input.Network = hnetfile
    	Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+String(nzones)}
    	Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid"}
    	Opts.Input.[Via Set] = {hwyfile+"|"+node_lyr, node_lyr}
    	Opts.Field.Minimize = CostFld[i]
    	Opts.Field.Nodes = node_lyr+".ID"

	    // always skim length
	    skmfld={{"Length","All"}}

	    // add the other fields to skim, as set above
	    for j=1 to SkimVar.length do
	        skmfld=skmfld+{{SkimVar[j],"All"}}
	    end
        Opts.Field.[Skim Fields]=skmfld


        // If creating toll skims
	    if iftoll<>0 then do
    	    skimsetfld=null
    	    // AM Non-Toll
    	    if (i>=4 & i<=6) then do
    	    	if skimset1[1] <> null then
    	            skimsetfld=skimsetfld+{{skimset1[1]}}
    	    	if skimset1[2] <> null then
    	            skimsetfld=skimsetfld+{{skimset1[2]}}
    	    	if skimset1[3] <> null then
    	            skimsetfld=skimsetfld+{{skimset1[3]}}
    	    end
    	    else if (i>=10 & i<=12) then do
    	    	if skimset2[1] <> null then
    	            skimsetfld=skimsetfld+{{skimset2[1]}}
    	    	if skimset2[2] <> null then
    	            skimsetfld=skimsetfld+{{skimset2[2]}}
    	    	if skimset2[3] <> null then
    	            skimsetfld=skimsetfld+{{skimset2[3]}}
    	    end
    	    Opts.Field.[Skim by Set]=skimsetfld
	    end

    	// final options
    	Opts.Output.[Output Matrix].Label = "congested "+skmmode[i]+" impedance"
    	Opts.Output.[Output Matrix].Compression = 1
    	Opts.Output.[Output Matrix].[File Name] = hskimfile[i]

        // perform the skimming
    	ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    	if !ret_value then goto quit
    end
    RunMacro("Close All")

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
/**********************************************************************************************************************
*
* Create non-motorized distance matrix.
*
* This macro will create a distance matrix based on the distance between XY coordinates of zone centroids.
*
* Arguments:
*    scenarioDirectory      Directory to write file to (file written to scenarioDirectory\outputs)
*    hwyfile                Highway line layer with XY fields for zone coordinates
*    nzones                 Number of TAZs, zones must be sequential starting at 1 through nzones.
*
**********************************************************************************************************************/
Macro "Non-Motorized Matrix" (scenarioDirectory, hwyfile, nzones)

    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    node_lyr=AddLayer(cc,"Oahu Nodes",hwyfile,"Oahu Nodes")

    // create a table for the matrix
    fields = {{"ITAZ","Integer",12,0,},
              {"JTAZ","Integer",12,0,},
              {"Distance","Float",12,2,}  }

    distanceTable = CreateTable("Non-motorized distance", scenarioDirectory+"\\outputs\\nonMotor.bin", "FFB", fields)

    // read the latitudes and longitudes into an array
    rh = GetFirstRecord(node_lyr+"|", {{"ID","Ascending"}})
    latlong = GetRecordsValues(node_lyr+"|", rh,{"ID","Longitude","Latitude"},{{"ID","Ascending"}} , nzones, "Column", )

//    EnableProgressBar("Calculating nonmotorized matrix...", 1)     // Allow only a single progress bar
    CreateProgressBar("Calculating nonmotorized matrix...", "True")

    //storing results in an array
    dim values[nzones,3]

    // iterate through zones and calculate distance
    for i = 1 to nzones do

        // update status bar
        stat = UpdateProgressBar("", RealToInt(i/nzones*100) )
        minDistance = 999.99
        for j = 1 to nzones do

            if latlong[1][i] != i then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                return(0)
            end
            if latlong[1][j] != j then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                return(0)
            end

            // store latitude, longitude
            ilat=  latlong[2][i]
            ilong= latlong[3][i]
            jlat=  latlong[2][j]
            jlong= latlong[3][j]

            x = Abs(ilat - jlat)
			y = Abs(ilong - jlong)

            // calculate right-angle distance
            distance = 0.0
            if x > 0.0 and y > 0.0 then do
                distance = ( x + y ) * 0.000068
            end

            // store minimum distance
            if(distance > 0 and distance< minDistance) then do
                minDistance = distance
            end

            values[j][1]=i
            values[j][2]=j
            values[j][3]=distance

        end

        //intrazonal is 1/2 time to nearest neighbor
        values[i][3]=minDistance*0.5

        // set records for this izone
        record_handle = AddRecords(distanceTable,
                {"ITAZ","JTAZ","Distance"},
                values, )

    end

    DestroyProgressBar()

    m = CreateMatrixFromView(distanceTable, distanceTable+"|", "ITAZ", "JTAZ",
        {"Distance" }, {{ "File Name", scenarioDirectory+"\\outputs\\nonMotor.mtx" }})

    RunMacro("Close All")

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
/*********************************************************************************************************************
*
* Create matrix of 1s for distribution of airport trips (don't ask)
*
* Arguments:
*    scenarioDirectory      Directory to write file to (file written to scenarioDirectory\outputs)
*    nzones                 Number of TAZs, zones must be sequential starting at 1 through nzones.
*
**********************************************************************************************************************/
Macro "Ones Matrix" (scenarioDirectory, nzones)

    fileName = scenarioDirectory+"\\outputs\\ones"+String(nzones)+".mtx"
    Opts=null
    Opts.[File Name] = fileName
    Opts.Label = "Ones"
    Opts.Type = "Float"
    Opts.Tables = {"Ones"}
    Opts.[Column Major] = "No"
    Opts.[File Based] = "Yes"
    Opts.Compression = True

    ones_matrix = CreateMatrixFromScratch("Ones Matrix", nzones,nzones, &Opts)
    ones = CreateMatrixCurrency(ones_matrix, "Ones", , , )
    ones := 1

    matrices = {fileName}
    CreateTableFromMatrix(ones_matrix, scenarioDirectory+"\\outputs\\ones"+String(nzones)+".bin", "FFB", {{"Complete", "Yes"}})

    RunMacro("Close All")

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro

/*****************************************************************************************************************************
*
* Create intrazonal impedances
*
* Arguments:
*    hskimfile      Array of skim files.  Every core in every file will have intrazonal time calculated as 1/2 time to
*                   nearest two neighbors.
*
*****************************************************************************************************************************/
Macro "Intrazonal Impedance" (hskimfile)


    // for each skim file
    for i=1 to hskimfile.length do
    	m=OpenMatrix(hskimfile[i],)
    	mtx_names=getMatrixCoreNames(GetMatrix())

    	// for each matrix in the file
    	for j=1 to mtx_names.length do
    	    Opts = null
    	    Opts.Input.[Matrix Currency] = {hskimfile[i], mtx_names[j], "Origin", "Destination"}
    	    Opts.Global.Factor = 1
    	    Opts.Global.Neighbors = 2
    	    Opts.Global.Operation = 1
    	    Opts.Global.[Treat Missing] = 2
    	    ret_value = RunMacro("TCB Run Procedure", "Intrazonal", Opts, &Ret)
    	    if !ret_value then goto quit
	    end
    end

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
