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
*            MODE5WW.MTX     JTW: Work-Based
*            MODE5WN.MTX     JTW: Non-Work-Based
*            MODE5AW.MTX     JAW: Work-Based
*            MODE5AN.MTX     JAW: Non-Work-Based
*            MODE5NK.MTX     Home-Based K-12
*            MODE5NC.MTX     Home-Based College
*            MODE5NS.MTX     Home-Based Shop
*            MODE5NO.MTX     Home-Based Other
*            MODE5NN.MTX     Non-Home-Based
*
*        Airport Trip Files ( 4 tables each)
*            MODE5AR.MTX     Airport Resident trips
*            MODE5AT.MTX     Airport Visitor Tour trips
*            MODE5AV.MTX     Airport Visitor Non-Tour trips
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
*       Visitor Trip File   (7 tables)
*           VIST5TRP.MTX    Visitor trips
*
*       Observed Visitor Trip file (1 table)
*           VISOBS.MTX      Observed Visitor Transit Trips
*
***************************************************************/
Macro "TOD Factor" (scenarioDirectory)

    persFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH.MTX",     //  JTW: Home - Work
            scenarioDirectory+"\\outputs\\MODE5WO.MTX",     //  JTW: Home - Other
            scenarioDirectory+"\\outputs\\MODE5WW.MTX",     //  JTW: Work-Based
            scenarioDirectory+"\\outputs\\MODE5WN.MTX",     //  JTW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5AW.MTX",     //  JAW: Work-Based
            scenarioDirectory+"\\outputs\\MODE5AN.MTX",     //  JAW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5NK.MTX",     //  Home-Based K-12
            scenarioDirectory+"\\outputs\\MODE5NC.MTX",     //  Home-Based College
            scenarioDirectory+"\\outputs\\MODE5NS.MTX",     //  Home-Based Shop
            scenarioDirectory+"\\outputs\\MODE5NO.MTX",     //  Home-Based Other
            scenarioDirectory+"\\outputs\\MODE5NN.MTX" }    //  Non-Home-Based

    airpFiles = {
            scenarioDirectory+"\\outputs\\MODE5AR.MTX",     //  Airport Resident trips
            scenarioDirectory+"\\outputs\\MODE5AT.MTX",     //  Airport Visitor Tour trips
            scenarioDirectory+"\\outputs\\MODE5AV.MTX" }    //  Airport Visitor Non-Tour trips

    trckFiles = {
            scenarioDirectory+"\\outputs\\DIST5G2.MTX",     //  Trucks, Garage-based, 2 axle
            scenarioDirectory+"\\outputs\\DIST5G3.MTX",     //  Trucks, Garage-based, 3 axle
            scenarioDirectory+"\\outputs\\DIST5G4.MTX",     //  Trucks, Garage-based, 4 axle
            scenarioDirectory+"\\outputs\\DIST5N2.MTX",     //  Trucks, Non-Garage-based, 2 axle
            scenarioDirectory+"\\outputs\\DIST5N3.MTX",     //  Trucks, Non-Garage-based, 3 axle
            scenarioDirectory+"\\outputs\\DIST5N4.MTX",     //  Trucks, Non-Garage-based, 4 axle
            scenarioDirectory+"\\outputs\\DIST5PO.MTX" }    //  Trucks, Port-based

    vistFiles = {
            scenarioDirectory+"\\outputs\\VIST5TRP.MTX" }   //  Visitor trips

    periodNames = { "AMPeak",  // 6 AM - 8 AM
                    "AMShld",  // 5 AM - 6 AM AND 8 AM - 9 AM
                    "Midday",  // 9 AM - 2 PM
                    "PMPeak",  // 3 PM - 5 PM
                    "PMShld",  // 2 PM - 3 PM AND 5 PM - 6 PM
                    "Night"}   // 6 PM - 5 AM

/****************************************************************************************************************************************
            TRUCK TRIPS - USE NHB FACTOR
****************************************************************************************************************************************/
      //Purpose      Gar-2     Gar-3    Gar-4   NGar-2   NGar-3    NGar-4   Port
      //Abbrev        g2        g3       g4       n2       n3       n4      po
    perFactors ={ { {0.051,   0.051,   0.051,   0.051,   0.051,   0.051,    0.051} ,      // Trucks, AM Peak
                    {0.069,   0.069,   0.069,   0.069,   0.069,   0.069,    0.069} ,      // Trucks, AM Shoulder
                    {0.566,   0.566,   0.566,   0.566,   0.566,   0.566,    0.566} ,      // Trucks, Midday
                    {0.115,   0.115,   0.115,   0.115,   0.115,   0.115,    0.115} ,      // Trucks, PM Peak
                    {0.108,   0.108,   0.108,   0.108,   0.108,   0.108,    0.108} ,      // Trucks, PM Shoulder
                    {0.091,   0.091,   0.091,   0.091,   0.091,   0.091,    0.091}  } }   // Trucks, Night

    // assume symmetry in each period
    apFactors = { { { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, AM Peak
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, AM Shoulder
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, Midday
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, PM Peak
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5} ,      // Trucks, PM Shoulder
                    { 0.5,    0.5,    0.5,    0.5,    0.5,    0.5,     0.5}  } }   // Trucks, Night

    modeIndex = {   1 }  // Trucks

    occFactors = { 1 } // Trucks

    outFile = scenarioDirectory+"\\outputs\\trck"

    ret_value = RunMacro("Factor OD",trckFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()


/****************************************************************************************************************************************
            VISITOR TRIPS - USE NHB FACTOR
****************************************************************************************************************************************/
      //Purpose    Visitors
    perFactors ={ { {0.122} ,                        // Auto, AM Peak
                    {0.085} ,                        // Auto, AM Shoulder
                    {0.287} ,                        // Auto, Midday
                    {0.133} ,                        // Auto, PM Peak
                    {0.139} ,                        // Auto, PM Shoulder
                    {0.234}  },                      // Auto, Night

                  { {0.122} ,                        // Transit, AM Peak
                    {0.085} ,                        // Transit, AM Shoulder
                    {0.287} ,                        // Transit, Midday
                    {0.133} ,                        // Transit, PM Peak
                    {0.139} ,                        // Transit, PM Shoulder
                    {0.234}  } }                     // Transit, Night

    apFactors = { { { 0.204} ,                        // Auto, AM Peak
                    { 0.204} ,                        // Auto, AM Shoulder
                    { 0.363} ,                        // Auto, Midday
                    { 0.488} ,                        // Auto, PM Peak
                    { 0.488} ,                        // Auto, PM Shoulder
                    { 0.061}  },                      // Auto, Night

                  { { 0.204} ,                        // Transit, AM Peak
                    { 0.204} ,                        // Transit, AM Shoulder
                    { 0.363} ,                        // Transit, Midday
                    { 0.488} ,                        // Transit, PM Peak
                    { 0.488} ,                        // Transit, PM Shoulder
                    { 0.061}  } }                     // Transit, Night

    modeIndex = { 1,      // AUTO
                  2,      // BUS
                  2,      // GDWY
                  1,      // TAXI
                  1,      // TOUR
                  1,      // WALK
                  1}      // TOTL

    occFactors ={ 1/2.0,    // AUTO
                  1,        // BUS
                  1,        // GDWY
                  1/2.0,    // TAXI
                  1/15.0,   // TOUR
                  1,        // WALK
                  1}        // TOTL

    outFile = scenarioDirectory+"\\outputs\\vist"

    ret_value = RunMacro("Factor OD",vistFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()

/****************************************************************************************************************************************
            FIXED VISITOR TRIPS - USE NHB FACTOR
****************************************************************************************************************************************/
      //Purpose    Visitors
    perFactors ={ { {0.122} ,                        // Transit, AM Peak
                    {0.085} ,                        // Transit, AM Shoulder
                    {0.287} ,                        // Transit, Midday
                    {0.133} ,                        // Transit, PM Peak
                    {0.139} ,                        // Transit, PM Shoulder
                    {0.234}  } }                     // Transit, Night

    apFactors = { { { 0.204} ,                        // Transit, AM Peak
                    { 0.204} ,                        // Transit, AM Shoulder
                    { 0.363} ,                        // Transit, Midday
                    { 0.488} ,                        // Transit, PM Peak
                    { 0.488} ,                        // Transit, PM Shoulder
                    { 0.061}  } }                     // Transit, Night

    modeIndex = { 1 }     // TRANSIT

    occFactors ={ 1 }     // TRAMSIT

    outFile = scenarioDirectory+"\\outputs\\visobs"

    ret_value = RunMacro("Factor OD",{scenarioDirectory+"\\inputs\\other\\visobs.mtx"},outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()

/****************************************************************************************************************************************
            AIRPORT TRIPS - USE NHB FACTORS
****************************************************************************************************************************************/
      //Purpose   Air-Res   Vis-onTour  Vis-noTour
      //Abbrev        ar      at       av
    perFactors ={ { {0.051,   0.051,    0.051} ,      // All Modes, AM Peak
                    {0.069,   0.069,    0.069} ,      // All Modes, AM Shoulder
                    {0.566,   0.566,    0.566} ,      // All Modes, Midday
                    {0.115,   0.115,    0.115} ,      // All Modes, PM Peak
                    {0.108,   0.108,    0.108} ,      // All Modes, PM Shoulder
                    {0.091,   0.091,    0.091}  } }   // All Modes, Night

    // assume symmetry in each period
    apFactors = { { { 0.5,    0.5,     0.5} ,      // All Modes, AM Peak
                    { 0.5,    0.5,     0.5} ,      // All Modes, AM Shoulder
                    { 0.5,    0.5,     0.5} ,      // All Modes, Midday
                    { 0.5,    0.5,     0.5} ,      // All Modes, PM Peak
                    { 0.5,    0.5,     0.5} ,      // All Modes, PM Shoulder
                    { 0.5,    0.5,     0.5}  } }   // All Modes, Night

    modeIndex = {   1,    // Auto
                    1,    // Taxi
                    1,    // Shuttle
                    1  }  // TourBus

    // airport trips are factored both by occupancy and by number of trips
    occFactors = {  2*1/2.0,    // Auto
                    2*1/2.0,    // Taxi
                    2*1/4.0,    // Shuttle
                    2*1/15.0  }  // TourBus

    outFile = scenarioDirectory+"\\outputs\\airp"

    ret_value = RunMacro("Factor OD",airpFiles,outFile,perFactors,apFactors,occFactors,modeIndex,periodNames)
    if !ret_value then Throw()

/****************************************************************************************************************************************
            PERSON TRIPS
****************************************************************************************************************************************/

        //Purpose    JTW-HBW  JTW-HBNW   JTW-WB    JTW-NB    JAW-WB    JAW-NB    HBSch    HBCol    HBShp     HBOth       NHB
        //Abbrev       wh       wo         ww        wn        aw        an        nk        nc        ns        no       nn
    perFactors ={ { {0.280,    0.106,    0.246,    0.090,    0.052,    0.000,    0.320,    0.161,    0.038,    0.122,    0.051},         // SOV, AM Peak
                    {0.133,    0.079,    0.095,    0.063,    0.060,    0.020,    0.113,    0.131,    0.055,    0.085,    0.069},         // SOV, AM Shoulder
                    {0.104,    0.119,    0.121,    0.213,    0.610,    0.739,    0.108,    0.382,    0.460,    0.286,    0.566},         // SOV, Midday
                    {0.188,    0.173,    0.280,    0.206,    0.122,    0.077,    0.075,    0.085,    0.140,    0.133,    0.115},         // SOV, PM Peak
                    {0.132,    0.170,    0.165,    0.212,    0.118,    0.164,    0.170,    0.106,    0.127,    0.140,    0.108},         // SOV, PM Shoulder
                    {0.163,    0.353,    0.093,    0.216,    0.038,    0.000,    0.214,    0.135,    0.180,    0.234,    0.091}   },     // SOV, Night

                  { {0.295,    0.379,    0.205,    0.201,    0.029,    0.096,    0.591,    0.233,    0.015,    0.139,    0.072},         // HOV, AM Peak
                    {0.137,    0.067,    0.070,    0.041,    0.052,    0.000,    0.052,    0.123,    0.022,    0.059,    0.038},         // HOV, AM Shoulder
                    {0.066,    0.052,    0.138,    0.098,    0.671,    0.712,    0.036,    0.298,    0.356,    0.210,    0.321},         // HOV, Midday
                    {0.192,    0.137,    0.282,    0.247,    0.132,    0.111,    0.106,    0.125,    0.134,    0.147,    0.215},         // HOV, PM Peak
                    {0.124,    0.170,    0.174,    0.188,    0.093,    0.055,    0.199,    0.175,    0.173,    0.173,    0.187},         // HOV, PM Shoulder
                    {0.186,    0.196,    0.131,    0.225,    0.023,    0.026,    0.016,    0.046,    0.300,    0.272,    0.167}  },      // HOV, Night

                  { {0.332,    0.087,    0.230,    0.000,    0.183,    0.000,    0.559,    0.238,    0.036,    0.088,    0.078},         // Walk-Transit, AM Peak
                    {0.127,    0.107,    0.012,    0.000,    0.000,    0.000,    0.041,    0.096,    0.065,    0.084,    0.119},         // Walk-Transit, AM Shoulder
                    {0.117,    0.274,    0.109,    0.771,    0.632,    0.000,    0.026,    0.212,    0.597,    0.401,    0.480},         // Walk-Transit, Midday,
                    {0.201,    0.277,    0.301,    0.037,    0.119,    0.000,    0.112,    0.183,    0.117,    0.126,    0.151},         // Walk-Transit, PM Peak,
                    {0.121,    0.132,    0.265,    0.050,    0.066,    0.000,    0.261,    0.159,    0.145,    0.181,    0.150},         // Walk-Transit, PM Shoulder
                    {0.102,    0.124,    0.083,    0.142,    0.000,    0.000,    0.001,    0.112,    0.040,    0.120,    0.022}  },      // Walk-Transit, Night,

                  { {0.332,    0.087,    0.230,    0.000,    0.183,    0.000,    0.559,    0.238,    0.036,    0.088,    0.078},         // Drive-Transit, AM Peak
                    {0.127,    0.107,    0.012,    0.000,    0.000,    0.000,    0.041,    0.096,    0.065,    0.084,    0.119},         // Drive-Transit, AM Shoulder
                    {0.117,    0.274,    0.109,    0.771,    0.632,    0.000,    0.026,    0.212,    0.597,    0.401,    0.480},         // Drive-Transit, Midday,
                    {0.201,    0.277,    0.301,    0.037,    0.119,    0.000,    0.112,    0.183,    0.117,    0.126,    0.151},         // Drive-Transit, PM Peak,
                    {0.121,    0.132,    0.265,    0.050,    0.066,    0.000,    0.261,    0.159,    0.145,    0.181,    0.150},         // Drive-Transit, PM Shoulder
                    {0.102,    0.124,    0.083,    0.142,    0.000,    0.000,    0.001,    0.112,    0.040,    0.120,    0.022}  } }     // Drive-Transit, Night,

    apFactors ={ {  {0.028,   0.003,    0.014,    0.000,    0.492,    0.000,    0.002,    0.005,    0.135,    0.204,    0.000},         // SOV, AM Peak
                    {0.039,   0.018,    0.048,    0.000,    0.578,    0.000,    0.016,    0.033,    0.208,    0.277,    0.000},         // SOV, AM Shoulder
                    {0.325,   0.453,    0.492,    0.000,    0.538,    0.000,    0.657,    0.397,    0.530,    0.363,    0.000},         // SOV, Midday
                    {0.885,   0.897,    0.921,    0.000,    0.767,    0.000,    0.845,    0.633,    0.634,    0.488,    0.000},         // SOV, PM Peak
                    {0.836,   0.919,    0.876,    0.000,    0.741,    0.000,    0.795,    0.848,    0.634,    0.522,    0.000},         // SOV, PM Shoulder
                    {0.748,   0.935,    0.814,    0.000,    0.710,    0.000,    0.758,    0.849,    0.621,    0.610,    0.000}  },      // SOV, Night

                  { {0.028,   0.003,    0.014,    0.000,    0.492,    0.000,    0.002,    0.005,    0.135,    0.204,    0.000},         // HOV, AM Peak
                    {0.039,   0.018,    0.048,    0.000,    0.578,    0.000,    0.016,    0.033,    0.208,    0.277,    0.000},         // HOV, AM Shoulder
                    {0.325,   0.453,    0.492,    0.000,    0.538,    0.000,    0.657,    0.397,    0.530,    0.363,    0.000},         // HOV, Midday
                    {0.885,   0.897,    0.921,    0.000,    0.767,    0.000,    0.845,    0.633,    0.634,    0.488,    0.000},         // HOV, PM Peak
                    {0.836,   0.919,    0.876,    0.000,    0.741,    0.000,    0.795,    0.848,    0.634,    0.522,    0.000},         // HOV, PM Shoulder
                    {0.748,   0.935,    0.814,    0.000,    0.710,    0.000,    0.758,    0.849,    0.621,    0.610,    0.000}  },      // HOV, Night

                  { {0.028,   0.003,    0.014,    0.000,    0.492,    0.000,    0.002,    0.005,    0.135,    0.204,    0.000},         // Walk-Transit, AM Peak
                    {0.039,   0.018,    0.048,    0.000,    0.578,    0.000,    0.016,    0.033,    0.208,    0.277,    0.000},         // Walk-Transit, AM Shoulder
                    {0.325,   0.453,    0.492,    0.000,    0.538,    0.000,    0.657,    0.397,    0.530,    0.363,    0.000},         // Walk-Transit, Midday
                    {0.885,   0.897,    0.921,    0.000,    0.767,    0.000,    0.845,    0.633,    0.634,    0.488,    0.000},         // Walk-Transit, PM Peak
                    {0.836,   0.919,    0.876,    0.000,    0.741,    0.000,    0.795,    0.848,    0.634,    0.522,    0.000},         // Walk-Transit, PM Shoulder
                    {0.748,   0.935,    0.814,    0.000,    0.710,    0.000,    0.758,    0.849,    0.621,    0.610,    0.000}  },      // Walk-Transit, Night

                  { {0.000,   0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, AM Peak
                    {0.000,   0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, AM Shoulder
                    {0.000,   0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,    0.000,},         // Drive-Transit, Midday
                    {1.000,   1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,},         // Drive-Transit, PM Peak
                    {1.000,   1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,},         // Drive-Transit, PM Shoulder
                    {1.000,   1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,    1.000,}  }  }    // Drive-Transit, Night

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

 collapse:
/***************************************************************************************************************************
   Collapse
****************************************************************************************************************************/

    // **********************************************************************************************************************
   //First collapse tables for AM 2-hour highway assignment
   inFiles = {scenarioDirectory+"\\outputs\\persAMPeak.mtx",
              scenarioDirectory+"\\outputs\\trckAMPeak.mtx",
              scenarioDirectory+"\\outputs\\vistAMPeak.mtx",
              scenarioDirectory+"\\outputs\\airpAMPeak.mtx"}

   outFile = scenarioDirectory+"\\outputs\\hwyAMPeak.mtx"

   description = "AM2Hour Hwy Tables"

   coreNames = {"SOV  - FREE", // 1
                "HOV2 - FREE", // 2
                "HOV3 - FREE", // 3
                "SOV  - PAY",  // 4
                "HOV2 - PAY",  // 5
                "HOV3 - PAY",  // 6
                "TRCK - FREE",  // 7
                "TRCK - PAY"}  // 8

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    //Truck Cores  -  All
    //Visit Cores  -  AUTO     BUS      GDWY     TAXI     TOUR     WALK     TOTL
    //Airpt Cores  -  Auto     Taxi     Shuttle  TourBus

   tableArray = {{      1,       2,       3,       0,       0,       0,       0,       0,       0,       0,       0,       0},  //Person trips
                 {      7,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0},  //Truck trips
                 {      1,       0,       0,       1,       1,       0,       0,       0,       0,       0,       0,       0},  //Visitor trips
                 {      1,       1,       1,       1,       0,       0,       0,       0,       0,       0,       0,       0}}  //Airport trips

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse AM shoulder tables
   inFiles = {scenarioDirectory+"\\outputs\\persAMShld.mtx",
              scenarioDirectory+"\\outputs\\trckAMShld.mtx",
              scenarioDirectory+"\\outputs\\vistAMShld.mtx",
              scenarioDirectory+"\\outputs\\airpAMShld.mtx"}

   outFile = scenarioDirectory+"\\outputs\\hwyAMShld.mtx"

   description = "AMShld Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse midday tables
   inFiles = {scenarioDirectory+"\\outputs\\persMidday.mtx",
              scenarioDirectory+"\\outputs\\trckMidday.mtx",
              scenarioDirectory+"\\outputs\\vistMidday.mtx",
              scenarioDirectory+"\\outputs\\airpMidday.mtx"}

   outFile = scenarioDirectory+"\\outputs\\hwyMidday.mtx"

   description = "Midday Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse PM 2-Hour tables
   inFiles = {scenarioDirectory+"\\outputs\\persPMPeak.mtx",
              scenarioDirectory+"\\outputs\\trckPMPeak.mtx",
              scenarioDirectory+"\\outputs\\vistPMPeak.mtx",
              scenarioDirectory+"\\outputs\\airpPMPeak.mtx"}

   outFile = scenarioDirectory+"\\outputs\\hwyPMPeak.mtx"

   description = "PM Peak Hwy Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse PM Shoulder tables
   inFiles = {scenarioDirectory+"\\outputs\\persPMShld.mtx",
              scenarioDirectory+"\\outputs\\trckPMShld.mtx",
              scenarioDirectory+"\\outputs\\vistPMShld.mtx",
              scenarioDirectory+"\\outputs\\airpPMShld.mtx"}

   outFile = scenarioDirectory+"\\outputs\\hwyPMShld.mtx"

   description = "PM Shoulder Tables"

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse night tables
    inFiles = {scenarioDirectory+"\\outputs\\persNight.mtx",
              scenarioDirectory+"\\outputs\\trckNight.mtx",
              scenarioDirectory+"\\outputs\\vistNight.mtx",
              scenarioDirectory+"\\outputs\\airpNight.mtx"}

    outFile = scenarioDirectory+"\\outputs\\hwyNight.mtx"

    description = "Night Hwy Tables"

    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse midday and night tables into off-peak 16 hour table
    inFiles = {scenarioDirectory+"\\outputs\\hwyMidday.mtx",
              scenarioDirectory+"\\outputs\\hwyNight.mtx"}

    outFile = scenarioDirectory+"\\outputs\\hwyOffpeak.mtx"

    description = "Offpeak Hwy Tables"

    tableArray = {{      1,       2,       3,       4,       5,       6,       7,       8},  //Midday
                  {      1,       2,       3,       4,       5,       6,       7,       8}}  //Night

    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse AM Peak and AM Shoulder tables into AM Peak 4 hour table
    inFiles = {scenarioDirectory+"\\outputs\\hwyAMPeak.mtx",
              scenarioDirectory+"\\outputs\\hwyAMShld.mtx"}

    outFile = scenarioDirectory+"\\outputs\\hwyAM4Hour.mtx"

    description = "AM Peak Hwy Tables"

    tableArray = {{      1,       2,       3,       4,       5,       6,       7,       8},  //AM 2 Hour
                  {      1,       2,       3,       4,       5,       6,       7,       8}}  //AM Shoulder

    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

   // **********************************************************************************************************************
    //Now collapse PM Peak and PM Shoulder tables into PM Peak 4 hour table
    inFiles = {scenarioDirectory+"\\outputs\\hwyPMPeak.mtx",
               scenarioDirectory+"\\outputs\\hwyPMShld.mtx"}

    outFile = scenarioDirectory+"\\outputs\\hwyPM4Hour.mtx"

    description = "PM Peak Hwy Tables"

    tableArray = {{      1,       2,       3,       4,       5,       6,       7,       8},  //PM 2 Hour
                  {      1,       2,       3,       4,       5,       6,       7,       8}}  //PM Shoulder

    ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()


    // **********************************************************************************************************************
    //Now collapse AM Peak transit tables
   inFiles = {scenarioDirectory+"\\outputs\\persAMPeak.mtx",
              scenarioDirectory+"\\outputs\\vistAMPeak.mtx",
              scenarioDirectory+"\\outputs\\visobsAMPeak.mtx"}

   outFile = scenarioDirectory+"\\outputs\\trnAMPeak.mtx"

   description = "AMPeak Transit Tables"

   coreNames = {"WLK-EXP",  // 1
                "WLK-LOC",  // 2
                "WLK-GDWY", // 3
                "PNR-FRM",  // 4
                "PNR-INF",  // 5
                "KNR" }     // 6

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    //Visit Cores  -  AUTO     BUS      GDWY     TAXI     TOUR     WALK     TOTL
    //Visit Obs  -    TRN
   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Person trips
                 {      0,       1,       3,       0,       0,       0,       0,       0,       0,       0,       0,       0}, //Visitor trips
                 {      1,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0}} //Observed visitor transit trips

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse peak transit tables
   inFiles = {
            scenarioDirectory+"\\outputs\\MODE5WH.MTX",     //  JTW: Home - Work
            scenarioDirectory+"\\outputs\\MODE5WO.MTX",     //  JTW: Home - Other
            scenarioDirectory+"\\outputs\\MODE5WW.MTX",     //  JTW: Work-Based
            scenarioDirectory+"\\outputs\\MODE5WN.MTX",     //  JTW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5NK.MTX",     //  Home-Based K-12
            scenarioDirectory+"\\outputs\\MODE5NC.MTX"}     //  Home-Based College

   outFile = scenarioDirectory+"\\outputs\\trnPeak.mtx"

   description = "Peak Period Transit Tables"

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Work
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Home - Other
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Work-Based
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JTW: Non-Work-Based
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based K-12
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}} //Home-Based College

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

    // **********************************************************************************************************************
    //Now collapse off-peak transit tables
   inFiles = {
            scenarioDirectory+"\\outputs\\MODE5AW.MTX",     //  JAW: Work-Based
            scenarioDirectory+"\\outputs\\MODE5AN.MTX",     //  JAW: Non-Work-Based
            scenarioDirectory+"\\outputs\\MODE5NS.MTX",     //  Home-Based Shop
            scenarioDirectory+"\\outputs\\MODE5NO.MTX",     //  Home-Based Other
            scenarioDirectory+"\\outputs\\MODE5NN.MTX",     //  Non-Home-Based
            scenarioDirectory+"\\outputs\\VIST5TRP.MTX",    //  Visitor trips
            scenarioDirectory+"\\inputs\\other\\VISOBS.MTX"}      //  Observed Visitor transit trips

   outFile = scenarioDirectory+"\\outputs\\trnOffPeak.mtx"

   description = "Off-Peak Period Transit Tables"

   coreNames = {"WLK-EXP",  // 1
                "WLK-LOC",  // 2
                "WLK-GDWY", // 3
                "PNR-FRM",  // 4
                "PNR-INF",  // 5
                "KNR" }     // 6

    //Person Cores -  DA       S2       S3+      Wlk-Exp  Wlk-Loc  Wlk-Gdwy PNR      KNR     Walk     Bike     PNR-Frm  PNR-Inf
    //Visit Cores  -  AUTO     BUS      GDWY     TAXI     TOUR     WALK     TOTL
    //Obs Visit Cores- TRN

   tableArray = {{      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JAW: Work-Based
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //JAW: Non-Work-Based
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based Shop
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Home-Based Other
                 {      0,       0,       0,       1,       2,       3,       0,       6,       0,       0,       4,       5}, //Non-Home-Based
                 {      0,       1,       3,       0,       0,       0,       0,       0,       0,       0,       0,       0}, //Visitor trips
                 {      1,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0,       0}} //Observed visitor transit trips

   ret_value = RunMacro("Collapse Matrices",inFiles, tableArray, outFile, coreNames, description)
    if !ret_value then Throw()

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
     quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
/***********************************************************************************************************************************
*
* Collapse Matrices
* Macro collapses trip tables in multiple files according to an array.
*
* Arguments:
*   inFiles             Array of input file names.  Each file does not have to have the same number of matrix cores,
*                       but there cannot be an entry in the tableArray for a non-existant core (it must be 0).
*   tableArray          A 2-dimensional table, dimensioned by inFiles and maximum number of matrix cores across all input files.
*                       The entry in the table corresponds to the number of the core in the output file that the core in the input
*                       file should be added to.
*   outFile             Path/name of output file.
*   coreNames           Array of core names for output file; should be dimensioned accordingly.
*   description         Description for output file.
*
***********************************************************************************************************************************/
Macro "Collapse Matrices" (inFiles, tableArray, outFile, coreNames, description)

    //if input files not equal to table array dimension 1 length, error
    if (inFiles.length != tableArray.length) then do
    	MessageBox("Error in Collapse Matrix, inFiles not equal to tableArray for "+description, )
    	Return(0)
    end

    //open the input matrices and matrix currencies
    dim inMat[inFiles.length]
    dim inCur[inFiles.length]
    dim cNames[inFiles.length]
    for i = 1 to inFiles.length do
        inMat[i]  = OpenMatrix(inFiles[i],)
        inCur[i]  = CreateMatrixCurrencies(inMat[i], , ,)
        cNames[i]= GetMatrixCoreNames(inMat[i])
    end

    maxTable = 0

    //determine number of tables in outFile
    for i= 1 to tableArray.length do
        for j = 1 to tableArray[i].length do
            maxTable = Max(tableArray[i][j], maxTable)
        end
    end

    // if coreNames isn't dimensioned by maxTable, error
    if (coreNames.length < maxTable) then do
    	MessageBox("Error in Collapse Matrix, file names not given for all cores specified in tableArray for "+description, )
    	Return(0)
    end

    // create the output table
    Opts = null
    Opts.[File Name] = outFile
    Opts.Label = description
    Opts.Type = "Float"
    Opts.Tables = coreNames
    Opts.[Column Major] = "No"
    Opts.[File Based] = "Yes"
    Opts.Compression = True

    rowLabels = GetMatrixRowLabels(inCur[1].(cNames[1][1]))
    zones = rowLabels.length
    outMat = CreateMatrixFromScratch(description, zones, zones, Opts)
    outCur = CreateMatrixCurrencies(outMat, , ,)

    //initialize all matrices to 0
    for i = 1 to outCur.length do
        outCore = outCur.(coreNames[i])
        outCore := 0
    end

    // iterate through the tableArray and collapse
    for i= 1 to tableArray.length do
        for j = 1 to tableArray[i].length do

            outTable = tableArray[i][j]

            //if the outTable isn't 0, add the input table to the output table
            if(outTable !=0) then do
                inCore = inCur[i].(cNames[i][j])
                outCore = outCur.(coreNames[outTable])
                outCore := outCore + inCore
            end
        end
    end

    // Sum the output tables in the output file and report
    dim outTotals[coreNames.length]
    stat_array = MatrixStatistics(outMat,)
    for j = 1 to coreNames.length do
        outTotals[j] = stat_array.(coreNames[j]).Sum
    end

    //write the table for inputs to the report file
    AppendToReportFile(0, "Collapse Matrices", {{"Section", "True"}})
    fileColumn = { {"Name", "Matrix"}, {"Percentage Width", 20}, {"Alignment", "Left"}}
    tripColumn = { {"Name", "Total"},  {"Percentage Width", 80}, {"Alignment", "Left"}, {"Decimals", 0} }

    columns = {fileColumn} + { tripColumn }
    path = SplitPath(outFile)
    AppendTableToReportFile( columns, {{"Title", "Collapse Matrix Table Totals for "+path[3]}})

    for j = 1 to coreNames.length do
        outRow = { coreNames[j] } + { outTotals[j]}
        AppendRowToReportFile(outRow,)
    end
    CloseReportFileSection()

    RunMacro("Close All")

    Return(1)
     quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
