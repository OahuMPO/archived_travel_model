/********************************************************************************
*
* Report Obs Trip Distribution
* This macro performs trip length frequency distributions and district summaries
* on observed trip tables.
*
* PB - jef 4/08
*
********************************************************************************/
Macro "Report Obs Trip Distribution" 

    RunMacro("TCB Init")

    scenarioDirectory= "c:\\projects\\ompo\\conversion\\application\\2005_base"
    tripDirectory= "c:\\projects\\ompo\\conversion\\data\\observed_trips\\"
    tazFile=scenarioDirectory+"\\inputs\\taz\\Scenario TAZ Layer.dbd"
 
    pkTrips = { "obstrpwh0.mtx",
                "obstrpwh1.mtx",
                "obstrpwh2.mtx",
                "obstrpwha.mtx",
                "obstrpnc0.mtx",
                "obstrpnc1.mtx",
                "obstrpnc2.mtx",
                "obstrpnca.mtx",
                "obstrpnk.mtx",
                "obstrpwn.mtx",
                "obstrpwoa.mtx",
                "obstrpww.mtx"
                }      
    pkSkim = scenarioDirectory+"\\outputs\\hwyam_sov.mtx"
    
    opTrips = { 
                "obstrpan.mtx ",  // hwymd_sov.bin
                "obstrpaw.mtx ",  // hwymd_sov.bin
                "obstrpnn.mtx ",  // hwymd_sov.bin
                "obstrpno0.mtx",  // hwymd_sov.bin
                "obstrpno1.mtx",  // hwymd_sov.bin
                "obstrpno2.mtx",
                "obstrpnoa.mtx",
                "obstrpns0.mtx",
                "obstrpns1.mtx",
                "obstrpns2.mtx",
                "obstrpnsa.mtx"
              }
    opSkim = scenarioDirectory+"\\outputs\\hwymd_sov.mtx"
          
    skimOptions = {  
                { 1, 1.0}, //time, one minute increment
                { 2, 1.0 } //dist, one mile increment
                 }    
                 
    //perform TLFDs
    ret_value = RunMacro("Run TLFDs", tripDirectory, pkTrips, pkSkim, skimOptions)
    if !ret_value then Throw()
   
    ret_value = RunMacro("Run TLFDs", tripDirectory, opTrips, opSkim, skimOptions)
    if !ret_value then Throw()
    
    //perform district summaries
    trips = {
                "obstrpwh0.mtx",
                "obstrpwh1.mtx",
                "obstrpwh2.mtx",
                "obstrpwha.mtx",
                "obstrpnc0.mtx",
                "obstrpnc1.mtx",
                "obstrpnc2.mtx",
                "obstrpnca.mtx",
                "obstrpnk.mtx",
                "obstrpwn.mtx",
                "obstrpwoa.mtx",
                "obstrpww.mtx",
                "obstrpan.mtx ",  
                "obstrpaw.mtx ",  
                "obstrpnn.mtx ",  
                "obstrpno0.mtx",  
                "obstrpno1.mtx",  
                "obstrpno2.mtx",
                "obstrpnoa.mtx",
                "obstrpns0.mtx",
                "obstrpns1.mtx",
                "obstrpns2.mtx",
                "obstrpnsa.mtx"
    }
    ret_value = RunMacro("District Summaries", tripDirectory, trips, tazFile, "TD")    
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
*   tripFiles           An array of trip tables; tlfds will be performed for each core
*   skimFile            A matrix file of skims, full path should be given
*   skimOptions         A two-dimensional array, d1 should be number of core in matrix,
*                       d2 should be bin size for matrix core.  All specified cores
*                       will be used for summary. 
*
************************************************************************************/
Macro "Run TLFDs" (scenarioDirectory, tripFiles, skimFile, skimOptions)

//    dim avgTLength[tripFiles.length]
    
    for i = 1 to tripFiles.length do  // for each trip file
    
        tripFile = scenarioDirectory+tripFiles[i]
    
        // convert binary trip tables to mtx format
        path = SplitPath(tripFile)
        if (path[4] = ".bin"|path[4] = ".BIN"  ) then do
            RunMacro("Convert Binary to Mtx" , {tripFile})
            tripFile = scenarioDirectory+path[3]+".mtx"
        end
    
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

                outputFile = scenarioDirectory+"TLFD_"+path[3]+"_"+skimLabel+".mtx"
                outputLabel = "TLFD_"+path[3]+"_"+skimLabel
                
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
        
        
    end

    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )


EndMacro

/***********************************************************************************
*
* District Summaries
*
* PB - jef 4/08
*
* Script runs district summaries on trip tables, using tazData and district field.
* Summary file written to scenarioDirectory\outputs.
*
* Arguments:
*   scenarioDirectory   Trip tables should be in scenarioDirectory\outputs
*                       Output matrix will be written to scenarioDirectory\outputs
*   tripFiles           An array of trip tables; district aggregation will be performed for each core
*   tazFile             Path to TAZ file, with field TAZ
*   districtField       Name of district field to use for aggregation
*
************************************************************************************/
Macro "District Summaries" (scenarioDirectory, tripFiles, tazFile, districtField)


    for i = 1 to tripFiles.length do
    
        tripFile = scenarioDirectory+tripFiles[i]
    
        // convert binary trip tables to mtx format
        path = SplitPath(tripFile)
        if (path[4] = ".bin"|path[4] = ".BIN"  ) then do
            RunMacro("Convert Binary to Mtx" , {tripFile})
            tripFile = scenarioDirectory+path[3]+".mtx"
        end
    
        tripMatrix = OpenMatrix(tripFile,)
        tripCores = GetMatrixCoreNames(tripMatrix)
        tripCurrArray = CreateMatrixCurrencies(tripMatrix, , ,)
        
        for j = 1 to tripCurrArray.length do
    
            tripTable = tripCores[j]
            tripLabel = Substitute(tripTable, " ", "", ) 
            outputFile = scenarioDirectory+districtField+path[3]+"_"+tripLabel+".mtx"
            outputLabel = districtField+path[3]+"_"+tripTable

            Opts = null
            Opts.Input.[Matrix Currency] = {tripFile, tripCores[j], ,}
            Opts.Input.[Aggregation View] = { tazFile+"|Oahu TAZs", "Oahu TAZs"}
            Opts.Global.[Row Names] = {"[Oahu TAZs].TAZ", "[Oahu TAZs]."+districtField}
            Opts.Global.[Column Names] =  {"[Oahu TAZs].TAZ", "[Oahu TAZs]."+districtField}
            Opts.Output.[Aggregated Matrix].Label = outputLabel
            Opts.Output.[Aggregated Matrix].[File Name] = outputFile
            
            ret_value = RunMacro("TCB Run Operation", "Aggregate Matrix", Opts) 
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
    quit:      
    	Return( RunMacro("TCB Closing", ret_value, True ) )
               
EndMacro       
