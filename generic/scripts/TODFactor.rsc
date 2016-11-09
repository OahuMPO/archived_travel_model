/**************************************************************
*  TODFactor.rsc
*
*  PB - jef 3/08
*  Modified 4/13 to work with tour-based model output
*
*  TransCAD Macro used to factor trip tables
*
*    Inputs:
*        Tour-based model outputs
*
*
*  residentAutoTrips_xx.mtx, where xx is period:
*
*    EA:  Early AM - 3 AM to 6 AM
*    AM:  AM Peak  - 6 AM to 9 AM
*    MD:  Midday   - 9 AM to 3 PM
*    PM:  PM Peak  - 3 PM to 7 PM
*    EV:  Evening  - 7 PM to 3 AM
*
*  visitorAutoTrips_xx.mtx, where xx is period (see above)
*
*        Airport Trip Files ( 4 tables each)
*            AIR_RES.MTX     Airport Resident trips
*            AIR_TOUR.MTX    Airport Visitor Tour trips
*            AIR_VIS.MTX     Airport Visitor Non-Tour trips
*
*        Truck Trip Files (1 table each)
*            DIST5G2.MTX     Trucks, Garage-based, 2 axle
*            DIST5G3.MTX     Trucks, Garage-based, 3 axle
*            DIST5G4.MTX     Trucks, Garage-based, 4 axle
*            DIST5N2.MTX     Trucks, Non-Garage-based, 2 axle
*            DIST5N3.MTX     Trucks, Non-Garage-based, 3 axle
*            DIST5N4.MTX     Trucks, Non-Garage-based, 4 axle
*            DIST5PO.MTX     Trucks, Port-based
*
*
***************************************************************/
Macro "TOD Factor" (scenarioDirectory, railPresent, iftoll)


    persFiles = {
            scenarioDirectory+"\\outputs\\residentAutoTrips_EA.MTX",
            scenarioDirectory+"\\outputs\\residentAutoTrips_AM.MTX",
            scenarioDirectory+"\\outputs\\residentAutoTrips_MD.MTX",
            scenarioDirectory+"\\outputs\\residentAutoTrips_PM.MTX",
            scenarioDirectory+"\\outputs\\residentAutoTrips_EV.MTX"
            }



    airpFiles = {
            scenarioDirectory+"\\outputs\\AIR_RES.MTX",     //  Airport Resident trips
            scenarioDirectory+"\\outputs\\AIR_TOUR.MTX",    //  Airport Visitor Tour trips
            scenarioDirectory+"\\outputs\\AIR_VIS.MTX" }    //  Airport Visitor Non-Tour trips

    trckFiles = {
            scenarioDirectory+"\\outputs\\DIST5G2.MTX",     //  Trucks, Garage-based, 2 axle
            scenarioDirectory+"\\outputs\\DIST5G3.MTX",     //  Trucks, Garage-based, 3 axle
            scenarioDirectory+"\\outputs\\DIST5G4.MTX",     //  Trucks, Garage-based, 4 axle
            scenarioDirectory+"\\outputs\\DIST5N2.MTX",     //  Trucks, Non-Garage-based, 2 axle
            scenarioDirectory+"\\outputs\\DIST5N3.MTX",     //  Trucks, Non-Garage-based, 3 axle
            scenarioDirectory+"\\outputs\\DIST5N4.MTX",     //  Trucks, Non-Garage-based, 4 axle
            scenarioDirectory+"\\outputs\\DIST5PO.MTX" }    //  Trucks, Port-based

    vistFiles = {
            scenarioDirectory+"\\outputs\\visitorAutoTrips_EA.MTX",
            scenarioDirectory+"\\outputs\\visitorAutoTrips_AM.MTX",
            scenarioDirectory+"\\outputs\\visitorAutoTrips_MD.MTX",
            scenarioDirectory+"\\outputs\\visitorAutoTrips_PM.MTX",
            scenarioDirectory+"\\outputs\\visitorAutoTrips_EV.MTX"
            }   //  Visitor trips

    periodNames = { "_EA",  // 3 AM - 6 AM
                    "_AM",  // 6 AM - 9 AM
                    "_MD",  // 9 AM - 3 PM
                    "_PM",  // 3 PM - 7 PM
                    "_EV"}  // 7 PM - 3 AM



/****************************************************************************************************************************************
            TRUCK TRIPS - USE NHB FACTOR
****************************************************************************************************************************************/
      //Purpose      Gar-2     Gar-3    Gar-4   NGar-2   NGar-3    NGar-4   Port
      //Abbrev        g2        g3       g4       n2       n3       n4      po
    perFactors ={ { {0.021,   0.021,   0.021,   0.021,   0.021,   0.021,    0.021} ,      // Trucks, Early AM
                    {0.060,   0.060,   0.060,   0.060,   0.060,   0.060,    0.060} ,      // Trucks, AM Peak
                    {0.485,   0.485,   0.485,   0.485,   0.485,   0.485,    0.485} ,      // Trucks, Midday
                    {0.270,   0.270,   0.270,   0.270,   0.270,   0.270,    0.270} ,      // Trucks, PM Peak
                    {0.165,   0.165,   0.165,   0.165,   0.165,   0.165,    0.165}  } }   // Trucks, Evening


    // assume symmetry in each period
    apFactors = { { { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, Early AM
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, AM Peak
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, Midday
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, PM Peak
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5}  } }   // Trucks, Evening

    modeIndex = {   1 }  // Trucks

    occFactors = { 1 } // Trucks

    outFile = scenarioDirectory+"\\outputs\\trck"

    ret_value = RunMacro("Factor OD",trckFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then goto quit


/****************************************************************************************************************************************
            AIRPORT TRIPS - USE NHB FACTORS
****************************************************************************************************************************************/
      //Purpose   Air-Res   Vis-onTour  Vis-noTour
      //Abbrev        ar      at       av
    perFactors ={ { {0.041,   0.041,    0.041} ,      // All Modes, Early AM
                    {0.174,   0.174,    0.174} ,      // All Modes, AM Peak
                    {0.343,   0.343,    0.343} ,      // All Modes, Midday
                    {0.275,   0.275,    0.275} ,      // All Modes, PM Peak
                    {0.168,   0.168,    0.168}  } }   // All Modes, Evening

    // assume symmetry in each period
    apFactors = { { { 0.5,    0.5,     0.5} ,      // All Modes, Early AM
                    { 0.5,    0.5,     0.5} ,      // All Modes, AM Peak
                    { 0.5,    0.5,     0.5} ,      // All Modes, Midday
                    { 0.5,    0.5,     0.5} ,      // All Modes, PM Peak
                    { 0.5,    0.5,     0.5}  } }   // All Modes, Evening

    modeIndex = {   1,    // Auto
                    1,    // Taxi
                    1,    // Public Bus
                    1,    // Shuttle
                    1,    // Tour Bus
                    1  }  // Fixed-Guideway

    // airport trips are factored both by occupancy and by number of trips
    occFactors = {  2*1/2.0,    // Auto
                    2*1/2.0,    // Taxi
                    1.0,        // Public bus
                    2*1/4.0,    // Shuttle
                    2*1/15.0,   // TourBus
                    1.0  }      // Fixed-Guideway

    outFile = scenarioDirectory+"\\outputs\\airp"

    ret_value = RunMacro("Factor OD",airpFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then goto quit



 collapse:
/***************************************************************************************************************************
   Collapse
****************************************************************************************************************************/

 /*
 *  Early AM
 */

   //First collapse tables for AM 3-hour highway assignment
   inFiles = {scenarioDirectory+"\\outputs\\residentAutoTrips_EA.mtx",
              scenarioDirectory+"\\outputs\\trck_EA.mtx",
              scenarioDirectory+"\\outputs\\visitorAutoTrips_EA.mtx",
              scenarioDirectory+"\\outputs\\airp_EA.mtx"}

   outFile = scenarioDirectory+"\\outputs\\auto_EA.mtx"

   description = "Early AM Hwy Tables"

   coreNames = {"SOV  - FREE", // 1
                "HOV2 - FREE", // 2
                "HOV3 - FREE", // 3
                "SOV  - PAY",  // 4
                "HOV2 - PAY",  // 5
                "HOV3 - PAY",  // 6
                "TRCK - FREE", // 7
                "TRCK - PAY"}  // 8


      //Person Cores -  DA-NT    DA-Toll   S2 NT   S2-Toll   S3NT    S3Toll
      //Truck Cores  -  All
      //Visit Cores  -  DA-NT    DA-Toll   S2 NT   S2-Toll   S3NT    S3Toll   TOURBUS  TAXI
      //Airpt Cores  -  Auto     Taxi     P.Bus  Shuttle  TourBus   FIXGDWY

     tableArray = {{      1,       4,       2,       5,       3,       6,       0,       0,       0,       0,       0,       0},  //Person trips
                   {      7,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0},  //Truck trips
                   {      1,       4,       2,       5,       3,       6,       0,       0,       0,       0,       0,       0},  //Visitor trips
                   {      1,       1,       0,       1,       1,       0,       0,       0,       0,       0,       0,       0}}  //Airport trips


    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse AM Peak
   inFiles = {scenarioDirectory+"\\outputs\\residentAutoTrips_AM.mtx",
              scenarioDirectory+"\\outputs\\trck_AM.mtx",
              scenarioDirectory+"\\outputs\\visitorAutoTrips_AM.mtx",
              scenarioDirectory+"\\outputs\\airp_AM.mtx"}

   outFile = scenarioDirectory+"\\outputs\\auto_AM.mtx"

   description = "AM Peak Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse midday tables
  inFiles = {scenarioDirectory+"\\outputs\\residentAutoTrips_MD.mtx",
              scenarioDirectory+"\\outputs\\trck_MD.mtx",
              scenarioDirectory+"\\outputs\\visitorAutoTrips_MD.mtx",
              scenarioDirectory+"\\outputs\\airp_MD.mtx"}

   outFile = scenarioDirectory+"\\outputs\\auto_MD.mtx"

   description = "Midday Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse PM peak tables
  inFiles = {scenarioDirectory+"\\outputs\\residentAutoTrips_PM.mtx",
              scenarioDirectory+"\\outputs\\trck_PM.mtx",
              scenarioDirectory+"\\outputs\\visitorAutoTrips_PM.mtx",
              scenarioDirectory+"\\outputs\\airp_PM.mtx"}

   outFile = scenarioDirectory+"\\outputs\\auto_PM.mtx"

   description = "PM Peak Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse EV tables
  inFiles = {scenarioDirectory+"\\outputs\\residentAutoTrips_EV.mtx",
              scenarioDirectory+"\\outputs\\trck_EV.mtx",
              scenarioDirectory+"\\outputs\\visitorAutoTrips_EV.mtx",
              scenarioDirectory+"\\outputs\\airp_EV.mtx"}

   outFile = scenarioDirectory+"\\outputs\\auto_EV.mtx"

   description = "Evening auto tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

     // **********************************************************************************************************************
    //Now collapse early AM, midday and night tables into off-peak 17 hour table
    inFiles = {scenarioDirectory+"\\outputs\\auto_EA.mtx",
    					 scenarioDirectory+"\\outputs\\auto_MD.mtx",
               scenarioDirectory+"\\outputs\\auto_EV.mtx"}

    outFile = scenarioDirectory+"\\outputs\\auto_Offpeak.mtx"

    description = "Offpeak Hwy Tables"

    tableArray = {{      1,       2,       3,       4,       5,       6,       7,       8},  //Early AM
                  {      1,       2,       3,       4,       5,       6,       7,       8},  //Midday
                  {      1,       2,       3,       4,       5,       6,       7,       8}}  //Evening

    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse Early AM transit tables
   inFiles = {scenarioDirectory+"\\outputs\\residentTranTrips_EA.mtx",
              scenarioDirectory+"\\outputs\\visitorTranTrips_EA.mtx",
              scenarioDirectory+"\\outputs\\airp_EA.mtx"}

   outFile = scenarioDirectory+"\\outputs\\transit_EA.mtx"

   description = "Early AM Transit Tables"

   coreNames = {"WLK-LOC",  // 1
                "WLK-EXP",  // 2
                "WLK-GDWY", // 3
                "KNR",      // 4
                "PNR-INF",  // 5
                "PNR-FML"   // 6
                }

		     //Person Cores -  Wlk-Loc  Wlk-Exp  Wlk-Gdwy KNR     PNR-Inf  PNR-Fml
		     //Visit Cores  -  Wlk-Loc  Wlk-Exp  Wlk-Gdwy KNR     PNR-Inf  PNR-Fml
		     //Airpt Cores  -  Auto     Taxi     P.Bus  Shuttle  TourBus   FIXGDWY
		   tableArray = {{      1,       2,       3,       4,       5,       6,       0,       0,       0,       0,       0,       0}, //Person trips
		                 {      1,       2,       3,       4,       5,       6,       0,       0,       0,       0,       0,       0}, //Visitor trips
                     {      0,       0,       2,       0,       0,       3,       0,       0,       0,       0,       0,       0}} //Airport trips


    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse AM Peak transit tables
    inFiles = {scenarioDirectory+"\\outputs\\residentTranTrips_AM.mtx",
              scenarioDirectory+"\\outputs\\visitorTranTrips_AM.mtx",
              scenarioDirectory+"\\outputs\\airp_AM.mtx"}

   outFile = scenarioDirectory+"\\outputs\\transit_AM.mtx"

   description = "AM Peak Transit Tables"


   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

    // **********************************************************************************************************************
    //Now collapse Midday transit tables
    inFiles = {scenarioDirectory+"\\outputs\\residentTranTrips_MD.mtx",
              scenarioDirectory+"\\outputs\\visitorTranTrips_MD.mtx",
              scenarioDirectory+"\\outputs\\airp_MD.mtx"}

   outFile = scenarioDirectory+"\\outputs\\transit_MD.mtx"

   description = "Midday Transit Tables"


   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

   // **********************************************************************************************************************
    //Now collapse PM Peak transit tables
    inFiles = {scenarioDirectory+"\\outputs\\residentTranTrips_PM.mtx",
              scenarioDirectory+"\\outputs\\visitorTranTrips_PM.mtx",
              scenarioDirectory+"\\outputs\\airp_PM.mtx"}

   outFile = scenarioDirectory+"\\outputs\\transit_PM.mtx"

   description = "PM Peak Transit Tables"


   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit


   // **********************************************************************************************************************
    //Now collapse Evening transit tables
    inFiles = {scenarioDirectory+"\\outputs\\residentTranTrips_EV.mtx",
              scenarioDirectory+"\\outputs\\visitorTranTrips_EV.mtx",
              scenarioDirectory+"\\outputs\\airp_EV.mtx"}

   outFile = scenarioDirectory+"\\outputs\\transit_EV.mtx"

   description = "Evening Transit Tables"


   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then goto quit

  // **********************************************************************************************************************


    Return(1)

    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

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

    inMat = null
    inMat_T = null
    inTrips = null
    inTripsT = null

   // delete the transposed matrices
   for i = 1 to inFiles.length do
        //inMat[i] = OpenMatrix(inFiles[i],)
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
     quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
