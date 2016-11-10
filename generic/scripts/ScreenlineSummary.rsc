Macro "Screenline Summary" (scenarioDirectory, iteration)

//    RunMacro("TCB Init")

    //scenarioDirectory = "D:\\projects\\ompo\\ORTP2009\\2007_100709"

    //iteration=3

	//Open the scenario line layer and set the link layer as active layer
	hwyfile = scenarioDirectory + "\\inputs\\network\\Scenario Line Layer.dbd"
	link_lyrs = GetDBLayers(hwyfile)
	map = RunMacro("G30 new map",hwyfile, "False")
	SetLayer(link_lyrs[2])
    link_lyr = link_lyrs[2]

    fp = OpenFile(scenarioDirectory + "\\reports\\ScreenlineSummary.rpt", "w")

/***********************************************************************************************************************************
*
* Highway Screenline Calculations
*
***********************************************************************************************************************************/

    // TODO:  Code screenline on masterline layer, copy to scenario line layer
    view_name = GetView()
    hwyPeriods={"EA","AM","MD","PM", "EV"}

    dim Dir[1], Scr_Line[1]
    dim ABFlowSOVFREE[1], BAFlowSOVFREE[1], ABFlowHOV2FREE[1], BAFlowHOV2FREE[1], ABFlowHOV3FREE[1], BAFlowHOV3FREE[1]
    dim ABFlowSOVPAY[1], BAFlowSOVPAY[1], ABFlowHOV2PAY[1], BAFlowHOV2PAY[1], ABFlowHOV3PAY[1], BAFlowHOV3PAY[1]
    dim ABFlowTRCKFREE[1], BAFlowTRCKFREE[1], ABFlowTRCKPAY[1], BAFlowTRCKPAY[1]


    Dir[1] = GetDataVector(view_name + "|", "Dir",)                                  // Direction of the Link
    Scr_Line[1] = VectorToArray(GetDataVector(view_name + "|", "Scr_Line",))         // Screenline


    // Cycle through periods
    for period=1 to hwyPeriods.length do
        WriteLine(fp,"Period: " + hwyPeriods[period])

        iterationNumber=iteration

	    //Open the database containing the assignemnt results and combine that to the line layer

	    flowTable = scenarioDirectory + "\\outputs\\" + hwyPeriods[period] + "Flow" + IntToString(iterationNumber) + ".bin"

	    Asn = OpenTable("Asn", "FFB", {flowTable})
	    VIEW1 = JoinViews("VIEW1", link_lyr+".ID", Asn + ".ID1",)

        ABFlowSOVFREE[1]   = GetDataVector(VIEW1 + "|", "[AB_Flow_SOV  - FREE]",)
        BAFlowSOVFREE[1]   = GetDataVector(VIEW1 + "|", "[BA_Flow_SOV  - FREE]",)
        ABFlowHOV2FREE[1]  = GetDataVector(VIEW1 + "|", "[AB_Flow_HOV2 - FREE]",)
        BAFlowHOV2FREE[1]  = GetDataVector(VIEW1 + "|", "[BA_Flow_HOV2 - FREE]",)
        ABFlowHOV3FREE[1]  = GetDataVector(VIEW1 + "|", "[AB_Flow_HOV3 - FREE]",)
        BAFlowHOV3FREE[1]  = GetDataVector(VIEW1 + "|", "[BA_Flow_HOV3 - FREE]",)
        ABFlowSOVPAY[1]    = GetDataVector(VIEW1 + "|", "[AB_Flow_SOV  - PAY]" ,)
        BAFlowSOVPAY[1]    = GetDataVector(VIEW1 + "|", "[BA_Flow_SOV  - PAY]" ,)
        ABFlowHOV2PAY[1]   = GetDataVector(VIEW1 + "|", "[AB_Flow_HOV2 - PAY]" ,)
        BAFlowHOV2PAY[1]   = GetDataVector(VIEW1 + "|", "[BA_Flow_HOV2 - PAY]" ,)
        ABFlowHOV3PAY[1]   = GetDataVector(VIEW1 + "|", "[AB_Flow_HOV3 - PAY]" ,)
        BAFlowHOV3PAY[1]   = GetDataVector(VIEW1 + "|", "[BA_Flow_HOV3 - PAY]" ,)
        ABFlowTRCKFREE[1]  = GetDataVector(VIEW1 + "|", "[AB_Flow_TRCK - FREE]",)
        BAFlowTRCKFREE[1]  = GetDataVector(VIEW1 + "|", "[BA_Flow_TRCK - FREE]",)
        ABFlowTRCKPAY[1]   = GetDataVector(VIEW1 + "|", "[AB_Flow_TRCK - PAY]" ,)
        BAFlowTRCKPAY[1]   = GetDataVector(VIEW1 + "|", "[BA_Flow_TRCK - PAY]" ,)


        CloseView(VIEW1)

        //  Fill the missing values with zeros to make computations(finding maximum values) easier
        NumRec = Dir[1].length
        WriteLine(fp,"Links: " + IntToString(NumRec))


        for j = 1 to NumRec do
            if Scr_Line[1][j] = "" then
               Scr_Line[1][j] = 0
        end

        //Computes the maximum values in each array
        MaxScrLine = RealToInt(ArrayMax(Scr_Line[1]))


        hwyVariables = 10
        //initialize the screenline and district data
        dim HwyScrLines[hwyVariables, MaxScrLine + 1]


        for i = 1 to MaxScrLine + 1 do
            for j = 1 to HwyScrLines.length do
                HwyScrLines[j][i] = 0
            end
        end


        //iterate through links
        for i = 1 to NumRec do

            ScreenlineNumber = RealToInt(Scr_Line[1][i])

            if(ScreenlineNumber > 0) then do
                FlowSOVFREE     = 0
                FlowHOV2FREE    = 0
                FlowHOV3FREE    = 0
                FlowSOVPAY      = 0
                FlowHOV2PAY     = 0
                FlowHOV3PAY     = 0
                FlowTRCKFREE    = 0
                FlowTRCKPAY     = 0

                // AB Direction valid
                if Dir[1][i] <> -1 then do
                    FlowSOVFREE   = ABFlowSOVFREE[1][i]
                    FlowHOV2FREE  = ABFlowHOV2FREE[1][i]
                    FlowHOV3FREE  = ABFlowHOV3FREE[1][i]
                    FlowSOVPAY    = ABFlowSOVPAY[1][i]
                    FlowHOV2PAY   = ABFlowHOV2PAY[1][i]
                    FlowHOV3PAY   = ABFlowHOV3PAY[1][i]
                    FlowTRCKFREE  = ABFlowTRCKFREE[1][i]
                    FlowTRCKPAY   = ABFlowTRCKPAY[1][i]
                end

                // BA Direction valid
                if Dir[1][i] <> 1 then do
                    FlowSOVFREE   = FlowSOVFREE  + BAFlowSOVFREE[1][i]
                    FlowHOV2FREE  = FlowHOV2FREE + BAFlowHOV2FREE[1][i]
                    FlowHOV3FREE  = FlowHOV3FREE + BAFlowHOV3FREE[1][i]
                    FlowSOVPAY    = FlowSOVPAY   + BAFlowSOVPAY[1][i]
                    FlowHOV2PAY   = FlowHOV2PAY  + BAFlowHOV2PAY[1][i]
                    FlowHOV3PAY   = FlowHOV3PAY  + BAFlowHOV3PAY[1][i]
                    FlowTRCKFREE  = FlowTRCKFREE + BAFlowTRCKFREE[1][i]
                    FlowTRCKPAY   = FlowTRCKPAY  + BAFlowTRCKPAY[1][i]
                end

                HwyScrLines[1][ScreenlineNumber] =  HwyScrLines[1][ScreenlineNumber] + 1
                HwyScrLines[2][ScreenlineNumber] =  HwyScrLines[2][ScreenlineNumber] + FlowSOVFREE
                HwyScrLines[3][ScreenlineNumber] =  HwyScrLines[3][ScreenlineNumber] + FlowHOV2FREE
                HwyScrLines[4][ScreenlineNumber] =  HwyScrLines[4][ScreenlineNumber] + FlowHOV3FREE
                HwyScrLines[5][ScreenlineNumber] =  HwyScrLines[5][ScreenlineNumber] + FlowSOVPAY
                HwyScrLines[6][ScreenlineNumber] =  HwyScrLines[6][ScreenlineNumber] + FlowHOV2PAY
                HwyScrLines[7][ScreenlineNumber] =  HwyScrLines[7][ScreenlineNumber] + FlowHOV3PAY
                HwyScrLines[8][ScreenlineNumber] =  HwyScrLines[8][ScreenlineNumber] + FlowTRCKFREE
                HwyScrLines[9][ScreenlineNumber] =  HwyScrLines[9][ScreenlineNumber] + FlowTRCKPAY
                HwyScrLines[10][ScreenlineNumber] =  HwyScrLines[10][ScreenlineNumber] + FlowSOVFREE + FlowSOVPAY + 2*(FlowHOV2FREE + FlowHOV2PAY) + 3.5*(FlowHOV3FREE + FlowHOV3PAY)


                //screenline totals
                HwyScrLines[1][MaxScrLine+1] =  HwyScrLines[1][MaxScrLine+1] + 1
                HwyScrLines[2][MaxScrLine+1] =  HwyScrLines[2][MaxScrLine+1] + FlowSOVFREE
                HwyScrLines[3][MaxScrLine+1] =  HwyScrLines[3][MaxScrLine+1] + FlowHOV2FREE
                HwyScrLines[4][MaxScrLine+1] =  HwyScrLines[4][MaxScrLine+1] + FlowHOV3FREE
                HwyScrLines[5][MaxScrLine+1] =  HwyScrLines[5][MaxScrLine+1] + FlowSOVPAY
                HwyScrLines[6][MaxScrLine+1] =  HwyScrLines[6][MaxScrLine+1] + FlowHOV2PAY
                HwyScrLines[7][MaxScrLine+1] =  HwyScrLines[7][MaxScrLine+1] + FlowHOV3PAY
                HwyScrLines[8][MaxScrLine+1] =  HwyScrLines[8][MaxScrLine+1] + FlowTRCKFREE
                HwyScrLines[9][MaxScrLine+1] =  HwyScrLines[9][MaxScrLine+1] + FlowTRCKPAY
                HwyScrLines[10][MaxScrLine+1] = HwyScrLines[10][MaxScrLine+1] + FlowSOVFREE + FlowSOVPAY + 2*(FlowHOV2FREE + FlowHOV2PAY) + 3.5*(FlowHOV3FREE + FlowHOV3PAY)

            end

        end
        WriteLine(fp,"End Calculations")

         // Format the Statistics appropriately, this has two advantages
        // (1) Easy to read
        // (2) Will convert the numeric values to string, so "+ operator" will concatenate the values later
        for i = 1 to hwyVariables do
            for j = 1 to MaxScrLine + 1 do
  //              if  HwyScrLines[i][j] <> 0 then do
                    HwyScrLines[i][j] = LPad(Format(HwyScrLines[i][j],",*"),12)
 //               end
            end

        end

        ScreenHeader =    "Screenline                    Links    SOV-Free   HOV2-Free   HOV3-Free     SOV-Pay    HOV2-Pay    HOV3-Pay  Truck-Free   Truck-Pay  Person-Trips"

        // Print out the Tables

	    WriteLine(fp, "Highway Assignment Results for "+hwyPeriods[period])

	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Screenline Analysis")
	    WriteLine(fp,ScreenHeader)
        for i = 1 to MaxScrLine + 1 do
            outline =  RPad(IntToString(i),23)
            if i = MaxScrLine + 1 then outline = "Total                  "
            for j = 1 to HwyScrLines.length do
                outline = outline + HwyScrLines[j][i]
            end
            WriteLine(fp,outline)
	    end

	end  //looping through periods

/***********************************************************************************************************************************
*
* Transit Screenline Calculations
*
***********************************************************************************************************************************/

	trnPeriods = {"EA", "AM", "MD", "PM", "EV"}
	trnAssigns = {"WLK-LOC", "WLK-EXP", "WLK-GDWY", "PNR-INF", "PNR-FML", "KNR"}
	trnVariables = trnPeriods.length*trnAssigns.length
	dim ABTransitFlow[trnVariables], BATransitFlow[trnVariables]

	variable=0
	for period = 1 to trnPeriods.length do

	    for assign = 1 to trnAssigns.length do

	        variable = variable + 1

	        flowTable = scenarioDirectory + "\\outputs\\" + trnAssigns[assign]+"_"+trnPeriods[period]+"_LINKFLOW.BIN"

	        Asn = OpenTable("Asn", "FFB", {flowTable})
	        VIEW1 = JoinViews("VIEW1", link_lyr+".ID", Asn + ".ID1",)

            ABTransitFlow[variable]   = GetDataVector(VIEW1 + "|", "AB_TransitFlow",)
            BATransitFlow[variable]   = GetDataVector(VIEW1 + "|", "BA_TransitFlow",)

            CloseView(VIEW1)

	    end
	end

    dim TrnScrLines[trnVariables + 1, MaxScrLine + 1]

    for i = 1 to MaxScrLine + 1 do
        for j = 1 to TrnScrLines.length do
            TrnScrLines[j][i] = 0
        end
    end

   //iterate through links
   for i = 1 to NumRec do

        ScreenlineNumber = RealToInt(Scr_Line[1][i])

        if (ScreenlineNumber = 7) then do
            s=1
        end

        if(ScreenlineNumber > 0) then do

	        variable = 0
	        for period = 1 to trnPeriods.length do
	            for assign = 1 to trnAssigns.length do

	                variable = variable + 1

	                transitFlow = 0

                    // AB Direction valid
                    if Dir[1][i] <> -1 and ABTransitFlow[variable][i] > 0 then  transitFlow   = ABTransitFlow[variable][i]

                    // BA Direction valid
                    if Dir[1][i] <> 1 and BATransitFlow[variable][i] > 0 then   transitFlow   = transitFlow + BATransitFlow[variable][i]

	                TrnScrLines[variable][ScreenlineNumber] = TrnScrLines[variable][ScreenlineNumber] + transitFlow
	                TrnScrLines[trnVariables+1][ScreenlineNumber] = TrnScrLines[trnVariables+1][ScreenlineNumber] + transitFlow

	                TrnScrLines[variable][MaxScrLine+1] = TrnScrLines[variable][MaxScrLine+1] + transitFlow
	                TrnScrLines[trnVariables+1][MaxScrLine+1] = TrnScrLines[trnVariables+1][MaxScrLine+1] + transitFlow

	            end  // end assigns
	        end  // end periods

	    end // end if screenline
	end  // end records

	  ScreenHeader1 = "Period                    ------------------------       Peak        --------------------------    ----------------------       Off-Peak        -----------------------"
    ScreenHeader2 =    "Screenline                  "
    for period = 1 to trnPeriods.length do
	   for assign = 1 to trnAssigns.length do
	       ScreenHeader2 = ScreenHeader2 + Rpad(trnAssigns[assign],12)
	   end
    end
    ScreenHeader2 = ScreenHeader2 + "  Total"

    // Format the Statistics appropriately
    for i = 1 to trnVariables+1 do
            for j = 1 to MaxScrLine + 1 do
//                if  TrnScrLines[i][j] <> 0 then do
                    TrnScrLines[i][j] = LPad(Format(TrnScrLines[i][j],",*"),12)
//                end
            end
    end


   // Print out the Tables

    WriteLine(fp, "Transit Assignment Results")

    WriteLine(fp, "")						//--- a blank line
    WriteLine(fp, "")						//--- a blank line
    WriteLine(fp, "Screenline Analysis")
    WriteLine(fp,ScreenHeader1)
    WriteLine(fp,ScreenHeader2)
    for i = 1 to MaxScrLine + 1 do
        outline =  RPad(IntToString(i),23)
            if i = MaxScrLine + 1 then outline = "Total                  "
        for j = 1 to TrnScrLines.length do
            outline = outline + TrnScrLines[j][i]
        end
        WriteLine(fp,outline)
    end


	RunMacro("Close All")

	Return(1)
    
        
EndMacro
                                    
