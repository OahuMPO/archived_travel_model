Macro "Batch Macro"
    RunMacro("TCB Init")
// STEP 1: Fill Dataview
     Opts = null
     Opts.Input.[Dataview Set] = {"D:\\Honolulu\\hawaii5\\generic\\inputs\\master_network\\Oahu Route System 102907.rts|Route System", "Route System"}
     Opts.Input.[Tag View Set] = {"D:\\Honolulu\\hawaii5\\generic\\inputs\\master_network\\Oahu Network 102907.DBD|Oahu Nodes", "Oahu Nodes"}
     Opts.Global.Fields = {"[Route System].NODENUMBER"}
     Opts.Global.Method = "Tag"
     Opts.Global.Parameter = {"Value", "Oahu Nodes", "[Oahu Nodes].ID"}

     ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)

     if !ret_value then goto quit


    quit:
         Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro

