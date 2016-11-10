/**************************************************************
   modechoice.rsc

  TransCAD Macro used to run mode choice

**************************************************************/
Macro "Mode Choice" (scenarioDirectory, Options)

    // apply the airport model
    airport:
    ret_value = RunMacro("Airport Model", scenarioDirectory, Options)
    if (!ret_value) then Throw()

    iftoll=Options[2]		                    // indicate if toll is used, 0 means no toll.
    fixgdwy=Options[3]                          // indicate if fixed-guideway is used, 0 means no fixed-guideway
    userben=Options[4]                          // indicate if user benefits are to be written, 0 means no user benefits
    logsumByAuto=Options[7]                     // write logsums by auto ownership (for Urbansim)
    logsumByMode=Options[8]                     // write logsums by mode
    cordonPricing=Options[10]                    // Cordon pricing scenario - reset non-toll skims to 0 if toll is non-zero


    if(cordonPricing=1) then do
       ret_value = RunMacro("Modify Skims For Cordon Pricing", scenarioDirectory)
       if !ret_value then Throw()
    end

    executableString = ".\\programs\\HNL5MODE.exe"

    //build options string
    if(iftoll <> 0 or fixgdwy <> 0 or userben <> 0 or logsumByAuto<>0 or logsumByMode<>0) then do
        optionString = "-"
        if(iftoll <> 0) then optionString = optionString + "t"
        if(fixgdwy <> 0) then optionString = optionString + "g"
        if(userben <> 0) then optionString = optionString + "u"
        if(logsumByAuto <> 0) then optionString = optionString + "d"
        if(logsumByMode <> 0) then optionString = optionString + "q"

    end

    controls = {"MODE5WH.CTL",
                "MODE5WO.CTL",
                "MODE5WW.CTL",
                "MODE5WN.CTL",
                "MODE5AW.CTL",
                "MODE5AN.CTL",
                "MODE5NK.CTL",
                "MODE5NC.CTL",
                "MODE5NS.CTL",
                "MODE5NO.CTL",
                "MODE5NN.CTL"}

    // run mode choice for all purposes
    program:

    for i = 1 to controls.length do

				//drive letter
				path = SplitPath(scenarioDirectory)

        //open the batch file to run
        fileString = scenarioDirectory+"\\programs\\source.bat"
        ptr = OpenFile(fileString, "w")
        WriteLine(ptr,path[1] )
        WriteLine(ptr,"cd "+scenarioDirectory )

        controlString =    ".\\controls\\"+controls[i]

        if(optionString != null) then controlString = controlString + " " + optionString

        runString = "call "+executableString + " " + controlString
        WriteLine(ptr,runString)

        //write the return code check
        failString = "IF NOT ERRORLEVEL = 0 ECHO "+controlString+" > failed.txt"
        WriteLine(ptr,failString)

        CloseFile(ptr)
        status = RunProgram(fileString, {{"Minimize", "True"}})

        info = GetFileInfo(scenarioDirectory+"\\failed.txt")
        if(info != null) then do
            ret_value=0
            Throw()
        end
    end

    //convert the output bin files to mtx format
    convert:

    files = {scenarioDirectory+"\\outputs\\mode5wh.bin",
             scenarioDirectory+"\\outputs\\mode5wo.bin",
             scenarioDirectory+"\\outputs\\mode5ww.bin",
             scenarioDirectory+"\\outputs\\mode5wn.bin",
             scenarioDirectory+"\\outputs\\mode5aw.bin",
             scenarioDirectory+"\\outputs\\mode5an.bin",
             scenarioDirectory+"\\outputs\\mode5nk.bin",
             scenarioDirectory+"\\outputs\\mode5nc.bin",
             scenarioDirectory+"\\outputs\\mode5ns.bin",
             scenarioDirectory+"\\outputs\\mode5no.bin",
             scenarioDirectory+"\\outputs\\mode5nn.bin"}

    ret_value = RunMacro("Convert Binary to Mtx",files)
    if(!ret_value) then Throw()

    if(iftoll <> 0 ) then do

       files = {scenarioDirectory+"\\outputs\\mode5wh_tol.bin",
             scenarioDirectory+"\\outputs\\mode5wo_tol.bin",
             scenarioDirectory+"\\outputs\\mode5ww_tol.bin",
             scenarioDirectory+"\\outputs\\mode5wn_tol.bin",
             scenarioDirectory+"\\outputs\\mode5aw_tol.bin",
             scenarioDirectory+"\\outputs\\mode5an_tol.bin",
             scenarioDirectory+"\\outputs\\mode5nk_tol.bin",
             scenarioDirectory+"\\outputs\\mode5nc_tol.bin",
             scenarioDirectory+"\\outputs\\mode5ns_tol.bin",
             scenarioDirectory+"\\outputs\\mode5no_tol.bin",
             scenarioDirectory+"\\outputs\\mode5nn_tol.bin"}

        ret_value = RunMacro("Convert Binary to Mtx",files)
        if(!ret_value) then Throw()
     end

    if(logsumByAuto <> 0 ) then do

        files = {scenarioDirectory+"\\outputs\\mode5wh_dst.bin",
             scenarioDirectory+"\\outputs\\mode5wo_dst.bin",
             scenarioDirectory+"\\outputs\\mode5ww_dst.bin",
             scenarioDirectory+"\\outputs\\mode5wn_dst.bin",
             scenarioDirectory+"\\outputs\\mode5aw_dst.bin",
             scenarioDirectory+"\\outputs\\mode5an_dst.bin",
             scenarioDirectory+"\\outputs\\mode5nk_dst.bin",
             scenarioDirectory+"\\outputs\\mode5nc_dst.bin",
             scenarioDirectory+"\\outputs\\mode5ns_dst.bin",
             scenarioDirectory+"\\outputs\\mode5no_dst.bin",
             scenarioDirectory+"\\outputs\\mode5nn_dst.bin"}

        ret_value = RunMacro("Convert Binary to Mtx",files)
        if(!ret_value) then Throw()

        files = {scenarioDirectory+"\\outputs\\mode5wh_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5wo_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5ww_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5wn_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5aw_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5an_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5nk_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5nc_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5ns_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5no_dst.mtx",
             scenarioDirectory+"\\outputs\\mode5nn_dst.mtx"}

        ret_value = RunMacro("Convert Matrices to CSV",files)
        if(!ret_value) then Throw()
    end

    if(logsumByMode <> 0 ) then do

        files = {scenarioDirectory+"\\outputs\\mode5wh_qos.bin",
             scenarioDirectory+"\\outputs\\mode5wo_qos.bin",
             scenarioDirectory+"\\outputs\\mode5ww_qos.bin",
             scenarioDirectory+"\\outputs\\mode5wn_qos.bin",
             scenarioDirectory+"\\outputs\\mode5aw_qos.bin",
             scenarioDirectory+"\\outputs\\mode5an_qos.bin",
             scenarioDirectory+"\\outputs\\mode5nk_qos.bin",
             scenarioDirectory+"\\outputs\\mode5nc_qos.bin",
             scenarioDirectory+"\\outputs\\mode5ns_qos.bin",
             scenarioDirectory+"\\outputs\\mode5no_qos.bin",
             scenarioDirectory+"\\outputs\\mode5nn_qos.bin"}

        ret_value = RunMacro("Convert Binary to Mtx",files)
        if(!ret_value) then Throw()

        files = {scenarioDirectory+"\\outputs\\mode5wh_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5wo_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5ww_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5wn_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5aw_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5an_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5nk_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5nc_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5ns_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5no_qos.mtx",
             scenarioDirectory+"\\outputs\\mode5nn_qos.mtx"}

        ret_value = RunMacro("Convert Matrices to CSV",files)
        if(!ret_value) then Throw()
    end


    Return(1)




EndMacro
/***********************************************************************************************************************************
*
* Airport Model
* Applies trip distribution and mode choice model for airport trips
*
* Inputs:
*       HNL5AIRP.EXE    Airport model executable
*       AIRP5RES.CTL    Resident airport trip control file
*       AIRP5VIS.CTL    Visitor not on tour trip control file
*       AIRP5TOUR.CTL   Visitor on tour trip control file
*
* Outputs:
*       AIR_RES.MTX    Resident airport trips by mode
*       AIR_VIS.mtx    Visitor not on tour airport trips by mode
*       AIR_TOUR.mtx   Visitor on tour airport trips by mode
*
*       Each output file has 6 tables:
*           Auto
*           Taxi
*           Public Bus
*           Shuttle Bus
*           Tour Bus
*           Rail
*
***********************************************************************************************************************************/
Macro "Airport Model" (scenarioDirectory, Options)
//    RunMacro("TCB Init")

    Options = {0,0,0,1}


    scenarioDirectory="f:\\projects\\ompo\\ortp2009\\c_model\\2030tsm_setdist_110420"
    optionString = "-"

        //drive letter
    iftoll=0		                    // indicate if toll is used, 0 means no toll.
    fixgdwy=0                          // indicate if fixed-guideway is used, 0 means no fixed-guideway
    userben=1                          // indicate if user benefits are to be written, 0 means no user benefits

    executableString = ".\\programs\\HNL5AIRP.exe"

    //build options string
    if(iftoll <> 0 or fixgdwy <> 0 or userben <> 0 ) then do
        optionString = "-"
        if(iftoll <> 0) then optionString = optionString + "t"
        if(fixgdwy <> 0) then optionString = optionString + "g"
        if(userben <> 0) then optionString = optionString + "u"

    end

    controls = {scenarioDirectory+"\\controls\\AIRP5VIS.CTL"}

    tripTable = {"AIR_VIS.BIN"}



    for i = 1 to controls.length do

        controlString = controls[i]

        if(optionString != null) then controlString = controls[i] + " " + optionString

//        ret_value = RunMacro("Run Program",scenarioDirectory,executableString, controlString)
//        if(!ret_value) then Throw()

        ret_value = RunMacro("Convert Binary to Mtx",{scenarioDirectory+"\\outputs\\"+tripTable[i]})
        if(!ret_value) then Throw()

    end


    Return(1)


EndMacro
