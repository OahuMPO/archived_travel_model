Macro "Highway Assignment Summary" (scenarioDirectory)

//    RunMacro("TCB Init")

//    scenarioDirectory = "F:\\projects\\OMPO\\ORTP2009\\A_Model\\2007_100709"


	// Open the taz layer, which contains the district field
	tazfile = scenarioDirectory + "\\inputs\\taz\\Scenario TAZ Layer.dbd"

	//Open the scenario line layer and set the link layer as active layer
	hwyfile = scenarioDirectory + "\\inputs\\network\\Scenario Line Layer.dbd"
	link_lyrs = GetDBLayers(hwyfile)
	map = RunMacro("G30 new map",hwyfile, "False")
	SetLayer(link_lyrs[2])
    link_lyr = link_lyrs[2]
    taz_lyr=AddLayer(cc,"Oahu TAZs",tazfile,"Oahu TAZs")

    fp = OpenFile(scenarioDirectory + "\\reports\\AssignmentSummary.rpt", "w")
    slfp = OpenFile(scenarioDirectory + "\\reports\\ScreenlineLinks.rpt", "w")
    speedfp = OpenFile(scenarioDirectory + "\\reports\\SpeedData.csv", "w")

    WriteLine(slfp,"Period,Screenline,LinkID,AB_LinkFlow,AB_LinkVOC,BA_LinkFlow,BA_LinkVOC")

    view_name = GetView()
    periods={"EA","AM","MD","PM","EV"}

    dim Dir[1], ID[1], length[1], ABFACTYPE[1], BAFACTYPE[1], ABATYPE[1], BAATYPE[1], District[1], abspeed[1], baspeed[1]
    dim abflow[1], abVMT[1], baflow[1], baVMT[1], totflow[1], totVMT[1], Scr_Line[1], abffspeed[1],baffspeed[1]
    dim ablane[1], balane[1], abvoc[1], bavoc[1]

        Dir[1] = GetDataVector(view_name + "|", "Dir",)                                  // Direction of the Link
        ID[1] = GetDataVector(view_name + "|", "ID",)                                    // ID for link
        ABFACTYPE[1] = VectorToArray(GetDataVector(view_name + "|", "[AB FACTYPE]",))    // Facility Type for AB direction
        BAFACTYPE[1] = GetDataVector(view_name + "|", "[BA FACTYPE]",)                   // Facility Type for BA direction
        ABATYPE[1] = VectorToArray(GetDataVector(view_name + "|", "AB_ATYPE",))        // Area Type for AB direction
        BAATYPE[1] = GetDataVector(view_name + "|", "BA_ATYPE",)                       // Area Type for BA direction
        length[1]  = GetDataVector(view_name + "|", "Length",)                           // Area Type for BA direction
        Scr_Line[1] = VectorToArray(GetDataVector(view_name + "|", "Scr_Line",))         // Screenline
        District[1] = VectorToArray(GetDataVector(view_name + "|", "District",))         // District
        abffspeed[1] = GetDataVector(view_name + "|", "[AB Speed]",)        // Free-flow speed for AB direction
        baffspeed[1] = GetDataVector(view_name + "|", "[BA Speed]",)        // Free-flow speed for BA direction


//  Create Vectors/Arrays to read data from tables/Dataviews
    for period=1 to periods.length do
        WriteLine(fp,"Period: " + periods[period])

        abflow[1] = GetDataVector(view_name + "|", "AB_FLOW_"+periods[period],)         // assigned flow for AB direction
        baflow[1] = GetDataVector(view_name + "|", "BA_FLOW_"+periods[period],)         // assigned flow for BA direction
        totflow[1] = GetDataVector(view_name + "|", "TOT_FLOW_"+periods[period],)     // Total assigned flow for each link
        abspeed[1] = GetDataVector(view_name + "|", "AB_SPD_"+periods[period],)         // speed for AB direction
        baspeed[1] = GetDataVector(view_name + "|", "BA_SPD_"+periods[period],)         // speed for BA direction
        abvoc[1] =   GetDataVector(view_name + "|", "AB_VOC_"+periods[period],)         // vol to cap ratio AB direction
        bavoc[1] =   GetDataVector(view_name + "|", "BA_VOC_"+periods[period],)         // vol to cap ratio BA direction

        if period = 1 then do
            ablane[1] =   GetDataVector(view_name + "|", "[AB_LANEA]",)
            balane[1] =   GetDataVector(view_name + "|", "[BA_LANEA]",)
            end
        else if period = 2 then do
            ablane[1] =   GetDataVector(view_name + "|", "[AB_LANEM]",)
            balane[1] =   GetDataVector(view_name + "|", "[BA_LANEM]",)
            end
        else do
            ablane[1] =   GetDataVector(view_name + "|", "[AB_LANEP]",)
            balane[1] =   GetDataVector(view_name + "|", "[BA_LANEP]",)
        end

        //  Fill the missing values with zeros to make computations(finding maximum values) easier
        NumRec = Dir[1].length

        for j = 1 to NumRec do
            if ABFACTYPE[1][j] = "" then
               ABFACTYPE[1][j] = 0
            if ABATYPE[1][j] = "" then
               ABATYPE[1][j] = 0
            if Scr_Line[1][j] = "" then
               Scr_Line[1][j] = 0
            if District[1][j] ="" then
               District[1][j] = 0
            if ABFACTYPE[1][j] = 197 then
               ABFACTYPE[1][j] = 12
            if ABATYPE[1][j] = 197 then
               ABATYPE[1][j] = 12
            totflow[1][j] = RealToInt(totflow[1][j])
        end

        //Computes the maximum values in each array
        MaxFACTYPE = RealToInt(ArrayMax(ABFACTYPE[1]))
        MaxATYPE = RealToInt(ArrayMax(ABATYPE[1]))
        MaxScrLine = RealToInt(ArrayMax(Scr_Line[1]))
        MaxDistrict = RealToInt(ArrayMax(District[1]))
        MaxLOS = 6

        LOSNames = {"LOS A","LOS B","LOS C","LOS D","LOS E","LOS F"}
        LOSStart = { 0.00,   0.60,   0.70,   0.80,   0.90,   1.00} // >=
        LOSEnd   = { 0.60,   0.70,   0.80,   0.90,   1.00,  99.99} // <


        // Initialize the tables to be reported by facility type and area type
        Dim  Links[MaxFACTYPE + 1,MaxATYPE + 1], LaneMiles[MaxFACTYPE + 1,MaxATYPE + 1],Vol[MaxFACTYPE + 1,MaxATYPE + 1], VHT[MaxFACTYPE + 1,MaxATYPE + 1], VMT[MaxFACTYPE + 1,MaxATYPE + 1], VHD[MaxFACTYPE + 1,MaxATYPE + 1]
        Dim  LOSLaneMiles[MaxFACTYPE + 1,MaxATYPE + 1, MaxLOS]

        //Initialize a table to hold volume by facility type, area type, and speed range
        if period=1 then do

          SpeedBinSize = 5
          SpeedMax = 80
          SpeedBins = RealToInt(SpeedMax/SpeedBinSize)

          Dim SpeedStart[SpeedBins]
          Dim SpeedEnd[SpeedBins]

          for i = 1 to SpeedBins do
             SpeedStart[i] = (i-1) * SpeedBinSize
             SpeedEnd[i] = i * SpeedBinSize
          end

          Dim VMTByFacAreaSpeed[MaxFACTYPE,MaxATYPE,SpeedBins]

          //initialize to 0
          for i = 1 to MaxFACTYPE do
            for j = 1 to MaxATYPE do
              for k = 1 to SpeedBins do
                 VMTByFacAreaSpeed[i][j][k] = 0
              end
            end
          end


        end //initializing if period = 1

        for i = 1 to MaxFACTYPE + 1 do
            for j = 1 to MaxATYPE + 1 do
                Links[i][j] = 0
                LaneMiles[i][j] = 0
                Vol[i][j] = 0
                VHT[i][j] = 0
                VMT[i][j] = 0
                VHD[i][j] = 0

                for k = 1 to MaxLOS do
                    LOSLaneMiles[i][j][k] = 0
                end
            end
        end

        variables = 6
        //initialize the screenline and district data
        dim ScreenLines[variables, MaxScrLine + 1]
        dim Dist[variables, MaxDistrict + 1]


        for i = 1 to MaxScrLine + 1 do
            for j = 1 to ScreenLines.length do
                ScreenLines[j][i] = 0
            end
        end

        for i = 1 to MaxDistrict + 1 do
            for j = 1 to Dist.length do
                Dist[j][i] = 0
            end
        end

        //iterate through links
        for i = 1 to NumRec do

            ablinkLOS=0
            balinkLOS=0
            ablinkVOC = abvoc[1][i]
            balinkVOC = bavoc[1][i]


            if Dir[1][i] <> -1 then do
                FacType = RealToInt(ABFACTYPE[1][i])
                AreaType = RealToInt(ABATYPE[1][i])

                //code AB and BA LOS
                for j = 1 to MaxLOS do
                     if(ablinkVOC>= 0 and ablinkVOC >= LOSStart[j] and ablinkVOC < LOSEnd[j]) then ablinkLOS = j
                     if(balinkVOC>= 0 and balinkVOC >= LOSStart[j] and balinkVOC < LOSEnd[j]) then balinkLOS = j
                end
            end
            else do
                FacType = RealToInt(BAFACTYPE[1][i])
                AreaType = RealToInt(BAATYPE[1][i])

                //code only BA LOS
                for j = 1 to MaxLOS do
                     if(bavoc[1][i] >= LOSStart[j] and bavoc[1][i] < LOSEnd[j]) then balinkLOS = j
                end

            end

           ScreenlineNumber = RealToInt(Scr_Line[1][i])
           DistrictNumber = RealToInt(District[1][i])

           if(( FacType>0) and (AreaType>0) and DistrictNumber>0) then do

                //main calculations
                linkID = ID[1][i]
                totlinkflow = totflow[1][i]
                ablinkflow = abflow[1][i]
                balinkflow = baflow[1][i]
                linkdist = length[1][i]
                ablinkspd = abspeed[1][i]
                balinkspd = baspeed[1][i]
                ablinkffspd = abffspeed[1][i]
                balinkffspd = baffspeed[1][i]
                ablanes = ablane[1][i]
                balanes = balane[1][i]

                linkVMT = totlinkflow * linkdist

                linkVHT = 0
                ablinkLaneMiles = 0
                balinkLaneMiles = 0
                if(ablinkspd > 0) then do
                    linkVHT = (ablinkflow * linkdist/ablinkspd)
                    ablinkLaneMiles = ablanes * linkdist
                end
                if(balinkspd > 0) then do
                    linkVHT = linkVHT + (balinkflow * linkdist/balinkspd)
                    balinkLaneMiles = balanes * linkdist
                end

                linkff=0
                if(ablinkffspd>0) then do
                    linkff = (ablinkflow * linkdist/ablinkffspd)
                end
                if(balinkffspd>0) then do
                    linkff = linkff + (balinkflow * linkdist/balinkffspd)
                end

                linkVHD = linkVHT - linkff

                Links[FacType][AreaType]= Links[FacType][AreaType] + 1

                LaneMiles[FacType][AreaType]=LaneMiles[FacType][AreaType] + (ablinkLaneMiles + balinkLaneMiles )
                Vol[FacType][AreaType] = Vol[FacType][AreaType] + totlinkflow
                VMT[FacType][AreaType] = VMT[FacType][AreaType] + linkVMT
                VHT[FacType][AreaType] = VHT[FacType][AreaType] + linkVHT
                VHD[FacType][AreaType] = VHD[FacType][AreaType] + linkVHD

                if(ablinkLOS > 0) then do
                    LOSLaneMiles[FacType][AreaType][ablinkLOS] = LOSLaneMiles[FacType][AreaType][ablinkLOS] + ablinkLaneMiles
                end

                if(balinkLOS > 0) then do
                    LOSLaneMiles[FacType][AreaType][balinkLOS] = LOSLaneMiles[FacType][AreaType][balinkLOS] + balinkLaneMiles
                end

                //speedData
                if(period<=3) then do
                  if(ablinkspd > 0) then do
                    for j = 1 to SpeedBins do
                      if(ablinkspd >= SpeedStart[j] and ablinkspd < SpeedEnd[j]) then do
                          VMTByFacAreaSpeed[FacType][AreaType][j]  =  VMTByFacAreaSpeed[FacType][AreaType][j] + (ablinkflow*linkdist)
                      end
                    end
                  end
                  if(balinkspd > 0) then do
                    for j = 1 to SpeedBins do
                      if(balinkspd >= SpeedStart[j] and balinkspd < SpeedEnd[j]) then do
                          VMTByFacAreaSpeed[FacType][AreaType][j]  =  VMTByFacAreaSpeed[FacType][AreaType][j] + (balinkflow*linkdist)
                      end
                    end
                  end
                end

                //marginals
                Links[MaxFACTYPE+1][AreaType] = Links[MaxFACTYPE+1][AreaType] + 1
                LaneMiles[MaxFACTYPE+1][AreaType]=LaneMiles[MaxFACTYPE+1][AreaType] + (ablinkLaneMiles + balinkLaneMiles )
                Vol[MaxFACTYPE+1][AreaType] = Vol[MaxFACTYPE+1][AreaType] + totlinkflow
                VMT[MaxFACTYPE+1][AreaType] = VMT[MaxFACTYPE+1][AreaType] + linkVMT
                VHT[MaxFACTYPE+1][AreaType] = VHT[MaxFACTYPE+1][AreaType] + linkVHT
                VHD[MaxFACTYPE+1][AreaType] = VHD[MaxFACTYPE+1][AreaType] + linkVHD

                if(ablinkLOS > 0) then do
                    LOSLaneMiles[MaxFACTYPE+1][AreaType][ablinkLOS] = LOSLaneMiles[MaxFACTYPE+1][AreaType][ablinkLOS] + ablinkLaneMiles
                end

                if(balinkLOS > 0) then do
                    LOSLaneMiles[MaxFACTYPE+1][AreaType][balinkLOS] = LOSLaneMiles[MaxFACTYPE+1][AreaType][balinkLOS] + balinkLaneMiles
                end

                Links[FacType][MaxATYPE+1] = Links[FacType][MaxATYPE+1] + 1
                LaneMiles[FacType][MaxATYPE+1]=LaneMiles[FacType][MaxATYPE+1] + (ablinkLaneMiles + balinkLaneMiles )
                Vol[FacType][MaxATYPE+1] = Vol[FacType][MaxATYPE+1] + totlinkflow
                VMT[FacType][MaxATYPE+1] = VMT[FacType][MaxATYPE+1] + linkVMT
                VHT[FacType][MaxATYPE+1] = VHT[FacType][MaxATYPE+1] + linkVHT
                VHD[FacType][MaxATYPE+1] = VHD[FacType][MaxATYPE+1] + linkVHD

                if(ablinkLOS > 0) then do
                    LOSLaneMiles[FacType][MaxATYPE+1][ablinkLOS] = LOSLaneMiles[FacType][MaxATYPE+1][ablinkLOS] + ablinkLaneMiles
                end

                if(balinkLOS > 0) then do
                    LOSLaneMiles[FacType][MaxATYPE+1][balinkLOS] = LOSLaneMiles[FacType][MaxATYPE+1][balinkLOS] + balinkLaneMiles
                end

                //totals
                Links[MaxFACTYPE+1][MaxATYPE+1] = Links[MaxFACTYPE+1][MaxATYPE+1] + 1
                LaneMiles[MaxFACTYPE+1][MaxATYPE+1]=LaneMiles[MaxFACTYPE+1][MaxATYPE+1] + (ablinkLaneMiles + balinkLaneMiles )
                Vol[MaxFACTYPE+1][MaxATYPE+1] = Vol[MaxFACTYPE+1][MaxATYPE+1] + totlinkflow
                VMT[MaxFACTYPE+1][MaxATYPE+1] = VMT[MaxFACTYPE+1][MaxATYPE+1] + linkVMT
                VHT[MaxFACTYPE+1][MaxATYPE+1] = VHT[MaxFACTYPE+1][MaxATYPE+1] + linkVHT
                VHD[MaxFACTYPE+1][MaxATYPE+1] = VHD[MaxFACTYPE+1][MaxATYPE+1] + linkVHD

                if(ablinkLOS > 0) then do
                    LOSLaneMiles[MaxFACTYPE+1][MaxATYPE+1][ablinkLOS] = LOSLaneMiles[MaxFACTYPE+1][MaxATYPE+1][ablinkLOS] + ablinkLaneMiles
                end

                if(balinkLOS > 0) then do
                    LOSLaneMiles[MaxFACTYPE+1][MaxATYPE+1][balinkLOS] = LOSLaneMiles[MaxFACTYPE+1][MaxATYPE+1][balinkLOS] + balinkLaneMiles
                end

                //Screenline calculations
                if ScreenlineNumber > 0 then do
                     ScreenLines[1][ScreenlineNumber] =  ScreenLines[1][ScreenlineNumber] + 1
                     ScreenLines[2][ScreenlineNumber] =  ScreenLines[2][ScreenlineNumber] + (ablinkLaneMiles + balinkLaneMiles )
                     ScreenLines[3][ScreenlineNumber] =  ScreenLines[3][ScreenlineNumber] + totlinkflow
                     ScreenLines[4][ScreenlineNumber] =  ScreenLines[4][ScreenlineNumber] + linkVMT
                     ScreenLines[5][ScreenlineNumber] =  ScreenLines[5][ScreenlineNumber] + linkVHT
                     ScreenLines[6][ScreenlineNumber] =  ScreenLines[6][ScreenlineNumber] + linkVHD

                     //screenline totals
                     ScreenLines[1][MaxScrLine+1] = ScreenLines[1][MaxScrLine+1] + 1
                     ScreenLines[2][MaxScrLine+1] = ScreenLines[2][MaxScrLine+1] + (ablinkLaneMiles + balinkLaneMiles )
                     ScreenLines[3][MaxScrLine+1] = ScreenLines[3][MaxScrLine+1] + totlinkflow
                     ScreenLines[4][MaxScrLine+1] = ScreenLines[4][MaxScrLine+1] + linkVMT
                     ScreenLines[5][MaxScrLine+1] = ScreenLines[5][MaxScrLine+1] + linkVHT
                     ScreenLines[6][MaxScrLine+1] = ScreenLines[6][MaxScrLine+1] + linkVHD

                     WriteLine(slfp,periods[period]+","+IntToString(ScreenlineNumber)+","+IntToString(linkID)+","
                     		+RealToString(ablinkflow)+","
                     		+RealToString(ablinkVOC)+","
                     		+RealToString(balinkflow)+","
                     		+RealToString(balinkVOC))

                end

                //District calculations
                if DistrictNumber > 0 then do
                     Dist[1][DistrictNumber] = Dist[1][DistrictNumber] + 1
                     Dist[2][DistrictNumber] = Dist[2][DistrictNumber] + (ablinkLaneMiles + balinkLaneMiles )
                     Dist[3][DistrictNumber] = Dist[3][DistrictNumber] + totlinkflow
                     Dist[4][DistrictNumber] = Dist[4][DistrictNumber] + linkVMT
                     Dist[5][DistrictNumber] = Dist[5][DistrictNumber] + linkVHT
                     Dist[6][DistrictNumber] = Dist[6][DistrictNumber] + linkVHD

                     //District totals
                     Dist[1][MaxDistrict+1] = Dist[1][MaxDistrict+1] + 1
                     Dist[2][MaxDistrict+1] = Dist[2][MaxDistrict+1] + (ablinkLaneMiles + balinkLaneMiles )
                     Dist[3][MaxDistrict+1] = Dist[3][MaxDistrict+1] + totlinkflow
                     Dist[4][MaxDistrict+1] = Dist[4][MaxDistrict+1] + linkVMT
                     Dist[5][MaxDistrict+1] = Dist[5][MaxDistrict+1] + linkVHT
                     Dist[6][MaxDistrict+1] = Dist[6][MaxDistrict+1] + linkVHD
                 end

              end
        end
        WriteLine(fp,"End Calculations")

         // Format the Statistics appropriately, this has two advantages
        // (1) Easy to read
        // (2) Will convert the numeric values to string, so "+ operator" will concatenate the values later
        for i = 1 to variables do
            for j = 1 to MaxScrLine + 1 do
                if  ScreenLines[i][j] <> 0 then do
                    ScreenLines[i][j] = LPad(Format(ScreenLines[i][j],",*"),12)
                	end
                else do
                  ScreenLines[i][j] = "           0"
                end
            end

            for j = 1 to MaxDistrict + 1 do
                if  Dist[i][j] <> 0 then do
                    Dist[i][j] = LPad(Format(Dist[i][j], ",*"),12)
                    end
                else do
                    Dist[i][j] = "           0"
                end
   	        end

        end

        for i = 1 to MaxFACTYPE + 1 do
            for j = 1 to MaxATYPE + 1 do
                Links[i][j] = LPad(Format(Links[i][j],"*"),12)
                LaneMiles[i][j] = LPad(Format(LaneMiles[i][j],"*"),12)
                Vol[i][j] = LPad(Format(Vol[i][j],"*"),12)
                VMT[i][j] = LPad(Format(VMT[i][j],"*"),12)
                VHT[i][j] = LPad(Format(VHT[i][j],"*"),12)
                VHD[i][j] = LPad(Format(VHD[i][j],"*"),12)

                for k = 1 to MaxLOS do
                    LOSLaneMiles[i][j][k] = LPad(Format(LOSLaneMiles[i][j][k],"*"),12)
                end


            end
        end

        //Format the Labels, blank[i][1] is label for Table "i"

        FacilityRowHeader = {"1  Freeways            ",
                             "2 Other Freeways       ",
                             "3 Class I arterials    ",
                             "4 Class II arterials   ",
                             "5 Class III arterials  ",
                             "6 Class I collectors   ",
                             "7 Class II collectors  ",
                             "8 Local Streets        ",
                             "9 High Speed Ramps     ",
                             "10 Low Speed Ramps     ",
                             "11 Undefined           ",
                             "12 Centroid Connectors ",
                             "13 HOV Lanes           ",
                             "14 Rail                ",
                             "All Facility Types     "}
	      TableHeader = "Facility Type                     1           2           3           4           5           6           7           8   All Areas"
        ScreenlineHeader = "Screenline                    Links  Lane-Miles  Tot.Volume   Veh-Miles   Veh-Hours Veh-Hours-Delay"
        DistrictHeader =   "District                      Links  Lane-Miles  Tot.Volume   Veh-Miles   Veh-Hours Veh-Hours-Delay"



        // Print out the Observed counts and estimated flows for each count station


        // Print out the Tables

        // Counts Cross-check
	    WriteLine(fp, "Highway Assignment Results for "+periods[period])
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Number of Links")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE +1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + Links[i][j]
            end
            WriteLine(fp, outline)
	    end

	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Total Volume")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE + 1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + Vol[i][j]
            end
            WriteLine(fp, outline)
	    end


	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Lane Miles")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE + 1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + LaneMiles[i][j]
            end
            WriteLine(fp, outline)
	    end


	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Vehicle Hours of Travel")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE + 1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + VHT[i][j]
            end
            WriteLine(fp, outline)
	    end


	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Vehicle Hours of Delay")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE + 1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + VHD[i][j]
            end
            WriteLine(fp, outline)
	    end


      WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Vehicle Miles of Travel")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
        WriteLine(fp, TableHeader)
        for i = 1 to MaxFACTYPE + 1 do
            outline =  FacilityRowHeader[i]
            for j = 1 to MaxATYPE + 1 do
                outline = outline + VMT[i][j]
            end
            WriteLine(fp, outline)
	    end


        // Lane Miles by LOS
        for k = 1 to MaxLOS do

            WriteLine(fp, "")						//--- a blank line
	        WriteLine(fp, "")						//--- a blank line
	        WriteLine(fp, LOSNames[k] + " Lane Miles")
	    WriteLine(fp, "                              -----------------------------------       Area Type        ------------------------------")
            WriteLine(fp, TableHeader)
            for i = 1 to MaxFACTYPE + 1 do
                outline =  FacilityRowHeader[i]
                for j = 1 to MaxATYPE + 1 do
                    outline = outline + LOSLaneMiles[i][j][k]
                end
                WriteLine(fp, outline)
	        end
        end


	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "District Analysis")
	    WriteLine(fp,DistrictHeader)
        for i = 1 to MaxDistrict + 1 do
            outline = RPad(IntToString(i),23)
            if i = MaxDistrict + 1 then outline = "Total                  "
            for j = 1 to Dist.length do
                outline = outline + Dist[j][i]
            end
            WriteLine(fp,outline)
	    end

	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "")						//--- a blank line
	    WriteLine(fp, "Screenline Analysis")
	    WriteLine(fp,ScreenlineHeader)
        for i = 1 to MaxScrLine + 1 do
            outline = RPad(IntToString(i),23)
            if i = MaxScrLine + 1 then outline = "Total                  "
            for j = 1 to ScreenLines.length do
                outline = outline + ScreenLines[j][i]
            end
            WriteLine(fp,outline)
	    end



	end

	//write out speed data
	outline = "FacType,AreaType,SpeedBin,VMT"
	WriteLine(speedfp,outline)
    for i = 1 to MaxFACTYPE do
      for j = 1 to MaxATYPE do
	     for k = 1 to SpeedBins do
	        outline = IntToString(i)+","+IntToString(j)+","+IntToString(k)+","+RealToString( VMTByFacAreaSpeed[i][j][k] )
	        WriteLine(speedfp, outline)
	     end
	  end
    end

	RunMacro("Close All")

	Return(1)
    
        
EndMacro                                                                                                                                                                                                                                                                                                                                                                                                                                                                              
