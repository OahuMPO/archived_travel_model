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
*   tripFiles           An array of trip tables; district aggregation will be performed for each core
*   tazFile             Path to TAZ file, with field TAZ
*   districtField       Name of district field to use for aggregation
*
************************************************************************************/
Macro "District Summaries" (tripFiles, tazFile, districtField)


    for i = 1 to tripFiles.length do
    
        tripFile = tripFiles[i]
    
        // convert binary trip tables to mtx format
        path = SplitPath(tripFile)
        if (path[4] = ".bin"|path[4] = ".BIN"  ) then do
            RunMacro("Convert Binary to Mtx" , {tripFile})
            tripFile = path[1]+path[2]+path[3]+".mtx"
        end
    
        tripMatrix = OpenMatrix(tripFile,)
        tripCores = GetMatrixCoreNames(tripMatrix)
        tripCurrArray = CreateMatrixCurrencies(tripMatrix, , ,)
        
        for j = 1 to tripCurrArray.length do
    
            tripTable = tripCores[j]
            tripLabel = Substitute(tripTable, " ", "", ) 
            outputFile = path[1]+path[2]+districtField+path[3]+"_"+tripLabel+".mtx"
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
 
    RunMacro("Close All")
    
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
