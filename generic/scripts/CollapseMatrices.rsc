/***********************************************************************************************************************************
*
* Collapse Matrices
* Macro collapses trip tables in multiple files according to an array.
*
* Arguments:
*   inFiles             Array of input file names.  Each file does not have to have the same number of matrix cores,
*                       but there cannot be an entry in the tableArray for a non-existant core (it must be 0).
*   tableArray          A 2-dimensional table, dimensioned by inFiles and maximum number of matrix cores across all input files.
*                       The entry in the table corresponds to the number of the core in the output file that the core in the input
*                       file should be added to.
*   outFile             Path/name of output file.
*   coreNames           Array of core names for output file; should be dimensioned accordingly.
*   description         Description for output file.
*
***********************************************************************************************************************************/
Macro "Collapse Matrices" (inFiles, tableArray, outFile, coreNames, description)

    //if input files not equal to table array dimension 1 length, error
    if (inFiles.length != tableArray.length) then do
    	MessageBox("Error in Collapse Matrix, inFiles not equal to tableArray for "+description, )
    	Return(0)
    end

    //open the input matrices and matrix currencies
    dim inMat[inFiles.length]
    dim inCur[inFiles.length]
    dim cNames[inFiles.length]
    for i = 1 to inFiles.length do
        inMat[i]  = OpenMatrix(inFiles[i],)
        inCur[i]  = CreateMatrixCurrencies(inMat[i], , ,)
        cNames[i]= GetMatrixCoreNames(inMat[i])
    end

    maxTable = 0

    //determine number of tables in outFile
    for i= 1 to tableArray.length do
        for j = 1 to tableArray[i].length do
            maxTable = Max(tableArray[i][j], maxTable)
        end
    end

    // if coreNames isn't dimensioned by maxTable, error
    if (coreNames.length < maxTable) then do
    	MessageBox("Error in Collapse Matrix, file names not given for all cores specified in tableArray for "+description, )
    	Return(0)
    end

    // create the output table
    Opts = null
    Opts.[File Name] = outFile
    Opts.Label = description
    Opts.Type = "Float"
    Opts.Tables = coreNames
    Opts.[Column Major] = "No"
    Opts.[File Based] = "Yes"
    Opts.Compression = True

    rowLabels = GetMatrixRowLabels(inCur[1].(cNames[1][1]))
    zones = rowLabels.length
    outMat = CreateMatrixFromScratch(description, zones, zones, Opts)
    outCur = CreateMatrixCurrencies(outMat, , ,)

    //initialize all matrices to 0
    for i = 1 to outCur.length do
        outCore = outCur.(coreNames[i])
        outCore := 0
    end

    // iterate through the tableArray and collapse
    for i= 1 to tableArray.length do
        for j = 1 to tableArray[i].length do

            outTable = tableArray[i][j]

            //if the outTable isn't 0, add the input table to the output table
            if(outTable !=0) then do
                inCore = inCur[i].(cNames[i][j])
                outCore = outCur.(coreNames[outTable])
                outCore := outCore + inCore
            end
        end
    end

    // Sum the output tables in the output file and report
    dim outTotals[coreNames.length]
    stat_array = MatrixStatistics(outMat,)
    for j = 1 to coreNames.length do
        outTotals[j] = stat_array.(coreNames[j]).Sum
    end

    //write the table for inputs to the report file
    AppendToReportFile(0, "Collapse Matrices", {{"Section", "True"}})
    fileColumn = { {"Name", "Matrix"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    tripColumn = { {"Name", "Total"},  {"Percentage Width", 80}, {"Alignment", "Left"}, {"Decimals", 0} }

    columns = {fileColumn} + { tripColumn }
    path = SplitPath(outFile)
    AppendTableToReportFile( columns, {{"Title", "Collapse Matrix Table Totals for "+path[3]}})

    for j = 1 to coreNames.length do
        outRow = { coreNames[j] } + { outTotals[j]}
        AppendRowToReportFile(outRow,)
    end
    CloseReportFileSection()

    RunMacro("Close All")

    Return(1)
     
    	

EndMacro
