/*
Kyle: rewrite
*/

Macro "Summarize Transit" (scenarioDirectory)                                                                                                                                                                                                                                                                                                                                                                                                                                                            
    
    scenDir = "C:\\projects\\Honolulu\\Version6\\2035_basline_ec_proj_year_2012"
    hwyFile = scenDir + "\\inputs\\network\\Scenario Line Layer.dbd"
    rtsFile = scenDir + "\\inputs\\network\\Scenario Route System.rts"
    outputDir = scenDir + "\\outputs"
    reportDir = scenDir + "\\reports"
    reportFile = reportDir + "\\Transit Summary.csv"
    
    a_accMode = {"WLK"}
    a_tranMode = {"EXP","GDWY","LOC"}
    a_tod = {"PM","AM","MD","EV", "EA"}
    
    // Open file and write headers
    file = OpenFile(reportFile,"w")
    WriteLine(file,GetDateAndTime())
    WriteLine(file,"")
    WriteLine(file,"Route ID,Route Name,Total Boardings")
    
    // Get the list of all route names and IDs
    a_info  = GetDBInfo(hwyFile)
    scope = a_info[1]
    opts = null
    opts.scope = scope
    map = CreateMap("map",opts)
    rlyr = "routes"
    AddRouteSystemLayer(map,rlyr,rtsFile,)
    opts = null
    opts.[Sort Order] = {{"Route_ID","Ascending"}}
    v_allName = GetDataVector(rlyr + "|","Route_Name",opts)
    v_allID = GetDataVector(rlyr + "|","Route_ID",opts)
    opts = null
    opts.Constant = 0
    v_sum = Vector(v_allID.length,"Double",opts)
    
    // Calculate various metrics by looping over the different variables (access mode, transit mode, etc.)
    for a = 1 to a_accMode.length do
        acc = a_accMode[a]
        
        for m = 1 to a_tranMode.length do
            mode = a_tranMode[m]
            
            for t = 1 to a_tod.length do
                tod = a_tod[t]
                
                // Total Boardings ("On's")
                fileName = outputDir + "\\" + acc + "-" + mode + "_" + tod + "_" + "ONOFF.bin"
                dv_tbl = OpenTable("tbl","FFB",{fileName},)
                
                tempFileName = GetTempFileName(".bin")
                // tempFileName = outputDir + "\\!test.bin"
                output_fields = {{"On","Sum",}}
                opts = null
                opts.[Missing as Zero] = 1
                dv_agg = AggregateTable("agg",dv_tbl + "|","FFB",tempFileName,"ROUTE",output_fields,opts)
                
                opts = null
                opts.[Sort Order] = {{"ROUTE","Ascending"}}
                v_ROUTE = GetDataVector(dv_agg + "|","ROUTE",)
                v_On = GetDataVector(dv_agg + "|","On",)
                
                // Add current vector into summation vector
                // loop over
                for v = 1 to v_allID.length do
                    id = v_allID[v]
                    pos = ArrayPosition(V2A(v_ROUTE),{id},)
                    if pos != 0 then v_sum[v] = v_sum[v] + v_On[pos]
                end
                
                CloseView(dv_agg)
                CloseView(dv_tbl)
            end
        end
    end
    

    
    // Write the results out to the report file by looping over the final route ID vector
    for i = 1 to v_allID.length do
        WriteLine(file,String(v_allID[i]) + "," + v_allName[i] + "," + String(v_sum[i]))
    end
    CloseFile(file)
    CloseMap(map)
    ShowMessage("Done")
EndMacro
