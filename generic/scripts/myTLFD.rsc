Macro "My TLFD" (scenarioDirectory)
                                                                                                                                                                                                                                                                                                                                                                                                                                                            

    scenarioDirectory = "D:\\projects\\ompo\\ORTP2009\\2035ManagedLane_100330"
    
//***NOW RUN THE TLFDS FOR ALL THE MATRICES IN THE TRIP FILE (SOV)
    pkTrips = {
                "peakPASOVTollTrips.mtx"
              } 
    pkSkim = scenarioDirectory+"\\outputs\\hwyam_sov.mtx"
    
    opTrips = { 
                "offpeakPASOVTollTrips.mtx"
              
              }
    opSkim = scenarioDirectory+"\\outputs\\hwymd_sov.mtx"
          
    skimOptions = {  
                { 7, 1.0 }, //time savings, one minute increment
                { 8, 1.0 }  //toll savings, one dollar increment
                 }    
                 
    //perform TLFDs
    ret_value = RunMacro("Run TLFD", scenarioDirectory, pkTrips, pkSkim, skimOptions)
    if !ret_value then goto quit
   
    ret_value = RunMacro("Run TLFD", scenarioDirectory, opTrips, opSkim, skimOptions)
    if !ret_value then goto quit

//***NOW RUN THE TLFDS FOR ALL THE MATRICES IN THE TRIP FILE (HOV2)
    pkTrips = {
                "peakPAHOV2TollTrips.mtx"
              } 
    pkSkim = scenarioDirectory+"\\outputs\\hwyam_hov2.mtx"
    
    opTrips = { 
                "offpeakPAHOV2TollTrips.mtx"
              
              }
    opSkim = scenarioDirectory+"\\outputs\\hwymd_hov2.mtx"
          
    skimOptions = {  
                { 7, 1.0 }, //time savings, one minute increment
                { 8, 1.0 }  //toll savings, one dollar increment
                 }    
                 
    //perform TLFDs
    ret_value = RunMacro("Run TLFD", scenarioDirectory, pkTrips, pkSkim, skimOptions)
    if !ret_value then goto quit
   
    ret_value = RunMacro("Run TLFD", scenarioDirectory, opTrips, opSkim, skimOptions)
    if !ret_value then goto quit

//***NOW RUN THE TLFDS FOR ALL THE MATRICES IN THE TRIP FILE (HOV3)
    pkTrips = {
                "peakPAHOV3TollTrips.mtx"
              } 
    pkSkim = scenarioDirectory+"\\outputs\\hwyam_hov3.mtx"
    
    opTrips = { 
                "offpeakPAHOV3TollTrips.mtx"
              
              }
    opSkim = scenarioDirectory+"\\outputs\\hwymd_hov3.mtx"
          
    skimOptions = {  
                { 7, 1.0 }, //time savings, one minute increment
                { 8, 1.0 }  //toll savings, one dollar increment
                 }    
                 
    //perform TLFDs
    ret_value = RunMacro("Run TLFD", scenarioDirectory, pkTrips, pkSkim, skimOptions)
    if !ret_value then goto quit
   
    ret_value = RunMacro("Run TLFD", scenarioDirectory, opTrips, opSkim, skimOptions)
    if !ret_value then goto quit

    Return(1)

    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
///
/***********************************************************************************
*
* Run TLFD
*
* PB - jef 4/08
*
* Script runs trip length frequency distributions on trip tables, using skim provided.
* Report written to report file and summary files written to scenarioDirectory\reports.
*
* Arguments:
*   scenarioDirectory   Trip tables and skims should be in scenarioDirectory\outputs
*                       Output TLFD matrix will be written to scenarioDirectory\ouputs
*   tripFiles           An array of trip tables; tlfds will be performed for each core
*   skimFile            A matrix file of skims, full path should be given
*   skimOptions         A two-dimensional array, d1 should be number of core in matrix,
*                       d2 should be bin size for matrix core.  All specified cores
*                       will be used for summary. 
*
************************************************************************************/
Macro "Run TLFD" (scenarioDirectory, tripFiles, skimFile, skimOptions)
//        RunMacro("TCB Init")
    
    for i = 1 to tripFiles.length do  // for each trip file
    
        tripFile = scenarioDirectory+"\\outputs\\"+tripFiles[i]
        path = SplitPath(tripFile)
///        // convert binary trip tables to mtx format
///        path = SplitPath(tripFile)
///        if (path[4] = ".bin"|path[4] = ".BIN"  ) then do
///            RunMacro("Convert Binary to Mtx" , {tripFile})
///            tripFile = scenarioDirectory+"\\outputs\\"+path[3]+".mtx"
///        end
    
        tripMatrix = OpenMatrix(tripFile,)
        tripCores = GetMatrixCoreNames(tripMatrix)
        tripCurrArray = CreateMatrixCurrencies(tripMatrix, , ,)
        stat_array = MatrixStatistics(tripMatrix,)

        skimMatrix = OpenMatrix(skimFile,)
        skimCores = GetMatrixCoreNames(skimMatrix)
        skimCurrArray = CreateMatrixCurrencies(skimMatrix, , ,)

        dim avgLength[tripCores.length,skimCores.length]
        
        for j = 1 to tripCurrArray.length do  //for each trip table on each file
        
            tripTable = tripCores[j]
            tripLabel = Substitute(tripTable, " ", "", ) 
            tripIndex = GetMatrixIndex(tripMatrix)

            for k = 1 to skimOptions.length do  //for each skim
            

                skimTable = skimOptions[k][1]
                skimSize  = skimOptions[k][2]
                skimName  = skimCores[skimTable]
                skimIndex = GetMatrixIndex(skimMatrix)
               
                skimLabel = Substitute(skimName, "*", "", )
                skimLabel = Substitute(skimLabel, "_", "", )
                skimLabel = Substitute(skimLabel, " ", "", )
                skimLabel = Substitute(skimLabel, "(Skim)", "", )

                outputFile = scenarioDirectory+"\\outputs\\TLFD_"+path[3]+"_"+skimLabel+"_"+tripLabel+".mtx"
                outputLabel = "TLFD_"+path[3]+"_"+skimLabel+"_"+tripLabel
                
                Opts = null
                Opts.Input.[Base Currency] =  {tripFile, tripCores[j],tripIndex[1] ,tripIndex[2]} //tripCurrArray[j][2] 
                Opts.Input.[Impedance Currency] = {skimFile, skimCores[skimTable], skimIndex[1], skimIndex[2]} //skimCurrArray[skimTable][2]
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
                if !ret_value then goto quit
                
                //convert to text
                m = OpenMatrix(outputFile,)
		        path2 = SplitPath(outputFile)
		        matrix_cores = GetMatrixCoreNames(m)
		    
		       for l = 1 to matrix_cores.length do
		          mc1 = CreateMatrixCurrency(m, matrix_cores[l], , , )
                  mc1 := Nz(mc1)
              end
    	      CreateTableFromMatrix(m, path2[1]+path2[2]+path2[3]+".csv", "CSV", {{"Complete", "Yes"}})

                
/*
                shared d_matrix_options               
                // calculate average trip length
                skimMC = skimCurrArray.(skimCores[skimTable])
                tripMC = tripCurrArray.(tripCores[j])

                tempMatrix = CopyMatrix(tripMC, 
                    {{"File Name", scenarioDirectory+"\\outputs\\tempMatrix.mtx"},
//                    {"Label", "Temp Matrix"},
                    {"File Based", "Yes"}})
             
                
                tempCurrArray=CreateMatrixCurrencies(tempMatrix, , ,)
                tempMC = tempCurrArray.(tripCores[j])
                tempMC := skimMC * tripMC

                tripSum = stat_array.(tripCores[j]).Sum
                
                tempStat = MatrixStatistics(tempMatrix,)

                tempSum = skimStat.(tripCores[j]).Sum
        
                if(tripSum > 0) then do
                    avgLength[j][k] = tempSum/tripSum
                    end
                else do
                     avgLength[j][k] = 0
                end
*/
            end
        end
        
        
    end

    RunMacro("Close All")
    
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )


EndMacro

//*************************************************************
//
// A utility macro that will close all open map windows
//
//*************************************************************
Macro "Close All"
    // RunMacro("TCB Init")
    maps = GetMapNames()
    
    if(maps = null) then goto view
    for i = 1 to maps.length do
	    CloseMap(maps[i])
    end
    
    view:
    views = GetViewNames()
    if(views = null) then goto quit
    for i = 1 to views.length do
        if( !Left(views[i],2)="c:") then CloseView(views[i])
    end

    return(RunMacro("G30 File Close All"))

    quit:
    Return(1)
EndMacro
