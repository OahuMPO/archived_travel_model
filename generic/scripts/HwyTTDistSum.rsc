Macro "Hwy District Summary" (scenarioDirectory, tazFile )

//    RunMacro("TCB Init")                                                                                                                                                                                                                                                                                                                                                                                                                                                              
     
    scenarioDirectory = "F:\\projects\\OMPO\\ORTP2009\\A_Model\\2035Baseline_110125_cmp"
    tazFile = scenarioDirectory + "\\inputs\\taz\\Scenario TAZ Layer.DBD"

    //perform district summaries
    trips = {
                scenarioDirectory+"\\outputs\\hwyAM4Hour.MTX"  
            }
    
    ret_value = RunMacro("District Summaries", trips, tazFile, "TD")    
    if !ret_value then Throw()
       
    Return(1)
    
        
              
EndMacro


