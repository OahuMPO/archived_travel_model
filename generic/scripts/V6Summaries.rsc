
Macro "V6 Summaries" (scenarioDirectory)

  // for testing
  // scenarioDirectory = "C:\\projects\\Honolulu\\Version6\\OMPORepo\\scenarios\\LRTP2040"

  RunMacro("Close All")
  RunMacro("Additional Network Calculations", scenarioDirectory)
  RunMacro("Summarize by FT and AT", scenarioDirectory)
  RunMacro("Emission Estimation", scenarioDirectory)
  RunMacro("V/C Map", scenarioDirectory)
  RunMacro("Trav Time Map", scenarioDirectory)
  RunMacro("Trav Time Map - Zonal", scenarioDirectory)
  RunMacro("Transit Boardings", scenarioDirectory)
  RunMacro("Lane Miles by LOS", scenarioDirectory)
  RunMacro("Trips by Mode", scenarioDirectory)
  RunMacro("Append Skims to Trip Table", scenarioDirectory)
  RunMacro("Detailed Modal Summaries", scenarioDirectory)
  RunMacro("Close All", scenarioDirectory)

  Return(1)

EndMacro

/*
This macro adds extra fields to the loaded network including
delay and daily metrics like slowest speed and max v/c
*/

Macro "Additional Network Calculations" (scenarioDirectory)

  inputDir = scenarioDirectory + "\\inputs"

  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
  {nLyr, lLyr} = GetDBLayers(hwyDBD)
  AddLayerToWorkspace(lLyr, hwyDBD, lLyr)

  a_dir = {"AB", "BA"}
  a_tod = {"EA", "AM", "MD", "PM", "EV"}

  // Speed and V/C daily fields
  a_fields = {
    {"AB_VOC_Max", "Real", 10, 2},
    {"BA_VOC_Max", "Real", 10, 2},
    {"AB_SPD_Min", "Real", 10, 2},
    {"BA_SPD_Min", "Real", 10, 2}
  }
  RunMacro("Add Fields", lLyr, a_fields)

  for d = 1 to a_dir.length do
    dir = a_dir[d]

    for t = 1 to a_tod.length do
      tod = a_tod[t]

      vc_field = dir + "_VOC_" + tod
      spd_field = dir + "_SPD_" + tod

      v_vc = GetDataVector(lLyr + "|", vc_field, )
      v_spd = GetDataVector(lLyr + "|", spd_field, )

      if t = 1 then do
        v_max_vc = v_vc
        v_min_spd = v_spd
      end else do
        v_max_vc = if v_vc > v_max_vc then v_vc else v_max_vc
        v_min_spd = if v_spd < v_min_spd then v_spd else v_min_spd
      end
    end

    SetDataVector(lLyr + "|", dir + "_VOC_Max", v_max_vc, )
    SetDataVector(lLyr + "|", dir + "_SPD_Min", v_min_spd, )
  end

  // Delay fields
  for t = 1 to a_tod.length do
    tod = a_tod[t]

    for d = 1 to a_dir.length do
      dir = a_dir[d]

      field = dir + "_Delay_" + tod
      a_fields = {
        {field, "Real", 10, 2}
      }
      RunMacro("Add Fields", lLyr, a_fields)

      v_time = nz(GetDataVector(lLyr + "|", dir + "_TIME_" + tod, ))
      v_fftime = nz(GetDataVector(lLyr + "|", dir + "_FFTIME", ))
      v_vol = nz(GetDataVector(lLyr + "|", dir + "_FLOW_" + tod, ))
      v_delay = (v_time - v_fftime) * v_vol

      // correct any "negative zero" values (-0.00)
      v_delay = if ( v_delay < .0001 and v_delay > -.0001 )
        then 0
        else v_delay

      SetDataVector(lLyr + "|", field, v_delay, )

      if t = 1
        then TOTAL.(dir) = v_delay
        else TOTAL.(dir) = TOTAL.(dir) + v_delay
    end
  end

  a_fields = {
    {"AB_Delay_Total", "Real", 10, 2},
    {"BA_Delay_Total", "Real", 10, 2}
  }
  RunMacro("Add Fields", lLyr, a_fields)
  SetDataVector(lLyr + "|", "AB_Delay_Total", TOTAL.AB, )
  SetDataVector(lLyr + "|", "BA_Delay_Total", TOTAL.BA, )

EndMacro

/*
  This macro provides additional summaries including:
  VMT/VHT/Delay/SpaceMeanSpeed by facility type and area type
  Congested VMT
*/

Macro "Summarize by FT and AT" (scenarioDirectory)

  CreateProgressBar("",False)
  UpdateProgressBar("Summarizing by FT and AT",0)

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
  vcCutOff = .9   // V/C of .9 is the cut off for a congested link

  // outputs
  outputDir = scenarioDirectory + "\\reports"
  aqCSV = outputDir + "\\VMT and Speeds by FT and AT.csv"

  // looping arrays
  a_dir = {"AB","BA"}
  a_at = {1,2,3,4,5,6,7,8}        //FIELD: [AB/BA ATYPE]
  a_ft = {1,2,3,4,5,6,7,8,9}    //Field: [AB/BA_FNCLASS]
  a_ftname = {"Freeway","Expressway","Principal Arterial","Minor Arterial","Major Collector","Minor Collector","Local","Ramp","CC"}
  a_tod = {"EA","AM","MD","PM","EV"}

  // Add the highway layer to the workspace
  {nlyr,llyr} = GetDBLayers(hwyDBD)
  llyr = AddLayerToWorkspace(llyr,hwyDBD,llyr)

  file = OpenFile(aqCSV,"w")
  WriteLine(file,"AreaType,FClass,VMT,Congested VMT,Percent,VHT,Space-Mean Speed,Delay")

  for a = 1 to a_at.length do
    at = a_at[a]

    for f = 1 to a_ft.length do
      ft = a_ft[f]
      ftname = a_ftname[f]

      vmt = 0
      cvmt = 0
      vht = 0
      sms = 0
      delay = 0

      for d = 1 to a_dir.length do
        dir = a_dir[d]

        // Create a selection set of links in the current AT and FT
        SetLayer(llyr)
        qry = "Select * where " + dir + "_ATYPE = " + String(at) + " and " + dir + "_FNCLASS = " + String(ft)
        n = SelectByQuery("selection","Several",qry)

        // perform calculation if some links are selected
        if n > 0 then do

          for t = 1 to a_tod.length do
            tod = a_tod[t]

            // Collect vector data of all necessary fields
            // v_at = GetDataVector(llyr + "|selection",dir + " ATYPE",)
            // v_ft = GetDataVector(llyr + "|selection",dir + " FNCLASS",)
            v_length = GetDataVector(llyr + "|selection","Length",)
            v_vc = GetDataVector(llyr + "|selection",dir + "_VOC_" + tod,)
            v_spd = GetDataVector(llyr + "|selection",dir + "_SPD_" + tod,)
            v_vol = GetDataVector(llyr + "|selection",dir + "_FLOW_" + tod,)
            v_fftime = GetDataVector(llyr + "|selection",dir + "_FFTIME",)

            // calculate stats
            v_vmt = v_length * v_vol
            vmt = vmt + VectorStatistic(v_vmt,"Sum",)
            v_cvmt = if (v_vc >= vcCutOff) then v_vmt else 0
            cvmt = cvmt + VectorStatistic(v_cvmt,"Sum",)
            v_time = v_length / v_spd
            v_vht = v_time * v_vol
            vht = vht + VectorStatistic(v_vht,"Sum",)
            v_delay = (v_time - v_fftime/60) * v_vol
            delay = delay + VectorStatistic(v_delay,"Sum",)
          end
        end
      end

      if vht = 0 then sms = 0 else sms = vmt / vht
      if vmt = 0 then pct_cvmt = 0 else pct_cvmt = cvmt / vmt * 100

      // Write out results to the file
      string = String(at) + "," + ftname + "," + String(vmt) + "," + String(cvmt)
      string = string + "," + String(pct_cvmt) + "," + String(vht) + "," + String(sms) + "," + String(delay)
      WriteLine(file, string)
    end
  end




  CloseFile(file)
  DropLayerFromWorkspace(llyr)
  DestroyProgressBar()

EndMacro








/*
  This macro estimates grams of CO2 emission
  using some assumed rates and lookup tables.
*/



Macro "Emission Estimation" (scenarioDirectory)

  CreateProgressBar("",False)
  UpdateProgressBar("Emissions Estimation",0)

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
  curveTbl = inputDir + "\\aq\\CurveLookup.csv"
  mpgTbl = inputDir + "\\aq\\MPGbySpeed.csv"
  mJpg = 121          // megajoules per gallon of gas
  autoCO2pmJ  = 93.39 // auto CO2 grams emitted per mega joule
  truckCO2pmJ = 98.22 // truck CO2 grams emitted per mega joule

  // outputs
  outputDir = scenarioDirectory + "\\reports"
  aqCSV = outputDir + "\\Emissions.csv"

  // looping arrays
  a_dir = {"AB","BA"}
  a_at = {1,2,3,4,5,6,7,8}        //FIELD: [AB/BA ATYPE]
  a_ft = {1,2,3,4,5,6,7,8,9}    //Field: [AB/BA_FNCLASS]
  a_ftname = {"Freeway","Expressway","Principal Arterial","Minor Arterial","Major Collector","Minor Collector","Local","Ramp","CC"}
  speedStart = 0      // start at 0
  speedMax = 75      // stop at 75
  speedInc = 5        // and increase by 5  (final upper bound is 80)
  a_tod = {"EA","AM","MD","PM","EV"}

  // Add the highway layer to the workspace
  {nlyr,llyr} = GetDBLayers(hwyDBD)
  llyr = AddLayerToWorkspace(llyr,hwyDBD,llyr)

  // Open the lookup CSVs
  curveTbl = OpenTable("curveTbl","CSV",{curveTbl})
  mpgTbl = OpenTable("mpgTbl","CSV",{mpgTbl})

  file = OpenFile(aqCSV,"w")
  string = "AreaType,FClass,LowerSpeed,UpperSpeed,VMT,AutoVMT,AutoMPG,AutoGallons,AutoCO2(g)"
  string = string + ",TruckVMT,TruckMPG,TruckGallons,TruckCO2(g),TotalCO2(g)"
  WriteLine(file,string)

  for a = 1 to a_at.length do
    at = a_at[a]

    for f = 1 to a_ft.length do
      ft = a_ft[f]
      ftname = a_ftname[f]

      count = nz(count) + 1
      pct = round(count / (a_at.length * a_ft.length) * 100,0)
      UpdateProgressBar("Emission Estimation.  AreaType = " + String(at) + " FacType = " + String(ft),pct)

      for s = speedStart to speedMax step speedInc do
        slower = s              // e.g. 0, 5,10
        supper = s + speedInc   // e.g. 5,10,15

        // collect data from the lookup tables
        num = ft * 100 + at
        rh = LocateRecord(curveTbl + "|","Lookup",{ft * 100 + at},)
        CURVE = GetRecordValues(curveTbl,rh,)
        rh = LocateRecord(mpgTbl + "|","SpeedStart",{slower},)
        MPG = GetRecordValues(mpgTbl,rh,)

        autoMPG = mpgTbl.("MPG_" + String(curveTbl.AutoCurve))
        truckMPG = mpgTbl.("MPG_" + String(curveTbl.TruckCurve))

        // Sum these variables up over direction and TOD
        vmt = 0
        autoVMT = 0
        autoGal = 0
        autoEm = 0
        truckVMT = 0
        truckGal = 0
        truckEm = 0

        for d = 1 to a_dir.length do
          dir = a_dir[d]

          for t = 1 to a_tod.length do
            tod = a_tod[t]

            // Create a selection set of AB or BA links in the current
            // AT, FT, TOD, and speed range
            SetLayer(llyr)
            qry = "Select * where " + dir + "_ATYPE = " + String(at) +
              " and " + dir + "_FNCLASS = " + String(ft) +
              " and " + dir + "_SPD_" + tod + " > " + String(slower) +
              " and " + dir + "_SPD_" + tod + " <= " + String(supper)
            n = SelectByQuery("selection","Several",qry)

            // perform calculation if some links are selected
            if n > 0 then do

              v_length = GetDataVector(llyr + "|selection","Length",)
              v_vol = GetDataVector(llyr + "|selection",dir + "_FLOW_" + tod,)

              // calculate stats
              v_vmt = v_length * v_vol
              subvmt = VectorStatistic(v_vmt,"Sum",)  // VMT for just this combo of dir and TOD
              vmt = vmt + subvmt

              // autoVMT  = autoVMT  + subvmt * (1 - curveTbl.PctTruck)
              // if autoMPG = 0 then autoGal = autoGal + 0 else autoGal  = autoGal  + autoVMT / autoMPG
              // autoEm   = autoEm   + autoGal * mJpg * autoCO2pmJ

              // truckVMT = truckVMT + subvmt * curveTbl.PctTruck
              // if truckMPG = 0 then truckGal = truckGal + 0 else truckGal = truckGal + truckVMT / truckMPG
              // truckEm  = truckEm  + truckGal * mJpg * truckCO2pmJ
            end
          end

          autoVMT  = vmt * (1 - curveTbl.PctTruck)
          if autoMPG = 0 then autoGal = 0 else autoGal  = autoVMT / autoMPG
          autoEm   = autoGal * mJpg * autoCO2pmJ

          truckVMT = vmt * curveTbl.PctTruck
          if truckMPG = 0 then truckGal = 0 else truckGal = truckVMT / truckMPG
          truckEm  = truckGal * mJpg * truckCO2pmJ

        end


        // Write out results to the file
        string = String(at) + "," + ftname + "," + String(slower) + "," + String(supper)
        string = string + "," + String(vmt) + "," + String(autoVMT) + "," + String(autoMPG)
        string = string + "," + String(autoGal) + "," + String(autoEm) + "," + String(truckVMT)
        string = string + "," + String(truckMPG) + "," + String(truckGal) + "," + String(truckEm)
        string = string + "," + String(autoEm + truckEm)
        WriteLine(file, string)
      end
    end
  end

  CloseFile(file)
  DropLayerFromWorkspace(llyr)
  CloseView(curveTbl)
  CloseView(mpgTbl)
  DestroyProgressBar()
EndMacro







Macro "V/C Map" (scenarioDirectory)

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"

  // outputs
  outputDir = scenarioDirectory + "\\reports"
  mapFile = outputDir + "\\AM VoC.map"

  //Create a new, blank map
  {nlyr,llyr} = GetDBLayers(hwyDBD)
  a_info = GetDBInfo(hwyDBD)
  maptitle = "AM V/C"
  map = CreateMap(
    maptitle,{
  	{"Scope",a_info[1]},
  	{"Auto Project","True"}
	})

  //Add highway layer to the map
  llyr = AddLayer(map,llyr,hwyDBD,llyr)
  RunMacro("G30 new layer default settings", llyr)
  SetArrowheads(llyr + "|", "None")
  SetLayer(llyr)

  // Dualized Scaled Symbol Theme (from Caliper Support - not in Help)
	flds = {llyr+".AB_FLOW_AM"}
	opts = null
	opts.Title = "AM Flow"
	// opts.[Data Source] = "Screen"
	opts.[Data Source] = "All"
	//opts.[Minimum Value] = 0
	//opts.[Maximum Value] = 100
	opts.[Minimum Size] = 1
	opts.[Maximum Size] = 10
	theme_name = CreateContinuousTheme("Flows", flds, opts)

	//dual_colors = {ColorRGB(32000,32000,65535)}
  dual_colors = {ColorRGB(65535,65535,65535)} // Set to white to make it disappear in legend
	dual_linestyles = {LineStyle({{{1, -1, 0}}})}                       // without black outlines
	// dual_linestyles = {LineStyle({{{2, -1, 0},{0,0,1},{0,0,-1}}})}   // with black outlines
	//dual_labels = {"AB/BA PM VOL"}
	dual_linesizes = {0}
	SetThemeLineStyles(theme_name , dual_linestyles)
	//SetThemeClassLabels(theme_name , dual_labels)
	SetThemeLineColors(theme_name , dual_colors)
	SetThemeLineWidths(theme_name , dual_linesizes)

	ShowTheme(, theme_name)
	RedrawMap()

  // Apply the color ("c") theme based on the AM V/C
	// Sets up the name of the layer
  numClasses = 4
	cTheme = CreateTheme("AM V/C",llyr+".AB_VOC_AM","Manual",numClasses,{
		{"Values",{
			{0.0,"True",0.6,"False"},
			{0.6,"True",0.75,"False"},
			{0.75,"True",0.9,"False"},
			{0.9,"True",100,"False"}
			}},
		{"Other", "False"}
	})

	line_colors =	{
    ColorRGB(10794, 52428, 17733),
		ColorRGB(63736, 63736, 3084),
		ColorRGB(65535, 32896, 0),
		ColorRGB(65535, 0, 0)
	}
	//solidline = LineStyle({{{1, -1, 0}}})
	dualline = LineStyle({{{2, -1, 0},{0,0,1},{0,0,-1}}})

  for i = 1 to numClasses do
    class_id = llyr +"|" + cTheme + "|" + String(i)
    SetLineStyle(class_id, dualline)
    SetLineColor(class_id, line_colors[i])
    SetLineWidth(class_id, 2)
  end

	// Change the labels of the classes (how the divisions appear in the legend)
	labels = {
    "Congestion Free (VC < .6)",
    "Moderate Traffic (VC .60 to .75)",
    "Heavy Traffic (VC .75 to .90)",
    "Stop and Go (VC > .90)"
  }
	SetThemeClassLabels(cTheme, labels)
	ShowTheme(,cTheme)

    // Hide centroid connectors and transit access links
	SetLayer(llyr)
	ccquery = "Select * where [AB FACTYPE] = 197 or [AB FACTYPE] = 12 "
	n1 = SelectByQuery ("CCs", "Several", ccquery,)

	// Set status to Invisible
	SetDisplayStatus(llyr+"|CCs", "Invisible")

	// Configure Legend
	SetLegendDisplayStatus(llyr+"|", "False")
	RunMacro("G30 create legend", "Theme")
	SetLegendSettings (GetMap(), {"Automatic", {0,1,0,0,1,4,0} , {1,1,1} , {"Arial|Bold|16","Arial|9","Arial|Bold|16","Arial|12"} , {"","AM Period"} })
	str1 = "XXXXXXXX"
	solid = FillStyle({str1, str1, str1, str1, str1, str1, str1, str1})
	SetLegendOptions (GetMap(), {{"Background Style", solid}})

	// Refresh Map Window
	RedrawMap(map)

	// Save map
	SaveMap(map, mapFile)
  CloseMap(map)
EndMacro






/*
Creates Isochrone/Travel Time map
The travel time is for an SOV vehicle, meaning
that it cannot use HOV, zipper, etc.
*/

Macro "Trav Time Map" (scenarioDirectory)

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"

  // outputs
  outputDir = scenarioDirectory + "\\reports"
  mapFile = outputDir + "\\PM Travel Time Bands.map"

  // Create map and get layer names
  map = RunMacro("G30 new map", hwyDBD, "False")
  {nLyr,lLyr} = GetDBLayers(hwyDBD)

  // Create a link set of links that SOV can travel in the PM
  SetLayer(lLyr)
  setname = "sov pm links"
  qry =       "Select * where nz([AB_LIMITP]) not between 2 and 3 and nz([BA_LIMITP]) not between 2 and 3"
  qry = qry + " and (nz([AB_LANEP]) + nz([BA_LANEP])) > 0 and [Road Name] <> 'Walk Access'"
  SelectByQuery(setname, "Several", qry)

  // Create a network
  Flds = null
  Flds.[Set Name] = setname
  Flds.[Network File] = outputDir + "\\travbands.net"
  Flds.Label = null
  //Length must be included in link options
  Flds.[Link Options] = {
    {"Length", {lLyr+".Length", lLyr+".Length",,, "False"}},
    {"PMTime", {lLyr+".AB_TIME_PM", lLyr+".BA_TIME_PM",,, "True"}}
  }
  Flds.[Node Options] = null
  Flds.Options.[Link Type] = null
  Flds.Options.[Link ID] = lLyr+".ID"
  Flds.Options.[Node ID] = nLyr+".ID"
  Flds.Options.[Turn Penalties] = "No"
  Flds.Options.[Keep Duplicate Links] = "FALSE"
  Flds.Options.[Ignore Link Direction] = "FALSE"

  net_h = CreateNetwork(
      Flds.[Set Name],
      Flds.[Network File],
      Flds.Label,
      Flds.[Link Options],
      Flds.[Node Options],
      Flds.Options
      )

  // Select origin node(s)
  SetLayer(nLyr)
  setname = RunMacro("G30 create set", "Origin")
  n = SelectByQuery(setname,"Several","Select * where ID = 265")

  // Create the isochrone
  net_arr = GetNetworkInformation(net_h)
  link_vars = net_arr.[Link Attributes]
  // select origin node
  // generate options for network band
  opts = null
  opts.[Node Layer] = nLyr
  opts.existing_network = 1
  opts.[Band Method] = "Network"
  opts.[Seed Layer Set] = nLyr+"|" + setname
  opts.Network = net_h
  opts.[Cost Min Field] = "PMTime"
  /* From Jim Lam:
  The conversion factor estimates time in areas where you are not at a network node
  This is to make a better looking network band. The factor below:
  conversion_factor = 60 / unit_size / 30
  already assumes that you are minimizing time units and that areas outside of the
  nodes have an average speed of 30mph (last parameter).  */
  unit_size = GetUnitSize("Miles", GetMapUnits())
  conversion_factor = 60 / unit_size / 30
  opts.[Conversion Factor] = conversion_factor
  opts.[Band Layer Name] = "Network Bands"
  opts.[Band File Name] = outputDir + "\\networkbands.dbd"
  opts.[Band Interval] = 10
  opts.[Max Cost] = 120
  opts.[Do Band Theme] = 1
  opts.[Map Name]  = map
  Ret = RunMacro("Create Network Bands", opts)

  // Change Theme Name
  SetLayer("Network Bands")
  opts = null
  opts.Title = "Travel Time (mins)"
  SetThemeOptions("PMTime ()", opts)

  // Hide centroid connectors and transit access links
	SetLayer(lLyr)
	ccquery = "Select * where [AB FACTYPE] = 197 or [AB FACTYPE] = 12 "
	n1 = SelectByQuery ("CCs", "Several", ccquery,)

	// Set status to Invisible
	SetDisplayStatus(lLyr+"|CCs", "Invisible")

  // Configure Legend
	SetLegendDisplayStatus(lLyr+"|", "False")
	SetLegendDisplayStatus("Network Bands|", "False")
	RunMacro("G30 create legend", "Theme")
	SetLegendSettings (GetMap(), {"Automatic", {0,1,0,0,1,4,0} , {1,1,1} , {"Arial|Bold|16","Arial|9","Arial|Bold|16","Arial|12"} , {"","PM Travel Time from Downtown"} })
	str1 = "XXXXXXXX"
	solid = FillStyle({str1, str1, str1, str1, str1, str1, str1, str1})
	SetLegendOptions (GetMap(), {{"Background Style", solid}})

  RedrawMap(map)
  SaveMap(map,mapFile)
  CloseMap(map)
EndMacro

/*
The purpose of this map is to create the zone-based
travel times used directly by the ORTP.  Any difference
maps will still need to be created manually by comparing
two scenarios.
*/
Macro "Trav Time Map - Zonal" (scenarioDirectory)

  RunMacro("TCB Init")

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
  tazDBD = inputDir + "\\taz\\Scenario TAZ Layer.dbd"
  destTAZ = 265

  // outputs
  outputDir = scenarioDirectory + "\\reports"
  mapFile = outputDir + "\\AM SOV Zonal Travel Time to Downtown.map"
  skimMtx = outputDir + "\\AM SOV Zonal Travel Time to Downtown.mtx"

  // Create map and get layer names
  map = RunMacro("G30 new map", hwyDBD, "False")
  {nLyr,lLyr} = GetDBLayers(hwyDBD)

  // Create a link set of links that SOV can travel in the AM
  SetLayer(lLyr)
  setname = "sov am links"
  qry =       "Select * where nz([AB_LIMITA]) not between 2 and 3 and nz([BA_LIMITA]) not between 2 and 3"
  qry = qry + " and (nz([AB_LANEA]) + nz([BA_LANEA])) > 0 and [Road Name] <> 'Walk Access'"
  SelectByQuery(setname, "Several", qry)

  // Create a node set of centroids
  SetLayer(nLyr)
  centroidSet = "centroids"
  qry = "Select * where [Zone Centroid] = 'Yes'"
  SelectByQuery(centroidSet, "Several", qry)

  // Create a network
  SetLayer(lLyr)
  Flds = null
  Flds.[Set Name] = setname
  Flds.[Network File] = outputDir + "\\zonaltravtime.net"
  Flds.Label = null
  //Length must be included in link options
  Flds.[Link Options] = {{"Length", {lLyr+".Length", lLyr+".Length",,,"False"}},{"AMTime", {lLyr+".AB_TIME_AM", lLyr+".BA_TIME_AM",,,"True"}}}
  Flds.[Node Options] = null
  Flds.Options.[Link Type] = null
  Flds.Options.[Link ID] = lLyr+".ID"
  Flds.Options.[Node ID] = nLyr+".ID"
  Flds.Options.[Turn Penalties] = "No"
  Flds.Options.[Keep Duplicate Links] = "FALSE"
  Flds.Options.[Ignore Link Direction] = "FALSE"

  net_h = CreateNetwork(
      Flds.[Set Name],
      Flds.[Network File],
      Flds.Label,
      Flds.[Link Options],
      Flds.[Node Options],
      Flds.Options
  )

  // Change network settings (add centroids)
  opts = null
  opts.[Use Centroids] = "True"
  opts.[Centroid Set] = centroidSet
  ChangeNetworkSettings(net_h, opts)

  // Skim the highway network
  Opts = null
  Opts.Input.Network = Flds.[Network File]
  Opts.Input.[Origin Set] = {hwyDBD + "|" + nLyr, nLyr, "centroids", "Select * where [Zone Centroid] = 'Y'"}
  Opts.Input.[Destination Set] = {hwyDBD + "|" + nLyr, nLyr, "centroids"}
  Opts.Input.[Via Set] = {hwyDBD + "|" + nLyr, nLyr}
  Opts.Field.Minimize = "AMTime"
  Opts.Field.Nodes = nLyr + ".ID"
  Opts.Flag = {}
  Opts.Output.[Output Matrix].Label = "AM SOV Zonal Trav Time"
  Opts.Output.[Output Matrix].[File Name] = skimMtx
  ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)

  // Open matrix and collect the travel time column
  // of the destination zone.
  skimMtx = OpenMatrix(skimMtx, )
  {ri, ci} = GetMatrixIndex(skimMtx)
  skimMC  = CreateMatrixCurrency(skimMtx, "AM SOV Zonal Trav Time - AMTime", ri, ci, )
  opts = null
  opts.Column = destTAZ
  v_time = GetMatrixVector(skimMC, opts)

  CloseMap(map)

  // Create the final TAZ map
  map = RunMacro("G30 new map", tazDBD, "False")
  {tLyr} = GetDBLayers(tazDBD)

  // Add a field for the trav time to dest taz
  NewFlds = {
    {"TimeToDestTAZ", "real"}
  }
  ret_value = RunMacro("TCB Add View Fields", {tLyr, NewFlds})

  // Fill the travel time with the matrix vector
  opts = null
  opts.[Sort Order] = {{"ID", "Ascending"}}
  SetDataVector(tLyr + "|", "TimeToDestTAZ", v_time, opts)

  // Create a theme for the travel time
  numClasses = 8
  opts = null
  opts.[Pretty Values] = "True"
  opts.Title = "AM SOV Time to Downtown"
  opts.Other = "False"
  cTheme = CreateTheme("TravTime",tLyr+".TimeToDestTAZ","Optimal",numClasses, opts)

  // Set theme fill color and style
  opts = null
  // opts.method = "RGB"
  a_color = GeneratePalette(ColorRGB(65535, 61937, 47545), ColorRGB(0, 25000, 0), numClasses - 2, opts)
  SetThemeFillColors(cTheme, a_color)
  str1 = "XXXXXXXX"
  solid = FillStyle({str1, str1, str1, str1, str1, str1, str1, str1})
  for i = 1 to numClasses do
      a_fillstyles = a_fillstyles + {solid}
  end
  SetThemeFillStyles(cTheme, a_fillstyles)
  ShowTheme(, cTheme)

  // Modify the border color
  darkGray = ColorRGB(7196, 7196, 7196)
  SetLineColor(tLyr + "|", darkGray)

  RedrawMap(map)
  SaveMap(map,mapFile)
  CloseMap(map)
EndMacro


Macro "Transit Boardings" (scenarioDirectory)

  // inputs
  inputDir = scenarioDirectory + "\\inputs"
  outputDir = scenarioDirectory + "\\outputs"
  hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
  rtsFile = inputDir + "\\network\\Scenario Route System.rts"

  // outputs
  reportDir = scenarioDirectory + "\\reports"
  transitCSV = reportDir + "\\Transit Ridership.csv"

  // Create map and get layer names.  Add RTS
  map = RunMacro("G30 new map", hwyDBD, "False")
  {nLyr,lLyr} = GetDBLayers(hwyDBD)
  {rLyr,sLyr} = AddRouteSystemLayer(map,"Routes",rtsFile,)

  // Get list of all route names, numbers, and modes
  v_rtsID   = GetDataVector(rLyr + "|","Route_ID",)
  v_rtsName = GetDataVector(rLyr + "|","Route_Name",)
  v_rtsModeN = GetDataVector(rLyr + "|","Mode",)

  // Convert the mode number to a meaningful name
  v_rtsMode = if (v_rtsModeN = 4) then "Local Bus"      else ""
  v_rtsMode = if (v_rtsModeN = 5) then "Express Bus"    else v_rtsMode
  v_rtsMode = if (v_rtsModeN = 6) then "Limited Bus"    else v_rtsMode
  v_rtsMode = if (v_rtsModeN = 7) then "Fixed Guideway" else v_rtsMode
  v_rtsMode = if (v_rtsModeN = 8) then "Ferry"          else v_rtsMode


  // Create arrays to loop over
  a_access = {"KNR","PNR-FML","PNR-INF","WLK-EXP","WLK-GDWY","WLK-LOC"}
  a_tod = {"EA","AM","MD","PM","EV"}

  // Loop over the various transit tables to aggregate boardings
  // Sample table name of ON/OFF tale collapsed by route
  // PNR-FML_MD_ONOFF_COLL_JOIN.bin

  for t = 1 to a_tod.length do
    tod = a_tod[t]

    // Create vector to store boardings across access modes for current tod
    opts = null
    opts.Constant = 0
    v_rtsOn = Vector(v_rtsID.length, "Double", opts)

    for a = 1 to a_access.length do
      access = a_access[a]
      fileName = outputDir + "\\" + access + "_" + tod + "_ONOFF_COLL_JOIN.bin"

      // Open table and collect the ID and "ON" columns
      tbl = OpenTable("OnTbl","FFB",{fileName})
      v_tblID = GetDataVector(tbl + "|","ROUTE",)
      v_tblOn = GetDataVector(tbl + "|","On",)

      // Add them to the v_rtsOn vector
      // GISDK cannot compare vectors of different lengths - must loop
      for i = 1 to v_rtsID.length do
        id = v_rtsID[i]

        pos = ArrayPosition(V2A(v_tblID),{id},)
        if pos <> 0 then do
           test1 = v_rtsOn[i]
           test2 = v_tblOn[pos]
           v_rtsOn[i] = v_rtsOn[i] + v_tblOn[pos]
        end
      end
    end

    // Write out the results to a CSV
    if t = 1 then do
      transitCSV = OpenFile(transitCSV, "w")
      WriteLine(transitCSV,"Route ID,Route Name,Mode,Period,Boardings")
    end
    for i = 1 to v_rtsID.length do
      WriteLine(
        transitCSV,
        String(v_rtsID[i]) + "," +
        v_rtsName[i] + "," +
        v_rtsMode[i] + "," +
        tod + "," +
        String(v_rtsOn[i]))
    end
  end

  RunMacro("Close All")
EndMacro

/*
Summarizes lane miles by period, facility type, and level of service.

Depends
  gplyr
*/

Macro "Lane Miles by LOS" (scenarioDirectory)

  // Add link layer to workspace
  hwyDBD = scenarioDirectory + "/inputs/network/Scenario Line Layer.dbd"
  {nlyr, lLyr} = GetDBLayers(hwyDBD)
  lLyr = AddLayerToWorkspace(lLyr, hwyDBD, lLyr)

  // looping arrays
  a_ft = {1, 2, 3, 4, 5, 6, 7, 8, 9}    //Field: AB/BA_FNCLASS
  a_ftname = {"Freeway","Expressway","Principal Arterial","Minor Arterial","Major Collector","Minor Collector","Local","Ramp","CC"}
  a_tod = {"EA","AM","MD","PM","EV"}
  a_lf = {"M", "A", "M", "P", "M"} // which lane field is used for each period
  a_dir = {"AB", "BA"}


  for d = 1 to a_dir.length do
    dir = a_dir[d]

    for t = 1 to a_tod.length do
      tod = a_tod[t]
      lane_suffix = a_lf[t]

      // create list of fields
      lane = dir + "_LANE" + lane_suffix
      voc = dir + "_VOC_" + tod
      fnclass = dir + "_FNCLASS"
      a_fields = {
        "ID",
        "Length",
        fnclass,
        lane,
        voc
      }

      // Read view into a data frame
      df = CreateObject("df")
      opts = null
      opts.view = lLyr
      opts.fields = a_fields
      df.read_view(opts)

      // set standard names
      df.colnames(
        {"ID", "length", "fnclass", "lanes", "voc"}
      )

      // Add a tod column
      opts = null
      opts.Constant = tod
      v_tod = Vector(df.nrow(), "string", opts)
      df.mutate("tod", v_tod)

      // Add to final data frame
      if t = 1
        then final = df.copy()
        else final.bind_rows(df)
    end
  end

  // convert facility type numbers to names
  FT = null
  FT.fnumber = a_ft
  FT.fname = a_ftname
  FT = CreateObject("df", FT)
  final.left_join(FT, "fnclass", "fnumber")

  opts = null
  opts.in_field = "voc"
  opts.bins = {0, .6, .7, .8, .9, 1}
  opts.labels = {"A", "B", "C", "D", "E", "F"}
  final.bin_field(opts)
  final.rename("bin", "los")

  // Remove rows with null/0 lanes or null v/c
  final.filter("nz(lanes) > 0 and voc <> null and fname <> null")

  // Calculate lane miles
  final.mutate("lane_miles", final.tbl.lanes * final.tbl.length)

  // Group/summarize by functional class and time of day
  final.group_by({"fname", "tod", "los"})
  agg = null
  agg.lane_miles = {"sum"}
  final.summarize(agg)

  // Remove the "Count" field
  final.remove("Count")

  // output report
  file = scenarioDirectory + "/reports/lane miles by los.csv"
  final.write_csv(file)
EndMacro

/*
Produces tables of trips by mode and user class.
Output used in CMP analysis.

Depends
  gplyr
*/

Macro "Trips by Mode" (scenarioDirectory)

  out_dir = scenarioDirectory + "/outputs"
  rep_dir = scenarioDirectory + "/reports"

  // Resident and Visitor trips
  a_class = {"resident", "visitor"}
  a_mode = {"Auto", "Tran", "Nmot", "Othr"}
  a_mode_pretty = {"Private automobile", "Transit", "Bike/walk", "Other"}
  a_tod = {"EA", "AM", "MD", "PM", "EV"}
  for r = 1 to a_class.length do
    class = a_class[r]

    class_total = 0
    for m = 1 to a_mode.length do
      mode = a_mode[m]
      mode_pretty = a_mode_pretty[m]

      mode_total = 0
      for t = 1 to a_tod.length do
        tod = a_tod[t]

        in_file = out_dir + "/" + class + mode + "Trips_" + tod + ".mtx"
        mtx = OpenMatrix(in_file, )
        a_stats = MatrixStatistics(mtx, )

        for s = 1 to a_stats.length do
          mode_total = mode_total + a_stats[s][2].Sum
        end
      end

      class_total = class_total + mode_total

      // store the mode total in TBL
      TBL.Class = TBL.Class + {Proper(class)}
      TBL.Mode = TBL.Mode + {mode_pretty}
      TBL.Trips = TBL.Trips + {mode_total}
    end

    // Add the class total to TBL
    TBL.Class = TBL.Class + {Proper(class)}
    TBL.Mode = TBL.Mode + {"Total"}
    TBL.Trips = TBL.Trips + {class_total}
  end

  // Air trips
  a_modes = {
    "Private Automobile", "Taxi", "Transit", "Shuttle Bus",
    "Tour Bus", "Rail"
  }
  temp = null
  air_total = 0
  for t = 1 to a_tod.length do
    tod = a_tod[t]

    in_file = out_dir + "/airp_" + tod + ".mtx"
    mtx = OpenMatrix(in_file, )
    a_stats = MatrixStatistics(mtx, )

    for s = 1 to a_stats.length do
      core = a_stats[s][1]

      temp.(core) = nz(temp.(core)) + a_stats[s][2].Sum
      air_total = air_total + a_stats[s][2].Sum
    end
  end

  // Transfer temp data to TBL
  for i = 1 to temp.length do
    TBL.Class = TBL.Class + {"Air"}
    TBL.Mode = TBL.Mode + {a_modes[i]}
    TBL.Trips = TBL.Trips + {temp[i][2]}
  end

  // Add total air row
  TBL.Class = TBL.Class + {"Air"}
  TBL.Mode = TBL.Mode + {"Total"}
  TBL.Trips = TBL.Trips + {air_total}

  // Truck trips
  in_file = out_dir + "/trck_" + tod + ".mtx"
  mtx = OpenMatrix(in_file, )
  a_stats = MatrixStatistics(mtx, )
  TBL.Class = TBL.Class + {"Truck"}
  TBL.Mode = TBL.Mode + {"Total"}
  TBL.Trips = TBL.Trips + {a_stats[1][2].Sum}

  // write out to csv
  df = CreateObject("df", TBL)
  df.write_csv(rep_dir + "/trips by class and mode.csv")
EndMacro

/*
Not doing transit skims. The multi-part path approach makes it impossible.
(You don't know which stops they took).
*/

Macro "Append Skims to Trip Table" (scenarioDirectory)
  output_dir = scenarioDirectory + "\\outputs"
  ej_dir = RunMacro("Normalize Path", scenarioDirectory + "\\..\\..")
  trip_csv = output_dir + "\\trips.csv"
  mode_csv = ej_dir + "\\generic\\ej\\mode_codes.csv"
  period_csv = ej_dir + "\\generic\\ej\\period_codes.csv"

  // Export the trip csv file to a FFB table so it can be modified
  vw = OpenTable("trips", "CSV", {trip_csv})
  temp_file = GetTempFileName(".bin")
  ExportView(vw + "|", "FFB", temp_file, , )
  vw_trips = OpenTable("trips", "FFB", {temp_file})
  CloseView(vw)
  
  // // Translate mode and period into strings
  RunMacro(
    "Add Fields", vw_trips, {
      {"mode2", "character", 12},
      {"period2", "character", 10}
    },
  )
  vw_mode = OpenTable("mode", "CSV", {mode_csv})
  jv = JoinViews("jv", vw_trips + ".tripMode", vw_mode + ".Mode", )
  v = GetDataVector(jv + "|", vw_mode + ".mode2", )
  SetDataVector(jv + "|", vw_trips + ".mode2", v, )
  CloseView(jv)
  CloseView(vw_mode)
  vw_period = OpenTable("mode", "CSV", {period_csv})
  jv = JoinViews("jv", vw_trips + ".period", vw_period + ".Period", )
  v = GetDataVector(jv + "|", vw_period + ".Value", )
  SetDataVector(jv + "|", vw_trips + ".period2", v, )
  CloseView(jv)
  CloseView(vw_period)
 
  // join skim info
  SetView(vw_trips)
  current_trips = CreateSet("current_trips")
  RunMacro(
    "Add Fields", vw_trips,
    {
      {"skim_time", "Real", 10, 2},
      {"skim_length", "Real", 10, 2}
    },
  )
  a_tod = {"EA", "AM", "MD", "PM", "EV"}
  // a_mode = {"hwy", "transit"}
  a_mode = {"hwy"}
  a_submode.hwy = {"sov", "hov2", "hov3", }
  a_submode.transit = {"ktw", "ptw", "wexp", "wfxg", "wloc", "wtk", "wtp"}
  for tod in a_tod do
    for mode in a_mode do
      for submode in a_submode.(mode) do
        
        // Select the trips to fill info for
        query = "Select * where mode2 = '" + submode + "_notoll' and period2 = '" + tod + "'"
        n = SelectByQuery(current_trips, "several", query)
        if n = 0 then continue
      
        // Open the appropriate matrix
        mtx_file = output_dir + "\\" + mode + tod + "_" + submode + ".mtx"
        mtx = OpenMatrix(mtx_file, )

        // This method is available in TC 7.0 and above
        // c_time = CreateMatrixCurrency(mtx, "time (Skim)", , , )
        // c_length = CreateMatrixCurrency(mtx, "Length (Skim)", , , )
        // FillViewFromMatrix(vw_trips + "|" + current_trips, vw_trips + ".originTaz", vw_trips + ".destinationTaz", {
        //   {vw_trips + ".skim_time", c_time},
        //   {vw_trips + ".skim_length", c_length}
        // })

        // In TC 6, must use this approach
        temp_file = GetTempFileName(".bin")
        CreateTableFromMatrix(mtx, temp_file, "FFB", )
        vw_temp = OpenTable("temp", "FFB", {temp_file})
        jv = JoinViewsMulti("jv", {vw_trips + ".originTaz", vw_trips + ".destinationTAZ"}, {vw_temp + ".Origin", vw_temp + ".Destination"}, )
        v_time = GetDataVector(jv + "|" + current_trips, "time (Skim)", )
        v_length = GetDataVector(jv + "|" + current_trips, "Length (Skim)", )
        SetDataVector(jv + "|" + current_trips, "skim_time", v_time, )
        SetDataVector(jv + "|" + current_trips, "skim_length", v_length, )
      end
    end
  end
  
  CloseView(jv)
  CloseView(vw_temp)
  trip_bin = output_dir + "\\trips.bin"
  ExportView(vw_trips + "|", "FFB", trip_bin, , )
  CloseView(vw_trips)
endmacro

/*
Uses the trip list to create modal summaries.
*/

Macro "Detailed Modal Summaries" (scenarioDirectory)

  output_dir = scenarioDirectory + "\\outputs"
  report_dir = scenarioDirectory + "\\reports"
  
  trip_bin = output_dir + "\\trips.bin"
  vw_trips = OpenTable("trips", "FFB", {trip_bin})

  // Prep data frame for summary
  df = CreateObject("df")
  opts = null
  opts.view = vw_trips
  df.read_view(opts)

  /* The mode codes from the model documentation
  Trip Mode: Trip Mode:
  1 Drive Alone no toll – 1-occupant auto (SOV) no toll
  2 Drive Alone toll – 1-occupant auto (SOV) toll lane
  3 Shared Ride 2 no toll – 2-occupant auto (HOV) no toll
  4 Shared Ride 2 toll – 2-occupant auto (HOV) toll lane
  5 Shared Ride 3+ no toll – 3-or-more-occupant auto (HOV) no toll
  6 Shared Ride 3+ toll – 3-or-more-occupant auto (HOV) toll lane
  7 Walk – Walk to destination (Auxiliary
  8 Bike – Bike to destination (Auxiliary
  9 WK-Local – Walk to a local bus-only transit path (Walk to
  Transit)
  10 WK-Exp – Walk to a local or premium bus transit path (Walk
  to Transit)
  11 WK-FG – Walk to a fixed-guideway transit path (Walk to
  Transit)
  12 KNR – Get dropped off at a transit stop and take transit (Drive
  to Transit)
  13 PNR-Informal – Drive to an informal park-n-ride lot and taking
  transit (Drive to Transit)
  14 PNR-Formal – Drive to a formal park-n-ride lot and taking
  transit (Drive to Transit)
  15 School Bus – School bus for school tours only
 */

  df.tbl.mode = 
    if df.tbl.tripMode <= 2 then "drive"
    else if df.tbl.tripMode <= 6 then "carpool"
    else if df.tbl.tripMode <= 8 then "bike/walk"
    else if df.tbl.tripMode <= 11 then "transit"
    else "other"
  
  // See line 102 of ompo_tbm.properties for the order of purpose, but the
  // firstPurposeNumber is not correct. A tabulation of origin purposes
  // confirmed the true equivalency:
  //
  // originPurpose	Count	
  // -1	            915665	Home
  // 0	            288001	Work
  // 1	            28579	  University
  // 2	            125804	School
  // 3	            304160	Escort
  // 4	            464942	Maintanence
  // 5	            285314	Discretionary
  // 6	            38783	  At-work
  df.tbl.originPurpose =
    if df.tbl.originPurpose = -1 then "Home"
    else if df.tbl.originPurpose = 0 then "Work"
    else if df.tbl.originPurpose = 2 then "School"
    else "Other"
  df.tbl.destinationPurpose =
    if df.tbl.destinationPurpose = -1 then "Home"
    else if df.tbl.destinationPurpose = 0 then "Work"
    else if df.tbl.destinationPurpose = 2 then "School"
    else "Other"  
  // Work takes precedence over school. In other words, if either end is work,
  // then assign it as work, even if the other end is school.
  df.tbl.purpose = 
    if df.tbl.originPurpose = "Work" or df.tbl.destinationPurpose = "Work" then "Work"
    else if df.tbl.originPurpose = "School" or df.tbl.destinationPurpose = "School" then "School"
    else "Other"

  // Percentages by purpose and mode
  df2 = df.copy()
  df2.group_by({"purpose", "mode"})
  agg = null
  agg.expansionFactor = {"sum"}
  df2.summarize(agg)
  df2.rename("sum_expansionFactor", "trips")
  temp = df2.copy()
  temp.group_by("purpose")
  agg = null
  agg.trips = {"sum"}
  temp.summarize(agg)
  df2.left_join(temp, "purpose", "purpose")
  df2.mutate("percent", df2.tbl.trips / df2.tbl.sum_trips * 100)
  df2.write_csv(report_dir + "\\trips_by_purpose_and_mode.csv")

  // Average trip length by mode
  df3 = df.copy()
  df3.group_by("mode")
  agg = null
  agg.skim_length = {"avg"}
  df3.summarize(agg)
  df3.write_csv(report_dir + "\\average_trip_length_by_mode.csv")

  // Modal percent for all trips less than three miles
  df4 = df.copy()
  df4.filter("skim_length < 3")
  df4.group_by("mode")
  agg = null
  agg.expansionFactor = {"sum"}
  df4.summarize(agg)
  df4.rename("sum_expansionFactor", "trips")
  df4.mutate(
    "percent",
    df4.tbl.trips / VectorStatistic(df4.tbl.trips, "sum", ) * 100
  )
  df4.write_csv(report_dir + "\\trips_under_3_miles_by_mode.csv")

  RunMacro("Close All")
endmacro