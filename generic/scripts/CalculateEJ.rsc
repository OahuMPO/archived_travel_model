/***********************************************************************************************************************************
*
* Calculate Environmental Justice
*
* This macro will perform environmental justice calculations.
* 
* jef 5/08
*
***********************************************************************************************************************************/

Macro "Calculate Environmental Justice" (scenarioDirectory, nzones)          

    // The arrays of destination zones of interest
    univ = {64,  66,  103,  252,  334,  440,  668,  702,  755}
    hosp = {89,  166,  220,  224,  296,  300,  362,  363,  413,  519,  547,  635,  667,  702,  754}
    shop = {11,  97,  136,  186,  387,  413,  424,  433,  462,  490,  590,  636,  694}
    empl = {122,  186,  242,  333,  394,  490,  589,  721}

    //input skims, keyed to scenarioDirectory
    auto1PeakSkim = scenarioDirectory+"\\outputs\\hwyam_sov.mtx"
    auto2PeakSkim = scenarioDirectory+"\\outputs\\hwyam_hov2.mtx"
    auto3PeakSkim = scenarioDirectory+"\\outputs\\hwyam_hov3.mtx"
    transitPeakSkim = scenarioDirectory+"\\outputs\\transit_wloc_am.mtx"
    auto1OffpeakSkim = scenarioDirectory+"\\outputs\\hwymd_sov.mtx"   
    auto2OffpeakSkim = scenarioDirectory+"\\outputs\\hwymd_hov2.mtx"  
    auto3OffpeakSkim = scenarioDirectory+"\\outputs\\hwymd_hov3.mtx"  
    transitOffpeakSkim = scenarioDirectory+"\\outputs\\transit_wloc_md.mtx"
    
    //input trip tables, keyed to scenario directory
    workTrips = scenarioDirectory+"\\outputs\\mode5wh.mtx"
    collegeTrips = scenarioDirectory+"\\outputs\\mode5nc.mtx"
    shopTrips = scenarioDirectory+"\\outputs\\mode5ns.mtx"
    otherTrips = scenarioDirectory+"\\outputs\\mode5no.mtx"
    
    //output matrix of total trips weighted by time
    outputMatrix = scenarioDirectory + "\\outputs\\EJ.mtx"

    //output files
    wh_p = OpenFile(scenarioDirectory+"\\outputs\\wh_p.au", "w")          // work auto trips
    wh_pt = OpenFile(scenarioDirectory+"\\outputs\\wh_pt.au", "w")        // work auto-person trips
    wh_wl_p = OpenFile(scenarioDirectory+"\\outputs\\wh_wl_p.au", "w")    // work transit trips
    wh_wl_pt = OpenFile(scenarioDirectory+"\\outputs\\wh_wl_pt.au", "w")  // work transit-person trips
                                                                             
    nc_p = OpenFile(scenarioDirectory+"\\outputs\\nc_p.au", "w")          // college auto trips
    nc_pt = OpenFile(scenarioDirectory+"\\outputs\\nc_pt.au", "w")        // college auto-person trips
    nc_wl_p = OpenFile(scenarioDirectory+"\\outputs\\nc_wl_p.au", "w")    // college transit trips
    nc_wl_pt = OpenFile(scenarioDirectory+"\\outputs\\nc_wl_pt.au", "w")  // college transit-person trips
                                                                             
    ns_p = OpenFile(scenarioDirectory+"\\outputs\\ns_p.au", "w")          // shop auto trips
    ns_pt = OpenFile(scenarioDirectory+"\\outputs\\ns_pt.au", "w")        // shop auto-person trips
    ns_wl_p = OpenFile(scenarioDirectory+"\\outputs\\ns_wl_p.au", "w")    // shop transit trips
    ns_wl_pt = OpenFile(scenarioDirectory+"\\outputs\\ns_wl_pt.au", "w")  // shop transit-person trips
                                                                             
    no_p = OpenFile(scenarioDirectory+"\\outputs\\no_p.au", "w")          // other auto trips
    no_pt = OpenFile(scenarioDirectory+"\\outputs\\no_pt.au", "w")        // other auto-person trips
    no_wl_p = OpenFile(scenarioDirectory+"\\outputs\\no_wl_p.au", "w")    // other transit trips
    no_wl_pt = OpenFile(scenarioDirectory+"\\outputs\\no_wl_pt.au", "w")  // other transit-person trips

    amwltt = OpenFile(scenarioDirectory+"\\outputs\\TTAMXXWL.CSV", "w")     //AM Walk-Local Time to destinations
    amwl20 = OpenFile(scenarioDirectory+"\\outputs\\20AMXXWL.CSV", "w")     //AM Walk-Local 20 minute indicator to destinations

    mdwltt = OpenFile(scenarioDirectory+"\\outputs\\TTMDXXWL.CSV", "w")     //MD Walk-Local Time to destinations
    mdwl20 = OpenFile(scenarioDirectory+"\\outputs\\20MDXXWL.CSV", "w")     //MD Walk-Local 20 minute indicator to destinations

    pk01tt = OpenFile(scenarioDirectory+"\\outputs\\TTPKXX01.CSV", "w")     //Peak DA Time to destinations
    pk0120 = OpenFile(scenarioDirectory+"\\outputs\\20PKXX01.CSV", "w")     //Peak DA 20 minute indicator to destinations

    op01tt = OpenFile(scenarioDirectory+"\\outputs\\TTOPXX01.CSV", "w")     //Off-Peak DA Time to destinations
    op0120 = OpenFile(scenarioDirectory+"\\outputs\\20OPXX01.CSV", "w")     //Off-Peak DA 20 minute indicator to destinations

    //open auto and transit matrices
    auto1PeakMatrix = OpenMatrix(auto1PeakSkim, "False")
    auto2PeakMatrix = OpenMatrix(auto2PeakSkim, "False")
    auto3PeakMatrix = OpenMatrix(auto3PeakSkim, "False")
    auto1OffpeakMatrix = OpenMatrix(auto1OffpeakSkim, "False")
    auto2OffpeakMatrix = OpenMatrix(auto2OffpeakSkim, "False")
    auto3OffpeakMatrix = OpenMatrix(auto3OffpeakSkim, "False")
    transitPeakMatrix = OpenMatrix(transitPeakSkim, "False")
    transitOffpeakMatrix = OpenMatrix(transitOffpeakSkim, "False")
    
    //open trip tables
    workMatrix = OpenMatrix(workTrips, "False")
    collegeMatrix = OpenMatrix(collegeTrips, "False")
    shopMatrix = OpenMatrix(shopTrips, "False")
    otherMatrix = OpenMatrix(otherTrips, "False")
    
    // get the necessary skim matrix currencies   
 	pkAuto1MatrixCores = GetMatrixCoreNames(auto1PeakMatrix)
 	pkAuto2MatrixCores = GetMatrixCoreNames(auto2PeakMatrix)
 	pkAuto3MatrixCores = GetMatrixCoreNames(auto3PeakMatrix)
 	opAuto1MatrixCores = GetMatrixCoreNames(auto1OffpeakMatrix)
 	opAuto2MatrixCores = GetMatrixCoreNames(auto2OffpeakMatrix)
 	opAuto3MatrixCores = GetMatrixCoreNames(auto3OffpeakMatrix)

    pkAuto1TimeCurr = CreateMatrixCurrency(auto1PeakMatrix   , pkAuto1MatrixCores[1], null, null, )
    pkAuto2TimeCurr = CreateMatrixCurrency(auto2PeakMatrix   , pkAuto2MatrixCores[1], null, null, )
    pkAuto3TimeCurr = CreateMatrixCurrency(auto3PeakMatrix   , pkAuto3MatrixCores[1], null, null, )
    opAuto1TimeCurr = CreateMatrixCurrency(auto1OffpeakMatrix, opAuto1MatrixCores[1], null, null, )
    opAuto2TimeCurr = CreateMatrixCurrency(auto2OffpeakMatrix, opAuto2MatrixCores[1], null, null, )
    opAuto3TimeCurr = CreateMatrixCurrency(auto3OffpeakMatrix, opAuto3MatrixCores[1], null, null, )

    pkTransitIVTCurr  = CreateMatrixCurrency(transitPeakMatrix, "In-Vehicle Time", null, null, )    
    opTransitIVTCurr  = CreateMatrixCurrency(transitOffpeakMatrix, "In-Vehicle Time", null, null, )    
 
    // Create trip matrix currencies
    workAuto1Curr =   CreateMatrixCurrency(workMatrix, "Drive Alone", null, null, )
    workAuto2Curr =   CreateMatrixCurrency(workMatrix, "Shared 2", null, null, )
    workAuto3Curr =   CreateMatrixCurrency(workMatrix, "Shared 3+", null, null, )
    workTransitCurr = CreateMatrixCurrency(workMatrix, "Walk to Local", null, null, )
    
    collegeAuto1Curr =   CreateMatrixCurrency(collegeMatrix, "Drive Alone", null, null, )
    collegeAuto2Curr =   CreateMatrixCurrency(collegeMatrix, "Shared 2", null, null, )
    collegeAuto3Curr =   CreateMatrixCurrency(collegeMatrix, "Shared 3+", null, null, )
    collegeTransitCurr = CreateMatrixCurrency(collegeMatrix, "Walk to Local", null, null, )

    shopAuto1Curr =   CreateMatrixCurrency(shopMatrix, "Drive Alone", null, null, )
    shopAuto2Curr =   CreateMatrixCurrency(shopMatrix, "Shared 2", null, null, )
    shopAuto3Curr =   CreateMatrixCurrency(shopMatrix, "Shared 3+", null, null, )
    shopTransitCurr = CreateMatrixCurrency(shopMatrix, "Walk to Local", null, null, )

    otherAuto1Curr =   CreateMatrixCurrency(otherMatrix, "Drive Alone", null, null, )
    otherAuto2Curr =   CreateMatrixCurrency(otherMatrix, "Shared 2", null, null, )
    otherAuto3Curr =   CreateMatrixCurrency(otherMatrix, "Shared 3+", null, null, )
    otherTransitCurr = CreateMatrixCurrency(otherMatrix, "Walk to Local", null, null, )

    // Create the EJ matrix
	Opts = null
	Opts.[Compression] = 1
	Opts.[Tables] = {"Work Auto Trips","Work Transit Trips", "Work Auto Sum",   "Work Transit Sum",
	                 "College Auto Trips","College Transit Trips",  "College Auto Sum","College Transit Sum",
	                 "Shop Auto Trips",   "Shop Transit Trips", "Shop Auto Sum",   "Shop Transit Sum",
	                 "Other Auto Trips",  "Other Transit Trips", "Other Auto Sum",  "Other Transit Sum"}
	                 
	Opts.[Type] = "Float"
	Opts.[File Name] = outputMatrix
	Opts.[Label] = "Relative Auto Importance"
	EJMatrix = CopyMatrixStructure({        workAuto1Curr,workAuto1Curr,workAuto1Curr,workAuto1Curr,
	                                        workAuto1Curr,workAuto1Curr,workAuto1Curr,workAuto1Curr,
	                                        workAuto1Curr,workAuto1Curr,workAuto1Curr,workAuto1Curr,
	                                        workAuto1Curr,workAuto1Curr,workAuto1Curr,workAuto1Curr},Opts)
	    
	// Create the matrix currencies for each output matrix
	workAutoTripCurr    = CreateMatrixCurrency(EJMatrix,"Work Auto Trips", null, null, ) 
	workTransitTripCurr = CreateMatrixCurrency(EJMatrix,"Work Transit Trips", null, null, ) 
	collegeAutoTripCurr    = CreateMatrixCurrency(EJMatrix,"College Auto Trips", null, null, ) 
	collegeTransitTripCurr = CreateMatrixCurrency(EJMatrix,"College Transit Trips", null, null, ) 
	shopAutoTripCurr    = CreateMatrixCurrency(EJMatrix,"Shop Auto Trips", null, null, ) 
	shopTransitTripCurr = CreateMatrixCurrency(EJMatrix,"Shop Transit Trips", null, null, ) 
	otherAutoTripCurr    = CreateMatrixCurrency(EJMatrix,"Other Auto Trips", null, null, ) 
	otherTransitTripCurr = CreateMatrixCurrency(EJMatrix,"Other Transit Trips", null, null, ) 
	workAutoSumCurr    = CreateMatrixCurrency(EJMatrix,"Work Auto Sum", null, null, ) 
	workTransitSumCurr = CreateMatrixCurrency(EJMatrix,"Work Transit Sum", null, null, ) 
	collegeAutoSumCurr    = CreateMatrixCurrency(EJMatrix,"College Auto Sum", null, null, ) 
	collegeTransitSumCurr = CreateMatrixCurrency(EJMatrix,"College Transit Sum", null, null, ) 
	shopAutoSumCurr    = CreateMatrixCurrency(EJMatrix,"Shop Auto Sum", null, null, ) 
	shopTransitSumCurr = CreateMatrixCurrency(EJMatrix,"Shop Transit Sum", null, null, ) 
	otherAutoSumCurr    = CreateMatrixCurrency(EJMatrix,"Other Auto Sum", null, null, ) 
	otherTransitSumCurr = CreateMatrixCurrency(EJMatrix,"Other Transit Sum", null, null, ) 
	
	// calculate the output matrices

	workAutoSumCurr       := workAuto1Curr * pkAuto1TimeCurr + workAuto2Curr * pkAuto2TimeCurr + workAuto3Curr * pkAuto3TimeCurr
	workAutoTripCurr      := workAuto1Curr + workAuto2Curr + workAuto3Curr 
	workTransitSumCurr    := workTransitCurr * pkTransitIVTCurr
	workTransitTripCurr   := workTransitCurr
	
	collegeAutoSumCurr    := (collegeAuto1Curr * pkAuto1TimeCurr + collegeAuto2Curr * pkAuto2TimeCurr + collegeAuto3Curr * pkAuto3TimeCurr)*0.2 +
	                         (collegeAuto1Curr * pkAuto1TimeCurr + collegeAuto2Curr * pkAuto2TimeCurr + collegeAuto3Curr * pkAuto3TimeCurr)*0.8
	collegeTransitSumCurr := (collegeTransitCurr * pkTransitIVTCurr)*0.2 + (collegeTransitCurr * pkTransitIVTCurr)*0.8
	collegeTransitSumCurr    := collegeTransitCurr * pkTransitIVTCurr
	collegeTransitTripCurr   := collegeTransitCurr
	
	shopAutoSumCurr    := (shopAuto1Curr * pkAuto1TimeCurr + shopAuto2Curr * pkAuto2TimeCurr + shopAuto3Curr * pkAuto3TimeCurr)*0.1 +
	                         (shopAuto1Curr * pkAuto1TimeCurr + shopAuto2Curr * pkAuto2TimeCurr + shopAuto3Curr * pkAuto3TimeCurr)*0.9
	shopTransitSumCurr := (shopTransitCurr * pkTransitIVTCurr)*0.1 + (shopTransitCurr * pkTransitIVTCurr)*0.9
	shopTransitSumCurr    := shopTransitCurr * pkTransitIVTCurr
	shopTransitTripCurr   := shopTransitCurr

	otherAutoSumCurr    := (otherAuto1Curr * pkAuto1TimeCurr + otherAuto2Curr * pkAuto2TimeCurr + otherAuto3Curr * pkAuto3TimeCurr)*0.15 +
	                         (otherAuto1Curr * pkAuto1TimeCurr + otherAuto2Curr * pkAuto2TimeCurr + otherAuto3Curr * pkAuto3TimeCurr)*0.85
	otherTransitSumCurr := (otherTransitCurr * pkTransitIVTCurr)*0.15 + (otherTransitCurr * pkTransitIVTCurr)*0.85
	otherTransitSumCurr    := otherTransitCurr * pkTransitIVTCurr
	otherTransitTripCurr   := otherTransitCurr
	
	
   // calculate the column vector of row sums
    workAutoTripTot = GetMatrixMarginals(workAutoTripCurr, "Sum", "row" )
    workTranTripTot = GetMatrixMarginals(workTransitTripCurr, "Sum", "row" )
    workAutoSumTot = GetMatrixMarginals(workAutoSumCurr, "Sum", "row" )
    workTranSumTot = GetMatrixMarginals(workTransitSumCurr, "Sum", "row" )
    
    collegeAutoTripTot = GetMatrixMarginals(collegeAutoTripCurr, "Sum", "row" )
    collegeTranTripTot = GetMatrixMarginals(collegeTransitTripCurr, "Sum", "row" )
    collegeAutoSumTot = GetMatrixMarginals(collegeAutoSumCurr, "Sum", "row" )
    collegeTranSumTot = GetMatrixMarginals(collegeTransitSumCurr, "Sum", "row" )

    shopAutoTripTot = GetMatrixMarginals(shopAutoTripCurr, "Sum", "row" )
    shopTranTripTot = GetMatrixMarginals(shopTransitTripCurr, "Sum", "row" )
    shopAutoSumTot = GetMatrixMarginals(shopAutoSumCurr, "Sum", "row" )
    shopTranSumTot = GetMatrixMarginals(shopTransitSumCurr, "Sum", "row" )

    otherAutoTripTot = GetMatrixMarginals(otherAutoTripCurr, "Sum", "row" )
    otherTranTripTot = GetMatrixMarginals(otherTransitTripCurr, "Sum", "row" )
    otherAutoSumTot = GetMatrixMarginals(otherAutoSumCurr, "Sum", "row" )
    otherTranSumTot = GetMatrixMarginals(otherTransitSumCurr, "Sum", "row" )

	//write headers to the travel time output files
	header1="FROM"
	header2="TAZ"
	
	for i=1 to univ.length do
	    header1=header1+",TO UNIV"
	    header2=header2+", "+String(univ[i])+" "
	end
	
	for i=1 to hosp.length do
	    header1=header1+",TO HOSP"
	    header2=header2+", "+String(hosp[i])+" "
	end

	for i=1 to shop.length do
	    header1=header1+",TO SHOP"
	    header2=header2+", "+String(shop[i])+" "
	end

	for i=1 to empl.length do
	    header1=header1+",TO EMPL"
	    header2=header2+", "+String(empl[i])+" "
	end

	WriteLine(amwltt, header1)
	WriteLine(amwltt, header2)
	
    WriteLine(amwl20, header1)
    WriteLine(amwl20, header2)
	                          
	WriteLine(mdwltt, header1)          
	WriteLine(mdwltt, header2)          
	
	WriteLine(mdwl20, header1)          
	WriteLine(mdwl20, header2)          
	                          
	WriteLine(pk01tt, header1)          
	WriteLine(pk01tt, header2)          
	
	WriteLine(pk0120, header1)          
	WriteLine(pk0120, header2)          
	                          
	WriteLine(op01tt, header1)          
	WriteLine(op01tt, header2)          

	WriteLine(op0120, header1)          
	WriteLine(op0120, header2)          
	                      
    CreateProgressBar("Calculating EJ Vectors ...", "True")
 
 	//write the output
	for i = 1 to nzones do
	
        // update status bar
        stat = UpdateProgressBar("", RealToInt(i/nzones*100) )

	    iString = RunMacro ("RightFormat",i,4)
	    
	    //work
	    vString = RunMacro ("RightFormat",RealToInt(workAutoTripTot[i]),10)
        WriteLine(wh_p,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(workAutoSumTot[i]),10)
        WriteLine(wh_pt,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(workTranTripTot[i]),10)
        WriteLine(wh_wl_p,iString+" "+vString)
	   
	    vString = RunMacro ("RightFormat",RealToInt(workTranSumTot[i]),10)
        WriteLine(wh_wl_pt,iString+" "+vString)

	    //college
	    vString = RunMacro ("RightFormat",RealToInt(collegeAutoTripTot[i]),10)
        WriteLine(nc_p,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(collegeAutoSumTot[i]),10)
        WriteLine(nc_pt,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(collegeTranTripTot[i]),10)
        WriteLine(nc_wl_p,iString+" "+vString)
	   
	    vString = RunMacro ("RightFormat",RealToInt(collegeTranSumTot[i]),10)
        WriteLine(nc_wl_pt,iString+" "+vString)

	    //shop
	    vString = RunMacro ("RightFormat",RealToInt(shopAutoTripTot[i]),10)
        WriteLine(ns_p,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(shopAutoSumTot[i]),10)
        WriteLine(ns_pt,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(shopTranTripTot[i]),10)
        WriteLine(ns_wl_p,iString+" "+vString)
	   
	    vString = RunMacro ("RightFormat",RealToInt(shopTranSumTot[i]),10)
        WriteLine(ns_wl_pt,iString+" "+vString)

	    //other
	    vString = RunMacro ("RightFormat",RealToInt(otherAutoTripTot[i]),10)
        WriteLine(no_p,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(otherAutoSumTot[i]),10)
        WriteLine(no_pt,iString+" "+vString)

	    vString = RunMacro ("RightFormat",RealToInt(otherTranTripTot[i]),10)
        WriteLine(no_wl_p,iString+" "+vString)
	   
	    vString = RunMacro ("RightFormat",RealToInt(otherTranSumTot[i]),10)
        WriteLine(no_wl_pt,iString+" "+vString)

	    amwlttLine = String(i)
        amwl20Line = String(i)
	    mdwlttLine = String(i)          
	    mdwl20Line = String(i)          
	    pk01ttLine = String(i)          
	    pk0120Line = String(i)          
	    op01ttLine = String(i)          
	    op0120Line = String(i)          

       //univ
	    for j= 1 to univ.length do
	        
	        // am wl
	        value = GetMatrixValue(pkTransitIVTCurr,String(i),String(univ[j]))
	        amwlttLine = amwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            amwl20Line = amwl20Line + " , 1"
	            end
	        else do
	            amwl20Line = amwl20Line + " , 0"
	        end
	        
	        // md wl
	        value = GetMatrixValue(opTransitIVTCurr,String(i),String(univ[j]))
	        mdwlttLine = mdwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            mdwl20Line = mdwl20Line + " , 1"
	            end
	        else do
	            mdwl20Line = mdwl20Line + " , 0"
	        end
	        
	        // am auto
	        value = GetMatrixValue(pkAuto1TimeCurr,String(i),String(univ[j]))
	        pk01ttLine = pk01ttLine +  " , "+String(Round(value,2))
	        if(value<20) then do
	            pk0120Line = pk0120Line+ " , 1"
	            end
	        else do
	            pk0120Line = pk0120Line+  " , 0"
	        end
	        
	        // md auto
	        value = GetMatrixValue(opAuto1TimeCurr,String(i),String(univ[j]))
	        op01ttLine = op01ttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            op0120Line = op0120Line +  " , 1"
	            end
	        else do
	            op0120Line = op0120Line +  " , 0"
	        end
        end
	        
       //hosp
	    for j= 1 to hosp.length do
	        
	        // am wl
	        value = GetMatrixValue(pkTransitIVTCurr,String(i),String(hosp[j]))
	        amwlttLine = amwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            amwl20Line = amwl20Line + " , 1"
	            end
	        else do
	            amwl20Line = amwl20Line + " , 0"
	        end
	        
	        // md wl
	        value = GetMatrixValue(opTransitIVTCurr,String(i),String(hosp[j]))
	        mdwlttLine = mdwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            mdwl20Line = mdwl20Line + " , 1"
	            end
	        else do
	            mdwl20Line = mdwl20Line + " , 0"
	        end
	        
	        // am auto
	        value = GetMatrixValue(pkAuto1TimeCurr,String(i),String(hosp[j]))
	        pk01ttLine = pk01ttLine +  " , "+String(Round(value,2))
	        if(value<20) then do
	            pk0120Line = pk0120Line+ " , 1"
	            end
	        else do
	            pk0120Line = pk0120Line+  " , 0"
	        end
	        
	        // md auto
	        value = GetMatrixValue(opAuto1TimeCurr,String(i),String(hosp[j]))
	        op01ttLine = op01ttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            op0120Line = op0120Line +  " , 1"
	            end
	        else do
	            op0120Line = op0120Line +  " , 0"
	        end
        end
	
       //shop
	    for j= 1 to shop.length do
	        
	        // am wl
	        value = GetMatrixValue(pkTransitIVTCurr,String(i),String(shop[j]))
	        amwlttLine = amwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            amwl20Line = amwl20Line + " , 1"
	            end
	        else do
	            amwl20Line = amwl20Line + " , 0"
	        end
	        
	        // md wl
	        value = GetMatrixValue(opTransitIVTCurr,String(i),String(shop[j]))
	        mdwlttLine = mdwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            mdwl20Line = mdwl20Line + " , 1"
	            end
	        else do
	            mdwl20Line = mdwl20Line + " , 0"
	        end
	        
	        // am auto
	        value = GetMatrixValue(pkAuto1TimeCurr,String(i),String(shop[j]))
	        pk01ttLine = pk01ttLine +  " , "+String(Round(value,2))
	        if(value<20) then do
	            pk0120Line = pk0120Line+ " , 1"
	            end
	        else do
	            pk0120Line = pk0120Line+  " , 0"
	        end
	        
	        // md auto
	        value = GetMatrixValue(opAuto1TimeCurr,String(i),String(shop[j]))
	        op01ttLine = op01ttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            op0120Line = op0120Line +  " , 1"
	            end
	        else do
	            op0120Line = op0120Line +  " , 0"
	        end
        end
        
       //empl
	    for j= 1 to empl.length do
	        
	        // am wl
	        value = GetMatrixValue(pkTransitIVTCurr,String(i),String(empl[j]))
	        amwlttLine = amwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            amwl20Line = amwl20Line + " , 1"
	            end
	        else do
	            amwl20Line = amwl20Line + " , 0"
	        end
	        
	        // md wl
	        value = GetMatrixValue(opTransitIVTCurr,String(i),String(empl[j]))
	        mdwlttLine = mdwlttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            mdwl20Line = mdwl20Line + " , 1"
	            end
	        else do
	            mdwl20Line = mdwl20Line + " , 0"
	        end
	        
	        // am auto
	        value = GetMatrixValue(pkAuto1TimeCurr,String(i),String(empl[j]))
	        pk01ttLine = pk01ttLine +  " , "+String(Round(value,2))
	        if(value<20) then do
	            pk0120Line = pk0120Line+ " , 1"
	            end
	        else do
	            pk0120Line = pk0120Line+  " , 0"
	        end
	        
	        // md auto
	        value = GetMatrixValue(opAuto1TimeCurr,String(i),String(empl[j]))
	        op01ttLine = op01ttLine + " , "+String(Round(value,2))
	        if(value<20) then do
	            op0120Line = op0120Line +  " , 1"
	            end
	        else do
	            op0120Line = op0120Line +  " , 0"
	        end
        end
	    
	    WriteLine(amwltt, amwlttLine)
        WriteLine(amwl20, amwl20Line)
	    WriteLine(mdwltt, mdwlttLine)          
	    WriteLine(mdwl20, mdwl20Line)          
	    WriteLine(pk01tt, pk01ttLine)          
	    WriteLine(pk0120, pk0120Line)          
	    WriteLine(op01tt, op01ttLine)          
	    WriteLine(op0120, op0120Line)
	end
	
    DestroyProgressBar()

    CloseFile(amwltt)
    CloseFile(amwl20)
    CloseFile(mdwltt)          
    CloseFile(mdwl20)          
    CloseFile(pk01tt)          
    CloseFile(pk0120)          
    CloseFile(op01tt)          
    CloseFile(op0120)          
    CloseFile(wh_p    )
    CloseFile(wh_pt   )
    CloseFile(wh_wl_p )
    CloseFile(wh_wl_pt)
    CloseFile(nc_p    )
    CloseFile(nc_pt   )
    CloseFile(nc_wl_p )
    CloseFile(nc_wl_pt)
    CloseFile(ns_p    )
    CloseFile(ns_pt   )
    CloseFile(ns_wl_p )
    CloseFile(ns_wl_pt)
    CloseFile(no_p    )
    CloseFile(no_pt   )
    CloseFile(no_wl_p )
    CloseFile(no_wl_pt)
          
    Return(1)
              
EndMacro


/*
  Add spaces to a number, right shifting.

*/
Macro "RightFormat" (value, spaces)

    valueString = String(value)
    length = Len(valueString)
    
    if(length > spaces) then Return ("xxx")
        
    newString=""
    fill = spaces - length
    for i = 1 to fill do
	    newString = newString + " "                      
	end                      
	newString = newString + valueString
	
	Return (newString) 
	                     
EndMacro	                      
	                      
	                      
	                      
	          