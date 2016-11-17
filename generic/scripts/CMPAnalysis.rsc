/*
The primary purpose of this script is to run the OMPO model
repeatedly - once for each non-E+C project.  Each of those
projects is run along with the E+C projects to facilitate
individual project metrics like delay reduction.
*/

/*
Dialog box to setup arguments needed for the CMP
analysis.
*/

dBox "CMP"

  toolbox NoKeyboard
  title: "CMP Analysis Toolbox"

  init do
    shared year, seYear, ec_list, nonec_list
    year = 2020
    seYear = 2040

    // Determine UI location
    uiDBD = GetInterface()
    a_path = SplitPath(uiDBD)
    uiDir = a_path[1] + a_path[2]
  enditem

  // EC project list
  text 2, 2, 35 variable: ec_list prompt: "EC Project List" framed
  button ".." after, same icons: "bmp\\buttons|114.bmp" do
    on error, notfound, escape goto nofile1
    opts = null
    opts.[Initial Directory] = uiDir
    ec_list = ChooseFile(
      {{"CSV", "*.csv"}}, "Choose the EC project list", opts
    )
    nofile1:
    on error, notfound, escape default
  enditem

  // non-EC project list
  text 2, 4, 35 variable: nonec_list prompt: "Non-EC Project List" framed
  button ".." after, same icons: "bmp\\buttons|114.bmp" do
    on error, notfound, escape goto nofile2
    opts = null
    opts.[Initial Directory] = uiDir
    nonec_list = ChooseFile(
      {{"CSV", "*.csv"}}, "Choose the non-EC project list", opts
    )
    nofile2:
    on error, notfound, escape default
  enditem

  close do
		return()
	enditem

  // Specify other EC conditions
  text 2, 6 variable: "Specify other EC conditions"
  Edit Int "rdwy year item" same, after, 10, 1
    prompt: "EC Transit Year" variable: year
  Edit Int "rdwy year item" same, after, 10, 1
    prompt: "EC SE Year" variable: seYear

  // Run Analysis
  button "Perform Analysis" 2, 12 do
    RunMacro("CMP Wrapper", ec_list, nonec_list)
    ShowMessage("CMP Analysis Complete")
  enditem

  // Quit
  button "Quit" after, same, 14 do
    return()
  enditem
EndDbox

/*
Called by the "CMP" dBox.  Wraps the OMPO model in order to
create and run a scenario for each non-E+C project.
*/

Macro "CMP Wrapper"
  shared year, seYear, path, Options, ec_list, nonec_list, scen_dir, wrapper

  // This lets various steps in the model know
  // that they are being run by a wrapper.  This
  // prevents them from displaying completion
  // messages (which would pause the run).
  wrapper = "True"

  // Use the nonec_list location to determine the working dir
  a_path = SplitPath(nonec_list)
  dir = a_path[1] + a_path[2]

  // Read project lists
  df_ec = CreateObject("df")
  df_nec = CreateObject("df")
  df_ec.read_csv(ec_list)
  df_nec.read_csv(nonec_list)

  // Loop over each non-ec project
  for i = 1 to df_nec.nrow() do
    proj_id = df_nec.tbl.ProjID[i]

    // Create scenario folder
    scen_dir = dir + "/cmp_proj_" + if (TypeOf(proj_id) = "string")
      then proj_id
      else String(proj_id)
    on error goto skip
    CreateDirectory(scen_dir)
    skip:
    on error default

    // Create a project list csv for that scenario
    df = df_ec.copy()
    df.mutate("ProjID", V2A(df.tbl.ProjID) + {proj_id})
    df.write_csv(scen_dir + "/ProjectList.csv")

    // Run scenario manager steps
    RunMacro("SetDirectoryDefaults")
    path[2] = scen_dir
    RunMacro("Create TAZ File")
    RunMacro("Create Network", path, Options, year)

    // Start the model run
    jump = "UpdateLineLayer"
    RunMacro("OMPO6", path, Options, jump)

    // Create a shapefile of the project links
    RunMacro("Create Project Shape", proj_id)
  end

EndMacro

/*
Creates a shapefile of the current project by extracting
it from the scenario network.

Depends
  RoadProjectManagement.rsc
    "Create Project Set"
*/

Macro "Create Project Shape" (proj_id)
  shared path, scen_dir

  // Open map to export project links
  hwyDBD = scen_dir + "/inputs/network/Scenario Line Layer.dbd"
  {nLyr, lLyr} = GetDBLayers(hwyDBD)
  map = RunMacro("G30 new map", hwyDBD)

  // Select project
  {set_name, num_records, num_pgroups} = RunMacro(
    "Create Project Set", proj_id, lLyr
  )
  if num_records = 0 then Throw("No links found.")

  // Remove CCs and ramps from set
  SetLayer(lLyr)
  qry = "Select * where nz(AB_FNCLASS) < 8 or nz(BA_FNCLASS) < 8"
  SelectByQuery(set_name, "subset", qry)

  // Export the selection set as a shapefile
  opts = null
  opts = {
    {"Projection", "nad83:5101", },
    {"Fields", {
      "ID",
      "AB_Flow_AM", "BA_Flow_AM",
      "AB_VOC_AM", "BA_VOC_AM",
      "AB_SPD_AM", "BA_SPD_AM"
    }}
  }
  ExportArcViewShape(
    lLyr + "|" + set_name,
    scen_dir + "/reports/proj_shapefile.shp",
    opts
  )

  RunMacro("Close All")
EndMacro
