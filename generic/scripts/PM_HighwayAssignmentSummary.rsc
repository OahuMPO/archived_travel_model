Macro "PM_Highway Assignment Summary"

    RunMacro("TCB Init")

//    RunMacro("AllDay")
	// This section reads the line layer, count layer, and assignment results table
	//and then combines the three databases into one single dataview

	// Open the taz layer, which contains the district field
	TAZ_geography = "C:\\Projects\\Ompo\\Conversion\\Application\\\generic\\inputs\\taz\\Master TAZ Layer.dbd"
	TAZlayers = GetDBLayers(TAZ_geography)


	//Open the scenario line layer and set the link layer as active layer
	line_geography = "C:\\Projects\\Ompo\\Conversion\\Application\\\generic\\inputs\\master_network\\Oahu Network 102907.dbd"
	llayers = GetDBLayers(line_geography)
	map = RunMacro("G30 new map",line_geography, "False")
	SetLayer(llayers[2])


	// Add the district field to the line layer using district field from the taz layer
//	Dim TD_at
//	TD_at = "TD"
    	Opts = null
    	Opts.Input.[Dataview Set] = {line_geography+"|"+llayers[2], llayers[2]}    // fill layer is link layer
    	Opts.Input.[Tag View Set] = {TAZ_geography+"|"+TAZlayers[1], TAZlayers[1]}      // tag layer is TAZs
    	Opts.Global.Fields = {llayers[2]+"."+"Drop ME"}                  // the field to fill
    	Opts.Global.Method = "Tag"                                      // fill by tagging
    	Opts.Global.Parameter = {"Value", TAZlayers[1], TAZlayers[1]+".TD"}  // the value to fill with is the taz layer District
    	ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
	if !ret_value then Throw()


	//Open the database containing the assignemnt results and combine that to the line layer
	DayAssign = "C:\\Projects\\Ompo\\Conversion\\Application\\2005_base\\outputs\\PM4HourFlow1.bin"
	Asn = OpenTable("Asn", "FFB", {DayAssign})
	VIEW1 = JoinViews("VIEW1", llayers[2]+".ID", Asn + ".ID1",)

	//Open the geographic layer containing the count data
	Count_geography = "C:\\Projects\\Ompo\\Conversion\\Application\\generic\\counts\\2005 OahuFinalCounts_mar2508.dbd"
	Clayers = GetDBLayers(Count_geography)
	map = RunMacro("G30 new map",Count_geography, "False")
	SetLayer(Clayers[1])

    // Combine the "Line Layer + Assignemnt results Dataview" and the Count Data
	VIEW2 = JoinViews("VIEW2", VIEW1+".[CountID]", Clayers[1] + ".ID",)

    dim Dir[1], CountID[1], ABFACTYPE[1], BAFACTYPE[1], ABATYPE[1], BAATYPE[1], District[1], LinkID[1]
    dim abflow[1], abVMT[1], baflow[1], baVMT[1], totflow[1], totVMT[1], AADT[1]
    dim Scr_Line[1]

//  Create Vectors/Arrays to read data from tables/Dataviews
    Dir[1] = GetDataVector(VIEW2 + "|", "Dir",)                                     // Direction of the Link
    LinkID[1] = GetDataVector(VIEW2 + "|", "[Oahu Links].ID",)				    // Link ID number
    CountID[1] = VectorToArray(GetDataVector(VIEW2 + "|", "[CountID]",))            // ID of count station on each Link
    ABFACTYPE[1] = VectorToArray(GetDataVector(VIEW2 + "|", "[AB FACTYPE]",))       // Facility Type for AB direction
    BAFACTYPE[1] = GetDataVector(VIEW2 + "|", "[BA FACTYPE]",)                      // Facility Type for BA direction
    ABATYPE[1] = VectorToArray(GetDataVector(VIEW2 + "|", "AB_ATYPE",))           // Area Type for AB direction
    BAATYPE[1] = GetDataVector(VIEW2 + "|", "BA_ATYPE",)                          // Area Type for BA direction
    abflow[1] = GetDataVector(VIEW2 + "|", "AB_Flow",)                          // PM Peak assigned flow for AB direction
    abVMT[1] = GetDataVector(VIEW2 + "|", "AB_VMT",)                                // PM Peak assigned flow for BA direction
    baflow[1] = GetDataVector(VIEW2 + "|", "BA_Flow",)                          // PM Peak assigned flow for AB direction
    baVMT[1] = GetDataVector(VIEW2 + "|", "BA_VMT",)                                // Daily Vehicles Miles Travelled for BA direction
    totflow[1] = GetDataVector(VIEW2 + "|", "Tot_Flow",)                        // PM Peak assigned flow for each link
    totVMT[1] = GetDataVector(VIEW2 + "|", "Tot_VMT",)                              // PM Peak Vehicles Miles Travelled
    AADT[1] = GetDataVector(VIEW2 + "|", "[PM Peak]",)                                   // Count Data
    Scr_Line[1] = VectorToArray(GetDataVector(VIEW2 + "|", "Scr_Line",))                               // Screenline data
    District[1] = VectorToArray(GetDataVector(VIEW2 + "|", "District",))
    RunMacro("Close All")

//    Fill the missing values with zeros to make computations(finding maximum values) easier
    NumRec = Dir[1].length
    for j = 1 to NumRec do
        if CountID[1][j] = "" then
           CountID[1][j] = 0
        if ABFACTYPE[1][j] = "" then
           ABFACTYPE[1][j] = 0
        if ABATYPE[1][j] = "" then
           ABATYPE[1][j] = 0
        if Scr_Line[1][j] = "" then
           Scr_Line[1][j] = 0
        if District[1][j] = "" then
           District[1][j] = 0

        totflow[1][j] = RealToInt(totflow[1][j])

    end

//  Computes the maximum values in each array
    MaxCountID = RealToInt(ArrayMax(CountID[1]))
    MaxFACTYPE = RealToInt(ArrayMax(ABFACTYPE[1]))
    MaxAREATYPE = RealToInt(ArrayMax(ABATYPE[1]))
    MaxScrLine = RealToInt(ArrayMax(Scr_Line[1]))
    MaxDistrict = RealToInt(ArrayMax(District[1]))


//    Fill zeros with missing values after computations (finding maximum values) are done
    for j = 1 to NumRec do
        if CountID[1][j] = 0 then
           CountID[1][j] = ""
        if ABFACTYPE[1][j] = 0 then
           ABFACTYPE[1][j] = ""
        if ABATYPE[1][j] = 0 then
           ABATYPE[1][j] = ""
        if Scr_Line[1][j] = 0 then
           Scr_Line[1][j] = ""
        if District[1][j] = 0 then
           District[1][j] = ""
    end

//  Initialize the Vectors that are used to estimate the statistics for comparing observed and assigned flows
    Dim  NumLinkCS[MaxFACTYPE + 4,MaxAREATYPE + 1], Obs_Link_Count[MaxFACTYPE + 4,MaxAREATYPE + 1], Est_Link_Count[MaxFACTYPE + 4,MaxAREATYPE + 1]
    Dim  Obs_Sta_Count[5,MaxCountID], Est_Sta_Count[MaxCountID]
    Dim  Diff_Count[MaxFACTYPE + 4,MaxAREATYPE + 1], Abs_Diff_Count[MaxFACTYPE + 4,MaxAREATYPE + 1], Relative_Error[MaxFACTYPE + 4,MaxAREATYPE + 1], RMSE[4,MaxFACTYPE + 4,MaxAREATYPE + 1]
    dim  Volume_Groups[8,3]
    Volume_Groups = {{"0-5,000",0,5000},{"5,000-10,000",5001,10000},{"10,000-15,000",10001,15000},{"15,000-20,000",15001,20000},{"20,000-25,000",20001,25000},{"25,000-50,000",25001,50000},{"50,000+",50001,999999}}
    dim  Vol_Groups[ArrayLength(Volume_Groups) + 1,10]
    for i = 1 to MaxFACTYPE + 4 do
        for j = 1 to MaxAREATYPE + 1 do
            NumLinkCS[i][j] = 0
            Obs_Link_Count[i][j] = 0
            Est_Link_Count[i][j] = 0
            RMSE[1][i][j] = 0
            RMSE[2][i][j] = 0
            RMSE[3][i][j] = 0
            RMSE[4][i][j] = 0
        end
    end

// Initialize volume group matrix
    for i = 1 to ArrayLength(Volume_Groups) + 1 do
        for j = 1 to 10 do
            Vol_Groups[i][j] = 0
        end
    end


    dim Links_Per_Station[MaxCountID], ScreenLines[10, MaxScrLine + 3]
    Dim Dist[10, MaxDistrict + 1]

    for i = 1 to MaxCountID do
        Links_Per_Station[i] = 0
    end

    for i = 1 to MaxScrLine + 3 do
        ScreenLines[1][i] = IntToString(i)
        for j = 2 to 10 do
            ScreenLines[j][i] = 0
        end
    end

    for i = 1 to MaxDistrict + 1 do
        Dist[1][i] = IntToString(i)
        for j = 2 to 10 do
            Dist[j][i] = 0
        end
    end

    for i = 1 to NumRec do
        if CountID[1][i] <> "" then do
            if Dir[1][i] <> -1 then do
                FacType = RealToInt(ABFACTYPE[1][i])
                ATYPE = RealToInt(ABATYPE[1][i])
            end

            if Dir[1][i] <> 1 then do
                FacType = RealToInt(BAFACTYPE[1][i])
                ATYPE = RealToInt(BAATYPE[1][i])
            end

//            if Scr_Line[1][i] <> "" then do
//                ScreenLines[2][Scr_Line[1][i]] = ScreenLines[2][Scr_Line[1][i]] + 1
//            end

//            if District[1][i] <> "" then do
//                Dist[2][District[1][i]] = Dist[2][District[1][i]] + 1
//            end

            if Links_Per_Station[CountID[1][i]] < 1 then do
//              Obs_Link_Count[FacType][ATYPE] =  Obs_Link_Count[FacType][ATYPE] + AADT[1][i]
                Obs_Sta_Count[2][CountID[1][i]] =  AADT[1][i]
                Obs_Sta_Count[1][CountID[1][i]] = FacType
                Obs_Sta_Count[3][CountID[1][i]] = ATYPE
                if Scr_Line[1][i] <> "" then do
                    Obs_Sta_Count[4][CountID[1][i]] = Scr_Line[1][i]
                end
                if District[1][i] <> "" then do
                    Obs_Sta_Count[5][CountID[1][i]] = District[1][i]
                end
                Est_Sta_Count[CountID[1][i]] = totflow[1][i]
                NumLinkCS[FacType][ATYPE] = NumLinkCS[FacType][ATYPE] + 1
            end

            if Links_Per_Station[CountID[1][i]] >= 1 then do
//                CS_Counte = Links_Per_Station[CountID[1][i]]
                if Obs_Sta_Count[1][CountID[1][i]] <> FacType then do
                    if Min(Obs_Sta_Count[1][CountID[1][i]],FacType) = 1 and (Max(Obs_Sta_Count[1][CountID[1][i]],FacType) = 9 or Max(Obs_Sta_Count[1][CountID[1][i]],FacType) = 10) then do
                        Obs_Sta_Count[1][CountID[1][i]] = 11
                        FacType = 11
                    end
                    if Min(Obs_Sta_Count[1][CountID[1][i]],FacType) = 1 and (Max(Obs_Sta_Count[1][CountID[1][i]],FacType) = 13) then do
                        Obs_Sta_Count[1][CountID[1][i]] = 16
                        FacType = 16
                    end
                    if Min(Obs_Sta_Count[1][CountID[1][i]],FacType) = 2 and (Max(Obs_Sta_Count[1][CountID[1][i]],FacType) = 9 or Max(Obs_Sta_Count[1][CountID[1][i]],FacType) = 10) then do
                        Obs_Sta_Count[1][CountID[1][i]] = 17
                        FacType = 17
                    end
                    if Links_Per_Station[CountID[1][i]] = 1 then do
                        NumLinkCS[FacType][ATYPE] = NumLinkCS[FacType][ATYPE] + 2
                    end
                    else do
                        NumLinkCS[FacType][ATYPE] = NumLinkCS[FacType][ATYPE] + 1
                    end

                end
                Est_Sta_Count[CountID[1][i]] = Est_Sta_Count[CountID[1][i]] + totflow[1][i]
            end

            Links_Per_Station[CountID[1][i]] = Links_Per_Station[CountID[1][i]] + 1

//            Est_Link_Count[FacType][ATYPE] = Est_Link_Count[FacType][ATYPE] + totflow[1][i]
//            Est_Sta_Count[CountID[1][i]] = Est_Sta_Count[CountID[1][i]] + totflow[1][i]
        end
    end



//  Compute the Observed and estimated flows by AreaType & Facility type
//          Which are: Obs_Link_Count & Est_Link_Count
//                           using
//   Observed and estimated flows by count station
//          Which are:  Obs_Sta_Count & Est_Sta_Count
    for i = 1 to MaxCountID do
        if Obs_Sta_Count[2][i] <> null then do
//            NumLinkCS[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = NumLinkCS[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + 1
            Obs_Link_Count[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = Obs_Link_Count[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + Obs_Sta_Count[2][i]
            Est_Link_Count[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = Est_Link_Count[Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + Est_Sta_Count[i]
            RMSE[1][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = RMSE[1][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + (Obs_Sta_Count[2][i] - Est_Sta_Count[i])*(Obs_Sta_Count[2][i] - Est_Sta_Count[i])
            RMSE[2][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = RMSE[2][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + Obs_Sta_Count[2][i]
            RMSE[3][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] = RMSE[3][Obs_Sta_Count[1][i]][Obs_Sta_Count[3][i]] + 1
            if Obs_Sta_Count[4][i] <> "" then do
		ScreenLines[2][Obs_Sta_Count[4][i]] = ScreenLines[2][Obs_Sta_Count[4][i]] + Links_Per_Station[i]
                ScreenLines[3][Obs_Sta_Count[4][i]] = ScreenLines[3][Obs_Sta_Count[4][i]] + Obs_Sta_Count[2][i]
                ScreenLines[4][Obs_Sta_Count[4][i]] = ScreenLines[4][Obs_Sta_Count[4][i]] + Est_Sta_Count[i]
                ScreenLines[8][Obs_Sta_Count[4][i]] = ScreenLines[8][Obs_Sta_Count[4][i]] + (Obs_Sta_Count[2][i] - Est_Sta_Count[i])*(Obs_Sta_Count[2][i] - Est_Sta_Count[i])
                ScreenLines[9][Obs_Sta_Count[4][i]] = ScreenLines[9][Obs_Sta_Count[4][i]] + Obs_Sta_Count[2][i]
                ScreenLines[10][Obs_Sta_Count[4][i]] = ScreenLines[10][Obs_Sta_Count[4][i]] + 1
            end
            if Obs_Sta_Count[5][i] <> "" then do
                Dist[2][Obs_Sta_Count[5][i]] = Dist[2][Obs_Sta_Count[5][i]] + Links_Per_Station[i]
                Dist[3][Obs_Sta_Count[5][i]] = Dist[3][Obs_Sta_Count[5][i]] + Obs_Sta_Count[2][i]
                Dist[4][Obs_Sta_Count[5][i]] = Dist[4][Obs_Sta_Count[5][i]] + Est_Sta_Count[i]
                Dist[8][Obs_Sta_Count[5][i]] = Dist[8][Obs_Sta_Count[5][i]] + (Obs_Sta_Count[2][i] - Est_Sta_Count[i])*(Obs_Sta_Count[2][i] - Est_Sta_Count[i])
                Dist[9][Obs_Sta_Count[5][i]] = Dist[9][Obs_Sta_Count[5][i]] + Obs_Sta_Count[2][i]
                Dist[10][Obs_Sta_Count[5][i]] = Dist[10][Obs_Sta_Count[5][i]] + 1
            end
        end
    end

// Compute the statistics for the volume groups
    for i = 1 to MaxCountID do
        for j = 1 to ArrayLength(Volume_Groups) do
            if Obs_Sta_Count[2][i] <= Volume_Groups[j][3] and Obs_Sta_Count[2][i] > Volume_Groups[j][2] then do
                Vol_Groups[j][2] = Vol_Groups[j][2] + Links_Per_Station[i]
                Vol_Groups[j][3] = Vol_Groups[j][3] + Obs_Sta_Count[2][i]
                Vol_Groups[j][4] = Vol_Groups[j][4] + Est_Sta_Count[i]
                Vol_Groups[j][8] = Vol_Groups[j][8] + (Est_Sta_Count[i] - Obs_Sta_Count[2][i])*(Est_Sta_Count[i] - Obs_Sta_Count[2][i])
                Vol_Groups[j][9] = Vol_Groups[j][9] + Obs_Sta_Count[2][i]
                Vol_Groups[j][10] = Vol_Groups[j][10] + 1
            end
        end
    end

    Vol_Groups[ArrayLength(Volume_Groups) + 1][1] = "Total"
    for j = 1 to ArrayLength(Volume_Groups) do
        Vol_Groups[ArrayLength(Volume_Groups) + 1][2] = Vol_Groups[ArrayLength(Volume_Groups) + 1][2] + Vol_Groups[j][2]
        Vol_Groups[ArrayLength(Volume_Groups) + 1][3] = Vol_Groups[ArrayLength(Volume_Groups) + 1][3] + Vol_Groups[j][3]
        Vol_Groups[ArrayLength(Volume_Groups) + 1][4] = Vol_Groups[ArrayLength(Volume_Groups) + 1][4] + Vol_Groups[j][4]
        Vol_Groups[ArrayLength(Volume_Groups) + 1][8] = Vol_Groups[ArrayLength(Volume_Groups) + 1][8] + Vol_Groups[j][8]
        Vol_Groups[ArrayLength(Volume_Groups) + 1][9] = Vol_Groups[ArrayLength(Volume_Groups) + 1][9] + Vol_Groups[j][9]
        Vol_Groups[ArrayLength(Volume_Groups) + 1][10] = Vol_Groups[ArrayLength(Volume_Groups) + 1][10] + Vol_Groups[j][10]
    end


// Format the Volume groups table
    for i = 1 to ArrayLength(Volume_Groups) + 1 do
        if Vol_Groups[i][2] <> 0 then do
            Vol_Groups[i][5] = Format(Vol_Groups[i][4]/Vol_Groups[i][3], "*.00")
            Vol_Groups[i][6] = Format((Vol_Groups[i][4]- Vol_Groups[i][3])/Vol_Groups[i][3], ",*.00 %")
            Vol_Groups[i][7] = Format(((Sqrt(Vol_Groups[i][8]/Vol_Groups[i][10]))/(Vol_Groups[i][9]/Vol_Groups[i][10])), ",*.00 %")
        end
        if Vol_Groups[i][2] = 0 then do
            Vol_Groups[i][5] = Format(Vol_Groups[i][5], "*.00")
            Vol_Groups[i][6] = Format(Vol_Groups[i][6], ",*.00 %")
            Vol_Groups[i][7] = Format(Vol_Groups[i][7], ",*.00 %")
        end
            Vol_Groups[i][2] = Format(Vol_Groups[i][2], ",*")
            Vol_Groups[i][3] = Format(Vol_Groups[i][3], ",*")
            Vol_Groups[i][4] = Format(Vol_Groups[i][4], ",*")
    end

//  Compute the Aggregate statistics(Difference: "Diff_Count[i][j]", Absolute-Difference: Abs_Diff_Count[i][j], Relative Error: "Relative_Error[i][j]")
//  for comparing the observed and estimated flows
    for i = 1 to MaxFACTYPE + 3 do
        for j = 1 to MaxAREATYPE do
            Diff_Count[i][j] = (Est_Link_Count[i][j] - Obs_Link_Count[i][j])
            Abs_Diff_Count[i][j] = Abs(Est_Link_Count[i][j] - Obs_Link_Count[i][j])
            if Obs_Link_Count[i][j] <> 0 then
                Relative_Error[i][j] = ((Est_Link_Count[i][j] - Obs_Link_Count[i][j])/Obs_Link_Count[i][j])
            else do
                Relative_Error[i][j] = 0
            end
        end
    end


    for i = 1 to MaxFACTYPE + 3 do
        for j = 1 to MaxAREATYPE do
            if RMSE[3][i][j] <> 0 then do
                RMSE[4][i][j] = ((Sqrt(RMSE[1][i][j]/RMSE[3][i][j]))/(RMSE[2][i][j]/RMSE[3][i][j]))
            end
            else do
                RMSE[4][i][j] = 0
            end
        end
    end


// Compute the marginal statistics for each Facility Type
for i = 1 to MaxFACTYPE + 3 do
    for j = 1 to MaxAREATYPE do
        NumLinkCS[i][MaxAREATYPE + 1] = NumLinkCS[i][MaxAREATYPE + 1] + NumLinkCS[i][j]
        Obs_Link_Count[i][MaxAREATYPE + 1] = Obs_Link_Count[i][MaxAREATYPE + 1] + Obs_Link_Count[i][j]
        Est_Link_Count[i][MaxAREATYPE + 1] = Est_Link_Count[i][MaxAREATYPE + 1] + Est_Link_Count[i][j]
        RMSE[1][i][MaxAREATYPE + 1] = RMSE[1][i][MaxAREATYPE + 1] + RMSE[1][i][j]
        RMSE[2][i][MaxAREATYPE + 1] = RMSE[2][i][MaxAREATYPE + 1] + RMSE[2][i][j]
        RMSE[3][i][MaxAREATYPE + 1] = RMSE[3][i][MaxAREATYPE + 1] + RMSE[3][i][j]
    end
        Diff_Count[i][MaxAREATYPE + 1] = Est_Link_Count[i][MaxAREATYPE + 1] - Obs_Link_Count[i][MaxAREATYPE + 1]
        Abs_Diff_Count[i][MaxAREATYPE + 1] = Abs(Est_Link_Count[i][MaxAREATYPE + 1] - Obs_Link_Count[i][MaxAREATYPE + 1])
        if Obs_Link_Count[i][MaxAREATYPE + 1] <> 0 then
            Relative_Error[i][MaxAREATYPE + 1] = (Est_Link_Count[i][MaxAREATYPE + 1] - Obs_Link_Count[i][MaxAREATYPE + 1])/Obs_Link_Count[i][MaxAREATYPE + 1]
        else do
            Relative_Error[i][MaxAREATYPE + 1] = 0
        end
        if RMSE[3][i][MaxAREATYPE + 1] <> 0 then
            RMSE[4][i][MaxAREATYPE + 1] = ((Sqrt(RMSE[1][i][MaxAREATYPE + 1]/RMSE[3][i][MaxAREATYPE + 1]))/(RMSE[2][i][MaxAREATYPE + 1]/RMSE[3][i][MaxAREATYPE + 1]))
        else do
            RMSE[4][i][MaxAREATYPE + 1] = 0
        end
end

// Compute the marginal statistics for each Area Type
for j = 1 to MaxAREATYPE + 1 do
    for i = 1 to MaxFACTYPE + 3 do
        NumLinkCS[MaxFACTYPE + 4][j] = NumLinkCS[MaxFACTYPE + 4][j] + NumLinkCS[i][j]
        Obs_Link_Count[MaxFACTYPE + 4][j] = Obs_Link_Count[MaxFACTYPE + 4][j] + Obs_Link_Count[i][j]
        Est_Link_Count[MaxFACTYPE + 4][j] = Est_Link_Count[MaxFACTYPE + 4][j] + Est_Link_Count[i][j]
        RMSE[1][MaxFACTYPE + 4][j] = RMSE[1][MaxFACTYPE + 4][j] + RMSE[1][i][j]
        RMSE[2][MaxFACTYPE + 4][j] = RMSE[2][MaxFACTYPE + 4][j] + RMSE[2][i][j]
        RMSE[3][MaxFACTYPE + 4][j] = RMSE[3][MaxFACTYPE + 4][j] + RMSE[3][i][j]
    end
        Diff_Count[MaxFACTYPE + 4][j] = Est_Link_Count[MaxFACTYPE + 4][j] - Obs_Link_Count[MaxFACTYPE + 4][j]
        Abs_Diff_Count[MaxFACTYPE + 4][j] = Abs(Est_Link_Count[MaxFACTYPE + 4][j] - Obs_Link_Count[MaxFACTYPE + 4][j])
        if Obs_Link_Count[MaxFACTYPE + 4][j] <> 0 then
                Relative_Error[MaxFACTYPE + 4][j] = (Est_Link_Count[MaxFACTYPE + 4][j] - Obs_Link_Count[MaxFACTYPE + 4][j])/Obs_Link_Count[MaxFACTYPE + 4][j]
        else do
            Relative_Error[MaxFACTYPE + 4][j] = 0
        end
        if RMSE[3][MaxFACTYPE + 4][j] <> 0 then
            RMSE[4][MaxFACTYPE + 4][j] = ((Sqrt(RMSE[1][MaxFACTYPE + 4][j]/RMSE[3][MaxFACTYPE + 4][j]))/(RMSE[2][MaxFACTYPE + 4][j]/RMSE[3][MaxFACTYPE + 4][j]))
        else do
            RMSE[4][MaxFACTYPE + 4][j] = 0
        end
end



//  Compute the marginals for the screenline table and the district table
//  Add titles for the cumulative statistics
    ScreenLines[1][MaxScrLine + 1] = "Sub-total"
    ScreenLines[1][MaxScrLine + 2] = "No-Screenline"
    ScreenLines[1][MaxScrLine + 3] = "Total"
    Dist[1][MaxDistrict + 1] = "Total"

//  Calculate the cumulative statistics for the screenline table and the district table
    for i = 2 to 4 do
        for j = 1 to MaxScrLine do
            ScreenLines[i][MaxScrLine + 1] = ScreenLines[i][MaxScrLine + 1] + ScreenLines[i][j]
        end
    end
    for i = 8 to 10 do
        for j = 1 to MaxScrLine do
            ScreenLines[i][MaxScrLine + 1] = ScreenLines[i][MaxScrLine + 1] + ScreenLines[i][j]
        end
    end

    for i = 2 to 4 do
        for j = 1 to MaxDistrict do
            Dist[i][MaxDistrict + 1] = Dist[i][MaxDistrict + 1] + Dist[i][j]
        end
    end
    for i = 8 to 10 do
        for j = 1 to MaxDistrict do
            Dist[i][MaxDistrict + 1] = Dist[i][MaxDistrict + 1] + Dist[i][j]
        end
    end

    ScreenLines[2][MaxScrLine + 3] = NumLinkCS[MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[3][MaxScrLine + 3] = Obs_Link_Count[MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[4][MaxScrLine + 3] = Est_Link_Count[MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[2][MaxScrLine + 2] = NumLinkCS[MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[2][MaxScrLine + 1]
    ScreenLines[3][MaxScrLine + 2] = Obs_Link_Count[MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[3][MaxScrLine + 1]
    ScreenLines[4][MaxScrLine + 2] = Est_Link_Count[MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[4][MaxScrLine + 1]
    ScreenLines[8][MaxScrLine + 3] = RMSE[1][MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[9][MaxScrLine + 3] = RMSE[2][MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[10][MaxScrLine + 3] = RMSE[3][MaxFACTYPE + 4][MaxAREATYPE + 1]
    ScreenLines[8][MaxScrLine + 2] = RMSE[1][MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[8][MaxScrLine + 1]
    ScreenLines[9][MaxScrLine + 2] = RMSE[2][MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[9][MaxScrLine + 1]
    ScreenLines[10][MaxScrLine + 2] = RMSE[3][MaxFACTYPE + 4][MaxAREATYPE + 1] - ScreenLines[10][MaxScrLine + 1]

    for i = 1 to MaxScrLine + 3 do
        if  ScreenLines[3][i] <> 0 then do
            ScreenLines[5][i] = Format((ScreenLines[4][i]/ScreenLines[3][i]),"*.00")
            ScreenLines[6][i] = Format(((ScreenLines[4][i] - ScreenLines[3][i])/(ScreenLines[3][i])),"*.00 %")
            ScreenLines[7][i] = Format(((Sqrt(ScreenLines[8][i]/ScreenLines[10][i]))/(ScreenLines[9][i]/ScreenLines[10][i])), ",*.00 %")
        end
	else do
	    ScreenLines[5][i] = Format((ScreenLines[5][i]),"*.00")
            ScreenLines[6][i] = Format((ScreenLines[6][i]),"*.00 %")
            ScreenLines[7][i] = Format((ScreenLines[7][i]), ",*.00 %")
	end
            ScreenLines[2][i] = Format(ScreenLines[2][i], ",*")
            ScreenLines[3][i] = Format(ScreenLines[3][i], ",*")
            ScreenLines[4][i] = Format(ScreenLines[4][i], ",*")
    end

    for i = 1 to MaxDistrict + 1 do
        if  Dist[3][i] <> 0 then do
            Dist[5][i] = (Dist[4][i]/Dist[3][i])
            Dist[6][i] = ((Dist[4][i] - Dist[3][i])/(Dist[3][i]))
            Dist[7][i] = ((Sqrt(Dist[8][i]/Dist[10][i]))/(Dist[9][i]/Dist[10][i]))
        end
            Dist[2][i] = Format(Dist[2][i], ",*")
            Dist[3][i] = Format(Dist[3][i], ",*")
            Dist[4][i] = Format(Dist[4][i], ",*")
	    Dist[5][i] = Format(Dist[5][i],"*.00")
	    Dist[6][i] = Format(Dist[6][i],"*.00 %")
	    Dist[7][i] = Format(Dist[7][i], ",*.00 %")
    end

// Format the Statistics appropriately, this has two advantages
// (1) Easy to read
// (2) Will convert the numeric values to string, so "+ operator" will concatenate the values later
for i = 1 to MaxFACTYPE + 4 do
    for j = 1 to MaxAREATYPE + 1 do
        Obs_Link_Count[i][j] = Format(Obs_Link_Count[i][j], ",*")
        Est_Link_Count[i][j] = Format(Est_Link_Count[i][j], ",*")
        Diff_Count[i][j] = Format(Diff_Count[i][j], ",+/-*")
        Relative_Error[i][j] = Format(Relative_Error[i][j], ",+/-*.00 %")
        RMSE[4][i][j] = Format(RMSE[4][i][j],  ",+/-*.00 %")
    end
end

//  FOrmat the Labels, blank[i][1] is label for Table "i"
	dim blank[7,MaxFACTYPE + 5]
	dim blank2[MaxScrLine + 4]
	dim blank4[MaxDistrict + 2]
	dim blank3[ArrayLength(Volume_Groups) + 2]
    dim Facility[MaxFACTYPE + 4]
    Facility = {{"1", "Freeways"},{"2", "Expressways"},{"3", "Class I arterials"},{"4", "Class II arterials"},{"5", "Class III arterials"},{"6", "Class I collectors"},{"7", "Class II collectors"},{"8", "local streets"},{"9", "High speed Ramps"},{"10", "Low Speed Ramps"},{"11", "Freeway and Ramps"},{"12", "centroid connectors"},{"13", "HOV lanes"},{"14", "Rail"},{"15", "Walk Access"},{"16","Freeway and HOV"},{"17","Expressway and Ramps"},{"All","All Facility Types"}}
	blank[1][1] = "Facility Type                 1         2         3         4         5         6         7         8         All Areas"
    blank[2][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank[3][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank[4][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank[5][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank[6][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank[7][1] = "Facility Type	              1         2         3         4         5         6         7         8         All Areas"
    blank2[1] = "Screenlines   	    Links               Observed Count      Estimated Count     Est/Obs Ratio       Relative Error      %RMSE"
    blank4[1] = "Districts     	    Links               Observed Count      Estimated Count     Est/Obs Ratio       Relative Error      %RMSE"
    blank3[1] = "Observed ADT Range Links               Observed Count      Estimated Count     Est/Obs Ratio       Relative Error      %RMSE"


//  For ease of reading, the values are written in a table format, where each cell in the table has a fixed width "w"
//  The empty space of width = w - length of the cell is filled with spaces
    dim temp[2,MaxFACTYPE + 5]
    for i = 2 to MaxFACTYPE + 5 do
        for j = 1 to (5 - Len(Facility[i-1][1])) do temp[1][i-1] = temp[1][i-1] + " " end
        for j = 1 to (25 - Len(Facility[i-1][2])) do temp[2][i-1] = temp[2][i-1] + " " end

        blank[1][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[2][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[3][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[4][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[5][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[6][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
        blank[7][i]= Facility[i-1][1] + temp[1][i-1] + Facility[i-1][2] + temp[2][i-1]
    	for j = 1 to MaxAREATYPE + 1 do
    		blank[1][i]=blank[1][i] + IntToString(NumLinkCS[i-1][j])
    		for k = 1 to (10 - Len(IntToString(NumLinkCS[i-1][j]))) do blank[1][i] = blank[1][i] + " " end

    		blank[2][i]=blank[2][i] + Obs_Link_Count[i-1][j]
    		for k = 1 to (10 - Len(Obs_Link_Count[i-1][j])) do blank[2][i] = blank[2][i] + " " end

    		blank[3][i]=blank[3][i] + Est_Link_Count[i-1][j]
    		for k = 1 to (10 - Len(Est_Link_Count[i-1][j])) do blank[3][i] = blank[3][i] + " " end

    		blank[4][i]=blank[4][i] + (Diff_Count[i-1][j])
    		for k = 1 to (10 - Len((Diff_Count[i-1][j]))) do blank[4][i] = blank[4][i] + " " end

    		blank[5][i]=blank[5][i] + IntToString(RealToInt(Abs_Diff_Count[i-1][j]))
    		for k = 1 to (10 - Len(IntToString(RealToInt(Abs_Diff_Count[i-1][j])))) do blank[5][i] = blank[5][i] + " " end

    		blank[6][i]=blank[6][i] + Relative_Error[i-1][j]
    		for k = 1 to (10 - Len(Relative_Error[i-1][j])) do blank[6][i] = blank[6][i] + " " end

    		blank[7][i]=blank[7][i] + RMSE[4][i-1][j]
    		for k = 1 to (10 - Len(RMSE[4][i-1][j])) do blank[7][i] = blank[7][i] + " " end
        end

    end

        for i = 2 to MaxScrLine + 4 do
            for j = 1 to 7 do
        		blank2[i] = blank2[i] + ScreenLines[j][i-1]
        		for k = 1 to (20 - Len((ScreenLines[j][i-1]))) do blank2[i] = blank2[i] + " " end
            end
        end


        for i = 2 to MaxDistrict + 2 do
            for j = 1 to 7 do
        		blank4[i] = blank4[i] + Dist[j][i-1]
        		for k = 1 to (20 - Len((Dist[j][i-1]))) do blank4[i] = blank4[i] + " " end
            end
        end


        for i = 2 to ArrayLength(Volume_Groups) + 2 do
            if i = ArrayLength(Volume_Groups) + 2 then do
                blank3[i] = blank3[i] + Vol_Groups[i-1][1]
            for k = 1 to (20 - Len((Vol_Groups[i-1][1]))) do blank3[i] = blank3[i] + " " end
            end
            else do
                blank3[i] = blank3[i] + Volume_Groups[i-1][1]
            for k = 1 to (20 - Len((Volume_Groups[i-1][1]))) do blank3[i] = blank3[i] + " " end
            end
            for j = 2 to 7 do
        		blank3[i] = blank3[i] + Vol_Groups[i-1][j]
        		for k = 1 to (20 - Len((Vol_Groups[i-1][j]))) do blank3[i] = blank3[i] + " " end
            end
        end


// Print out the Observed counts and estimated flows for each count station


//	Counts Cross-check
    fp = OpenFile("C:\\Projects\\Ompo\\Conversion\\Application\\PM_Peak_Counts Cross-check.txt", "w")
	WriteLine(fp, "PM Peak Highway Assignment Results for OMPO Model")
	Writeline(fp, "")						//--- a blank line
	WriteLine(fp, "Links with Counts")
	Writeline(fp, "Count ID            Observed Count      Estimated Count      Observed Links")
	for i = 1 to MaxCountID do
	  blank5 = ""
	  if Obs_Sta_Count[2][i] <> "" then do
		Obs_Sta_Count[2][i] = Format(Obs_Sta_Count[2][i], "*,")
		Est_Sta_Count[i] = Format(Est_Sta_Count[i], "*,")
		blank51 = inttostring(i)
		for j = 1 to (20 - len(inttostring(i))) do
			blank51 = blank51 + " "
		end
		blank52 = Obs_Sta_Count[2][i]
		for j = 1 to (20 - len(Obs_Sta_Count[2][i])) do
			blank52 = blank52 + " "
		end
		blank53 = Est_Sta_Count[i]
		for j = 1 to (20 - len(Est_Sta_Count[i])) do
			blank53 = blank53 + " "
		end
//		if Obs_Sta_Count[2][i] <> "" then do
//			blank55 = format((Est_Sta_Count[i] - Obs_Sta_Count[2][i])/(Obs_Sta_Count[2][i]), "*.00 %")
//		end
//		else do
//			blank55 = ""
//		end
//		for j = 1 to (20 - len(format(((Est_Sta_Count[i] - Obs_Sta_Count[2][i])/(Obs_Sta_Count[2][i])), "*.00 %"))) do
//			blank55 = blank55 + " "
//		end
		blank54 = ""
		for j = 1 to NumRec do
			if CountID[1][j] = i then do
				if len(blank54) > 1 then do
					blank54 = blank54 + ", "
				end
				blank54 = blank54 + inttostring(LinkID[1][j])
			end
		end
		blank5 = blank51 + blank52 + blank53 + blank55 + blank54
		Writeline(fp, blank5)
	 end
	 else do
	    Obs_Sta_Count[2][i] = Format(Obs_Sta_Count[2][i], "*,")
		Est_Sta_Count[i] = Format(Est_Sta_Count[i], "*,")
     end
	end



// Print out the Tables
    fp = OpenFile("C:\\Projects\\Ompo\\Conversion\\Application\\PM_Peak_Highway Assignment Summary.txt", "w")
	WriteLine(fp, "PM Peak Highway Assignment Results for OMPO Model")
	Writeline(fp, "")						//--- a blank line
	WriteLine(fp, "Links with Counts")
	Writeline(fp, "                              ---------------------------       Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
    		WriteLine(fp, blank[1][i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Observed Flows")
	Writeline(fp, "                              ---------------------------       Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
      	WriteLine(fp, blank[2][i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Estimated Flows")
	Writeline(fp, "                              ---------------------------       Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
        	WriteLine(fp, blank[3][i])
	end


	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Difference Between Estimated and Observed Flows")
	Writeline(fp, "                              ---------------------------       Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
        	WriteLine(fp, blank[4][i])
	end


	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Absolute Difference Between Estimated and Observed Flows")
	Writeline(fp, "                              ---------------------------       Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
        	WriteLine(fp, blank[5][i])
	end


	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Relative Error Between Estimated and Observed Flows")
	Writeline(fp, "                              ----------------------            Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
        	WriteLine(fp, blank[6][i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "RMSE Between Estimated and Observed Flows")
	Writeline(fp, "                              ----------------------            Area Type           -----------------------")
    for i = 1 to MaxFACTYPE + 5 do
        	WriteLine(fp, blank[7][i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Screenline Analysis")
    for i = 1 to MaxScrLine + 4 do
        	WriteLine(fp, blank2[i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "District Analysis")
    for i = 1 to MaxDistrict + 2 do
        	WriteLine(fp, blank4[i])
	end

	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "")						//--- a blank line
	Writeline(fp, "Comparison between Observed and Estimated flows")
    for i = 1 to ArrayLength(Volume_Groups) + 2 do
        	WriteLine(fp, blank3[i])
	end
    quit:
    Return(1)
EndMacro
