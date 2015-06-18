Macro "MC Cordon Summaries" (scenarioDirectory)
                                                                                                                                                                                                                                                                                                                                                                                                                                                            

    scenarioDirectory = "D:\\projects\\ompo\\ORTP2009\\2035CordonPricing_100412_750toll"

    
//  get all the MC matrices
   mcFiles = {scenarioDirectory+"\\outputs\\mode5wh.mtx",
              scenarioDirectory+"\\outputs\\mode5wo.mtx",
              scenarioDirectory+"\\outputs\\mode5ww.mtx",
              scenarioDirectory+"\\outputs\\mode5wn.mtx",
              scenarioDirectory+"\\outputs\\mode5nk.mtx",
              scenarioDirectory+"\\outputs\\mode5nc.mtx",
              scenarioDirectory+"\\outputs\\mode5aw.mtx",
              scenarioDirectory+"\\outputs\\mode5an.mtx",
              scenarioDirectory+"\\outputs\\mode5ns.mtx",
              scenarioDirectory+"\\outputs\\mode5no.mtx",
              scenarioDirectory+"\\outputs\\mode5nn.mtx"}
              


    for i = 1 to mcFiles.length do
    //create mode choice output files for cordon trips only
    	parts = SplitPath(mcFiles[i])
        CopyFile(mcFiles[i], parts[1]+parts[2]+parts[3]+"_cordon.mtx")
   end

 
    outputDirectory = scenarioDirectory+"\\outputs\\"
    
/// DO THE PEAK PURPOSES FIRST

   hskimfile={outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx",
                outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx",
                outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx",
                outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_sov.mtx"}

   mcCordonFiles = {scenarioDirectory+"\\outputs\\mode5wh_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5wo_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5ww_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5wn_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5nk_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5nc_cordon.mtx"}

        
   for i = 1 to mcCordonFiles.length do
   
        tripMatrix = OpenMatrix( mcCordonFiles[i],)
        tripCores = GetMatrixCoreNames(tripMatrix)
        
        //for each mode
        for j = 1 to 12 do
           skimMatrix = OpenMatrix( hskimfile[j],)
           skimCores = GetMatrixCoreNames(skimMatrix)

           tollCostCurrency      = CreateMatrixCurrency(skimMatrix, skimCores[5], , , )
           tripCurrency          = CreateMatrixCurrency(tripMatrix, tripCores[j], , , )
 
           
           tripCurrency := if tollCostCurrency=0 then 0 else tripCurrency
        end

    end

////DO A MATRIX SUMMARY AND OUTPUT ALL THIS STUFF TO THE REPORT FILE
    //initialize stuff
    dim inTotals[mcFiles.length, 12]
    dim outTotals[mcCordonFiles.length, 12]
    //open input trip tables (original MC tables)
    dim inMat [mcFiles.length]
    for i = 1 to mcFiles.length do
        inMat[i] = OpenMatrix(mcFiles[i],)
        
        //matrix totals
        inModeNames  = GetMatrixCoreNames(inMat[i])
        stat_array = MatrixStatistics(inMat[i],)
        
        for j = 1 to inModeNames.length do
            inTotals[i][j] = stat_array.(inModeNames[j]).Sum
        end
        
    end

   //write the table for inputs to the report file
    AppendToReportFile(0, "Mode Choice Summary", {{"Section", "True"}})
    fileColumn = { {"Name", "File"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to inModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/inModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "Mode Choice Input File Totals (Region)"}})

    for i = 1 to mcFiles.length do
        path = SplitPath(mcFiles[i])
        fileName = path[3]
        outRow = null
        for j = 1 to inModeNames.length do
            outRow =  outRow  + {inTotals[i][j] }
        end
        outRow = { fileName } + outRow  
        AppendRowToReportFile(outRow,)
    end
    
    //open output trip tables (cordon MC tables)
     dim outMat[mcCordonFiles.length]
    
    // sum the output matrices
   for i = 1 to mcCordonFiles.length do
        outMat[i] = OpenMatrix(mcCordonFiles[i],)
        outModeNames  = GetMatrixCoreNames(outMat[i])
        stat_array = MatrixStatistics(outMat[i],)
        
        for j = 1 to outModeNames.length do
            outTotals[i][j] = stat_array.(outModeNames[j]).Sum
        end

    end   
    //write out the table of outputs now to the report file (these are the cordon summaries)

    fileColumn = { {"Name", "File"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to outModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/outModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "Mode Choice Output File Totals (Cordon)"}})

    for i = 1 to mcCordonFiles.length do
        path = SplitPath(mcCordonFiles[i])
        fileName = path[3]
        outRow = null
        for j = 1 to outModeNames.length do
            outRow =  outRow  + {outTotals[i][j] }
        end
        outRow = { filename } + outRow  
        AppendRowToReportFile(outRow,)
    end


////// DO THE OFFPEAK PURPOSES NOW
   hskimfile={outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_hov2.mtx",outputDirectory+"hwymd_hov3.mtx",
                outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx",
                outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx",
                outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_sov.mtx"}

   mcCordonFiles = {scenarioDirectory+"\\outputs\\mode5aw_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5an_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5ns_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5no_cordon.mtx",
                    scenarioDirectory+"\\outputs\\mode5nn_cordon.mtx"}

        
   for i = 1 to mcCordonFiles.length do
   
        tripMatrix = OpenMatrix( mcCordonFiles[i],)
        tripCores = GetMatrixCoreNames(tripMatrix)
        
        //for each mode
        for j = 1 to 12 do
           skimMatrix = OpenMatrix( hskimfile[j],)
           skimCores = GetMatrixCoreNames(skimMatrix)

           tollCostCurrency      = CreateMatrixCurrency(skimMatrix, skimCores[5], , , )
           tripCurrency          = CreateMatrixCurrency(tripMatrix, tripCores[j], , , )
 
           
           tripCurrency := if tollCostCurrency=0 then 0 else tripCurrency
        end

    end

    //open output trip tables (cordon MC tables)
     dim outMat[mcCordonFiles.length]
     dim outTotals[mcCordonFiles.length, 12]
    
    // sum the output matrices
   for i = 1 to mcCordonFiles.length do
        outMat[i] = OpenMatrix(mcCordonFiles[i],)
        outModeNames  = GetMatrixCoreNames(outMat[i])
        stat_array = MatrixStatistics(outMat[i],)
        
        for j = 1 to outModeNames.length do
            outTotals[i][j] = stat_array.(outModeNames[j]).Sum
        end

    end   
    //write out the table of outputs now to the report file (these are the cordon summaries)

    fileColumn = { {"Name", "Period"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to outModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/outModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "Mode Choice Input File Totals (Cordon)"}})

    for i = 1 to mcCordonFiles.length do
        path = SplitPath(mcCordonFiles[i])
        fileName = path[3]
        outRow = null
        for j = 1 to outModeNames.length do
            outRow =  outRow  + {outTotals[i][j] }
        end
        outRow = { filename } + outRow  
        AppendRowToReportFile(outRow,)
    end

    CloseReportFileSection()


   
    Return(1)
    quit:

EndMacro