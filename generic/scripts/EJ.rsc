/*
This rsc file contains two different tools:

The first is the EJ dialog box utility. It is a post-process procedures for
viewing highway volumes and trip origins by race and income. It is not run
automatically for every model run.

The second is a summary script that creates a travel time metric originally
requested by Christine Feiholz to support the official EJ process. This script
is run automatically for each scenario and creates a shapefile of travel times.
These travel times identify the auto and transit time required from every zone
to a set number of destination zones.
*/

dBox "EJ"

  toolbox NoKeyboard
  title: "EJ Analysis Toolbox"

  init do
    shared scen_dir, path, ej_dir, output_dir

    // Set the scen_dir to the currently selected scenario
    // if there is one.
    scen_dir = path[2]
    if scen_dir <> null then do
      if !RunMacro("Is Scenario Run?", scen_dir)
        then scen_dir = null
        else output_dir = scen_dir + "/reports/ej"
    end

    // Determine UI location, initial search dir, and ej dir
    uiDBD = GetInterface()
    a_path = SplitPath(uiDBD)
    ui_dir = a_path[1] + a_path[2]
    init_dir = ui_dir + "../../scenarios"
    init_dir = RunMacro("Resolve Path", init_dir)
    ej_dir = ui_dir + "/../ej"
    ej_dir = RunMacro("Resolve Path", ej_dir)
  enditem

  // Explanatory text
  button 50, 1 prompt: " ? " do
    message = "This tool will re-assign trips stratified by\n" +
      "race and income. The scenario chosen must already have\n" +
      "been run through the standard model (with full feedback)."
    ShowMessage(message)
  enditem

  // Scenario folder (and report directory)
  text 1, 3, 35 variable: scen_dir prompt: "Scenario Directory" framed
  button ".." after, same icons: "bmp\\buttons|114.bmp" do
    on error, notfound, escape goto nodir
    opts = null
    opts.[Initial Directory] = init_dir
    scen_dir = ChooseDirectory("Choose the directory to analyze.", opts)
    output_dir = scen_dir + "/reports/ej"
    if !RunMacro("Is Scenario Run?", scen_dir) then do
      scen_dir = null
      output_dir = null
    end
    nodir:
    on error, notfound, escape default
  enditem

  // Analyze Button
  button "Perform Analysis" 7, 7 do
    if scen_dir = null
      then ShowMessage("Select a scenario")
      else do
        CreateProgressBar("Performing EJ Analysis", "False")
        RunMacro("EJ Analysis")
        DestroyProgressBar()
        ShowMessage("EJ Analysis Complete")
      end
  enditem

  // Quit button
  button "Quit" after, same, 15 do
    return()
  enditem
EndDbox

Macro "Is Scenario Run?" (scen_dir)

  test_file = scen_dir + "/reports/VMT and Speeds by FT and AT.csv"
  if GetFileInfo(test_file) = null
    then do
      ShowMessage(
        "Selected scenario has not been run\n" +
        "(File: 'VMT and Speeds by FT and AT.csv' does not exist.)"
      )
      return("False")
    end else return("True")
EndMacro

/*

*/

Macro "EJ Analysis"

  RunMacro("Create EJ Trip Table")
  RunMacro("EJ CSV to MTX")
  RunMacro("EJ Assignment")
  RunMacro("EJ Mapping")
  RunMacro("Summarize HH by Income by TAZ")
  RunMacro("Summarize Persons by Race by TAZ")
EndMacro

/*

*/

Macro "Create EJ Trip Table"
  shared scen_dir, ej_dir, output_dir
  UpdateProgressBar("Create EJ Trip Table", 0)

  // Create output_dir if it doesn't exist
  if GetDirectoryInfo(output_dir, "All") = null then CreateDirectory(output_dir)

  // Read in the ej param files
  mode_df = CreateObject("df")
  mode_df.read_csv(ej_dir + "/mode_codes.csv")
  period_df = CreateObject("df")
  period_df.read_csv(ej_dir + "/period_codes.csv")
  race_df = CreateObject("df")
  race_df.read_csv(ej_dir + "/race_codes.csv")

  // Read in the households csv
  a_fields = {"household_id", "income"}
  house_df = CreateObject("df")
  house_df.read_csv(scen_dir + "/inputs/taz/households.csv", a_fields)

  // Read in the persons csv
  a_fields = {"household_id", "pums_pnum", "race"}
  person_df = CreateObject("df")
  person_df.read_csv(scen_dir + "/inputs/taz/persons.csv", a_fields)

  // Read in the trip csv
  a_fields = {
    "hh_id", "person_id", "tripMode", "period",
    "originTaz", "destinationTaz", "expansionFactor"
  }
  trip_df = CreateObject("df")
  trip_df.read_csv(scen_dir + "/outputs/trips.csv", a_fields)

  // Join tables (and filter to AM)
  trip_df.left_join(period_df, "period", "Period")
  trip_df.rename("Value", "period2")
  trip_df.filter("period2 = 'AM'")
  trip_df.left_join(
    person_df,
    {"hh_id", "person_id"},
    {"household_id", "pums_pnum"}
  )
  trip_df.rename("race", "race_num")
  trip_df.left_join(house_df, "hh_id", "household_id")

  // Join the mode description table
  trip_df.left_join(mode_df, "tripMode", "Mode")
  trip_df.rename("Value", "mode")

  // Join the race description table
  trip_df.left_join(race_df, "race_num", "Race")
  trip_df.rename("Value", "race")

  // Calculate income group field
  trip_df.mutate(
    "IncGroup",
    if (trip_df.tbl.income < 25000) then "Low" else "NotLow"
  )

  // Remove any records missing income/race info
  trip_df.filter("race_num <> null")
  trip_df.filter("income <> null")

  // write final table to csv
  trip_df.write_csv(output_dir + "/trips_am.csv")

  RunMacro("Close All")
EndMacro

/*

*/

Macro "EJ CSV to MTX"
  shared scen_dir, ej_dir, output_dir
  UpdateProgressBar("EJ CSV to MTX", 0)

  // Open the mode table to get unique modes
  mode_df = CreateObject("df")
  mode_df.read_csv(ej_dir + "/mode_codes.csv")
  v_modes = mode_df.unique("Value")

  // Open the long-format trip table
  csv_file = output_dir + "/trips_am.csv"
  vw_long = OpenTable("ej_long", "CSV", {csv_file})

  // for each mode
  for m = 1 to v_modes.length do
    mode = v_modes[m]

    // Create a selection set on the view
    SetView(vw_long)
    qry = "Select * where Mode = '" + mode + "'"
    n = SelectByQuery("mode_set", "Several", qry)

    // continue if there are records for current mode
    if n > 0 then do

      // For race and income separately
      a_type = {"race", "IncGroup"}
      for t = 1 to a_type.length do
        type = a_type[t]

        // read in the trip table
        trip_df = CreateObject("df")
        opts = null
        opts.view = vw_long
        opts.set = "mode_set"
        trip_df.read_view(opts)

        // Create a vector of unique groups
        a_groups = trip_df.unique(type)

        // spread the trip table by type
        trip_df.spread(type, "expansionFactor", 0)
        csv_file = output_dir + "/trips_am_" + mode + "_by_" + type + ".csv"
        trip_df.write_csv(csv_file)
        vw = OpenTable("ej_" + type, "CSV", {csv_file})

        // Create a copy of the resident am matrix
        in_file = scen_dir + "/outputs/residentAutoTrips_AM.mtx"
        out_file = output_dir + "/trips_am_" + mode + "_by_" + type + ".mtx"
        CopyFile(in_file, out_file)

        // Create an array of cores to remove
        mtx = OpenMatrix(out_file, )
        cores_to_remove = GetMatrixCoreNames(mtx)

        // add a core for each unique group
        for i = 1 to a_groups.length do
          AddMatrixCore(mtx, a_groups[i])
        end

        // Remove the original cores
        for i = 1 to cores_to_remove.length do
          DropMatrixCore(mtx, cores_to_remove[i])
        end

        // Update the new cores with the trips
        SetView(vw)
        opts = null
        opts.[Missing is zero] = "True"
        UpdateMatrixFromView(
          mtx,
          vw + "|",
          "originTaz",
          "destinationTaz",
          ,
          v2a(a_groups),
          "Add",
          opts
        )

        CloseView(vw)
      end
    end
  end

  RunMacro("Close All")
EndMacro

/*
The settings are intended to mirror those found in highwayAssign.rsc
for the AM period.
*/

Macro "EJ Assignment"
  shared scen_dir, ej_dir, output_dir
  UpdateProgressBar("EJ Assignment", 0)

  // Input files and link exclusion
  hwy_dbd = scen_dir + "/inputs/network/Scenario Line Layer.dbd"
  {nlyr, llyr} = GetDBLayers(hwy_dbd)
  net = scen_dir + "/outputs/hwyAM.net"
  turn_pen = scen_dir + "\\inputs\\turns\\am turn penalties.bin"
  ab_limit = "[AB_LIMITA]"
  ba_limit = "[BA_LIMITA]"
  // Using the SOV link exclusion query for all matrix cores
  validlink = "(([AB FACTYPE]  between 1 and 13 ) or ([BA FACTYPE] between 1 and 13))"
  excl_qry = "Select * where !"+validlink+" or !(("+ab_limit+"=0 | "+
    ab_limit+"=1 | "+ab_limit+"=6 | "+ba_limit+"=0 | "+ba_limit+"=1 | "+
    ba_limit+"=6)" + ")"
  Opts = null
  Opts.Input.Database = hwy_dbd
  Opts.Input.Network = net
  excl_set = {hwy_dbd + "|" + llyr, llyr, "SOV -FREE", excl_qry}


  // VDF options
  Opts.Field.[VDF Fld Names] = {"*_FFTIME", "*_CAPACITY", "*_ALPHA",  "None"}  // JL Added for Conical Function
  Opts.Global.[Load Method] = "NCFW"
  if (Opts.Global.[Load Method] = "NCFW") then Opts.Global.[N Conjugate] = 2
  if (Opts.Global.[Load Method] = "NCFW") then do
      Opts.Global.[N Conjugate] = 2
      Opts.Global.[T2 Iterations] = 100
  end
  Opts.Global.[Loading Multiplier] = 1
  Opts.Global.Convergence = 0.0001
  Opts.Global.Iterations = 300
  Opts.Global.[Cost Function File] = "emme2.vdf"
  Opts.Global.[VDF Defaults] = {, , 4, }

  // Settings that vary depending on the matrix used
  a_type = {"race", "IncGroup"}
  for t = 1 to a_type.length do
    type = a_type[t]

    // set od matrix
    od_mtx = output_dir + "/trips_am_auto_by_" + type + ".mtx"
    mtx = OpenMatrix(od_mtx, )
    a_cores = GetMatrixCoreNames(mtx)
    core_name = a_cores[1]
    mtx = null
    Opts.Input.[OD Matrix Currency] = {od_mtx, core_name, , }

    // Exclusion set array
    Opts.Input.[Exclusion Link Sets] = null
    for i = 1 to a_cores.length do
      Opts.Input.[Exclusion Link Sets] = Opts.Input.[Exclusion Link Sets] +
        {excl_set}
    end

    // Class information
    a_class_num = null
    a_class_pce = null
    a_class_voi = null
    a_toll = null
    a_turn = null
    for i = 1 to a_cores.length do
      a_class_num = a_class_num + {i}
      a_class_pce = a_class_pce + {1}
      a_class_voi = a_class_voi + {.25}
      a_toll = a_toll + {"*_COST_DANT"}
      a_turn = a_turn + {"PENALTY"}
    end
    Opts.Field.[Vehicle Classes] = a_class_num
    Opts.Global.[Number of Classes] = a_cores.length
    Opts.Global.[Class PCEs] = a_class_pce
    Opts.Global.[Class VOIs] = a_class_voi
    Opts.Field.[Fixed Toll Fields] = a_toll
    Opts.Field.[Turn Attributes] = a_turn

    // output file
    Opts.Output.[Flow Table] = output_dir + "/flow_am_by_" + type + ".bin"

    ret_value = RunMacro("TCB Run Procedure", 1, "MMA", Opts, &Ret)
    if !ret_value then do
        Throw("Highway assignment failed.")
    end
  end
EndMacro

/*
Create a map showing EJ origins and flows.
*/

Macro "EJ Mapping"
  shared scen_dir, ej_dir, output_dir
  UpdateProgressBar("EJ Mapping", 0)

  // Open the ej trip table
  trip_df = CreateObject("df")
  trip_df.read_csv(output_dir + "/trips_am.csv")

  // Determine modes in the model
  mode_df = CreateObject("df")
  mode_df.read_csv(ej_dir + "/mode_codes.csv")
  a_modes = v2a(mode_df.unique("Value"))

  // Create summary tables by mode, o/d, and race/income
  a_od = {"origin", "destination"}
  a_ej = {"race", "IncGroup"}

  for m = 1 to a_modes.length do
    mode = a_modes[m]

    // Check to make sure that the current mode exists in the table.
    // This primarily effects the walk_to_rail mode, which isn't always present.
    mode_present = trip_df.in(mode, trip_df.unique("mode"))
    if mode_present then do
      for e = 1 to a_ej.length do
        ej = a_ej[e]

        // Determine Categories
        if ej = "race" then do
          race_df = CreateObject("df")
          race_df.read_csv(ej_dir + "/race_codes.csv")
          a_cats = V2A(race_df.tbl.Value)
        end else a_cats = {"Low", "NotLow"}

        for o = 1 to a_od.length do
          od = a_od[o]

          // Create a summary table of trips by TAZ for current mode/ej/od
          temp_df = trip_df.copy()
          temp_df.filter("mode = '" + mode + "'")
          temp_df.group_by({od + "Taz", ej})
          agg = null
          agg.expansionFactor = {"sum"}
          temp_df.summarize(agg)
          temp_df.spread(ej, "sum_expansionFactor", 0)
          temp_df.group_by({od + "Taz"})
          agg = null
          sum_names = null
          renames = null
          for c = 1 to a_cats.length do  // set array of category fields to agg
            cat = a_cats[c]

            // check that the category exists as a column before including it
            if temp_df.in(cat, temp_df.colnames()) then do
              agg.(a_cats[c]) = {"sum"}
              sum_names = sum_names + {"sum_" + a_cats[c]}
              renames = renames + {a_cats[c]}
            end
          end
          temp_df.summarize(agg)
          temp_df.rename(sum_names, renames)
          csv = output_dir + "/summary_" + mode + "_" + od + "s_by_" + ej + ".csv"
          temp_df.remove("Count")
          temp_df.write_csv(csv)

          // Create a map
          if od = "origin" then RunMacro("EJ Map Helper", mode, od, ej, a_cats)
        end
      end
    end
  end
EndMacro

/*
Middle-man macro between "EJ Mapping" and the gisdk_tools macro
"Create Chart Theme". Creaets a map and sets up the options before calling
chart macro for tazs and links.

mode
  String
  The mode to be mapped. Link flows will only be mapped for
  the "auto" mode.

od
  String "origin" or "destination"
  Whether the TAZ origins or destinations will be mapped

ej
  String "race" or "IncGroup"
  Which ej category will be mapped
*/

Macro "EJ Map Helper" (mode, od, ej, a_cats)
  shared scen_dir, output_dir, ej_dir

  // Determine which ej files to map
  orig_tbl = output_dir + "/summary_" + mode + "_" + od + "s_by_" + ej + ".csv"
  flow_tbl = output_dir + "/flow_am_by_" + ej + ".bin"

  // Create Map
  hwy_dbd = scen_dir + "/inputs/network/Scenario Line Layer.dbd"
  taz_dbd = scen_dir + "/inputs/taz/Scenario TAZ Layer.dbd"
  {nlyr, llyr} = GetDBLayers(hwy_dbd)
  {tlyr} = GetDBLayers(taz_dbd)
  map = RunMacro("G30 new map", hwy_dbd)
  MinimizeWindow(GetWindowName())
  AddLayer(map, tlyr, taz_dbd, tlyr)
  RunMacro("G30 new layer default settings", tlyr)

  // Create pie chart theme on the TAZ layer of origins by category
  orig_tbl = OpenTable("origins", "CSV", {orig_tbl})
  taz_jv = JoinViews("jv", tlyr + ".TAZ", orig_tbl + ".originTaz", )
  SetLayer(tlyr)
  a_cat_specs = V2A(taz_jv + "." + A2V(a_cats))
  opts = null
  opts.layer = tlyr
  opts.field_specs = a_cat_specs
  opts.type = "Pie"
  opts.Title = "Trip " + od + "s by " + ej
  RunMacro("Create Chart Theme", opts)

  if mode = "auto" then do
    // Summarize the assignment table to combine ab/ba
    flow_tbl = OpenTable("flow", "FFB", {flow_tbl})
    df = CreateObject("df")
    opts = null
    opts.view = flow_tbl
    df.read_view(opts)
    a_dir = {"AB", "BA"}
    v_fields = ("tot_" + A2V(a_cats) + "_flow")
    for f = 1 to v_fields.length do
      field_name = v_fields[f]
      cat = a_cats[f]

      df.mutate(
        field_name,
        df.tbl.("AB_Flow_" + cat) + df.tbl.("BA_Flow_" + cat)
      )
    end
    df.select(v_fields)
    df.update_view(flow_tbl)

    // Create pie chart of flow
    link_jv = JoinViews("jv_link", llyr + ".ID", flow_tbl + ".ID1", )
    SetLayer(llyr)
    a_cat_specs = V2A(link_jv + ".tot_" + A2V(a_cats) + "_flow")
    opts = null
    opts.layer = llyr
    opts.field_specs = a_cat_specs
    opts.type = "Pie"
    opts.Title = "Flow by " + ej
    RunMacro("Create Chart Theme", opts)
  end

  MaximizeWindow(GetWindowName())
  RedrawMap(map)
  SaveMap(map, output_dir + "/map_" + mode + "_by_" + ej + ".map")
  CloseMap(map)
EndMacro

Macro "Summarize HH by Income by TAZ"
  shared scen_dir, ej_dir, output_dir

  // Read in the households csv
  a_fields = {"household_id", "household_zone", "income"}
  house_df = CreateObject("df")
  house_df.read_csv(scen_dir + "/inputs/taz/households.csv", a_fields)

  // Calculate income group field
  house_df.mutate(
    "IncGroup",
    if (house_df.tbl.income < 25000) then "Low" else "NotLow"
  )

  // Remove any records missing income info
  house_df.filter("income <> null")

  // Spread by Income
  house_df.mutate("HH", house_df.tbl.income*0 + 1)
  house_df.spread("IncGroup", "HH", 0)

  // Group by TAZ
  house_df.group_by("household_zone")
  agg = null
  agg.Low = {"sum"}
  agg.NotLow = {"sum"}
  house_df.summarize(agg)

  // Calculate percentages
  house_df.mutate(
  "total",
  house_df.tbl.sum_Low + house_df.tbl.sum_NotLow
  )
  house_df.mutate(
  "Low_income_pct",
  house_df.tbl.sum_Low/house_df.tbl.total
  )
  house_df.mutate(
  "NotLow__income_pct",
  house_df.tbl.sum_NotLow/house_df.tbl.total
  )

  // Rename variables
  house_df.rename("sum_Low", "Low_income")
  house_df.rename("sum_NotLow", "NotLow_income")

  // write final table to csv
  house_df.select(
  {"household_zone", "Low_income", "NotLow_income",
   "Low_income_pct", "NotLow__income_pct"}
  )
  house_df.write_csv(output_dir + "/hh_income.csv")

  RunMacro("Close All")
EndMacro


Macro "Summarize Persons by Race by TAZ"
  shared scen_dir, ej_dir, output_dir
  
  // Join household and race code data to the persons table
  vw_per = OpenTable(
    "per", "CSV", {scen_dir + "/inputs/taz/persons.csv", a_fields})
  vw_hh = OpenTable(
    "hh", "CSV", {scen_dir + "/inputs/taz/households.csv", a_fields})
  jv = JoinViews("jv", vw_per + ".household_id", vw_hh + ".household_id", )
  vw_race = OpenTable("race", "CSV", {ej_dir + "/race_codes.csv"})
  jv2 = JoinViews("jv2", jv + ".race", vw_race + ".Race", )

  // Read info into a data frame
  person_df = CreateObject("df")
  opts = null
  opts.view = jv2
  opts.fields = {"household_zone", "Value"}
  person_df.read_view(opts)
  person_df.rename("Value", "race")
  
  // Get unique values of race
  v_races = person_df.unique("race")
  
  // Add a POP field full of 1s (each row represents 1 person)
  person_df.mutate("POP", person_df.tbl.household_zone * 0 + 1)
  
  // In a separate df, calculate total pop
  tot_df = person_df.copy()
  tot_df.group_by("household_zone")
  agg = null
  agg.POP = {"sum"}
  tot_df.summarize(agg)
  tot_df.remove("Count")
  
  // Sum up population by household zone and race
  person_df.group_by({"household_zone", "race"})
  agg = null
  agg.POP = {"sum"}
  person_df.summarize(agg)
  person_df.rename("sum_POP", "POP")
  person_df.remove("Count")

  // Spread the main table by race and join the total df
  person_df.spread("race", "POP", 0)
  person_df.left_join(tot_df, "household_zone", "household_zone")

  // Calculate racial percentage columns
  for i = 1 to v_races.length do
    race = v_races[i]
    person_df.mutate(
      (race + "_" + "pct"),
      person_df.tbl.(race)/person_df.tbl.sum_POP
    )
  end

  // write final table to csv
  person_df.write_csv(output_dir + "/population_by_race_and_taz.csv")
  
  RunMacro("Close All")
EndMacro  

/*
Creates a travel time metric originally requested by Christine Feiholz to
support the official EJ process. This script is run automatically for each
scenario and creates a shapefile of travel times. These travel times identify
the auto and transit time required from every zone to a set number of
destination zones.
*/

Macro "EJ Trav Time Table"
  shared path
  UpdateProgressBar("EJ Trav Time Table", 0)

  // Use the ui location to find the ej directory
  uiDBD = GetInterface()
  a_path = SplitPath(uiDBD)
  uiDir = a_path[1] + a_path[2]
  ej_dir = uiDir + "../ej"
  ej_dir = RunMacro("Resolve Path", ej_dir)

  scen_dir = path[2]
  output_dir = scen_dir + "/reports/ej"
  if GetDirectoryInfo(output_dir, "All") = null then CreateDirectory(output_dir)

  // Open the equivalency table
  equiv = CreateObject("df")
  equiv.read_csv(ej_dir + "/ej_taz_equiv.csv")

  // Loop over highway and transit skim matrices to get times
  a_mode = {"hwy", "trn"}
  a_matrices = {"hwyAM_sov.mtx", "transit_wloc_AM.mtx"}
  for m = 1 to a_mode.length do
    mode = a_mode[m]
    file_name = a_matrices[m]
    final = CreateObject("df") // Final data frame
    
    // Open the impedance matrix
    file = scen_dir + "/outputs/" + file_name
    mtx = OpenMatrix(file, )
    a_cores = GetMatrixCoreNames(mtx)
    core_to_use = a_cores[1]
    
    // The first time through, start by collecting the column
    // of TAZ IDs.
    cur = CreateMatrixCurrency(mtx, core_to_use, , , )
    v_ids = GetMatrixRowLabels(cur)
    cur = null
    final.mutate("TAZ", v_ids)
    
    // If the transit matrix, calculate a total time core
    if file_name = "transit_wloc_AM.mtx" then do
      
      // change core to use and add if needed
      core_to_use = "total_time"
      if ArrayPosition(a_cores, {core_to_use}, ) = 0 then do
        AddMatrixCore(mtx, core_to_use)
      end
      
      // Calculate the total time
      a_curs = CreateMatrixCurrencies(mtx, , , )
      a_curs.(core_to_use) := a_curs.[Access Walk Time] +
        a_curs.[Initial Wait Time] +
        a_curs.[In-Vehicle Time] +
        a_curs.[Transfer Wait Time] +
        a_curs.[Transfer Walk Time] +
        a_curs.[Dwelling Time]
    end
    
    // Create a currency of the impedance core to use
    cur = CreateMatrixCurrency(mtx, core_to_use, , , )
    
    // Get the matrix column for each TAZ listed in equiv
    for t = 1 to equiv.nrow() do
      taz_num = equiv.tbl.TAZ[t]
      taz_name = equiv.tbl.TAZ_ID[t]
      
      opts = null
      opts.Column = taz_num
      v = GetMatrixVector(cur, opts)
      final.mutate(taz_name, v)
    end
  
    final.write_csv(output_dir + "/ej_travel_times_" + mode + ".csv")
  end
  
  
  RunMacro("Close All")
EndMacro
