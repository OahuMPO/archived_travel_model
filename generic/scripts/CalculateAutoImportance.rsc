/***********************************************************************************************************************************
*
* Calculate Auto Importance
*
* This macro will calculate the auto importance matrix which is used for the auto ownership model.
* The calculation is based on a weighted accessibility index. It considers highway, walk, and transit time
* (generalized cost) from each origin to the employment in every destination.  This is then summed to 
* determine the relative accessibility from each origin zone by highway compared to all modes.  The macro
* uses the TAZ data table, the auto skims, and the walk-express skims.  The results are written to the taz binary data file.
* 
* TO DO:  walk-express should be replaced by walk-rail if rail is active.
*
***********************************************************************************************************************************/

Macro "Calculate Auto Importance" (scenarioDirectory, tazfile, hwyskim, trnskim, nzones)

    //outputs, keyed to scenarioDirectory
    autoimpskim=scenarioDirectory+"\\outputs\\auto_importance.mtx"
    autoimpskim_bin=scenarioDirectory+"\\outputs\\auto_importance.bin"
    
    //open auto and transit matrices
    hwyMatrix = OpenMatrix(hwyskim, "False")
    matrix_info = GetMatrixInfo(hwyMatrix)
    trnMatrix = OpenMatrix(trnskim, "False")
 
 	hwymatrix_cores = GetMatrixCoreNames(hwyMatrix)

    hwyTime = CreateMatrixCurrency(hwyMatrix, hwymatrix_cores[1], null, null, )
    hwyDist = CreateMatrixCurrency(hwyMatrix, "Length (Skim)", null, null, )
    trnIVT  = CreateMatrixCurrency(trnMatrix, "In-Vehicle Time", null, null, )    
    trnIWT  = CreateMatrixCurrency(trnMatrix, "Initial Wait Time", null, null, )
    trnXWT  = CreateMatrixCurrency(trnMatrix, "Transfer Wait Time", null, null, ) 
    trnACC  = CreateMatrixCurrency(trnMatrix, "Access Walk Time", null, null, )   
    trnEGR  = CreateMatrixCurrency(trnMatrix, "Egress Walk Time", null, null, )   
 
    // Create the auto importance skim
	Opts = null
	Opts.[Compression] = 1
	Opts.[Tables] = {"Weighted Hwy Time","Weighted Walk Time","Weighted Transit Time","Weighted Hwy Time Emp","Weighted Walk Time Emp","Weighted Transit Time Emp"}
	Opts.[Type] = "Float"
	Opts.[File Name] = autoimpskim
	Opts.[Label] = "Relative Auto Importance"
	importanceMatrix = CopyMatrixStructure({trnIVT,trnIVT,trnIVT,trnIVT,trnIVT,trnIVT},Opts)
	    
	// Create the matrix currencies for each matrix
	hwyTimeWeighted = CreateMatrixCurrency(importanceMatrix,"Weighted Hwy Time", null, null, ) 
	wlkTimeWeighted = CreateMatrixCurrency(importanceMatrix,"Weighted Walk Time", null, null, ) 
	trnTimeWeighted = CreateMatrixCurrency(importanceMatrix,"Weighted Transit Time", null, null, ) 
	hwyTimeWeightedEmp = CreateMatrixCurrency(importanceMatrix,"Weighted Hwy Time Emp", null, null, ) 
	wlkTimeWeightedEmp = CreateMatrixCurrency(importanceMatrix,"Weighted Walk Time Emp", null, null, ) 
	trnTimeWeightedEmp = CreateMatrixCurrency(importanceMatrix,"Weighted Transit Time Emp", null, null, ) 
	
    // Get vectors from the taz data file
    pth = SplitPath(tazfile)
    
    tazData = OpenTable("tazData", "FFB",{ pth[1]+pth[2]+pth[3]+".bin" }, {{"Shared", "False"}})
    origTermTime = GetDataVector(tazData+"|", "TERMTIME", {{"Sort Order", {{"TAZ", "Ascending"}}}})
    destTermTime = GetDataVector(tazData+"|", "TERMTIME", {{"Sort Order", {{"TAZ", "Ascending"}}},{"Column Based", "True"}})
    totalEmp  = GetDataVector(tazData+"|", "TOTALEMP", {{"Sort Order", {{"TAZ", "Ascending"}}}})
    
    //get highway time and add terminal times to it-term times weighted by 2
    hwyTimeWeighted := hwyTime + 2.0*(origTermTime + destTermTime)

    // compute walk time-weighted by 2
    wlkTimeWeighted := 2.0*20.0*hwyDist

    //compute weighted transit time
    trnTimeWeighted := trnIVT + 2.0*(trnIWT + trnXWT + trnACC + trnEGR)

    hwyTimeWeightedEmp := totalEmp/(hwyTimeWeighted * hwyTimeWeighted)
    wlkTimeWeightedEmp := totalEmp/(wlkTimeWeighted * wlkTimeWeighted)
    trnTimeWeightedEmp := totalEmp/(trnTimeWeighted * trnTimeWeighted)

    // calculate the column vector of row sums
    hwySums = GetMatrixMarginals(hwyTimeWeightedEmp, "Sum", "row" )
    wlkSums = GetMatrixMarginals(wlkTimeWeightedEmp, "Sum", "row" )
    trnSums = GetMatrixMarginals(trnTimeWeightedEmp, "Sum", "row" )

     // Create a vector for storing the results of the calculation
    autoImportance = Vector(totalEmp.length, "float", {{"Constant", 0.0},})
    hwySumsVec = Vector(totalEmp.length, "float", {{"Constant", 0.0},})
    wlkSumsVec = Vector(totalEmp.length, "float", {{"Constant", 0.0},})
    trnSumsVec = Vector(totalEmp.length, "float", {{"Constant", 0.0},})
    
    for i = 1 to autoImportance.length do
        hwySumsVec[i]=hwySums[i]
        wlkSumsVec[i]=wlkSums[i]
        trnSumsVec[i]=trnSums[i]
        autoImportance[i]= 100.0 * hwySums[i] / (hwySums[i] + wlkSums[i] + trnSums[i])
    end
    
    // add the data to the taz file.  In order to do this, need to create a structure,
    // based on the structure of the existing taz data binary file, but with an added field
    // appended which refers to the original field in the file.  New elements are added to 
    // the end of the array for each new field, but the last field in that element is set to null
    // to indicate that it is a new field.  See ModifyTable() for details.
    strct = GetTableStructure(tazData)
    dim newstrct[strct.length + 4]
    counter = 0 
     // Copy the current name to the end of strct
    for i = 1 to strct.length do
        
        temp =1
        
        if Position(strct[i][1],"Hwy Emp Access")  > 0 then temp=0
        if Position(strct[i][1],"Wlk Emp Access") > 0 then temp=0
        if Position(strct[i][1],"Trn Emp Access")  > 0 then temp=0
        if Position(strct[i][1],"Hwy Emp Importance") > 0 then temp=0
        
        if temp = 1 then do
            counter = counter + 1
            newstrct[counter] = strct[i] + {strct[i][1]}
        end
     end

    // Add fields for new data
    newstrct[counter+1] = {"Hwy Emp Access", "Float", 8, 2, , , , , , , ,null }
    newstrct[counter+2] = {"Wlk Emp Access", "Float", 8, 2, , , , , , , ,null }
    newstrct[counter+3] = {"Trn Emp Access", "Float", 8, 2, , , , , , , ,null }
    newstrct[counter+4] = {"Hwy Emp Importance", "Float", 8, 2, , , , , , , ,null }

    // drop any extra fields
    if(counter < strct.length+4) then newstrct = Subarray(newstrct, 1, counter+4)

    // Modify the table
    ModifyTable(tazData, newstrct)

    // set the data
    SetDataVectors(tazData+"|", {{"Hwy Emp Access", hwySumsVec}, 
                                {"Wlk Emp Access", wlkSumsVec}, 
                                {"Trn Emp Access", trnSumsVec}, 
                                {"Hwy Emp Importance", autoImportance}}, 
                                {{"Sort Order", {{"TAZ", "Ascending"}}}} )
    
    ret_value = RunMacro("Close All")
    if !ret_value then goto quit

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
  
EndMacro
