Macro "Factor Visitor Observed" (ScenarioDirectory)

//    RunMacro("TCB Init")

    ScenarioDirectory="f:\\projects\\ompo\\ortp2009\\c_model\\2030tsm_setdist_110428"

    currentYear = 2030
    // Find the groth factor for the current year
    visitorGFTable = ScenarioDirectory + "\\inputs\\other\\Visitor Growth Factors.bin"
    visitorGF = OpenTable("visitorGF", "FFB", {visitorGFTable})
    SetView("visitorGF")
		rh = LocateRecord("visitorGF|", "Year", {currentYear}, )
		GF = GetRecordValues("visitorGF", rh, {"[Growth Factor]"})
		temp11 = GF[1][2] 
    CloseView("visitorGF")

    // Modify the observed visitor trips based on the groth factors
    Opts = null
		Opts.Input.[Matrix Currency] = {ScenarioDirectory + "\\inputs\\visobs.mtx", "Table 1", , }
		Opts.Global.Method = 5
		Opts.Global.[Cell Range] = 2
		Opts.Global.[Matrix Range] = 1
		Opts.Global.[Matrix List] = {"Table 1"}
		Opts.Global.[Value] = GF[1][2]
		Opts.Global.[Force Missing] = "Yes"
		
		ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    Return(1)    



    Opts = null
    Opts.Input.[Matrix Currency] = { KNRfile, "OPTime", "Orig", "Dest"}
    Opts.Global.Method = 11
    Opts.Global.[Cell Range] = 2
    Opts.Global.[Expression Text] = "if([OPTime]=0) then null else [OPTime]"
    Opts.Global.[Force Missing] = "Yes"
    ret_value = RunMacro("TCB Run Operation", "Fill Matrices", Opts) 
    if !ret_value then goto quit






    
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

    
EndMacro
