/*

*/

dBox "EJ"

  toolbox NoKeyboard
  title: "EJ Analysis Toolbox"

  init do
    shared scen_dir, path, ej_dir, race_or_inc

    // Set the scen_dir to the currently selected scenario
    // if there is one.
    scen_dir = path[2]
    if scen_dir <> null then do
      if !RunMacro("Scenario is Run?", scen_dir) then scen_dir = null
    end

    race_or_inc = null

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
      "race or income. The scenario chosen must already have\n" +
      "been run through the standard model (with full feedback)."
    ShowMessage(message)
  enditem

  // Scenario folder
  text 1, 3, 35 variable: scen_dir prompt: "Scenario Directory" framed
  button ".." after, same icons: "bmp\\buttons|114.bmp" do
    on error, notfound, escape goto nodir
    opts = null
    opts.[Initial Directory] = init_dir
    scen_dir = ChooseDirectory("Choose the directory to analyze.", opts)
    if !RunMacro("Scenario is Run?", scen_dir) then scen_dir = null
    nodir:
    on error, notfound, escape default
  enditem

  // Race / Income Radio
  /*Radio List 2, 5 prompt: "Race or Income"
  Radio Button 4, 6.5 prompt: "Race" do
    race_or_inc = "race"
  enditem
  Radio Button 4, 7.75 prompt: "Income" do
    race_or_inc = "income"
  enditem*/

  // Analyze Button
  button "Perform Analysis" 2, 10 do
    if scen_dir = null
      then ShowMessage("Select a scenario")
      /*else if race_or_inc = null
        then ShowMessage("Select race or income")*/
        else do
          RunMacro("EJ Analysis")
          ShowMessage("EJ Analysis Complete")
        end
  enditem

  // Quit button
  button "Quit" after, same, 15 do
    return()
  enditem
EndDbox

Macro "Scenario is Run?" (scen_dir)

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
EndMacro

/*

*/

Macro "Create EJ Trip Table"
  shared scen_dir, ej_dir, race_or_inc

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

  // write to final table to csv
  trip_df.write_csv(scen_dir + "/outputs/ej_am_trips.csv")

  RunMacro("Close All")
EndMacro

/*

*/

Macro "EJ CSV to MTX"
  shared scen_dir, ej_dir, race_or_inc

  // Open the long-format trip table
  csv_file = scen_dir + "/outputs/ej_am_trips.csv"
  vw_long = OpenTable("ej_long", "CSV", {csv_file})

  // For race and income separately
  a_type = {"race", "IncGroup"}
  for t = 1 to a_type.length do
    type = a_type[t]

    // read in the trip table and spread by type
    trip_df = CreateObject("df")
    opts = null
    opts.view = vw_long
    trip_df.read_view(opts)
    trip_df.spread(type, "expansionFactor", 0)
    csv_file = scen_dir + "/outputs/ej_am_trips_by_" + type + ".csv"
    trip_df.write_csv(csv_file)
    vw = OpenTable("ej_" + type, "CSV", {csv_file})

    // Create a copy of the resident am matrix
    in_file = scen_dir + "/outputs/residentAutoTrips_AM.mtx"
    out_file = scen_dir + "/outputs/ej_od_by_" + type + ".mtx"
    CopyFile(in_file, out_file)

    // Create an array of cores to remove
    mtx = OpenMatrix(out_file, )
    cores_to_remove = GetMatrixCoreNames(mtx)

    // Create a vector of unique groups
    vec = GetDataVector(vw_long + "|", type, )
    opts = null
    opts.Unique = "True"
    opts.[Omit Missing] = "True"
    a_groups = V2A(SortVector(vec, opts))

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
      a_groups,
      "Add",
      opts
    )

    CloseView(vw)
  end

  RunMacro("Close All")
EndMacro
