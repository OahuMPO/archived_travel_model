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
    if !RunMacro("Scenario is Run?", scen_dir) then scen_dir = null

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
    nodir:
    on error, notfound, escape default

    if !RunMacro("Scenario is Run?", scen_dir) then scen_dir = null
  enditem

  // Race / Income Radio
  Radio List 2, 5 prompt: "Race or Income"
  Radio Button 4, 6.5 prompt: "Race" do
    race_or_inc = "race"
  enditem
  Radio Button 4, 7.75 prompt: "Income" do
    race_or_inc = "income"
  enditem

  // Analyze Button
  button "Perform Analysis" 2, 10 do
    if scen_dir = null
      then ShowMessage("Select a scenario")
      else if race_or_inc = null
        then ShowMessage("Select race or income")
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
    "originTaz", "destinationTaz"
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
  trip_df.left_join(house_df, "hh_id", "household_id")

  // Calculate income group field
  trip_df.mutate(
    "inc_group",
    if (trip_df.tbl.income < 25000) then "Low" else "NotLow"
  )

  // write to final table to csv
  trip_df.write_csv(scen_dir + "/outputs/trips_by_ej.csv")
EndMacro

Macro "EJ CSV to MTX"
  shared scen_dir, ej_dir, race_or_inc

  // Open the ej trip table csv
  csv_file = scen_dir + "/outputs/ej_trips.csv"
  vw = OpenTable("ej", "CSV", {csv_file})

  // For race and income separately
  a_type = {"race", "inc_group"}
  for t = 1 to a_type.length do
    type = a_type[t]

    // Create a copy of the resident am matrix
    in_file = scen_dir + "/outputs/residentAutoTrips_AM.mtx"
    out_file = scen_dir + "/outputs/ej_od_by_" + type + ".mtx"
    CopyFile(in_file, out_file)

    // Create an array of cores to remove
    mtx = OpenMatrix(out_file, )
    cores_to_remove = GetMatrixCoreNames()

    // Create a vector of unique groups
    vec = GetDataVector(vw + "|", type, )
    opts = null
    opts.Unique = "True"
    v_uniq = SortVector(vec, opts)

    // for each unique value of race or income group
    for i = 1 to v_uniq.length do
      name = v_uniq[i]

      // Add a matrix core
      AddMatrixCore(mtx, name)

      // Create a selection set of trips of that unique value
      SetView(vw)
      SelectByQuery("sel", "Several", type + " = " + name)

      // Update the new core with the trips
      opts = null
      opts.[Missing is zero] = "True"
      UpdateMatrixFromView(
        mtx,
        vw + "|sel",
        "originTaz",
        "destinationTaz",
        "expansionFactor",
        ,
        "Add",
        opts
      )
    end
  end
EndMacro
