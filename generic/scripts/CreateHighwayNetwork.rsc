/*******************************************************************************************************************************
*   Create Highway Network 
*
*   Create a highway network from a highway line layer.
*
*   Arguments:
*       hwyfile     The line layer
*       hnetfile    The highway network to create
*
*******************************************************************************************************************************/
Macro "Create Highway Network" (hwyfile, hnetfile, iftoll) 
    
    vot=15.00
    dollarspermile = 0.12
    distfactor = 60/(vot/dollarspermile)
        

    ab_eacost = "AB_EATIME"
    ba_eacost = "BA_EATIME"
    ab_amcost = "AB_AMTIME"
    ba_amcost = "BA_AMTIME"
    ab_mdcost = "AB_MDTIME"
    ba_mdcost = "BA_MDTIME"
    ab_pmcost = "AB_PMTIME"
    ba_pmcost = "BA_PMTIME"
    ab_evcost = "AB_EVTIME"
    ba_evcost = "BA_EVTIME"

    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    hwy_node_lyr = hwyfile + "|" + node_lyr
    hwy_link_lyr = hwyfile + "|" + link_lyr
    SetLayer(link_lyr) //Line Layer  
    
    //if there is a vot for assignment, compute the cost field
    if(vot > 0) then do 
    
        NewFlds = {{"AB_EASKIMCOST", "real"},{"BA_EASKIMCOST", "real"},
        	         {"AB_AMSKIMCOST", "real"},{"BA_AMSKIMCOST", "real"},
                   {"AB_MDSKIMCOST", "real"},{"BA_MDSKIMCOST", "real"},
                   {"AB_PMSKIMCOST", "real"},{"BA_PMSKIMCOST", "real"},
                   {"AB_EVSKIMCOST", "real"},{"BA_EVSKIMCOST", "real"}}     
    
        // add the new fields to the link layer
        ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
        if !ret_value then Throw()
    
        Opts = null
        Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}	
        Opts.Global.Fields = {"AB_EASKIMCOST","BA_EASKIMCOST",
        	                    "AB_AMSKIMCOST","BA_AMSKIMCOST",
                              "AB_MDSKIMCOST","BA_MDSKIMCOST",
                              "AB_PMSKIMCOST","BA_PMSKIMCOST",
                              "AB_EVSKIMCOST","BA_EVSKIMCOST"}

        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {ab_eacost+ " + "+String(distfactor)+" * Length",
                                 ba_eacost+ " + "+String(distfactor)+" * Length",
                                 ab_amcost+ " + "+String(distfactor)+" * Length",
                                 ba_amcost+ " + "+String(distfactor)+" * Length",
                                 ab_mdcost+ " + "+String(distfactor)+" * Length",                                  
                                 ba_mdcost+ " + "+String(distfactor)+" * Length",                                  
                                 ab_pmcost+ " + "+String(distfactor)+" * Length",                                  
                                 ba_pmcost+ " + "+String(distfactor)+" * Length",                                  
                                 ab_evcost+ " + "+String(distfactor)+" * Length",                                 
                                 ba_evcost+ " + "+String(distfactor)+" * Length"                                
                                 }
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()
            
        if(iftoll <> 0) then do
            
            NewFlds = {{"AB_EASKIMCOST_DATL", "real"},{"BA_EASKIMCOST_DATL", "real"},
            	         {"AB_AMSKIMCOST_DATL", "real"},{"BA_AMSKIMCOST_DATL", "real"},
            	         {"AB_MDSKIMCOST_DATL", "real"},{"BA_MDSKIMCOST_DATL", "real"},
            	         {"AB_PMSKIMCOST_DATL", "real"},{"BA_PMSKIMCOST_DATL", "real"},
                       {"AB_EVSKIMCOST_DATL", "real"},{"BA_EVSKIMCOST_DATL", "real"},  
                       {"AB_EASKIMCOST_S2TL", "real"},{"BA_EASKIMCOST_S2TL", "real"},
                       {"AB_AMSKIMCOST_S2TL", "real"},{"BA_AMSKIMCOST_S2TL", "real"},  
                       {"AB_MDSKIMCOST_S2TL", "real"},{"BA_MDSKIMCOST_S2TL", "real"},
                       {"AB_PMSKIMCOST_S2TL", "real"},{"BA_PMSKIMCOST_S2TL", "real"},  
                       {"AB_EVSKIMCOST_S2TL", "real"},{"BA_EVSKIMCOST_S2TL", "real"},
                       {"AB_EASKIMCOST_S3TL", "real"},{"BA_EASKIMCOST_S3TL", "real"},
                       {"AB_AMSKIMCOST_S3TL", "real"},{"BA_AMSKIMCOST_S3TL", "real"},
                       {"AB_MDSKIMCOST_S3TL", "real"},{"BA_MDSKIMCOST_S3TL", "real"},
                       {"AB_PMSKIMCOST_S3TL", "real"},{"BA_PMSKIMCOST_S3TL", "real"},
                       {"AB_EVSKIMCOST_S3TL", "real"},{"BA_EVSKIMCOST_S3TL", "real"}}          
           
            // add the new fields to the link layer
            ret_value = RunMacro("TCB Add View Fields", {link_lyr, NewFlds})
            if !ret_value then Throw()
        
            Opts = null
            Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}	
            Opts.Global.Fields = {"AB_EASKIMCOST_DATL","BA_EASKIMCOST_DATL",
            	                    "AB_AMSKIMCOST_DATL","BA_AMSKIMCOST_DATL",
            	                    "AB_MDSKIMCOST_DATL","BA_MDSKIMCOST_DATL",
            	                    "AB_PMSKIMCOST_DATL","BA_PMSKIMCOST_DATL",
            	                    "AB_EVSKIMCOST_DATL","BA_EVSKIMCOST_DATL",
                                  "AB_EASKIMCOST_S2TL","BA_EASKIMCOST_S2TL",
                                  "AB_AMSKIMCOST_S2TL","BA_AMSKIMCOST_S2TL",
                                  "AB_MDSKIMCOST_S2TL","BA_MDSKIMCOST_S2TL",
                                  "AB_PMSKIMCOST_S2TL","BA_PMSKIMCOST_S2TL",
                                  "AB_EVSKIMCOST_S2TL","BA_EVSKIMCOST_S2TL",
                                  "AB_EASKIMCOST_S3TL","BA_EASKIMCOST_S3TL",
                                  "AB_AMSKIMCOST_S3TL","BA_AMSKIMCOST_S3TL",
                                  "AB_MDSKIMCOST_S3TL","BA_MDSKIMCOST_S3TL",
                                  "AB_PMSKIMCOST_S3TL","BA_PMSKIMCOST_S3TL",
                                  "AB_EVSKIMCOST_S3TL","BA_EVSKIMCOST_S3TL"}
            Opts.Global.Method = "Formula"
            Opts.Global.Parameter = {ab_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL1/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL2/100 *0.5)/"+String(vot)+ " * 60)",                                     
                                     ab_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_eacost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_amcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_mdcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_pmcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ab_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)",
                                     ba_evcost+ " + ("+String(distfactor)+" * Length) + ((TOLL3/100 *0.5)/"+String(vot)+ " * 60)"}
            ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
            if !ret_value then Throw()
                
        end
    end

    
    // Create a selection set to exclude the transit only links and walk connectors while creating a highway network for highway skimming 
    No_Tran_Link = SelectByQuery("NTL", "Several", "Select * where ([AB FACTYPE] != 14 & [AB FACTYPE] != 197)",)

    //*************************************************** Create Highway Network ***************************************************
    Opts = null
    Opts.Input.[Link Set] = {hwyfile+"|"+link_lyr, link_lyr,"NTL"}
    Opts.Global.[Network Options].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
    Opts.Global.[Network Options].[Node ID] = node_lyr+".ID"
    Opts.Global.[Network Options].[Link ID] = link_lyr+".ID"
    Opts.Global.[Network Options].[Turn Penalties] = "Yes"
    Opts.Global.[Network Options].[Keep Duplicate Links] = "FALSE"
    Opts.Global.[Network Options].[Ignore Link Direction] = "FALSE"
    Opts.Global.[Network Options].[Time Unit] = "Minutes"
    
    if(iftoll = 0) then do
      Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}}, 
     				  {"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}}, 
     				  {"*_FFTIME", {link_lyr+".AB_FFTIME", link_lyr+".BA_FFTIME", , , "False"}}, 
     				  {"*_EATIME", {link_lyr+".AB_EATIME", link_lyr+".BA_EATIME", , , "False"}}, 
     				  {"*_AMTIME", {link_lyr+".AB_AMTIME", link_lyr+".BA_AMTIME", , , "False"}}, 
     				  {"*_MDTIME", {link_lyr+".AB_MDTIME", link_lyr+".BA_MDTIME", , , "False"}}, 
     				  {"*_PMTIME", {link_lyr+".AB_PMTIME", link_lyr+".BA_PMTIME", , , "False"}}, 
      			  {"*_EVTIME", {link_lyr+".AB_EVTIME", link_lyr+".BA_EVTIME", , , "False"}}, 
    				  {"TOLL1", {link_lyr+".TOLL1", link_lyr+".TOLL1", , , "False"}}, 
     				  {"TOLL2", {link_lyr+".TOLL2", link_lyr+".TOLL2", , , "False"}}, 
     				  {"TOLL3", {link_lyr+".TOLL3", link_lyr+".TOLL3", , , "False"}},
     				  {"*_ALPHA", {link_lyr+".[AB_ALPHA]", link_lyr+".[BA_ALPHA]", , , "False"}},
     				  {"*_EASKIMCOST", {link_lyr+".AB_EASKIMCOST", link_lyr+".BA_EASKIMCOST", , , "False"}},
     				  {"*_AMSKIMCOST", {link_lyr+".AB_AMSKIMCOST", link_lyr+".BA_AMSKIMCOST", , , "False"}},
     				  {"*_MDSKIMCOST", {link_lyr+".AB_MDSKIMCOST", link_lyr+".BA_MDSKIMCOST", , , "False"}},
     				  {"*_PMSKIMCOST", {link_lyr+".AB_PMSKIMCOST", link_lyr+".BA_PMSKIMCOST", , , "False"}},
     				  {"*_EVSKIMCOST", {link_lyr+".AB_EVSKIMCOST", link_lyr+".BA_EVSKIMCOST", , , "False"}}
     				  }
    end
    else do
      Opts.Global.[Link Options] = {{"Length", {link_lyr+".Length", link_lyr+".Length", , , "False"}}, 
     				  {"*_FACTYPE", {link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]", , , "False"}}, 
     				  {"*_FFTIME", {link_lyr+".AB_FFTIME", link_lyr+".BA_FFTIME", , , "False"}}, 
     				  {"*_EATIME", {link_lyr+".AB_EATIME", link_lyr+".BA_EATIME", , , "False"}}, 
     				  {"*_AMTIME", {link_lyr+".AB_AMTIME", link_lyr+".BA_AMTIME", , , "False"}}, 
     				  {"*_MDTIME", {link_lyr+".AB_MDTIME", link_lyr+".BA_MDTIME", , , "False"}}, 
     				  {"*_PMTIME", {link_lyr+".AB_PMTIME", link_lyr+".BA_PMTIME", , , "False"}}, 
      			  {"*_EVTIME", {link_lyr+".AB_EVTIME", link_lyr+".BA_EVTIME", , , "False"}}, 
     				  {"TOLL1", {link_lyr+".TOLL1", link_lyr+".TOLL1", , , "False"}}, 
     				  {"TOLL2", {link_lyr+".TOLL2", link_lyr+".TOLL2", , , "False"}}, 
     				  {"TOLL3", {link_lyr+".TOLL3", link_lyr+".TOLL3", , , "False"}},
     				  {"*_ALPHA", {link_lyr+".[AB_ALPHA]", link_lyr+".[BA_ALPHA]", , , "False"}},
      			  {"*_EASKIMCOST", {link_lyr+".AB_EASKIMCOST", link_lyr+".BA_EASKIMCOST", , , "False"}},
     				  {"*_AMSKIMCOST", {link_lyr+".AB_AMSKIMCOST", link_lyr+".BA_AMSKIMCOST", , , "False"}},
     				  {"*_MDSKIMCOST", {link_lyr+".AB_MDSKIMCOST", link_lyr+".BA_MDSKIMCOST", , , "False"}},
     				  {"*_PMSKIMCOST", {link_lyr+".AB_PMSKIMCOST", link_lyr+".BA_PMSKIMCOST", , , "False"}},
     				  {"*_EVSKIMCOST", {link_lyr+".AB_EVSKIMCOST", link_lyr+".BA_EVSKIMCOST", , , "False"}},
     				  {"*_EASKIMCOST_DATL", {link_lyr+".AB_EASKIMCOST_DATL", link_lyr+".BA_EASKIMCOST_DATL", , , "False"}},
     				  {"*_AMSKIMCOST_DATL", {link_lyr+".AB_AMSKIMCOST_DATL", link_lyr+".BA_AMSKIMCOST_DATL", , , "False"}},
     				  {"*_MDSKIMCOST_DATL", {link_lyr+".AB_MDSKIMCOST_DATL", link_lyr+".BA_MDSKIMCOST_DATL", , , "False"}},
     				  {"*_PMSKIMCOST_DATL", {link_lyr+".AB_PMSKIMCOST_DATL", link_lyr+".BA_PMSKIMCOST_DATL", , , "False"}},
     				  {"*_EVSKIMCOST_DATL", {link_lyr+".AB_EVSKIMCOST_DATL", link_lyr+".BA_EVSKIMCOST_DATL", , , "False"}},
     				  {"*_EASKIMCOST_S2TL", {link_lyr+".AB_EASKIMCOST_S2TL", link_lyr+".BA_EASKIMCOST_S2TL", , , "False"}},
     				  {"*_AMSKIMCOST_S2TL", {link_lyr+".AB_AMSKIMCOST_S2TL", link_lyr+".BA_AMSKIMCOST_S2TL", , , "False"}},
     				  {"*_MDSKIMCOST_S2TL", {link_lyr+".AB_MDSKIMCOST_S2TL", link_lyr+".BA_MDSKIMCOST_S2TL", , , "False"}},
     				  {"*_PMSKIMCOST_S2TL", {link_lyr+".AB_PMSKIMCOST_S2TL", link_lyr+".BA_PMSKIMCOST_S2TL", , , "False"}},
     				  {"*_EVSKIMCOST_S2TL", {link_lyr+".AB_EVSKIMCOST_S2TL", link_lyr+".BA_EVSKIMCOST_S2TL", , , "False"}},
     				  {"*_EASKIMCOST_S3TL", {link_lyr+".AB_EASKIMCOST_S3TL", link_lyr+".BA_EASKIMCOST_S3TL", , , "False"}},
     				  {"*_AMSKIMCOST_S3TL", {link_lyr+".AB_AMSKIMCOST_S3TL", link_lyr+".BA_AMSKIMCOST_S3TL", , , "False"}},
     				  {"*_MDSKIMCOST_S3TL", {link_lyr+".AB_MDSKIMCOST_S3TL", link_lyr+".BA_MDSKIMCOST_S3TL", , , "False"}},
     				  {"*_PMSKIMCOST_S3TL", {link_lyr+".AB_PMSKIMCOST_S3TL", link_lyr+".BA_PMSKIMCOST_S3TL", , , "False"}},
     				  {"*_EVSKIMCOST_S3TL", {link_lyr+".AB_EVSKIMCOST_S3TL", link_lyr+".BA_EVSKIMCOST_S3TL", , , "False"}}
     				  }
   end        
        
        
    // Opts.Global.[Node Options] = {{"[ID:1]", {node_lyr+".[ID:1]", , }}, 
    Opts.Global.[Node Options] = {{"[ID]", {node_lyr+".[ID]", , }}, 
        {"X", {node_lyr+".X", , }}, {"Y", {node_lyr+".Y", , }}
    }
    Opts.Global.[Length Unit] = "Miles"
    Opts.Global.[Time Unit] = "Minutes"
    Opts.Output.[Network File] = hnetfile

    ret_value = RunMacro("TCB Run Operation", "Build Highway Network", Opts, &Ret)
    if !ret_value then Throw()

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )
endMacro
