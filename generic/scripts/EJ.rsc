/*

*/

dBox "EJ"

  toolbox NoKeyboard
  title: "EJ Analysis Toolbox"

  init do
    shared scen_dir, path, race_or_inc

    // Set the scen_dir to the currently selected scenario
    // if there is one.
    scen_dir = path[2]
    if !RunMacro("Scenario is Run?", scen_dir) then scen_dir = null

    race_or_inc = null

    // Determine UI location and initial search dir
    uiDBD = GetInterface()
    a_path = SplitPath(uiDBD)
    uiDir = a_path[1] + a_path[2]
    init_dir = uiDir + "../../scenarios"
    init_dir = RunMacro("Resolve Path", init_dir)
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
  shared scen_dir, race_or_inc

  // Read in the persons csv file
EndMacro
