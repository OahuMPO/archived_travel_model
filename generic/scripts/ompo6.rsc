
Macro "OMPO6" (path, Options, jump)
    RunMacro("TCB Init")	
    scenarioDirectory = path[2]

    //input files
    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    tazfile=scenarioDirectory+"\\inputs\\taz\\Scenario TAZ Layer.dbd"
    fspdfile=scenarioDirectory+"\\inputs\\other\\fsped.bin"
    cspdfile=scenarioDirectory+"\\inputs\\other\\csped.bin"
    capfile=scenarioDirectory+"\\inputs\\other\\acapa.bin"
    conicalsfile = scenarioDirectory+"\\inputs\\other\\conical.bin"
    hwyfile=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"
    rtsfile=scenarioDirectory+"\\inputs\\network\\Scenario Route System.rts"
    rstopfile=scenarioDirectory+"\\inputs\\network\\Scenario Route SystemS.dbd"
    modefile=scenarioDirectory+"\\inputs\\other\\modes.bin"
    xferfile=scenarioDirectory+"\\inputs\\other\\transfer.bin"
    trnpkfactfile=scenarioDirectory+"\\inputs\\other\\TRANPKTIMEFAC.bin"
    trnopfactfile=scenarioDirectory+"\\inputs\\other\\TRANOPTIMEFAC.bin"
    tpen={scenarioDirectory+"\\inputs\\turns\\am turn penalties.bin",
    	  scenarioDirectory+"\\inputs\\turns\\md turn penalties.bin",
    	  scenarioDirectory+"\\inputs\\turns\\link type turn penalties.bin"}

    // Some constants Used in the model
    nzones=764              
    Counter = 1                                 // Used to decide what to do next at the end of each iteration
    converged=0

    // Options available to user 
    for i = 1 to ArrayLength(Options) do
        if Options[i] = null then do              
            Options[i] = 0
        end
//        Options[i] = StringToInt(Options[i])
    end
    
    //Options
    stop_after_each_step = Options[1]           // Stops the model after each step
    iftoll=Options[2]		                    // indicate if toll is used, 0 means no toll.
    fixgdwy=Options[3]                          // indicate if fixed-guideway is used, 0 means no fixed-guideway
    userben=Options[4]                          // indicate if user benefits are to be written, 0 means no user benefits
    stop_after_each_itr = Options[5]            // Stops the model after each iteration
    iteration=StringToInt(Options[6])           // Get iteration number from GUI
    max_iteration = StringToInt(Options[9])     // Converges by 3rd iteration; user can define max. 
    cordonPricing = Options[10]                 // Cordon pricing:  Reset the non-toll skims to 0 if toll skimmed
    sample_rate = { 0.20, 0.60, 1.0, 1.0, 1.0, 1.0 }
   
   	path_parts = SplitPath(scenarioDirectory)
    path_no_drive = path_parts[2]+path_parts[3]
    drive=path_parts[1]  
    path_forward_slash =  Substitute(path_no_drive, "\\", "/", )
 
    //output files    
    hnetfile=scenarioDirectory+"\\outputs\\hwy.net"
    hwyskim=scenarioDirectory + "\\outputs\\hwyam_sov.mtx"
    trnskim=scenarioDirectory + "\\outputs\\transit_wexp_pk.mtx"
    
    SetReportFileName(scenarioDirectory+"\\Report.xml")
    SetLogFileName(scenarioDirectory+"\\Log.xml")
          
    if jump = "UpdateLineLayer" then goto UpdateLineLayer
    if jump = "HighwaySkim" then goto HighwaySkim        
    if jump = "TransitSkim" then goto TransitSkim            
    if jump = "SpecialMarket" then goto SpecialMarket 
    if jump = "TourBasedModels" then goto TourBasedModels
    if jump = "TimeOfDay" then goto TimeOfDay        
    if jump = "HighwayAssign" then goto HighwayAssign 
    if jump = "TransitAssign" then goto TransitAssign
    if jump = "EJSummaries" then goto EJSummaries
    if jump = "DTArun" then goto DTArun
                
    UpdateLineLayer:
    // Update the line layer with lookup table fields
    args = {hwyfile,tazfile,fspdfile,cspdfile,capfile,conicalsfile,trnpkfactfile,trnopfactfile,nzones}
    ret_value = RunMacro("Update Line Layer", args)
    if !ret_value then goto quit

    TransitAccess:
    // Create the highway network
    ret_value = RunMacro("Create Highway Network" ,hwyfile, hnetfile, iftoll) 
    if !ret_value then goto quit
    
    // Create transit access links
    ret_value = RunMacro("Transit Access Links", scenarioDirectory, hwyfile, rtsfile, nzones,fixgdwy)
    if !ret_value then goto quit
    if stop_after_each_step then goto quit
      
    
    Feedback:       
    //Enter a feedback loop
    while(converged = 0)  do
    
        HighwaySkim:
        
        //first delete some files and move last iteration stuff to its sub-directory
        if (iteration>1) then do
            fromDir = scenarioDirectory+"\\outputs"
            toDir =   scenarioDirectory+"\\outputs\\iter"+String(iteration-1)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\mode*.bin",)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\mode*.dcb",)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\hwy*.bin",)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\hwy*.dcb",)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\transit*.bin",)
            status = RunProgram("cmd.exe /c del "+fromDir+"\\transit*.dcb",)
            if(iteration = 2 ) then do
                status = RunProgram("cmd.exe /c del "+fromDir+"temp*.bin",)
                status = RunProgram("cmd.exe /c del "+fromDir+"temp*.dcb",)
            end
            //check for directory of output
            if GetDirectoryInfo(toDir, "Directory")=null then do
                CreateDirectory( toDir)   
            end
            status = RunProgram("cmd.exe /c copy "+fromDir+"\\*.* "+toDir+"\\*.*",)
            fromDir = scenarioDirectory+"\\reports"
            status = RunProgram("cmd.exe /c copy "+fromDir+"\\*.* "+toDir+"\\*.*",)
        
        end
       
        iftoll = Options[2]    
        ret_value = RunMacro("Highway Skims", scenarioDirectory, hwyfile, tpen, nzones, iftoll, iteration)
        if !ret_value then goto quit
        if stop_after_each_step then goto quit
        
        TransitSkim:
        ret_value = RunMacro("Transit Network and Skim", scenarioDirectory, hwyfile, rtsfile, rstopfile, modefile, xferfile, nzones, iteration)
        if !ret_value then goto quit
        if stop_after_each_step then goto quit
        
        SpecialMarket:
        ret_value = RunMacro("Trip Generation", scenarioDirectory, iftoll, fixgdwy)
        if !ret_value then goto quit
     
        ret_value = RunMacro("Trip Distribution", scenarioDirectory, iftoll)
        if !ret_value then goto quit
        // ret_value = RunMacro("Trip Distribution")
        // if !ret_value then goto quit
        
        ret_value = RunMacro("Report Trip Distribution" , scenarioDirectory, tazfile )
        if !ret_value then goto quit
        
        ret_value = RunMacro("Mode Choice", scenarioDirectory, Options)
        if !ret_value then goto quit
        if stop_after_each_step then goto quit
        
        TourBasedModels:
 			  // Run tour-based model, visitor model
        runString = scenarioDirectory+"\\programs\\runompotbm.cmd "+drive+" "+path_forward_slash +" "+r2s(sample_rate[iteration])+" "+i2s(iteration)
        ret_value = RunMacro("TCB Run Command", 1, "Run Tour-Based Model", runString)
        if stop_after_each_step then goto quit
    
        TimeOfDay:
        ret_value = RunMacro("TOD Factor", scenarioDirectory,fixgdwy, iftoll)
        if !ret_value then goto quit
        
        if(cordonPricing <> 0) then do 
            ret_value = RunMacro("Modify Trips For Cordon Pricing" , scenarioDirectory)
            if !ret_value then goto quit
        end
        if stop_after_each_step then goto quit
            
        
        HighwayAssign:
        ret_value = RunMacro("Highway Assignment", scenarioDirectory, nzones, iteration)
        if !ret_value then goto quit
        if stop_after_each_step then goto quit
        
        CheckConvergence:
        if(iteration>1) then do
            thisSkim = scenarioDirectory+"\\outputs\\hwyam_sov.mtx"
            lastSkim = scenarioDirectory+"\\outputs\\iter"+String(iteration-1)+"\\hwyam_sov.mtx"
            skimPRMSE = RunMacro("Check Convergence", {thisSkim, 1},{lastSkim,1})        
            AppendToLogFile(0, "Iteration "+String(iteration)+" AM SOV PRMSE is "+String(skimPRMSE))
            if(skimPRMSE < 5) then converged = 1             
        end
        
        if(iteration = max_iteration) then converged = 1                  // If the model doesnt converge within the maximum number of iterations, the model is considered to be converged
    
        if (converged <> 1 and stop_after_each_itr = 1 and Counter = 1) then do                        // If the user chooses to pause the application at the end of each iteration
           {iteration, converged, Counter} = RunDbox("Iteration Counter",iteration, max_iteration)     // A seperate dialogebox is shown at the end of each iteration highlighting 
        end                                                                                            // the options available to the user
        
        
        if (stop_after_each_step = 1 and  converged = 0)then do           // This conversion (=2) of the "Converged" value ensures that
            converged = 2                                                 // when running either FinalHighwayAssign or TransitAssign one step of the model at a time
        end  
        
        if(converged = 0) then iteration = iteration + 1
                                                             // the application doesnt get into the iteration loop
    end //feedback loops
 
    if (stop_after_each_step = 1 and  converged = 2) then do          // This back conversion (=0) of the "Converged" value ensures that                                 
        converged = 0                                                 // when running either FinalHighwayAssign or TransitAssign one step of the model at a time  
    end                                                               // the application doesnt get into the iteration loop                                       
   
    if converged = 1 then do
    		
    		
        /*	No final assignment needed fpr tour-based model
        FinalHighwayAssign:
        ret_value = RunMacro("Final Highway Assignment", scenarioDirectory, nzones)
        if !ret_value then goto quit
        */
        Append:                                                                     // Once the model converges and all the assignments are done                         
        ret_value = RunMacro("AppendAssign", scenarioDirectory, iteration)          // The AM peak, PM Peak, and Daily flows are appended to the scenario line layer 
        if !ret_value then goto quit 
        ret_value = RunMacro("Highway Assignment Summary", scenarioDirectory)
        if !ret_value then goto quit
        ret_value = RunMacro("AQ Summary", scenarioDirectory)
        if !ret_value then goto quit
       // Append:                                                                     // Once the model converges and all the assignments are done                         
       // ret_value = RunMacro("AppendAssign", scenarioDirectory, iteration)          // The AM peak, PM Peak, and Daily flows are appended to the scenario line layer 
       // if !ret_value then goto quit                                                                                      

        if stop_after_each_step then goto quit
     end
        
    TransitAssign:
    ret_value = RunMacro("Transit Assignment", scenarioDirectory, rtsfile)
    if !ret_value then goto quit
    ret_value = RunMacro("Screenline Summary", scenarioDirectory, iteration)
    if !ret_value then goto quit
    ret_value = RunMacro("Skim Summary", scenarioDirectory)
    if !ret_value then goto quit

    if !ret_value then goto quit
    if stop_after_each_step then goto quit    
   
      
    EJSummaries:
   // ret_value = RunMacro("Calculate Environmental Justice", scenarioDirectory, nzones)
    
    //don't run dta as part of the regular model
    goto quit  
    	
    DTArun:
    ret_value = RunMacro("OahuMPO DTA", path,options)
    if !ret_value then goto quit
    if stop_after_each_step then goto quit    
       
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
    
EndMacro

Dbox "Iteration Counter" (iteration, converged, Counter)

    Text "The model has not yet converged" 5, 1

    Radio List 1, 3, 38, 7 Prompt: "Would you like to:" Variable: selection

    Radio Button 2, 4.5 Prompt: "Stop at this Iteration & summarize results" do converged = 1 enditem

    Radio Button 2, 6.5 Prompt: "Run another Iteration" do iteration = iteration enditem

    Radio Button 2, 8.5 Prompt: "Run untill convergence & summarize results" do Counter = 0 enditem
     
    button "OK" 7, 11, 10, 1.5 do
		iteration = IntToString(iteration)
		ShowMessage("This is "+iteration+" Iteration")
		iteration = StringToInt(iteration)
		ret = {iteration, max_iteration}
		Return(ret) 
	enditem
        
	button "Cancel" 22, 11, 10, 1.5 cancel do
		//ShowMessage(" Exit")
		Return() 
	enditem

EndDbox