/*****************************************************************************
*
*  This macro updates the line layer with area type, free-flow speed,
*  congested speed, capacity, and alpha parameter for conical vdf.
*
*****************************************************************************/
Macro "Update Line Layer" (args)
    shared scenarioDirectory

    hwyfile=args[1]
    tazfile=args[2]
    fspdfile=args[3]
    cspdfile=args[4]
    capfile=args[5]
    conicalsfile=args[6]
    trnpkfactfile=args[7]
    trnopfactfile=args[8]
    nzones=args[9]

    POP_fld="POP"
    EMP_fld="TOTALEMP"
    taz_at="ATYPE"
    link_at={"[AB ATYPE]","[BA ATYPE]"}
    ab_lanea="[AB LaneA]"
    ab_lanem="[AB LaneM]"
    ab_lanep="[AB LaneP]"
    ba_lanea="[BA LaneA]"
    ba_lanem="[BA LaneM]"
    ba_lanep="[BA LaneP]"

    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    node_lyr=AddLayer(cc,"Oahu Nodes",hwyfile,"Oahu Nodes")
    link_lyr=AddLayer(cc,"Oahu Links",hwyfile,"Oahu Links")
    taz_lyr=AddLayer(cc,"Oahu TAZs",tazfile,"Oahu TAZs")

    // Kyle: Add the density fields
    NewFlds = {
    	   {"POP_DEN", "integer"},
           {"EMP_DEN", "integer"},
           {"ATYPE", "integer"}
           }
    ret_value = RunMacro("TCB Add View Fields", {taz_lyr, NewFlds})

    // Add cong/skim time and capacity fields
    a_tod = {"EA", "AM", "MD", "PM", "EV"}
    a_hour = {"3HR", "3HR", "6HR", "4HR", "8HR"}
    a_dir = {"AB", "BA"}

    for t = 1 to a_tod.length do
      tod = a_tod[t]
      hour = a_hour[t]

      for d = 1 to a_dir.length do
        dir = a_dir[d]

        a_fields = {
          {dir + "_" + tod + "TIME", "Real", 10, 2,,,, tod + " skim time" },
          {dir + "_CAP_" + tod + hour, "Real", 10, 2,,,, tod + " per cap" }
        }

        RunMacro("Add Fields", link_lyr, a_fields)
      end
    end

    // Add other fields
    a_fields = {
      {"AB_FFTIME", "Real", 10, 2,,,, "forward free-flow time" },
      {"BA_FFTIME", "Real", 10, 2,,,, "reverse free-flow time" },
      {"WALKTIME", "Real", 10, 2,,,, "walk time" },
      {"AB Peak Speed", "Integer", 10, ,,,, "forward speed class" },
      {"BA Peak Speed", "Integer", 10, ,,,, "reverse speed class" },
      {"AB_ALPHA", "Real", 10, 2,,,, "forward alpha" },
      {"BA_ALPHA", "Real", 10, 2,,,, "reverse alpha" }
    }
    RunMacro("Add Fields", link_lyr, a_fields)

    //******************************************** Update Area Type ********************************************

    // Calculate population and employment density for every TAZ
    debug = false

    // read the latitudes and longitudes into an array
    rh = GetFirstRecord(node_lyr+"|", {{"ID","Ascending"}})
    nodedata = GetRecordsValues(node_lyr+"|", rh,{"ID","Longitude","Latitude"},{{"ID","Ascending"}} , nzones, "Column", )
    th = GetFirstRecord(taz_lyr+"|", {{"TAZ","Ascending"}})
    tazdata = GetRecordsValues(taz_lyr+"|", th,{"TAZ","POP","TOTALEMP","AREA"},{{"TAZ","Ascending"}} , nzones, "Column", )

    CreateProgressBar("Calculating area type...", "True")

    radius = 0.5
    if(debug) then AppendToLogFile(0,"TAZ    POP_DEN    EMP_DEN   TOTAREA")

    SetLayer(taz_lyr) //TAZ Layer
    curr_record = GetFirstRecord(taz_lyr+"|", {{"TAZ","Ascending"}})

    // iterate through zones and calculate distance
    for i = 1 to nzones do
        // update status bar
        stat = UpdateProgressBar("", RealToInt(i/nzones*100) )

        totpop = 0.0
        totemp = 0.0
        totarea = 0.0

        for j = 1 to nzones do

            if nodedata[1][i] != i then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                ShowMessage(1)
                return(0)
            end
            if nodedata[1][j] != j then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                ShowMessage(1)
                return(0)
            end

            // store latitude, longitude
            ilat=  nodedata[2][i]
            ilong= nodedata[3][i]
            jlat=  nodedata[2][j]
            jlong= nodedata[3][j]

            loc1 = Coord(ilat, ilong)
            loc2 = Coord(jlat, jlong)
            distance = GetDistance(loc1, loc2)

            if(distance<radius) then do
                totpop = totpop + tazdata[2][j]
                totemp = totemp + tazdata[3][j]
                totarea = totarea + tazdata[4][j]
                if(debug) then do
                    AppendToLogFile(1, String(tazdata[1][j])+"    "+String(distance)+"     "+String(tazdata[2][j]) + "   " + String(tazdata[3][j])+ "     "+String(tazdata[4][j]))
                end
            end
        end
        pop_den = totpop/totarea
        emp_den = totemp/totarea
        if(debug) then AppendToLogFile(0, String(i)+"    "+String(pop_den) + "   " + String(emp_den)+ "     "+String(totarea))
        SetRecordValues(taz_lyr, curr_record, { {"POP_DEN", pop_den}, {"EMP_DEN", emp_den}  })

        curr_record = GetNextrecord(taz_lyr+"|",curr_record ,{{"TAZ","Ascending"}})
   end
   DestroyProgressBar()
    /*
   Opts = null
    Opts.Input.[Dataview Set] = {tazfile+"|"+taz_lyr,taz_lyr}
    Opts.Global.Fields = {"POP_DEN","EMP_DEN"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {POP_fld+"/Area",EMP_fld+"/Area"}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit
*/
    SetLayer(taz_lyr) //TAZ Layer

    //  Create selection sets n1 through n8 of TAZs, based on their population and employment density
    n1 = SelectByQuery("AT1", "Several", "Select * where EMP_DEN>78500",)
    n2 = SelectByQuery("AT2", "Several", "Select * where EMP_DEN>22630 & EMP_DEN<=78500",)
    n3 = SelectByQuery("AT3", "Several", "Select * where POP_DEN>24000 & EMP_DEN<=78500",)
    n4 = SelectByQuery("AT4", "Several", "Select * where (POP_DEN<=4975 & EMP_DEN>1615 & EMP_DEN<=22630) | (POP_DEN<=11588 & EMP_DEN>6202 & EMP_DEN<=22630)",)
    n5 = SelectByQuery("AT5", "Several", "Select * where (POP_DEN>4975 & POP_DEN<=11588 & EMP_DEN<=6202) | (POP_DEN<=24000 & POP_DEN>11588 & EMP_DEN<=22630)",)
    n6 = SelectByQuery("AT6", "Several", "Select * where (POP_DEN<1623 & EMP_DEN>397 & EMP_DEN<=1615) | (POP_DEN<=192 & POP_DEN>0 & EMP_DEN>93 & EMP_DEN<=397)",)
    n7 = SelectByQuery("AT7", "Several", "Select * where (POP_DEN>192 & POP_DEN<=1623 & EMP_DEN<=397) | (POP_DEN<=4975 & POP_DEN>1623 & EMP_DEN<=1615) | (POP_DEN=0 & EMP_DEN>93 & EMP_DEN<=397)",)
    n8 = SelectByQuery("AT8", "Several", "Select * where POP_DEN<=192 & EMP_DEN<=93",)

    // store the selection sets in an array
    n={n1,n2,n3,n4,n5,n6,n7,n8}

    // iterate through the array of area types
    for i=1 to 8 do
    	if n[i]>0 then do   // if there are TAZs in the selection set
    	    Opts = null
    	    // Not sure what the Dataview Set is here; the taz layer but what is AT1->8?
    	    Opts.Input.[Dataview Set] = {tazfile+"|"+taz_lyr, taz_lyr, "AT"+string(i)}
    	    Opts.Global.Fields = {taz_at}                               // the field to fill
    	    Opts.Global.Method = "Value"                                // fill with a single value
    	    Opts.Global.Parameter = {i}                                 // equal to the area type
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    end

    // Code TAZ area type on highway links
    for i=1 to link_at.length do
    	Opts = null
    	Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}    // fill layer is link layer
    	Opts.Input.[Tag View Set] = {tazfile+"|"+taz_lyr, taz_lyr}      // tag layer is TAZs
    	// Opts.Global.Fields = {link_lyr+"."+link_at[i]}                  // the field to fill
    	Opts.Global.Fields = {"["+link_lyr+"]."+link_at[i]}             // the field to fill
    	Opts.Global.Method = "Tag"                                      // fill by tagging
    	Opts.Global.Parameter = {"Value", taz_lyr, "["+taz_lyr+"]."+taz_at}  // the value to fill with is the taz layer area type
    	ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	if !ret_value then do
            // ShowMessage("Coding TAZ area type to highway links failed.")
            // ShowMessage(1)
            goto quit
        end
    end

    DropLayer(cc, taz_lyr)

//******************************* Assign the missing area types as "area type 6" *******************************
    // Create selection set to identify the the links with missing area types:
    SetLayer(link_lyr) //Line Layer
	link_at={"[AB ATYPE]","[BA ATYPE]"}

	SetLayer(link_lyr) //Line Layer
	dir1 = ".Dir"

    // Create selection set to identify the links with missing area types:

    m1 = SelectByQuery("NoATab", "Several", "Select * where " + link_at[1] + "=null",)
    if m1 > 0 then do
        if link_lyr+"|"+Dir1 <> I2S(-1) then do
            Opts = null
            Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr, "NoATab"}
            Opts.Global.Fields = {"[AB ATYPE]"}
            Opts.Global.Method = "Value"
            Opts.Global.Parameter = {"6"}
            ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
            if !ret_value then goto quit
        end
    end
        m2 = SelectByQuery("NoATba", "Several", "Select * where " + link_at[2] + "=null",)
    if m2 >0 then do
        if  link_lyr+"|"+Dir1 <> I2S(1) then do
            Opts = null
            Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr, "NoATba"}
            Opts.Global.Fields = {"[BA ATYPE]"}
            Opts.Global.Method = "Value"
            Opts.Global.Parameter = {"6"}
            ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
            if !ret_value then goto quit
        end
    end

    //******************************* Update FF Speed, Congested Speed and Capacity *******************************

    // Create selection sets based on link area type:
    //
    // n1 through n8 are links where AB area type is 1 through 8 respectively
    // n11 through n18 are links where BA area type is 1 through 8 respectively
    //
    n1 = SelectByQuery("AT1", "Several", "Select * where " + link_at[1] + "=1",)
    n2 = SelectByQuery("AT2", "Several", "Select * where " + link_at[1] + "=2",)
    n3 = SelectByQuery("AT3", "Several", "Select * where " + link_at[1] + "=3",)
    n4 = SelectByQuery("AT4", "Several", "Select * where " + link_at[1] + "=4",)
    n5 = SelectByQuery("AT5", "Several", "Select * where " + link_at[1] + "=5",)
    n6 = SelectByQuery("AT6", "Several", "Select * where " + link_at[1] + "=6",)
    n7 = SelectByQuery("AT7", "Several", "Select * where " + link_at[1] + "=7",)
    n8 = SelectByQuery("AT8", "Several", "Select * where " + link_at[1] + "=8",)
    n11 = SelectByQuery("AT11", "Several", "Select * where " + link_at[2] + "=1",)
    n12 = SelectByQuery("AT12", "Several", "Select * where " + link_at[2] + "=2",)
    n13 = SelectByQuery("AT13", "Several", "Select * where " + link_at[2] + "=3",)
    n14 = SelectByQuery("AT14", "Several", "Select * where " + link_at[2] + "=4",)
    n15 = SelectByQuery("AT15", "Several", "Select * where " + link_at[2] + "=5",)
    n16 = SelectByQuery("AT16", "Several", "Select * where " + link_at[2] + "=6",)
    n17 = SelectByQuery("AT17", "Several", "Select * where " + link_at[2] + "=7",)
    n18 = SelectByQuery("AT18", "Several", "Select * where " + link_at[2] + "=8",)

    // put the selection sets in array n
    n={n1,n2,n3,n4,n5,n6,n7,n8,n9,n10,n11,n12,n13,n14,n15,n16,n17,n18}

    //iterate through area types
    for i=1 to 8 do
        // Calculate AB Speed [AB Speed]
    	if n[i]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the fspdfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, fspdfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvw11_"+string(i), "AT"+string(i)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[AB Speed]"}                           // the field to fill
    	    Opts.Global.Method = "Formula"                                          // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                                // the column in the fspdfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    	// Calculate AB Congested Speed [AB Peak Speed]
    	if n[i]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the cspdfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, cspdfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvw12_"+string(i), "AT"+string(i)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[AB Peak Speed]"}                           // the field to fill
    	    Opts.Global.Method = "Formula"                                          // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                                // the column in the cspdfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    	// Calculate AB Capacity [AB Capacity]
    	if n[i]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the capfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, capfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvw13_"+string(i), "AT"+string(i)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[AB Capacity]"}                        // the field to fill
    	    Opts.Global.Method = "Formula"                                          // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                                // the column in the capfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    	// Calculate BA Speed [BA Speed]
    	if n[i+10]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the fspdfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, fspdfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvw21_"+string(i), "AT"+string(i+10)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[BA Speed]"}                           // the field to fill
    	    Opts.Global.Method = "Formula"                                          // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                                // the column in the fspdfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    	// Calculate BA Congested Speed [BA Peak Speed]
    	if n[i+10]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the cspdfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, cspdfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvw22_"+string(i), "AT"+string(i+10)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[BA Peak Speed]"}                           // the field to fill
    	    Opts.Global.Method = "Formula"                                          // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                                // the column in the cspdfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    	// Calculate BA Capacity [BA Capacity]
    	if n[i+10]>0 then do
    	    Opts = null
    	    // The Dataview Set is a joined view of the link layer and the capfile, based on facility type
    	    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, capfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvw23_"+string(i), "AT"+string(i+10)}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    	    Opts.Global.Fields = {link_lyr+".[BA Capacity]"}                       // the field to fill
    	    Opts.Global.Method = "Formula"                                         // the fill method
    	    Opts.Global.Parameter = {"AT"+string(i)}                               // the column in the capfile
    	    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	    if !ret_value then goto quit
    	end
    end


    //******************************************** Update Congested Time and Period Capacities ********************************************
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"AB_FFTIME","BA_FFTIME","AB_AMTIME","BA_AMTIME","AB_PMTIME","BA_PMTIME",
                          "AB_CAP_EA3HR","BA_CAP_EA3HR","AB_CAP_AM3HR","BA_CAP_AM3HR",
                          "AB_CAP_MD6HR","BA_CAP_MD6HR","AB_CAP_PM4HR","BA_CAP_PM4HR",
                          "AB_CAP_EV8HR","BA_CAP_EV8HR"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"Length / [AB Speed]*60",
                             "Length / [BA Speed]*60",
                             "Length / [AB Peak Speed]*60",
                             "Length / [BA Peak Speed]*60",
                             "Length / [AB Peak Speed]*60",
                             "Length / [BA Peak Speed]*60",
                             "[AB Capacity]* "+ab_lanem+" * 3",
                             "[BA Capacity]* "+ba_lanem+" * 3",
                             "[AB Capacity]* "+ab_lanea+" * 2.5",
                             "[BA Capacity]* "+ba_lanea+" * 2.5",

                             "[AB Capacity]* "+ab_lanem+" * 6",
                             "[BA Capacity]* "+ba_lanem+" * 6",
                             "[AB Capacity]* "+ab_lanep+" * 3.3",
                             "[BA Capacity]* "+ba_lanep+" * 3.3",

                             "[AB Capacity]* "+ab_lanem+" * 8",
                             "[BA Capacity]* "+ba_lanem+" * 8"}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    //******************************************** Update OP Times ********************************************
    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"AB_EATIME","BA_EATIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"AB_FFTIME","BA_FFTIME"}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

     Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"AB_MDTIME","BA_MDTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"AB_FFTIME","BA_FFTIME"}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    Opts = null
    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}
    Opts.Global.Fields = {"AB_EVTIME","BA_EVTIME"}
    Opts.Global.Method = "Formula"
    Opts.Global.Parameter = {"AB_FFTIME","BA_FFTIME"}
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

   //******************************************** Update Alpha Parameter ********************************************
    Opts = null
    // The Dataview Set is a joined view of the link layer and the conical file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, conicalsfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvwALAB"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[AB_ALPHA]"}                       // the field to fill
    Opts.Global.Method = "Formula"                                         // the fill method
    Opts.Global.Parameter = {"Alpha"}                               // the column in the conicalsfile file
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    Opts = null
    // The Dataview Set is a joined view of the link layer and the conical file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, conicalsfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvwALBA"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[BA_ALPHA]"}                       // the field to fill
    Opts.Global.Method = "Formula"                                         // the fill method
    Opts.Global.Parameter = {"Alpha"}                               // the column in the conicals file
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit


    //******************************************** Join Transit Factor ********************************************

    NewFlds = {
    	     {"AB_PKTRNFAC", "real"},
           {"BA_PKTRNFAC", "real"},
           {"AB_OPTRNFAC", "real"},
           {"BA_OPTRNFAC", "real"},
           {"AB_EATRNTIME", "real"},
           {"BA_EATRNTIME", "real"},
           {"AB_AMTRNTIME", "real"},
           {"BA_AMTRNTIME",	"real"},
           {"AB_MDTRNTIME", "real"},
           {"BA_MDTRNTIME", "real"},
           {"AB_PMTRNTIME", "real"},
           {"BA_PMTRNTIME",	"real"},
           {"AB_EVTRNTIME", "real"},
           {"BA_EVTRNTIME",	"real"}
           }

    // add the new fields to the link layer
    ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
    if !ret_value then goto quit

    Opts = null
    // The Dataview Set is a joined view of the link layer and the transit peak time factor file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, trnpkfactfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvw11_1"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[AB_PKTRNFAC]"}                           // the field to fill
    Opts.Global.Method = "Formula"                                          // the fill method
    Opts.Global.Parameter = {"Factor"}                                // the column in the TranPkFact
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    Opts = null
    // The Dataview Set is a joined view of the link layer and the transit peak time factor file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, trnpkfactfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvw11_2"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[BA_PKTRNFAC]"}                           // the field to fill
    Opts.Global.Method = "Formula"                                          // the fill method
    Opts.Global.Parameter = {"Factor"}                                // the column in the TranPkFact
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    Opts = null
    // The Dataview Set is a joined view of the link layer and the transit off-peak time factor file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, trnopfactfile, {"[AB FACTYPE]"}, {"FACTYPE"}}, "joinedvw11_3"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[AB_OPTRNFAC]"}                           // the field to fill
    Opts.Global.Method = "Formula"                                          // the fill method
    Opts.Global.Parameter = {"Factor"}                                // the column in the TranOpFact
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit

    Opts = null
    // The Dataview Set is a joined view of the link layer and the transit off-peak time factor file, based on facility type
    Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, trnopfactfile, {"[BA FACTYPE]"}, {"FACTYPE"}}, "joinedvw11_4"}	//AB facility type/functional Class is not consistent with BA facility type/functional Class
    Opts.Global.Fields = {link_lyr+".[BA_OPTRNFAC]"}                           // the field to fill
    Opts.Global.Method = "Formula"                                          // the fill method
    Opts.Global.Parameter = {"Factor"}                                // the column in the TranOpFact
    ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    if !ret_value then goto quit



    maps = GetMapNames()
    for i = 1 to maps.length do
	CloseMap(maps[i])
    end

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
