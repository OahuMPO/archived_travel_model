/**************************************************************
*  TODFactor.rsc
*
*  PB - jef 3/08
*
*  TransCAD Macro used to factor trip tables
*
*    Inputs:
*        Mode Choice Person Trip Files (12 tables each)
*            MODE5WH.MTX     JTW: Home - Work
*            MODE5WO.MTX     JTW: Home - Other
*            MODE5NK.MTX     Home-Based K-12
*            MODE5NC.MTX     Home-Based College
*            MODE5NS.MTX     Home-Based Shop
*            MODE5NO.MTX     Home-Based Other
*
*  If toll option is true, then
*
*            MODE5WH_TOL.MTX     JTW: Home - Works  auto trips with toll trips
*            MODE5WO_TOL.MTX     JTW: Home - Other auto trips with toll trips
*            MODE5NK_TOL.MTX     Home-Based K-12 auto trips with toll trips
*            MODE5NC_TOL.MTX     Home-Based College auto trips with toll trips
*            MODE5NS_TOL.MTX     Home-Based Shop auto trips with toll trips
*            MODE5NO_TOL.MTX     Home-Based Other auto trips with toll trips
*
*
***************************************************************/
Macro "TOD Factor Home Based Transit" (scenarioDirectory, railPresent, iftoll)

    RunMacro("TCB Init")

    scenarioDirectory = "F:\\projects\\OMPO\\ORTP2009\\C_Model\\2030MOSJ_setdist_110503"
    railPresent = 1     // rail is present in MOS J scenario
    iftoll = 0          // no toll option for this scenario

    persFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH.MTX",     //  JTW: Home - Work
            scenarioDirectory+"\\outputs\\MODE5WO.MTX",     //  JTW: Home - Other
            scenarioDirectory+"\\outputs\\MODE5NK.MTX",     //  Home-Based K-12
            scenarioDirectory+"\\outputs\\MODE5NC.MTX",     //  Home-Based College
            scenarioDirectory+"\\outputs\\MODE5NS.MTX",     //  Home-Based Shop
            scenarioDirectory+"\\outputs\\MODE5NO.MTX" }     //  Home-Based Other

    tollFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH_TOL.MTX",     //  JTW: Home - Work
            scenarioDirectory+"\\outputs\\MODE5WO_TOL.MTX",     //  JTW: Home - Other
            scenarioDirectory+"\\outputs\\MODE5NK_TOL.MTX",     //  Home-Based K-12
            scenarioDirectory+"\\outputs\\MODE5NC_TOL.MTX",     //  Home-Based College
            scenarioDirectory+"\\outputs\\MODE5NS_TOL.MTX",     //  Home-Based Shop
            scenarioDirectory+"\\outputs\\MODE5NO_TOL.MTX" }     //  Home-Based Other



    periodNames = { "AMPeak",  // 6 AM - 8 AM
                    "AMShld",  // 5 AM - 6 AM AND 8 AM - 9 AM
                    "Midday",  // 9 AM - 2 PM
                    "PMPeak",  // 3 PM - 5 PM
                    "PMShld",  // 2 PM - 3 PM AND 5 PM - 6 PM
                    "Night"}   // 6 PM - 5 AM



/****************************************************************************************************************************************
            PERSON TRIPS
****************************************************************************************************************************************/

        //Purpose    JTW-HBW  JTW-HBNW   HBSch    HBCol    HBShp     HBOth
        //Abbrev       wh       wo         nk        nc        ns        no
    perFactors ={ { {0.280,    0.106,    0.320,    0.161,    0.038,    0.122},         // SOV, AM Peak
                    {0.133,    0.079,    0.113,    0.131,    0.055,    0.085},         // SOV, AM Shoulder
                    {0.104,    0.119,    0.108,    0.382,    0.460,    0.286},         // SOV, Midday
                    {0.188,    0.173,    0.075,    0.085,    0.140,    0.133},         // SOV, PM Peak
                    {0.132,    0.170,    0.170,    0.106,    0.127,    0.140},         // SOV, PM Shoulder
                    {0.163,    0.353,    0.214,    0.135,    0.180,    0.234}   },     // SOV, Night

                  { {0.295,    0.379,    0.591,    0.233,    0.015,    0.139},         // HOV, AM Peak
                    {0.137,    0.067,    0.052,    0.123,    0.022,    0.059},         // HOV, AM Shoulder
                    {0.066,    0.052,    0.036,    0.298,    0.356,    0.210},         // HOV, Midday
                    {0.192,    0.137,    0.106,    0.125,    0.134,    0.147},         // HOV, PM Peak
                    {0.124,    0.170,    0.199,    0.175,    0.173,    0.173},         // HOV, PM Shoulder
                    {0.186,    0.196,    0.016,    0.046,    0.300,    0.272}  },      // HOV, Night

                  { {0.258,    0.087,    0.305,    0.203,    0.043,    0.083},         // Walk-Transit, AM Peak
                    {0.120,    0.107,    0.066,    0.178,    0.090,    0.131},         // Walk-Transit, AM Shoulder
                    {0.186,    0.274,    0.154,    0.352,    0.448,    0.418},         // Walk-Transit, Midday,
                    {0.194,    0.277,    0.145,    0.082,    0.118,    0.071},         // Walk-Transit, PM Peak,
                    {0.150,    0.132,    0.308,    0.145,    0.189,    0.136},         // Walk-Transit, PM Shoulder
                    {0.092,    0.124,    0.022,    0.040,    0.112,    0.161}  },      // Walk-Transit, Night,

                  { {0.258,    0.087,    0.305,    0.203,    0.043,    0.083},         // Drive-Transit, AM Peak
                    {0.120,    0.107,    0.066,    0.178,    0.090,    0.131},         // Drive-Transit, AM Shoulder
                    {0.186,    0.274,    0.154,    0.352,    0.448,    0.418},         // Drive-Transit, Midday,
                    {0.194,    0.277,    0.145,    0.082,    0.118,    0.071},         // Drive-Transit, PM Peak,
                    {0.150,    0.132,    0.308,    0.145,    0.189,    0.136},         // Drive-Transit, PM Shoulder
                    {0.092,    0.124,    0.022,    0.040,    0.112,    0.161}  } }     // Drive-Transit, Night,

    apFactors ={ {  {0.028,   0.003,     0.002,    0.005,    0.135,    0.204},         // SOV, AM Peak
                    {0.039,   0.018,     0.016,    0.033,    0.208,    0.277},         // SOV, AM Shoulder
                    {0.325,   0.453,     0.657,    0.397,    0.530,    0.363},         // SOV, Midday
                    {0.885,   0.897,     0.845,    0.633,    0.634,    0.488},         // SOV, PM Peak
                    {0.836,   0.919,     0.795,    0.848,    0.634,    0.522},         // SOV, PM Shoulder
                    {0.748,   0.935,     0.758,    0.849,    0.621,    0.610}  },      // SOV, Night

                  { {0.028,   0.003,     0.002,    0.005,    0.135,    0.204},         // HOV, AM Peak
                    {0.039,   0.018,     0.016,    0.033,    0.208,    0.277},         // HOV, AM Shoulder
                    {0.325,   0.453,     0.657,    0.397,    0.530,    0.363},         // HOV, Midday
                    {0.885,   0.897,     0.845,    0.633,    0.634,    0.488},         // HOV, PM Peak
                    {0.836,   0.919,     0.795,    0.848,    0.634,    0.522},         // HOV, PM Shoulder
                    {0.748,   0.935,     0.758,    0.849,    0.621,    0.610}  },      // HOV, Night

                  { {0.028,   0.003,     0.002,    0.005,    0.135,    0.204},         // Walk-Transit, AM Peak
                    {0.039,   0.018,     0.016,    0.033,    0.208,    0.277},         // Walk-Transit, AM Shoulder
                    {0.325,   0.453,     0.657,    0.397,    0.530,    0.363},         // Walk-Transit, Midday
                    {0.885,   0.897,     0.845,    0.633,    0.634,    0.488},         // Walk-Transit, PM Peak
                    {0.836,   0.919,     0.795,    0.848,    0.634,    0.522},         // Walk-Transit, PM Shoulder
                    {0.748,   0.935,     0.758,    0.849,    0.621,    0.610}  },      // Walk-Transit, Night

                  { {0.000,   0.000,     0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, AM Peak
                    {0.000,   0.000,     0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, AM Shoulder
                    {0.000,   0.000,     0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, Midday
                    {1.000,   1.000,     1.000,    1.000,    1.000,    1.000,},         // Drive-Transit, PM Peak
                    {1.000,   1.000,     1.000,    1.000,    1.000,    1.000,},         // Drive-Transit, PM Shoulder
                    {1.000,   1.000,     1.000,    1.000,    1.000,    1.000,}  }  }    // Drive-Transit, Night

    //maps trip table modes to factor modes
    modeIndex =   { 1,  // Drive Alone
                    2,  // Shared 2
                    2,  // Shared 3+
                    3,  // Walk to Express
                    3,  // Walk to Local
                    3,  // Walk to Guideway
                    4,  // Park-and-Ride
                    4,  // Kiss-and-Ride
                    2,  // Walk
                    2,  // Bike
                    4,  // PNR-formal
                    4 } // PNR-informal


    occFactors = {  1,  // Drive Alone
                    1/2,  // Shared 2
                    1/3.5,  // Shared 3+
                    1,  // Walk to Express
                    1,  // Walk to Local
                    1,  // Walk to Guideway
                    1,  // Park-and-Ride
                    1,  // Kiss-and-Ride
                    1,  // Walk
                    1,  // Bike
                    1,  // PNR-formal
                    1 } // PNR-informal

    outFile = scenarioDirectory+"\\outputs\\pers"

    ret_value = RunMacro("Factor OD",persFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()

  if ( iftoll <> 0) then do


    //maps trip table modes to factor modes
    modeIndex =   { 1,    // Drive Alone Non-Toll
                    1,    // Drive Alone Toll
                    2,    // Shared 2 Non-Toll
                    2,    // Shared 2 Toll
                    2,    // Shared 3+ Non-Toll
                    2  }  // Shared 3+ Toll

    occFactors = {  1,    // Drive Alone Non-Toll
                    1,    // Drive Alone Toll
                    1/2,  // Shared 2 Non-Toll
                    1/2,  // Shared 2 Toll
                    1/3.5,  // Shared 3+ Non-Toll
                    1/3.5 } // Shared 3+ TOll

    outFile = scenarioDirectory+"\\outputs\\toll"

    ret_value = RunMacro("Factor OD",tollFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()

  end


 collapse:
/***************************************************************************************************************************
   Collapse
****************************************************************************************************************************/
    // **********************************************************************************************************************
    //Now collapse peak transit tables
   inFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH.MTX",     //  JTW: Home - Work
            scenarioDirectory+"\\outputs\\MODE5WO.MTX",     //  JTW: Home - Other
            scenarioDirectory+"\\outputs\\MODE5NK.MTX",     //  Home-Based K-12
            scenarioDirectory+"\\outputs\\MODE5NC.MTX"}     //  Home-Based College

   outFile = scenarioDirectory+"\\outputs\\trnPeakHB.mtx"

   description = "HB Peak Period Transit Tables"

   coreNames = {"WLK-EXP",  // 1
                "WLK-LOC",  // 2
                "WLK-GDWY", // 3
                "PNR-FRM",  // 4
                "PNR-INF",  // 5
                "KNR" }     // 6

      //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
      //Visit Cores  -  AUTO     BUS      GDWY     TAXI     TOUR     WALK     TOTL
      //Visit Obs  -    TRN
      //Airpt Cores  -  Auto     Taxi     P.Bus  Shuttle  TourBus   FIXGDWY
   if( railPresent <> 0) then do
   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Work
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Other
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based K-12
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}} //Home-Based College
	 end
	 else do
   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Work
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Other
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based K-12
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}} //Home-Based College
     end


   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse off-peak transit tables
   inFiles = {
            scenarioDirectory+"\\outputs\\MODE5NS.MTX",      //  Home-Based Shop
            scenarioDirectory+"\\outputs\\MODE5NO.MTX" }      //  Home-Based Other

   outFile = scenarioDirectory+"\\outputs\\trnOffPeakHB.mtx"

   description = "HB Off-Peak Period Transit Tables"

   coreNames = {"WLK-EXP",  // 1
                "WLK-LOC",  // 2
                "WLK-GDWY", // 3
                "PNR-FRM",  // 4
                "PNR-INF",  // 5
                "KNR" }     // 6

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    //Visit Cores  -  AUTO     BUS      GDWY     TAXI     TOUR     WALK     TOTL
    //Obs Visit Cores- TRN
    //Airpt Cores  -  Auto     Taxi     P.Bus  Shuttle  TourBus   FIXGDWY
   if( railPresent <> 0) then do

   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based Shop
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}} //Home-Based Other
	 end
	 else do
   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based Shop
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}} //Home-Based Other
     end

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    Return(1)

    
    	

EndMacro
/***********************************************************************************************************************************
*
* Factor OD
* Macro factors trip tables by OD.  The macro writes one file for each period, containing the same number of cores as the input
* files, factored by time-of-day and PA/AP (to OD format).  The files will be written to the same directory as the input files.
* In addition, transposes of the input files will be written to that directory.
*
* Arguments:
*   inFiles             Array of input file names.  Each file must have exactly the same number of matrix cores.
*   outFile             Path/name of output file prefix - period will be appended for each output file.
*   perFactors          Array of period-specific factors dimensioned by mode, period, and input files
*   apFactors           Array of attraction-production factors dimensioned by mode, period, and input files.
*   occFactors          Array of occupancy factors dimensioned by number of cores on input files.
*   modeIndex           Array of indexes dimensioned by number of cores on input files, relating each matrix core
*                       to a mode in the perFactors and apFactors tables.
*
***********************************************************************************************************************************/
Macro "Factor OD" (inFiles, outFile,perFactors, apFactors, occFactors, modeIndex, periodNames)

    dim matrixCurr[modeIndex.length]
    dim inTotals[inFiles.length, modeIndex.length]
    dim outTotals[periodNames.length, modeIndex.length]

    //open input trip tables and create transpose of trip files
    dim inMat [inFiles.length]
    dim inMat_T[inFiles.length]
    for i = 1 to inFiles.length do
        inMat[i] = OpenMatrix(inFiles[i],)

        //matrix totals
        inModeNames  = GetMatrixCoreNames(inMat[i])
        stat_array = MatrixStatistics(inMat[i],)

        for j = 1 to inModeNames.length do
            inTotals[i][j] = stat_array.(inModeNames[j]).Sum
        end

        //transpose
        path = SplitPath(inFiles[i])
        inMat_T[i] = TransposeMatrix(inMat[i],
            { {"File Name", path[1]+path[2]+path[3]+"_TPS.MTX"},
              {"Label", "Operated Matrix"},
              {"Type", "Float"},
              {"Sparse", "No"},
              {"Column Major", "No"},
              {"File Based", "Yes"}})
    end

   //write the table for inputs to the report file
    AppendToReportFile(0, "Time-of-Day Factoring", {{"Section", "True"}})
    fileColumn = { {"Name", "File"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to inModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/inModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "TOD Factor Input File Totals"}})

    for i = 1 to inFiles.length do
        path = SplitPath(inFiles[i])
        fileName = path[3]
        outRow = null
        for j = 1 to inModeNames.length do
            outRow =  outRow  + {inTotals[i][j] }
        end
        outRow = { fileName } + outRow
        AppendRowToReportFile(outRow,)
    end

    //create period files for outputs
    dim outMat[periodNames.length]
    for i = 1 to periodNames.length do
        fileName = outFile+periodNames[i]+".mtx"
        CopyFile(inFiles[1],fileName)
        outMat[i] = OpenMatrix(fileName,)
    end

    //enter a loop on time periods
    for i = 1 to periodNames.length do

        // enter loop on files
        for j = 1 to inFiles.length do

            // open the input trip file
            mcurr  = CreateMatrixCurrencies(inMat[j], , ,)
            m_cores  = GetMatrixCoreNames(inMat[j])

            // enter loop on tables
            for k = 1 to m_cores.length do

                // get the trip tables - input, input transposed, output
                inTrips     = mcurr.(m_cores[k])
                inTripsT    = CreateMatrixCurrency(inMat_T[j], m_cores[k], , , )
                outTrips    = CreateMatrixCurrency( outMat[i], m_cores[k], , , )

                //initialize the output matrix to 0 if the first file
                if(j = 1) then do
                    outTrips := 0
                end

                // get the factors
                mode        = modeIndex[k]
                apFactor    = apFactors[mode][i][j]
                paFactor    = 1.0 - apFactor
                todFactor   = perFactors[mode][i][j]
                occFactor   = occFactors[k]

                // calculate the output table
                outTrips := outTrips + (todFactor* occFactor * ( inTrips*paFactor + inTripsT*apFactor ) )

		    end
        end
    end

   // delete the transposed matrices
   for i = 1 to inFiles.length do
        inMat[i] = OpenMatrix(inFiles[i],)
        path = SplitPath(inFiles[i])
        DeleteFile(path[1]+path[2]+path[3]+"_TPS.MTX")
    end

   // sum the output matrices
   for i = 1 to outMat.length do
        fileName = outFile+periodNames[i]+".mtx"
        outMat[i] = OpenMatrix(fileName,)
        outModeNames  = GetMatrixCoreNames(outMat[i])
        stat_array = MatrixStatistics(outMat[i],)

        for j = 1 to outModeNames.length do
            outTotals[i][j] = stat_array.(outModeNames[j]).Sum
        end

    end

    //write the table for outputs to the report file
    fileColumn = { {"Name", "Period"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    modeColumns = null
    for i = 1 to outModeNames.length do
        modeColumns =   modeColumns + { { {"Name", inModeNames[i]}, {"Percentage Width", (100-20)/outModeNames.length}, {"Alignment", "Left"}, {"Decimals", 0} } }
    end
    columns = {fileColumn} + modeColumns
    AppendTableToReportFile( columns, {{"Title", "TOD Factor Output File Totals"}})

    for i = 1 to periodNames.length do
        outRow = null
        for j = 1 to outModeNames.length do
            outRow =  outRow  + {outTotals[i][j] }
        end
        outRow = { periodNames[i] } + outRow
        AppendRowToReportFile(outRow,)
    end
    CloseReportFileSection()


    RunMacro("Close All")

    Return(1)
     
    	

EndMacro
