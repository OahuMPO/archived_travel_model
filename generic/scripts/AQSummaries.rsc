/*
Kyle:
This script provides additional summaries including:
    VMT/VHT/SpaceMeanSpeed by facility type and area type
    Congested VMT
*/

Macro "AQ Summary" (scenarioDirectory) 
    
    CreateProgressBar("",False)
    UpdateProgressBar("AQ Summary",0)
    
    // for testing
    scenarioDirectory = "C:\\projects\\Honolulu\\Version6\\OMPORepo\\scenarios\\2012_calibration"
    
    // inputs
    inputDir = scenarioDirectory + "\\inputs"
    hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
    vcCutOff = .8   // V/C at .8 is the cut off for a congested link
    
    // outputs
    outputDir = scenarioDirectory + "\\reports"
    aqCSV = outputDir + "\\VMT and Speeds by FT and AT.csv"
    
    // looping arrays
    a_dir = {"AB","BA"}
    a_at = {1,2,3,4,5,6,7,8}        //FIELD: [AB/BA ATYPE]
    a_ft = {1,2,3,4,5,6,7,8,9}    //Field: [AB/BA FNCLASS]
    a_ftname = {"Freeway","Expressway","Principal Arterial","Minor Arterial","Major Collector","Minor Collector","Local","Ramp","CC"}
    a_tod = {"EA","AM","MD","PM","EV"}
    
    // Add the highway layer to the workspace
    {nlyr,llyr} = GetDBLayers(hwyDBD)
    llyr = AddLayerToWorkspace(llyr,hwyDBD,llyr)
    
    file = OpenFile(aqCSV,"w")
    WriteLine(file,"AreaType,FClass,VMT,Congested VMT,Percent,VHT,Space-Mean Speed")
    
    for a = 1 to a_at.length do
        at = a_at[a]
        
        for f = 1 to a_ft.length do
            ft = a_ft[f]
            ftname = a_ftname[f]
            
            vmt = 0
            cvmt = 0
            vht = 0
            sms = 0
                
            for d = 1 to a_dir.length do
                dir = a_dir[d]
                
                // Create a selection set of links in the current AT and FT
                SetLayer(llyr)
                qry = "Select * where [" + dir + " ATYPE] = " + String(at) + " and [" + dir + " FNCLASS] = " + String(ft)
                n = SelectByQuery("selection","Several",qry)
                    
                // perform calculation if some links are selected
                if n > 0 then do
                    
                    for t = 1 to a_tod.length do
                        tod = a_tod[t]
                        
                        // Collect vector data of all necessary fields
                        // v_at = GetDataVector(llyr + "|selection",dir + " ATYPE",)
                        // v_ft = GetDataVector(llyr + "|selection",dir + " FNCLASS",)
                        v_length = GetDataVector(llyr + "|selection","Length",)
                        v_vc = GetDataVector(llyr + "|selection",dir + "_VOC_" + tod,)
                        v_spd = GetDataVector(llyr + "|selection",dir + "_SPD_" + tod,)
                        v_vol = GetDataVector(llyr + "|selection",dir + "_FLOW_" + tod,)
                        
                        // calculate stats
                        v_vmt = v_length * v_vol
                        vmt = vmt + VectorStatistic(v_vmt,"Sum",)
                        v_cvmt = if (v_vc >= vcCutOff) then v_vmt else 0
                        cvmt = cvmt + VectorStatistic(v_cvmt,"Sum",)
                        v_time = v_length / v_spd
                        v_vht = v_time * v_vol
                        vht = vht + VectorStatistic(v_vht,"Sum",)
                    end
                
                
                end
                
            end
            
            if vht = 0 then sms = 0 else sms = vmt / vht
            if vmt = 0 then pct_cvmt = 0 else pct_cvmt = cvmt / vmt * 100                    
            
            // Write out results to the file
            string = String(at) + "," + ftname + "," + String(vmt) + "," + String(cvmt)
            string = string + "," + String(pct_cvmt) + "," + String(vht) + "," + String(sms)
            WriteLine(file, string)
            
        end
        
    end
    
    
    
    
    CloseFile(file)
    DropLayerFromWorkspace(llyr)
    DestroyProgressBar()
    
EndMacro
