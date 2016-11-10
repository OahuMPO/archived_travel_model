Macro "Add Highway Costs" (scenarioDirectory)


     //add the layers
    highway_db=scenarioDirectory+"\\inputs\\network\\Scenario Line Layer.dbd"

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", highway_db,,)
     SetLayer(link_lyr) //Line Layer


        NewFlds = {{"COST_DANT", "real"},
                   {"COST_S2NT", "real"},
                   {"COST_S3NT", "real"},
                   {"COST_DATL", "real"},
                   {"COST_S2TL", "real"},
                   {"COST_S3TL", "real"}}

        // add the new fields to the link layer
         ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
        if !ret_value then Throw()

        costpermile=0.12
        Opts = null
        Opts.Input.[Dataview Set] = {highway_db+"|"+link_lyr, link_lyr}
        Opts.Global.Fields = {"COST_DANT",
                              "COST_S2NT",
                              "COST_S3NT",
                              "COST_DATL",
                              "COST_S2TL",
                              "COST_S3TL"}
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {"Length * "+String(costpermile),
                                 "Length * "+String(costpermile),
                                 "Length * "+String(costpermile),
                                 "Length * "+String(costpermile), // delete this toll cost for a test; take half of hte toll cost in path-building since VOT in assignment is low
                                 "Length * "+String(costpermile),
                                 "Length * "+String(costpermile)}
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()


    Return(1)


        


EndMacro
