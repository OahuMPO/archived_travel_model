/**************************************************************************************************************
* The Setup of the highway network update and skim procedure:							
*
* 1. All the input and output files are defined in the beginning of the macro named "Highway Skims".		
*
* 2. Before running this script, make sure the highway geographic file has correct values for and consistency	 
*    between key fields, e.g., facility type, limit[i]/m/p, lanea/m/p for AB and BA directions, etc. 
*
* 3. Before using this script, make sure that the input files including the following fields:			
*
*    (1) TAZ file: base year: 
*       POP                             Total zonal population (input)
*       TOTALEMP		                Total zonal employment (input)
*       AREA                            Total zonal area (input)
*       POP_DEN                         Zonal population density (calculated)   
*       EMP_DEN                         Zonal employment density (calculated)
*       ATYPE                           Zonal area type 1-8 (calculated)
*    (2) Link layer: 												
*       [AB FACTYPE],[BA FACTYPE]       Link facility type (input)
*    	[AB_LIMIT[i]],[BA_LIMIT[i]]         AM Peak period limit field (input)
*    	[AB_LIMITM],[BA_LIMITM]         Midday period limit field (input)
*    	[AB_LIMITP],[BA_LIMITP]         PM Peak period limit field (input)
*       [AB_LANEA],[BA_LANEA]           AM Number of lanes (input)
*       [AB_LANEM],[BA_LANEM]           Midday number of lanes (input)
*       [AB_LANEP],[BA_LANEP]	        PM Number of lanes (input)
*       AB_ATYPE,BA_ATYPE           Link area type 1-8 (calculated based on zone that link is in)
* 	    [AB Speed],[BA Speed]           Free-flow speed (calculated based on fspd file)
*       AB_FFTIME,BA_FFTIME             Free-flow time (calculated) 
*	    	[AB Peak Speed],[BA Peak Speed]	Initial congested speed (calculated based on cspd file)
* 	    [AB Capacity],[BA Capacity]	    Capacity per lane/per hour (calculated based on capacity file) 							
* 	    AB_AMCAP,BA_AMCAP               AM peak period capacity (calculated)
*       AB_MDCAP,BA_MDCAP               Midday period capacity (calculated)
*       AB_PMCAP,BA_PMCAP			    PM peak period capacity (calculated)
* 	    AB_EATIME,BA_EATIME             Early AM period congested travel time from highway assignment (calculated from FFTIME)
*       AB_AMTIME,BA_AMTIME             AM period congested travel time from highway assignment	(calculated from CSPD)	
* 	    AB_MDTIME,BA_MDTIME             Midday period congested travel time from highway assignment (calculated from FFTIME)
*       AB_PMTIME,BA_PMTIME             PM period period congested travel time from highway assignment	(calculated from CSPD)	
* 	    AB_EVTIME,BA_EVTIME             Evening period congested travel time from highway assignment (calculated from FFTIME)
* 	    TOLL1                           Length if GP toll facility (TODO: calculate) 
*       TOLL2                           Length if SR2+ toll facility (TODO: calculate)
*       TOLL3						               	Length if SR3+ toll facility (TODO: calculate)		
*
* 4. Highway skim setup:											
*    (1) Highway links used in the different skims:								
* 	    Non-Toll Skims: 
*           SOV Skims:                  limit=0,1,6 
*           HOV2 Skims:                 limit=0,1,2,6
*           HOV3+ Skims:                limit=0,1,2,3,6				
* 	    Toll Skims: 
*           SOV NT:                     limit=0,1,6 
*           HOV2 NT:                    limit=0,1,2,6,11 
*           HOV3+ NT:                   limit=0,1,2,3,6,11,12		
* 		    SOV Toll:                   limit=0,1,6,10,11,12 
*           HOV2 Toll:                  limit=0,1,2,6,10,11,12 			
* 		    HOV3+ Toll:                 limit=0,1,2,3,6,10,11,12							
*    (2) Skimmed variables:											
* 	    Non-Toll Skims: 
*           Congested travel time
*           length
* 	    Toll Skims
*           Congested travel time
*           length
*           TOLL1-3
*           lengths on different toll facilities.									
*    
*       The variable "iftoll" is used to identify if toll facilities are included and the toll skims are created.	
*
*
*  Limit Fields:
*  0 = no restrictions
*  1 = no restrictions
*  2 = HOV2+, no SOVs
*  3 = HOV3+, no SOV or HOV2
*  6 = no restrictions
*  10 = toll facility - SOV, HOV2, and HOV3+ pay
*  11 = HOT facility - SOV pays, HOV2 and HOV3+ free
*  12 = HOT facility - SOV and HOV2 pay, HOV3+ free
**************************************************************************************************************/

Macro "Highway Skims" (scenarioDirectory, hwyfile, tpen, nzones, iftoll, iteration)
//    RunMacro("TCB Init")
    shared args

    //scenarioDirectory="C:\\projects\\ompo\\conversion\\application\\2005_base"
    
    ret_value = RunMacro("Highway Skim",scenarioDirectory, hwyfile, tpen, nzones, iftoll, iteration)
    if !ret_value then Throw()
    
    
    if(iteration = 1) then do
        nonmotorized:
        ret_value = RunMacro("Non-Motorized Matrix", scenarioDirectory, hwyfile, nzones)
        if !ret_value then Throw()
    
        ones:
        ret_value = RunMacro("Ones Matrix", scenarioDirectory, nzones)
        if !ret_value then Throw()
    end
    
    Return(1)
    
    	
EndMacro
/**********************************************************************************************************************
*
*   Highway Skim
*   Creates peak and off-peak highway skims.
*
*   This macro will create a highway skims for the peak and off-peak time periods.  Skims are described above.
*   Arguments:
*       scenarioDirectory   Directory for scenario
*       hwyfile             The highway line layer
*       tpen                An array of 3 files: AM turn penalties, Midday turn penalties, linktype turn penalties
*       nzones              Number of TAZs
*       iftoll              0 for no toll skims, 1 for toll skims
*       iteration           Feedback iteration number
*
**********************************************************************************************************************/
Macro "Highway Skim" (scenarioDirectory, hwyfile,  tpen, nzones, iftoll, iteration)

  
    outputDirectory = scenarioDirectory+"\\outputs"
    
    //check for directory of output network
    if GetDirectoryInfo(outputDirectory, "Directory")=null then do
        CreateDirectory( outputDirectory)   
    end

    //add the slash to the output directory
    outputDirectory = outputDirectory+"\\"

    vot=15.00
    dollarspermile = 0.12
    distfactor = 60/(vot/dollarspermile)
    
    linktypeturns = tpen[3]
    
    {node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile,,)  
    hwy_node_lyr = hwyfile + "|" + node_lyr
    hwy_link_lyr = hwyfile + "|" + link_lyr

    hnetfile=scenarioDirectory+"\\outputs\\hwy.net"
    eacost = "*_EASKIMCOST"
    amcost = "*_AMSKIMCOST"
    mdcost = "*_MDSKIMCOST"
    pmcost = "*_PMSKIMCOST"
    evcost = "*_EVSKIMCOST"
    
    costField = {eacost,amcost,mdcost,pmcost,evcost}

    turnPen = {tpen[2],tpen[1],tpen[2],tpen[1],tpen[2]}
     
    ab_limit= {"[AB_LIMITM]","[AB_LIMITA]","[AB_LIMITM]","[AB_LIMITP]","[AB_LIMITM]"}
    ba_limit= {"[BA_LIMITM]","[BA_LIMITA]","[BA_LIMITM]","[BA_LIMITP]","[BA_LIMITM]"}

  //recompute peak and off-peak speed in case model is being re-run in iteration 1
    if(iteration = 1) then do
 
        Opts = null
        Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr}	
        Opts.Global.Fields = { "AB_EATIME","BA_EATIME", 
        	                     "AB_AMTIME","BA_AMTIME", 
        	                     "AB_MDTIME","BA_MDTIME", 
        	                     "AB_PMTIME","BA_PMTIME", 
        	                     "AB_EVTIME","BA_EVTIME" 
        	                     }
        Opts.Global.Method = "Formula"
        Opts.Global.Parameter = {
                             "AB_FFTIME",                  "BA_FFTIME",
                             "Length / [AB Peak Speed]*60","Length / [BA Peak Speed]*60",
                             "AB_FFTIME",                  "BA_FFTIME", 
                             "Length / [AB Peak Speed]*60","Length / [BA Peak Speed]*60",
                             "AB_FFTIME",                  "BA_FFTIME"                              
                             }
        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        if !ret_value then Throw()
            
        //and re-create the highway network
        ret_value = RunMacro("Create Highway Network" ,hwyfile, hnetfile, iftoll) 
        if !ret_value then Throw()
            
    end    
    
    //in second plus iteration, need to recompute generalized cost using MSA cost in flow table,
    //then need to update networks with new fields

    periods = {"EA","AM","MD","PM","EV"}
    
    if(iteration > 1) then do 
   
        
        for i = 1 to 5 do 
        
       		flowTable = scenarioDirectory+"\\outputs\\"+periods[i]+"Flow"+String(iteration-1)+".bin"
        	
        	// The Dataview Set is a joined view of the link layer and the pk flow table, based on link ID
    			Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, flowTable, {"ID"}, {"ID1"}},periods[i]+"join"}	
    			Opts.Global.Fields = {"AB_"+periods[i]+"SKIMCOST","BA_"+periods[i]+"SKIMCOST"}  // the field to fill
        	Opts.Global.Method = "Formula"                                          // the fill method
    			Opts.Global.Parameter = {"AB_MSA_Cost + "+String(distfactor)+" * Length",
    	                             "BA_MSA_Cost + "+String(distfactor)+" * Length"}   
    			ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    			if !ret_value then Throw()
    	
        end    
    
        if(iftoll <> 0 ) then do
            
          for i = 1 to 5 do 

        		flowTable = scenarioDirectory+"\\outputs\\"+periods[i]+"Flow"+String(iteration-1)+".bin"

           // The Dataview Set is a joined view of the link layer and the pk flow table, based on link ID
          	Opts.Input.[Dataview Set] = {{hwyfile+"|"+link_lyr, flowTable, {"ID"}, {"ID1"}},periods[i]+"jointoll" }	
          	Opts.Global.Fields = {"AB_"+periods[i]+"SKIMCOST_DATL","BA_"+periods[i]+"SKIMCOST_DATL",
        	                        "AB_"+periods[i]+"SKIMCOST_S2TL","BA_"+periods[i]+"SKIMCOST_S2TL", 
        	                        "AB_"+periods[i]+"SKIMCOST_S3TL","BA_"+periods[i]+"SKIMCOST_S3TL" }  // the field to fill
            Opts.Global.Method = "Formula"                                          // the fill method
          	Opts.Global.Parameter = {"AB_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL1/100 * 0.5)/"+String(vot)+"*60)",
        	                           "BA_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL1/100 * 0.5)/"+String(vot)+"*60)",
                                     "AB_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL2/100 * 0.5)/"+String(vot)+"*60)",
        	                           "BA_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL2/100 * 0.5)/"+String(vot)+"*60)",
        	                           "AB_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL3/100 * 0.5)/"+String(vot)+"*60)",
        	                           "BA_MSA_Cost + ("+String(distfactor)+" * Length) + ((TOLL3/100 * 0.5)/"+String(vot)+"*60)" }   
        		ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
        		if !ret_value then Throw()
        	
      		end            
        end
    	
    end
    
    for i = 1 to periods.length do
      period = periods[i]
    // Link selection for skimming:
    //
    // Limit field:
    //  0 = All vehicles can use
    //  1 = All vehicles can use
    //  2 = No SOV or trucks  (HOV 2+ Lanes)
    //  3 = No SOV, HOV2, or trucks (HOV 3+ Lanes)
    //  6 = No Trucks
    //
    // The selection will result in a set of links that will be disabled in the Highway Network Setting step
    //
    
    	if iftoll=0 then do
        // No toll, 3 sets of skims for the period: SOV, HOV2, HOV3+ 
    		excl_qry={"!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=6 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=6)" +  ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=6 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=6)"  + ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=3 | "+ab_limit[i]+"=6 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=3 | "+ba_limit[i]+"=6)" + ")"
				}
    	
    		// minimizing cost field 
  	    CostFld = {costField[i],costField[i],costField[i]} 
    		skmmode={"SOV "+periods[i],"HOV2 "+periods[i],"HOV3 "+periods[i]}
    		network={hnetfile,hnetfile,hnetfile}
    		turns={turnPen[i],turnPen[i],turnPen[i]}
    		skimNames={"sov","hov2","hov3"}

    	end
    	else do
    
        SetLayer(link_lyr)
 
        // Link selection for skimming:
        // toll, 6 sets of skims: SOV-NT, HOV-NT, HOV3+ NT, SOV-TOLL, HOV2-TOLL, HOV3+ TOLL
    		excl_qry={"!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=6 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=6)" + ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=6 | "+ab_limit[i]+"=11 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=6 | "+ba_limit[i]+"=11)" + ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=3 | "+ab_limit[i]+"=6 | "+ab_limit[i]+"=11 | "+ab_limit[i]+"=12| "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=3 | "+ba_limit[i]+"=6 | "+ba_limit[i]+"=11 | "+ba_limit[i]+"=12)" + ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=6 | "+ab_limit[i]+"=10 | "+ab_limit[i]+"=11 | "+ab_limit[i]+"=12 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=6 | "+ba_limit[i]+"=10 | "+ba_limit[i]+"=11 | "+ba_limit[i]+"=12)" + ")",
    	          "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=6 | "+ab_limit[i]+"=10 | "+ab_limit[i]+"=11 | "+ab_limit[i]+"=12 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=6 | "+ba_limit[i]+"=10 | "+ba_limit[i]+"=11 | "+ba_limit[i]+"=12)" + ")",
    	        "!(("+ab_limit[i]+"=0 | "+ab_limit[i]+"=1 | "+ab_limit[i]+"=2 | "+ab_limit[i]+"=3 | "+ab_limit[i]+"=6 | "+ab_limit[i]+"=10 | "+ab_limit[i]+"=11 | "+ab_limit[i]+"=12 | "+ba_limit[i]+"=0 | "+ba_limit[i]+"=1 | "+ba_limit[i]+"=2 | "+ba_limit[i]+"=3 | "+ba_limit[i]+"=6 | "+ba_limit[i]+"=10 | "+ba_limit[i]+"=11 | "+ba_limit[i]+"=12)" + ")"}
	  
	  		// minimizing cost field
    		CostFld = {costField[i],costField[i],costField[i],costField[i]+"_DATL",costField[i]+"_S2TL",costField[i]+"_S3TL"}
    		skmmode={"SOVNT "+periods[i],"HOV2NT "+periods[i],"HOV3NT "+periods[i],"SOVT "+periods[i],"HOV2T "+periods[i],"HOV3T "+periods[i]}
     		network={hnetfile,hnetfile,hnetfile,hnetfile,hnetfile,hnetfile}
    		turns={turnPen[i],turnPen[i],turnPen[i],turnPen[i],turnPen[i],turnPen[i]}
    		skimNames={"sov","hov2","hov3","sovt","hov2t","hov3t"}

     	end
    
    
   		dim hskimfile[periods.length,excl_qry.length]

    	//*************************************************** Highway Network Setting ***************************************************

    	// for each set of skims (Time periods * occupancy * toll choice if applicable)   
    	for j=1 to excl_qry.length do
        
        
        hskimfile[i][j] = outputDirectory+"hwy"+periods[i]+"_"+skimNames[j]+".mtx"
          
        
        // First enable all links, and set the line layer and network properties
    		Opts = null
    		Opts.Input.Database = hwyfile
    		Opts.Input.Network = network[j]
     		Opts.Input.[Centroids Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+String(nzones)}
     		Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr}
     		Opts.Input.[Spc Turn Pen Table] = {turns[j]}
     		Opts.Input.[Link Type Turn Penalties] = linktypeturns
     		Opts.Flag.[Use Link Types] = "True"
     		Opts.Global.[Global Turn Penalties] = {0, 0, 0, 0}
     		Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
     		Opts.Global.[Update Link Options].Type = "Enable"
     		Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
     		Opts.Global.[Update Network Fields].Formulas = {}
     		
        // kyle: updating this to always include travel time info
        Opts.Global.[Update Network Fields].Links = {
          {"time", { link_lyr+".AB_"+period+"TIME",  link_lyr+".BA_"+period+"TIME", , , "True"}}
        }
        ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
        if !ret_value then Throw()

     		if(iteration>1) then do
     	    
     	    //update the highway network with the fields from the line layer (that were computed based on the flow table)
     	    if(iftoll=0) then do
     	      Opts.Global.[Update Network Fields].Links = {
               {costField[i],{ link_lyr+".AB_"+periods[i]+"SKIMCOST",  link_lyr+".BA_"+periods[i]+"SKIMCOST", , , "True"}}
            }
          end
          else do
     	      Opts.Global.[Update Network Fields].Links = {{costField[i],        { link_lyr+".AB_"+periods[i]+"SKIMCOST",  link_lyr+".BA_"+periods[i]+"SKIMCOST", , , "True"}},
     	                                                   {costField[i]+"_DATL",{ link_lyr+".AB_"+periods[i]+"SKIMCOST_DATL",  link_lyr+".BA_"+periods[i]+"SKIMCOST_DATL", , , "True"}},
     	                                                   {costField[i]+"_S2TL",{ link_lyr+".AB_"+periods[i]+"SKIMCOST_S2TL",  link_lyr+".BA_"+periods[i]+"SKIMCOST_S2TL", , , "True"}},
     	                                                   {costField[i]+"_S3TL",{ link_lyr+".AB_"+periods[i]+"SKIMCOST_S3TL",  link_lyr+".BA_"+periods[i]+"SKIMCOST_S3TL", , , "True"}}}     
          end
        end

    		ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    		if !ret_value then Throw()

    		set = "exclusivelinks"
    	
    		// vw_set is the toll set
    		vw_set = link_lyr + "|" + set
    		SetLayer(link_lyr)
    	
    		// now create a selection set of the links to disable
    		n = SelectByQuery(set, "Several","Select * where "+excl_qry[j],)
    	
    		// and disable the links that aren't relevant for this mode (occupancy/toll)
    		if n <> 0 then do
    	    Opts.Input.[Update Link Set] = {hwyfile+"|"+link_lyr, link_lyr, "Selection", "Select * where "+excl_qry[j]}
    	    Opts.Global.[Update Link Options].[Link ID] = link_lyr+".ID"
    	    Opts.Global.[Update Link Options].Type = "Disable"
     	    Opts.Global.[Update Network Fields].[Link Type] = {"*_FACTYPE", link_lyr+".[AB FACTYPE]", link_lyr+".[BA FACTYPE]"}
     	    Opts.Global.[Update Network Fields].Formulas = {}
    	    ret_value = RunMacro("TCB Run Operation", "Highway Network Setting", Opts, &Ret)
    	    if !ret_value then Throw()
    		end
        
        //*************************************************** Highway Skim ***************************************************
    	
    		// Set options for TCSPMAT:  Multiple shortest paths
    		Opts = null
    		Opts.Input.Network = network[j]
    		Opts.Input.[Origin Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid", "Select * where ID<="+String(nzones)}
    		Opts.Input.[Destination Set] = {hwyfile+"|"+node_lyr, node_lyr, "Centroid"}
    		Opts.Input.[Via Set] = {hwyfile+"|"+node_lyr, node_lyr}
    		Opts.Field.Minimize = CostFld[j]
    		Opts.Field.Nodes = node_lyr+".ID"
	    
	    	// always skim length
        // kyle: and travel time
	    	skmfld={
          {"Length","All"},
          {"time", "All"}
        }
        
    		// skim toll length
    		set = "Toll Length"
    		vw_set = link_lyr + "|" + set
    		SetLayer(link_lyr)
    		n = SelectByQuery(set, "Several","Select * where "+ab_limit[i]+"=10 | "+ba_limit[i]+"=10 | "+ab_limit[i]+"=11 | "+ba_limit[i]+"=11 |" +ab_limit[i]+"=12 | "+ba_limit[i]+"=12",)
    		if n = 0 then tollLengthSet=null    //reset value if no selection records
    		else tollLengthSet={vw_set, {"Length"}}

        // If creating toll skims, create the toll skim set (always skim toll, and length on toll facility if there are any links in the selection set)
    		SkimVar = null
	    	if iftoll<>0 then do
  	       // add the toll fields to skim, as set above
     	  	if (j=4 )  then SkimVar = {"TOLL1"}
         	if (j=5 )  then SkimVar = {"TOLL2"}
     	   	if (j=6 )  then SkimVar = {"TOLL3"}
	       	for k=1 to SkimVar.length do
	           skmfld=skmfld+{{SkimVar[k],"All"}}
	       	end
    	   	skimsetfld=null
    	   
    	   	//Toll length
    	   	if (j>=4 & j<=6) then do  
    	    	if tollLengthSet <> null then do
    	            skimsetfld=skimsetfld+{tollLengthSet}
    	   		end 
    	      Opts.Field.[Skim by Set]=skimsetfld
	    		end
	    	end
    	
    		// final options
      	Opts.Field.[Skim Fields]=skmfld
    		Opts.Output.[Output Matrix].Label = "congested "+skmmode[j]+" impedance"
    		Opts.Output.[Output Matrix].Compression = 1
    		Opts.Output.[Output Matrix].[File Name] = hskimfile[i][j]
        
        // perform the skimming
    		ret_value = RunMacro("TCB Run Procedure", "TCSPMAT", Opts, &Ret)
    		if !ret_value then Throw()
    	    
    		//copy skims before factoring
    		parts = SplitPath(hskimfile[i][j])
        CopyFile(hskimfile[i][j], parts[1]+parts[2]+parts[3]+"_orig.mtx")
    	
    		// since the cost matrix includes both time and vot*dist*aoc (and toll for toll modes), need to subtract non-time variable from cost for time skim
    		if(vot>0) then do
    	    skimMatrix = OpenMatrix( hskimfile[i][j],)
    	    costCurrency = CreateMatrixCurrency(skimMatrix, CostFld[j], , , )
          lengthCurrency = CreateMatrixCurrency(skimMatrix, "Length (Skim)", , , )
            
          if (iftoll <> 0 & SkimVar!=null ) then do
                tollCurrency = CreateMatrixCurrency(skimMatrix, SkimVar[1]+" (Skim)", , , )
                costCurrency := costCurrency - ((distfactor * lengthCurrency) + (tollCurrency/100 * 0.5)/vot * 60)
          end
          else do
                costCurrency := costCurrency - (distfactor * lengthCurrency)
          end       
        end
      end
    
      //add the toll and non-toll skims together for each occupancy category
      if (iftoll <> 0) then do
        
        for j = 1 to 3 do
        	//  AM SOV-NT, AM HOV-NT, AM HOV3+ NT, AM SOV-TOLL, AM HOV2-TOLL, AM HOV3+ TOLL
          nonTollMatrix = OpenMatrix( hskimfile[i][j],)
          tollMatrix = OpenMatrix( hskimfile[i][j+3],)
            
          //add skim length and set to 0 if not skimmed
          if(tollLengthSet=null) then do
            AddMatrixCore(tollMatrix, "Toll Length")
    		    matrixCopy = CreateMatrixCurrency(tollMatrix, "Toll Length", , , )
            matrixCopy := 0
          end
            
          tollMatrixCores = GetMatrixCoreNames(tollMatrix)

          for j = 1 to tollMatrixCores.length do 
          	tollCurrency = CreateMatrixCurrency(tollMatrix, tollMatrixCores[j], , , )
            AddMatrixCore(nonTollMatrix, "toll_"+tollMatrixCores[j])
    		    matrixCopy = CreateMatrixCurrency(nonTollMatrix, "toll_"+tollMatrixCores[j], , , )
            matrixCopy := tollCurrency
          end
            
        end
      end
       
    	ret_value = RunMacro("Intrazonal Impedance", hskimfile[i]) 
    	if !ret_value then Throw()
    
    	ret_value = RunMacro("Convert Matrices To Binary", hskimfile[i])
    	if !ret_value then Throw()
    
    end
    
    RunMacro("Close All")

    return(1)
    
        
EndMacro
/**********************************************************************************************************************
*
* Create non-motorized distance matrix.
*
* This macro will create a distance matrix based on the distance between XY coordinates of zone centroids.
*
* Arguments:
*    scenarioDirectory      Directory to write file to (file written to scenarioDirectory\outputs)
*    hwyfile                Highway line layer with XY fields for zone coordinates
*    nzones                 Number of TAZs, zones must be sequential starting at 1 through nzones.
*
**********************************************************************************************************************/
Macro "Non-Motorized Matrix" (scenarioDirectory, hwyfile, nzones) 
        
    // RunMacro("TCB Init")
    aa = GetDBInfo(hwyfile)
    cc = CreateMap("bb",{{"Scope",aa[1]}})
    node_lyr=AddLayer(cc,"Oahu Nodes",hwyfile,"Oahu Nodes")

    // create a table for the matrix
    fields = {{"ITAZ","Integer",12,0,},
              {"JTAZ","Integer",12,0,},
              {"Distance","Float",12,2,}  }
              
    distanceTable = CreateTable("Non-motorized distance", scenarioDirectory+"\\outputs\\nonMotor.bin", "FFB", fields)

    // read the latitudes and longitudes into an array
    rh = GetFirstRecord(node_lyr+"|", {{"ID","Ascending"}})
    latlong = GetRecordsValues(node_lyr+"|", rh,{"ID","Longitude","Latitude"},{{"ID","Ascending"}} , nzones, "Column", )

 //   EnableProgressBar("Calculating nonmotorized matrix...", 1)     // Allow only a single progress bar
    CreateProgressBar("Calculating nonmotorized matrix...", "True")
   
    //storing results in an array
    dim values[nzones,3]
    
    // iterate through zones and calculate distance
    for i = 1 to nzones do

        // update status bar
        stat = UpdateProgressBar("", RealToInt(i/nzones*100) )
        minDistance = 999.99
        for j = 1 to nzones do
 
            if latlong[1][i] != i then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                return(0)
            end
            if latlong[1][j] != j then do
                ShowMessage("Error! Node layer out of sequence for TAZs")
                return(0)
            end
            
            // store latitude, longitude
            ilat=  latlong[2][i]  
            ilong= latlong[3][i]
            jlat=  latlong[2][j]
            jlong= latlong[3][j]
        
            x = Abs(ilat - jlat)
			y = Abs(ilong - jlong)
            
            // great circle distance is probably more accurate
            loc1 = Coord(ilat, ilong)
            loc2 = Coord(jlat, jlong)
            distance = GetDistance(loc1, loc2)
/*
            // calculate right-angle distance
            distance = 0.0
            if x > 0.0 and y > 0.0 then do
                distance = ( x + y ) * 0.000068
            end
*/            
            // store minimum distance
            if(distance > 0 and distance< minDistance) then do
                minDistance = distance
            end
            
            values[j][1]=i
            values[j][2]=j
            values[j][3]=distance
            
        end
        
        //intrazonal is 1/2 time to nearest neighbor
        values[i][3]=minDistance*0.5
        
        // set records for this izone
        record_handle = AddRecords(distanceTable, 
                {"ITAZ","JTAZ","Distance"},
                values, )
    
    end 
         
    DestroyProgressBar()
    
    m = CreateMatrixFromView(distanceTable, distanceTable+"|", "ITAZ", "JTAZ",
        {"Distance" }, {{ "File Name", scenarioDirectory+"\\outputs\\nonMotor.mtx" }})

    RunMacro("Close All")
    
    Return(1)
    
        
EndMacro
/*********************************************************************************************************************
*
* Create matrix of 1s for distribution of airport trips (don't ask)
*
* Arguments:
*    scenarioDirectory      Directory to write file to (file written to scenarioDirectory\outputs)
*    nzones                 Number of TAZs, zones must be sequential starting at 1 through nzones.
*
**********************************************************************************************************************/
Macro "Ones Matrix" (scenarioDirectory, nzones) 
        
    // RunMacro("TCB Init")

    fileName = scenarioDirectory+"\\outputs\\ones"+String(nzones)+".mtx"
    Opts=null
    Opts.[File Name] = fileName
    Opts.Label = "Ones"
    Opts.Type = "Float" 
    Opts.Tables = {"Ones"}
    Opts.[Column Major] = "No"
    Opts.[File Based] = "Yes"
    Opts.Compression = True

    ones_matrix = CreateMatrixFromScratch("Ones Matrix", nzones,nzones, &Opts)
    ones = CreateMatrixCurrency(ones_matrix, "Ones", , , )
    ones := 1
    
    matrices = {fileName} 
    CreateTableFromMatrix(ones_matrix, scenarioDirectory+"\\outputs\\ones"+String(nzones)+".bin", "FFB", {{"Complete", "Yes"}})
 
    RunMacro("Close All")
    
    return(1)
    
        
EndMacro

/*****************************************************************************************************************************
*
* Create intrazonal impedances
*
* Arguments:
*    hskimfile      Array of skim files.  Every core in every file will have intrazonal time calculated as 1/2 time to 
*                   nearest two neighbors.
*
*****************************************************************************************************************************/
Macro "Intrazonal Impedance" (hskimfile) 

    // RunMacro("TCB Init")
    
    // for each skim file
    for i=1 to hskimfile.length do
    	m=OpenMatrix(hskimfile[i],)
    	mtx_names=getMatrixCoreNames(GetMatrix())
    	
    	// for each matrix in the file
    	for j=1 to mtx_names.length do
    	    Opts = null
    	    Opts.Input.[Matrix Currency] = {hskimfile[i], mtx_names[j], "Origin", "Destination"}
    	    Opts.Global.Factor = 1
    	    Opts.Global.Neighbors = 2
    	    Opts.Global.Operation = 1
    	    Opts.Global.[Treat Missing] = 2
    	    ret_value = RunMacro("TCB Run Procedure", "Intrazonal", Opts, &Ret)
    	    if !ret_value then Throw()
	    end	
    end

    RunMacro("Close All")
    return(1)
    
        
EndMacro
