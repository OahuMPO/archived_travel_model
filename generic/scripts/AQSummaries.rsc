
Macro "AQ Summary" (scenarioDirectory) 
    
    // for testing
    // scenarioDirectory = "C:\\projects\\Honolulu\\Version6\\OMPORepo\\scenarios\\2012_calibration"
    
    RunMacro("Summarized by FT and AT",scenarioDirectory)
    
    // This macro also stratifies by speed bin in order to calculate
    // emissions estimates
    RunMacro("Emission Estimation",scenarioDirectory)
    
    Return(1)
    
EndMacro

/*
    This macro provides additional summaries including:
    VMT/VHT/SpaceMeanSpeed by facility type and area type
    Congested VMT
*/

Macro "Summarized by FT and AT" (scenarioDirectory) 
    
    CreateProgressBar("",False)
    UpdateProgressBar("Summarizing by FT and AT",0)
    
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








/*
    This macro estimates grams of CO2 emission
    using some assumed rates and lookup tables.
*/



Macro "Emission Estimation" (scenarioDirectory) 
    
    CreateProgressBar("",False)
    UpdateProgressBar("Emissions Estimation",0)
    
    // inputs
    inputDir = scenarioDirectory + "\\inputs"
    hwyDBD = inputDir + "\\network\\Scenario Line Layer.dbd"
    // vcCutOff = .8   // V/C at .8 is the cut off for a congested link
    curveTbl = inputDir + "\\aq\\CurveLookup.csv"
    mpgTbl = inputDir + "\\aq\\MPGbySpeed.csv"
    mJpg = 121          // megajoules per gallon of gas
    autoCO2pmJ  = 93.39 // auto CO2 grams emitted per mega joule
    truckCO2pmJ = 98.22 // truck CO2 grams emitted per mega joule
    
    // outputs
    outputDir = scenarioDirectory + "\\reports"
    aqCSV = outputDir + "\\Emissions.csv"
    
    // looping arrays
    a_dir = {"AB","BA"}
    a_at = {1,2,3,4,5,6,7,8}        //FIELD: [AB/BA ATYPE]
    a_ft = {1,2,3,4,5,6,7,8,9}    //Field: [AB/BA FNCLASS]
    a_ftname = {"Freeway","Expressway","Principal Arterial","Minor Arterial","Major Collector","Minor Collector","Local","Ramp","CC"}
    speedStart = 0      // start at 0
    speedMax = 75      // stop at 75
    speedInc = 5        // and increase by 5  (final upper bound is 80)  
    a_tod = {"EA","AM","MD","PM","EV"}
    
    // Add the highway layer to the workspace
    {nlyr,llyr} = GetDBLayers(hwyDBD)
    llyr = AddLayerToWorkspace(llyr,hwyDBD,llyr)
    
    // Open the lookup CSVs
    curveTbl = OpenTable("curveTbl","CSV",{curveTbl})
    mpgTbl = OpenTable("mpgTbl","CSV",{mpgTbl})
    
    file = OpenFile(aqCSV,"w")
    string = "AreaType,FClass,LowerSpeed,UpperSpeed,VMT,AutoVMT,AutoMPG,AutoGallons,AutoCO2(g)"
    string = string + ",TruckVMT,TruckMPG,TruckGallons,TruckCO2(g),TotalCO2(g)"
    WriteLine(file,string)
    
    for a = 1 to a_at.length do
        at = a_at[a]
        
        for f = 1 to a_ft.length do
            ft = a_ft[f]
            ftname = a_ftname[f]
            
            count = nz(count) + 1
            pct = round(count / (a_at.length * a_ft.length) * 100,0)
            UpdateProgressBar("Emission Estimation.  AreaType = " + String(at) + " FacType = " + String(ft),pct)
            
            for s = speedStart to speedMax step speedInc do
                slower = s              // e.g. 0, 5,10
                supper = s + speedInc   // e.g. 5,10,15
                
                // collect data from the lookup tables
                num = ft * 100 + at
                rh = LocateRecord(curveTbl + "|","Lookup",{ft * 100 + at},)
                CURVE = GetRecordValues(curveTbl,rh,)
                rh = LocateRecord(mpgTbl + "|","SpeedStart",{slower},)
                MPG = GetRecordValues(mpgTbl,rh,)
                
                autoMPG = mpgTbl.("MPG_" + String(curveTbl.AutoCurve))
                truckMPG = mpgTbl.("MPG_" + String(curveTbl.TruckCurve))
                
                // Sum these variables up over direction and TOD
                vmt = 0
                autoVMT = 0
                autoGal = 0
                autoEm = 0
                truckVMT = 0
                truckGal = 0
                truckEm = 0
                
                for d = 1 to a_dir.length do
                    dir = a_dir[d]
                    
                    for t = 1 to a_tod.length do
                        tod = a_tod[t]
                        
                        // Create a selection set of AB or BA links in the current
                        // AT, FT, TOD, and speed range
                        SetLayer(llyr)
                        qry = "Select * where [" + dir + " ATYPE] = " + String(at) + " and [" + dir + " FNCLASS] = " + String(ft)
                        qry = qry + " and " + dir + "_SPD_" + tod + " > " + String(slower) + " and " + dir + "_SPD_" + tod + " <= " + String(supper)
                        n = SelectByQuery("selection","Several",qry)
                            
                        // perform calculation if some links are selected
                        if n > 0 then do
                            
                            v_length = GetDataVector(llyr + "|selection","Length",)
                            v_vol = GetDataVector(llyr + "|selection",dir + "_FLOW_" + tod,)
                            
                            // calculate stats
                            v_vmt = v_length * v_vol
                            subvmt = VectorStatistic(v_vmt,"Sum",)  // VMT for just this combo of dir and TOD
                            vmt = vmt + subvmt
                            
                            // autoVMT  = autoVMT  + subvmt * (1 - curveTbl.PctTruck)
                            // if autoMPG = 0 then autoGal = autoGal + 0 else autoGal  = autoGal  + autoVMT / autoMPG
                            // autoEm   = autoEm   + autoGal * mJpg * autoCO2pmJ
                            
                            // truckVMT = truckVMT + subvmt * curveTbl.PctTruck
                            // if truckMPG = 0 then truckGal = truckGal + 0 else truckGal = truckGal + truckVMT / truckMPG
                            // truckEm  = truckEm  + truckGal * mJpg * truckCO2pmJ
                            
                        end
                        
                    end
                    
                autoVMT  = vmt * (1 - curveTbl.PctTruck)
                if autoMPG = 0 then autoGal = 0 else autoGal  = autoVMT / autoMPG
                autoEm   = autoGal * mJpg * autoCO2pmJ
                
                truckVMT = vmt * curveTbl.PctTruck
                if truckMPG = 0 then truckGal = 0 else truckGal = truckVMT / truckMPG
                truckEm  = truckGal * mJpg * truckCO2pmJ
                    
                end
                                  
                
                // Write out results to the file
                string = String(at) + "," + ftname + "," + String(slower) + "," + String(supper)
                string = string + "," + String(vmt) + "," + String(autoVMT) + "," + String(autoMPG)
                string = string + "," + String(autoGal) + "," + String(autoEm) + "," + String(truckVMT)
                string = string + "," + String(truckMPG) + "," + String(truckGal) + "," + String(truckEm)
                string = string + "," + String(autoEm + truckEm)
                WriteLine(file, string)
            end
            
        end
        
    end
    
    
    
    
    CloseFile(file)
    DropLayerFromWorkspace(llyr)
    CloseView(curveTbl)
    CloseView(mpgTbl)
    DestroyProgressBar()
    
EndMacro







