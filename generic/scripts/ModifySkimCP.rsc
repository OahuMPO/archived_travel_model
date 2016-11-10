/**********************************************************************************************************************
*
*   Modify Skims For Cordon Pricing
*   Modifies peak and off-peak highway skims prior to mode choice for cordon pricing scenario.
* 
*   This macro will modify the highway skims for the peak and off-peak time periods prior to mode choice,
*   so that any interchange with a toll cost will have its non-toll time and distance set to 0.  
*
*   Arguments:
*       scenarioDirectory   Directory for scenario
*
*
*  There are 6 skim matrices:
*
*   AM SOV
*   AM HOV2
*   AM HOV3+
*   MD SOV
*   MD HOV2
*   MD HOV3+ 
*
*  Each skim matrix has 6 currencies:
*
*    Non-Toll Time
*    Non-Toll Distance
*    Toll Time
*    Toll Distance
*    Toll Cost
*    Length on toll facility
*
**********************************************************************************************************************/
Macro "Modify Skims For Cordon Pricing" (scenarioDirectory)


    outputDirectory = scenarioDirectory+"\\outputs\\"
    
    hskimfile={outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx",
    		   outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_hov2.mtx",outputDirectory+"hwymd_hov3.mtx"}


    for i = 1 to hskimfile.length do
        skimMatrix = OpenMatrix( hskimfile[i],)
        matrixCores = GetMatrixCoreNames(skimMatrix)

        nonTollTimeCurrency   = CreateMatrixCurrency(skimMatrix, matrixCores[1], , , )
        nonTollLengthCurrency = CreateMatrixCurrency(skimMatrix, matrixCores[2], , , )
        tollCostCurrency      = CreateMatrixCurrency(skimMatrix, matrixCores[5], , , )
  
        //reset the toll cost to 1/2 of its skimmed value, since trips are in PA format each trip sees half the cordon price
        tollCostCurrency  := (tollCostCurrency * 0.5)
        
        nonTollTimeCurrency := if(tollCostCurrency>0) then 0 else nonTollTimeCurrency
        nonTollLengthCurrency := if(tollCostCurrency>0) then 0 else nonTollLengthCurrency 
    
    end
    
    ret_value = RunMacro("Convert Matrices To Binary", hskimfile)
    if !ret_value then Throw()
    
    
    Return(1)
    
    	
EndMacro    
/**********************************************************************************************************************
*
*   Modify Trips For Cordon Pricing
*   Modifies trip tables for cordon pricing scenario.
* 
*   This macro will modify trip tables prior to assignment, so that non-toll trips in any interchange with a toll cost 
*   will be moved to the toll matrix.
*
*   Arguments:
*       scenarioDirectory   Directory for scenario
*
*   There are 4 matrices to adjust:
*   
*     hwyAMPeak.mtx     AM2Hour
*     hwyOffpeak.mtx    OffPeak
*     hwyAM4Hour.mtx    AM4Hour
*     hwyPM4Hour.mtx    PM4Hour
*
*  Each trip table has 8 matrices:
*
*   SOV -FREE
*   HOV2-FREE
*   HOV3-FREE
*   SOV -PAY
*   HOV2-PAY
*   HOV3-PAY
*   TRCK-FREE
    TRCK-PAY

*  There are 6 skim matrices:
*
*   AM SOV
*   AM HOV2
*   AM HOV3+
*   MD SOV
*   MD HOV2
*   MD HOV3+ 
*
*  Each skim matrix has 6 currencies:
*
*    Non-Toll Time
*    Non-Toll Distance
*    Toll Time
*    Toll Distance
*    Toll Cost
*    Length on toll facility
*
**********************************************************************************************************************/
Macro "Modify Trips For Cordon Pricing" (scenarioDirectory)


    outputDirectory = scenarioDirectory+"\\outputs\\"
    
    hskimfile={{outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx"}, // for am peak
    		   {outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx"}, // for am 4 hour peak
    		   {outputDirectory+"hwyam_sov.mtx",outputDirectory+"hwyam_hov2.mtx",outputDirectory+"hwyam_hov3.mtx"}, // for pm 4 hour peak
    		   {outputDirectory+"hwymd_sov.mtx",outputDirectory+"hwymd_hov2.mtx",outputDirectory+"hwymd_hov3.mtx"}} // for offpeak  

    tripfile = {  outputDirectory+"hwyAMPeak.mtx", 
                  outputDirectory+"hwyAM4Hour.mtx",
                  outputDirectory+"hwyPM4Hour.mtx",
                  outputDirectory+"hwyOffpeak.mtx"}
        
        
    for i = 1 to tripfile.length do
    
        tripMatrix = OpenMatrix( tripfile[i],)
        tripCores = GetMatrixCoreNames(tripMatrix)
        
        //for each occupancy category 
        for j = 1 to 3 do
           skimMatrix = OpenMatrix( hskimfile[i][j],)
           skimCores = GetMatrixCoreNames(skimMatrix)

           tollCostCurrency      = CreateMatrixCurrency(skimMatrix, skimCores[5], , , )
     
           freeTripCurrency      = CreateMatrixCurrency(tripMatrix, tripCores[i], , , )
           tollTripCurrency      = CreateMatrixCurrency(tripMatrix, tripCores[i+3], , , )
 
           //if there is a toll cost to the destination and free trips to the destination, then add the free trips and the toll trips together and store as toll trips          
           tollTripCurrency := if(tollCostCurrency>0 & freeTripCurrency>0) then (tollTripCurrency + freeTripCurrency) else tollTripCurrency 
          
           // then reset the free trips to 0
           freeTripCurrency := if(tollCostCurrency>0) then 0 else freeTripCurrency
    
           if(j=1) then do //trucks use SOV skim
              
               freeTripCurrency      = CreateMatrixCurrency(tripMatrix, tripCores[7], , , )
               tollTripCurrency      = CreateMatrixCurrency(tripMatrix, tripCores[8], , , )
 
               //if there is a toll cost to the destination and free trips to the destination, then add the free trips and the toll trips together and store as toll trips          
               tollTripCurrency := if(tollCostCurrency>0 & freeTripCurrency>0) then (tollTripCurrency + freeTripCurrency) else tollTripCurrency 
          
               // then reset the free trips to 0
               freeTripCurrency := if(tollCostCurrency>0) then 0 else freeTripCurrency
          
           end
       end
    end
  
    Return(1)
    
    	
EndMacro    