/**************************************************************
   ModeChoiceReport.rsc
 
  TransCAD Macro used to run mode choice

**************************************************************/
Macro "Report Observed Mode Choice" (scenarioDirectory, tazFile)

    RunMacro("TCB Init")
    scenarioDirectory="c:\\projects\\ompo\\conversion\\application\\2005_base"
    tazFile=scenarioDirectory+"\\inputs\\taz\\Scenario TAZ Layer.dbd"
    
   
    pkSkims = { scenarioDirectory+"\\outputs\\transit_wloc_pk.mtx",     //1 wlk-loc
                scenarioDirectory+"\\outputs\\transit_wexp_pk.mtx",     //2 wlk-exp
                scenarioDirectory+"\\outputs\\transit_pnr_pk.mtx",      //4 pnr-fml
                scenarioDirectory+"\\outputs\\transit_knr_pk.mtx"      //5 pnr-inf
               }
               
    opSkims = { scenarioDirectory+"\\outputs\\transit_wloc_op.mtx",     //1 wlk-loc 
                scenarioDirectory+"\\outputs\\transit_wexp_op.mtx",     //2 wlk-exp 
                scenarioDirectory+"\\outputs\\transit_pnr_op.mtx",      //4 pnr-fml 
                scenarioDirectory+"\\outputs\\transit_knr_op.mtx"      //5 pnr-inf 
               }
    nhbSkims = { scenarioDirectory+"\\outputs\\transit_wloc_op.mtx",     //1 wlk-loc 
                scenarioDirectory+"\\outputs\\transit_wexp_op.mtx" }     //2 wlk-exp 
                           
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
    
    
    //walk local
    wlocOptions =
    { {   2, 1.0},  //   In-Vehicle Time
      {   3, 1.0},  //   Initial Wait Time
      {   4, 1.0},  //   Transfer Wait Time
      {   5, 1.0},  //   Transfer Walk Time
      {   6, 1.0},  //   Access Walk Time
      {   7, 1.0},  //   Egress Walk Time
      {   8, 1.0} } //   Number of Transfers

    //walk express                   
    wexpOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Access Walk Time   
      {   7, 1.0},  //   Egress Walk Time   
      {   8, 1.0} } //   Number of Transfers
                                             
    //pnr-formal                   
    pnrOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Egress Walk Time   
      {   7, 1.0},  //   Access Drive Time  
      {   8, 1.0},  //   Number of Transfers
      {   8, 1.0} } //   Drive Distance     

    //pnr-informal,knr                   
    knrOptions =
    { {   2, 1.0},  //   In-Vehicle Time    
      {   3, 1.0},  //   Initial Wait Time  
      {   4, 1.0},  //   Transfer Wait Time 
      {   5, 1.0},  //   Transfer Walk Time 
      {   6, 1.0},  //   Egress Walk Time   
      {   7, 1.0},  //   Access Drive Time  
      {   8, 1.0},  //   Number of Transfers
      {   8, 1.0} } //   Drive Distance     

    skimOptions = {wlocOptions,wexpOptions,pnrOptions,knrOptions}
    obsDirectory = "c:\\projects\\ompo\\conversion\\data\\observed_trips\\"
                        
    //Run HBW TLFD
    ret_value = RunMacro("Run Transit TLFDs", obsDirectory+"HBWTRN.MTX", pkSkims, skimOptions)
    if !ret_value then Throw()

    //Run HBSchool TLFD
    ret_value = RunMacro("Run Transit TLFDs", obsDirectory+"HBCTRN.MTX", pkSkims, skimOptions)
    if !ret_value then Throw()

    //Run HBO TLFD
    ret_value = RunMacro("Run Transit TLFDs", obsDirectory+"HBOTRN.MTX", opSkims, skimOptions)
    if !ret_value then Throw()
    
    //Run NHB TLFD
    ret_value = RunMacro("Run Transit TLFDs", obsDirectory+"NHBTRN.MTX", nhbSkims, {wlocOptions,wexpOptions})
    if !ret_value then Throw()
    
    

    Return(1)
    
        

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
Macro "Run Transit TLFDs" (tripFile, skimFiles, skimOptions)

    
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
    
            outputFile = path[1]+path[2]+"TLFD_"+path[3]+"_"+skimLabel+"_"+tripLabel+".mtx"
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
                
    Return(1)
    
    	


EndMacro
