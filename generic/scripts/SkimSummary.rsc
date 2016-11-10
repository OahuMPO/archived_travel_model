/*****************************************************************************************************************************************
* Macro "Skim Summary" (scenarioDirectory)
* 
* Summarizes values from skims and puts them in the taz layer for subsequent mapping 
*
*****************************************************************************************************************************************/
Macro "Skim Summary" (scenarioDirectory)
    
//    RunMacro("TCB Init")

    //scenarioDirectory = "D:\\projects\\ompo\\ORTP2009\\2035CordonPricing_100412_750toll"
    //iftoll=1
    //these are the fields that will be added or replaced in the taz file, and the corresponding TAZs
    newHwyFields = {"Hwy_Downtown", "Hwy_Kapolei", "Hwy_Mililani", "Hwy_Airport", "Hwy_Waikiki","Hwy_Ewa"} 
    newTrnFields = {"Trn_Downtown", "Trn_Kapolei", "Trn_Mililani", "Trn_Airport", "Trn_Waikiki","Trn_Ewa"}
    plotZones =    {  240,           596,           494,            762,           118,            551         }

    dim hwyFound[newHwyFields.length]
    dim trnFound[newTrnFields.length]

    // Set the TAZ table, file
    tazTable = scenarioDirectory +"\\inputs\\taz\\Scenario TAZ Layer.bin"
    tazFile = scenarioDirectory +"\\inputs\\taz\\Scenario TAZ Layer.dbd"
    
    // First open customer.dbf in the Tutorial folder for exclusive access
    view_name = OpenTable("TAZ View", "FFB", {tazTable, null}, {{"Shared", "False"}})
    strct = GetTableStructure(view_name)
    for i = 1 to strct.length do
        // Copy the current name to the end of strct
         strct[i] = strct[i] + {strct[i][1]}
         for k = 1 to hwyFound.length do
            if strct[i][1] = newHwyFields[k] then hwyFound[k] = "True"
         end
         for k = 1 to trnFound.length do
            if strct[i][1] = newTrnFields[k] then trnFound[k] = "True"
         end
    end


    //add hwy fields that don't exist    
    for i = 1 to newHwyFields.length do
        if hwyFound[i] <> "True" then do
            strct = strct + {{newHwyFields[i], "Real", 12, 2, "True", , , , , , , null}}
        end
    end
 
    //add trn fields that don't exist    
    for i = 1 to newTrnFields.length do
        if trnFound[i] <> "True" then do
            strct = strct + {{newTrnFields[i], "Real", 12, 2, "True", , , , , , , null}}
        end
    end

    // Modify the table
    ModifyTable(view_name, strct)
    CloseView(view_name)
    
    //now create the walk-rail transit time matrix
    inskim = scenarioDirectory + "\\outputs\\transit_wfxg_am.mtx"
    outskim = scenarioDirectory + "\\outputs\\transit_bestwlk_am.mtx"
    
   //open input transit matrix
    inMatrix = OpenMatrix(inskim, "True")
    inMatrixCores = GetMatrixCoreNames(inMatrix)
    numCoresIn=inMatrixCores.length 
    matrixInfo=GetMatrixInfo(inMatrix)

    //create inMatrix currencies
    dim inMatrixCurrency[numCoresIn]
    
    ivt = CreateMatrixCurrency(inMatrix, "In-Vehicle Time", null, null, )
    iwt = CreateMatrixCurrency(inMatrix, "Initial Wait Time", null, null, )
    xwt = CreateMatrixCurrency(inMatrix, "Transfer Wait Time", null, null, )
    awk = CreateMatrixCurrency(inMatrix, "Access Walk Time", null, null, )
    ewk = CreateMatrixCurrency(inMatrix, "Egress Walk Time", null, null, )
    twk = CreateMatrixCurrency(inMatrix, "Transfer Walk Time", null, null, )
    dwt = CreateMatrixCurrency(inMatrix, "Dwelling Time", null, null, )
    
    //outMatrix core length 
    numCoresOut=1

    //outMatrix structure
    dim outMatrixStructure[numCoresOut]
    for i=1 to numCoresOut do
	    outMatrixStructure[i]=ivt
	end

    //Create the output transit matrix
    Opts = null
    Opts.[Compression] = 1
    Opts.[Tables] = outMatrixCores
    Opts.[Type] = "Float"
    Opts.[File Name] =outskim
    Opts.[Label] = "Total Transit Time"
    Opts.[Tables] = {"Total Transit Time"}
    outMatrix = CopyMatrixStructure(outMatrixStructure,Opts)
 
    //create outMatrix currencies
    tranTime = CreateMatrixCurrency(outMatrix, "Total Transit Time", null, null, )
    tranTime := ivt + iwt + xwt + awk + ewk + twk + dwt
    
    //open auto skim
    autoskim = scenarioDirectory + "\\outputs\\hwyam_sov.mtx"

    autoMatrix = OpenMatrix(autoskim, "True")
    autoTime = CreateMatrixCurrency(autoMatrix, "*_AMSKIMCOST", null, null, )
    if(cordonPricing=1) then autoTime = CreateMatrixCurrency(autoMatrix, "toll_*_AMSKIMCOST_DATL", null, null, )
        
    //add fields to TAZ layer
    dbInfo = GetDBInfo(tazFile)
    dbLayers = GetDBLayers(tazFile)
    newmap = CreateMap("TempMap",{{"Scope",dbInfo[1]}})
   
    // Add the taz layer to the map and make it visible
    taz_layer=AddLayer("TempMap","Oahu_TAZs", tazFile,dbLayers[1])
    SetLayerVisibility(taz_layer,"True")

    for i = 1 to newHwyFields.length do 
        vec = GetMatrixVector(autoTime, {{"Column", plotZones[i]}}) 
        SetDataVector(taz_layer + "|", newHwyFields[i], vec, {{"Sort Order", {{"TAZ", "A"}} }}) 
    end

    for i = 1 to newTrnFields.length do 
        vec = GetMatrixVector(tranTime, {{"Column", plotZones[i]}}) 
        SetDataVector(taz_layer + "|", newTrnFields[i], vec, {{"Sort Order", {{"TAZ", "A"}} }}) 
    end
    Return(1)           
    
    
    

EndMacro

