/**************************************************************
   ModeChoiceReport.rsc
 
  TransCAD Macro used to run mode choice

**************************************************************/
Macro "Report Mode Choice"

    RunMacro("TCB Init")
    scenarioDirectory="c:\\projects\\ompo\\conversion\\application\\2005-5"
    tazFile=scenarioDirectory+"\\inputs\\taz\\Scenario TAZ Layer.dbd"
    
   
    pkTrips  = {
                scenarioDirectory+"\\outputs\\"+"MODE5NC.BIN",          //Home-based School 
                scenarioDirectory+"\\outputs\\"+"MODE5NK.BIN",          //Home-based College 
                scenarioDirectory+"\\outputs\\"+"MODE5WH.BIN",          //Home-based Work  
                scenarioDirectory+"\\outputs\\"+"MODE5WN.BIN",          //Non-Home-Based
                scenarioDirectory+"\\outputs\\"+"MODE5WO.BIN",          //Home-based Other 
                scenarioDirectory+"\\outputs\\"+"MODE5WW.BIN"           //Non-Home-Based
    }                                                                     
   opTrips   = {scenarioDirectory+"\\outputs\\"+"MODE5AW.BIN",          //Non-Home-Based
                scenarioDirectory+"\\outputs\\"+"MODE5AN.BIN",          //Non-Home-Based
                scenarioDirectory+"\\outputs\\"+"MODE5NS.BIN",          //Home-based Other 
                scenarioDirectory+"\\outputs\\"+"MODE5NO.BIN",          //Home-based Other 
                scenarioDirectory+"\\outputs\\"+"MODE5NN.BIN"           //Non-Home-Based
   }
 
    pkSkims = { scenarioDirectory+"\\outputs\\transit_wloc_pk.mtx",     //1 wlk-loc
                scenarioDirectory+"\\outputs\\transit_wexp_pk.mtx",     //2 wlk-exp
                scenarioDirectory+"\\outputs\\transit_wfxg_pk.mtx",     //3 wlk-fxg
                scenarioDirectory+"\\outputs\\transit_pnr_pk.mtx",      //4 pnr-fml
                scenarioDirectory+"\\outputs\\transit_knr_pk.mtx",      //5 pnr-inf
                scenarioDirectory+"\\outputs\\transit_knr_pk.mtx"       //6 knr
               }
               
    opSkims = { scenarioDirectory+"\\outputs\\transit_wloc_op.mtx",     //1 wlk-loc 
                scenarioDirectory+"\\outputs\\transit_wexp_op.mtx",     //2 wlk-exp 
                scenarioDirectory+"\\outputs\\transit_wfxg_op.mtx",     //3 wlk-fxg 
                scenarioDirectory+"\\outputs\\transit_pnr_op.mtx",      //4 pnr-fml 
                scenarioDirectory+"\\outputs\\transit_knr_op.mtx",      //5 pnr-inf 
                scenarioDirectory+"\\outputs\\transit_knr_op.mtx"       //6 knr     
               }
                           
    /* Input Modes              Mode
        Drive Alone     
        Shared 2        
        Shared 3+       
        Walk to Express         2
        Walk to Local           1
        Walk to Guideway        3 
        Park-and-Ride           
        Kiss-and-Ride           6  
        Walk            
        Bike            
        PNR-formal              4
        PNR-informal            5  
    */
    
    // Output modes
    modes = { "WalkLocal", "WalkExpress", "WalkGuideway", "PNR-FRM", "PNR-INF", "KNR" }
    
    //walk local
    wlocOptions =
    { {   2, 1.0},  //   In-Vehicle Time
      {   3, 1.0},  //   Initial Wait Time
      {   4, 1.0},  //   Transfer Wait Time
      {   5, 1.0},  //   Transfer Walk Time
      {   6, 1.0},  //   Access Walk Time
      {   7, 1.0},  //   Egress Walk Time
      {   8, 0.1} } //   Number of Transfers

    //walk express                   
    wexpOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Access Walk Time   
      {   7, 1.0},  //   Egress Walk Time   
      {   8, 0.1} } //   Number of Transfers
                                             
    //walk fxgwy                   
    wfxgOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Access Walk Time   
      {   7, 1.0},  //   Egress Walk Time   
      {   8, 0.1} } //   Number of Transfers

    //pnr-formal                   
    pnrOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Egress Walk Time   
      {   7, 1.0},  //   Access Drive Time  
      {   8, 0.1},  //   Number of Transfers
      {   9, 1.0} } //   Drive Distance     

    //pnr-informal,knr                   
    knrOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Egress Walk Time   
      {   7, 1.0},  //   Access Drive Time  
      {   8, 0.1},  //   Number of Transfers
      {   9, 1.0} } //   Drive Distance     

    skimOptions = {wlocOptions,wexpOptions,wfxgOptions,pnrOptions,knrOptions,knrOptions}

    // **********************************************************************************************************************
    //Collapse transit tables by purpose for district summaries
   inFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH.MTX",     //  JTW: Home - Work  
            scenarioDirectory+"\\outputs\\MODE5WO.MTX",     //  JTW: Home - Other 
            scenarioDirectory+"\\outputs\\MODE5WW.MTX",     //  JTW: Work-Based   
            scenarioDirectory+"\\outputs\\MODE5WN.MTX",     //  JTW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5NK.MTX",     //  Home-Based K-12   
            scenarioDirectory+"\\outputs\\MODE5NC.MTX",     //  Home-Based College
            scenarioDirectory+"\\outputs\\MODE5AW.MTX",     //  JAW: Work-Based
            scenarioDirectory+"\\outputs\\MODE5AN.MTX",     //  JAW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5NS.MTX",     //  Home-Based Shop 
            scenarioDirectory+"\\outputs\\MODE5NO.MTX",     //  Home-Based Other
            scenarioDirectory+"\\outputs\\MODE5NN.MTX",     //  Non-Home-Based
            scenarioDirectory+"\\outputs\\VIST5TRP.MTX",    //  Visitor trips
            scenarioDirectory+"\\inputs\\other\\VISOBS.MTX"}      //  Observed Visitor transit trips

   outFile = scenarioDirectory+"\\outputs\\trnPurpose.mtx"

   coreNames = {"HBW",          // 1  
                "HBSCHCOLL",    // 2
                "HBO",          // 3
                "NHB",          // 4
                "VISITOR" }     // 5

   description = "Transit Tables By Purpose"

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
   tableArray = {{      0,       0,       0,       1,       1,       1,       0,       1,       0,       0,       1,       1}, //JTW: Home - Work       1
                 {      0,       0,       0,       3,       3,       3,       0,       3,       0,       0,       3,       3}, //JTW: Home - Other      3
                 {      0,       0,       0,       4,       4,       4,       0,       4,       0,       0,       4,       4}, //JTW: Work-Based        4
                 {      0,       0,       0,       4,       4,       4,       0,       4,       0,       0,       4,       4}, //JTW: Non-Work-Based    4
                 {      0,       0,       0,       2,       2,       2,       0,       2,       0,       0,       2,       2}, //Home-Based K-12        2
                 {      0,       0,       0,       2,       2,       2,       0,       2,       0,       0,       2,       2}, //Home-Based College     2
                 {      0,       0,       0,       4,       4,       4,       0,       4,       0,       0,       4,       4}, //JAW: Work-Based        4 
                 {      0,       0,       0,       4,       4,       4,       0,       4,       0,       0,       4,       4}, //JAW: Non-Work-Based    4 
                 {      0,       0,       0,       3,       3,       3,       0,       3,       0,       0,       3,       3}, //Home-Based Shop        3 
                 {      0,       0,       0,       3,       3,       3,       0,       3,       0,       0,       3,       3}, //Home-Based Other       3 
                 {      0,       0,       0,       4,       4,       4,       0,       4,       0,       0,       4,       4}, //Non-Home-Based         4 
                 {      0,       5,       5,       0,       0,       0,       0,       0,       0,       0,       0,       0}, //Visitor trips          5
                 {      5,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0}} //Observed visitor       5      

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)    
   if !ret_value then Throw()

    ret_value = RunMacro("District Summaries", {outFile}, tazFile, "TD")    
    if !ret_value then Throw()

    //Collapse the mode choice trip tables into just transit trips, by the 5 trip categories that the OD survey uses, then
    //run TFLDS
  
    // **********************************************************************************************************************
    //Collapse Home-Work
    inFiles = {scenarioDirectory+"\\outputs\\MODE5WH.MTX"}
              
    outFile = scenarioDirectory+"\\outputs\\MODE5HBWTRN.mtx"
      
    description = "Home-Based Work Transit Trips"
   
    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    tableArray = {{      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5}}  
   
    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, modes, description)    
    if !ret_value then Throw()

    //Run HBW TLFD
    ret_value = RunMacro("Run Transit TLFDs", scenarioDirectory, outFile, pkSkims, skimOptions)
    if !ret_value then Throw()
    
    // **********************************************************************************************************************
    //Next collapse Home-Other
    inFiles = { scenarioDirectory+"\\outputs\\"+"MODE5WO.MTX",          //Home-based Other
               scenarioDirectory+"\\outputs\\"+"MODE5NS.MTX",          //Home-based Other
               scenarioDirectory+"\\outputs\\"+"MODE5NO.MTX"           //Home-based Other
    }
              
    outFile = scenarioDirectory+"\\outputs\\MODE5HBOTRN.MTX"
              
    description = "Home-Based Other Transit Trips"
              
    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
  
    tableArray = {{      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //WO Person trips
                 {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //NS Person trips
                 {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5}}  //NO Person trips
   
    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, modes, description)    
    if !ret_value then Throw()

    //Run HBO TLFD
    ret_value = RunMacro("Run Transit TLFDs", scenarioDirectory, outFile, opSkims, skimOptions)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Next collapse Non-Home-Based
    inFiles = {  scenarioDirectory+"\\outputs\\"+"MODE5WN.MTX",          //Non-Home-Based
                 scenarioDirectory+"\\outputs\\"+"MODE5WW.MTX",          //Non-Home-Based
                 scenarioDirectory+"\\outputs\\"+"MODE5AW.MTX",          //Non-Home-Based
                 scenarioDirectory+"\\outputs\\"+"MODE5AN.MTX",          //Non-Home-Based
                 scenarioDirectory+"\\outputs\\"+"MODE5NN.MTX"           //Non-Home-Based
    }
              
    outFile = scenarioDirectory+"\\outputs\\MODE5NHBTRN.MTX"
              
    description = "Non-Home-Based Transit Trips"
              
    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    tableArray = {{      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //WN Person trips
                  {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //WW Person trips
                  {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //AW Person trips
                  {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //AN Person trips
                  {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5}}  //NN Person trips
   
    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, modes, description)    
    if !ret_value then Throw()

    //Run NHB TLFD
    ret_value = RunMacro("Run Transit TLFDs", scenarioDirectory, outFile, opSkims, skimOptions)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Next collapse School/College
    inFiles = {  scenarioDirectory+"\\outputs\\"+"MODE5NC.MTX",          //Home-based School 
                scenarioDirectory+"\\outputs\\"+"MODE5NK.MTX"           //Home-based College 
             }
              
    outFile = scenarioDirectory+"\\outputs\\MODE5HBCTRN.MTX"
              
    description = "Home-Based Sch/Coll Transit Trips"
              
    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    tableArray = {{      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5},  //NC Person trips
                  {      0,       0,       0,       2,       1,       3,       0,       6,       0,       0,       4,       5}}  //NK Person trips
   
    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, modes, description)    
    if !ret_value then Throw()
    
    //Run HBSchool TLFD
    ret_value = RunMacro("Run Transit TLFDs", scenarioDirectory, outFile, opSkims, skimOptions)
    if !ret_value then Throw()

    Return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro

/***********************************************************************************
*
* Run TLFDs
*
* PB - jef 4/08
*
* Script runs trip length frequency distributions on trip tables, using skim provided.
* Report written to report file and summary files written to scenarioDirectory\reports.
*
* Arguments:
*   scenarioDirectory   Trip tables and skims should be in scenarioDirectory\outputs
*                       Output TLFD matrix will be written to scenarioDirectory\ouputs
*   tripFile            A trip table; tlfds will be performed for each core
*   skimFiles           An array of matrix files of skims, full path should be given. Each
*                       skim file will be used for each table in the tripFile.  For example, if
*                       there are three trip tables - walk-local, walk-exp, walk-fxg, there should
*                       be three skim files in the array, corresponding to the tables.
*   skimOptions         An array of two-dimensional arrays, with one element per skim
*                       d1 should be number of core in matrix,
*                       d2 should be bin size for matrix core.  All specified cores
*                       will be used for summary. 
*
************************************************************************************/
Macro "Run Transit TLFDs" (scenarioDirectory, tripFile, skimFiles, skimOptions)

    
   // convert binary trip tables to mtx format
    path = SplitPath(tripFile)
    if (path[4] = ".bin"|path[4] = ".BIN"  ) then do
        RunMacro("Convert Binary to Mtx" , {tripFile})
        tripFile = scenarioDirectory+"\\outputs\\"+path[3]+".mtx"
    end
    
    tripMatrix = OpenMatrix(tripFile,)
    tripCores = GetMatrixCoreNames(tripMatrix)
    tripCurrArray = CreateMatrixCurrencies(tripMatrix, , ,)
    stat_array = MatrixStatistics(tripMatrix,)
    
    for i = 1 to skimFiles.length do
        skimMatrix = OpenMatrix(skimFiles[i],)
        skimCores = GetMatrixCoreNames(skimMatrix)
        skimCurrArray = CreateMatrixCurrencies(skimMatrix, , ,)
    
        dim avgLength[tripCores.length,skimCores.length]
    
    
        tripTable = tripCores[i]
        tripLabel = Substitute(tripTable, " ", "", ) 
        tripIndex = GetMatrixIndex(tripMatrix)
    
        for k = 1 to skimOptions[i].length do  //for each skim
        
    
            skimTable = skimOptions[i][k][1]
            skimSize  = skimOptions[i][k][2]
            skimName  = skimCores[skimTable]
            skimIndex = GetMatrixIndex(skimMatrix)
           
            skimLabel = Substitute(skimName, "*", "", )
            skimLabel = Substitute(skimLabel, "_", "", )
            skimLabel = Substitute(skimLabel, " ", "", )
            skimLabel = Substitute(skimLabel, "-", "", )
            skimLabel = Substitute(skimLabel, "(Skim)", "", )
    
            outputFile = scenarioDirectory+"\\outputs\\TLFD_"+path[3]+"_"+skimLabel+"_"+tripLabel+".mtx"
            outputLabel = "TLFD_"+path[3]+"_"+skimLabel+"_"+tripLabel
            
            Opts = null
            Opts.Input.[Base Currency] =  {tripFile, tripCores[i],tripIndex[1] ,tripIndex[2]} //tripCurrArray[j][2] 
            Opts.Input.[Impedance Currency] = {skimFiles[i], skimCores[skimTable], skimIndex[1], skimIndex[2]} //skimCurrArray[skimTable][2]
            Opts.Global.[Start Option] = 1          //start at 0
            Opts.Global.[Start Value] = 0           //minimum
            Opts.Global.[End Option] = 2            //end at maximum time
            Opts.Global.[End Value] = 120           //ignored
            Opts.Global.Method = 2                  //specify bin size
            Opts.Global.Size = skimSize             //read from skimOptions
            Opts.Global.[Statistics Option] = 1     //report to report file
            Opts.Global.[Min Value] = 0             //ignore times below
            Opts.Global.[Max Value] = 99            //ignore times above
            Opts.Output.[Output Matrix].Label = outputLabel
            Opts.Output.[Output Matrix].[File Name] = outputFile  
            
            ret_value = RunMacro("TCB Run Procedure", "TLD", Opts) 
            if !ret_value then Throw()
            
            //convert to text
            m = OpenMatrix(outputFile,)
            path2 = SplitPath(outputFile)
            matrix_cores = GetMatrixCoreNames(m)
        
           for l = 1 to matrix_cores.length do
              mc1 = CreateMatrixCurrency(m, matrix_cores[l], , , )
              mc1 := Nz(mc1)
          end
          CreateTableFromMatrix(m, path2[1]+path2[2]+path2[3]+".csv", "CSV", {{"Complete", "Yes"}})
    
            
        end
    end
                
    RunMacro("Close All")
    
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )


EndMacro
