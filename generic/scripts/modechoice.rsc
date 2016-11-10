/**************************************************************
   modechoice.rsc
 
  TransCAD Macro used to run mode choice

**************************************************************/
Macro "Mode Choice" (scenarioDirectory, Options)

    // apply the airport model
    airport:
    ret_value = RunMacro("Airport Model", scenarioDirectory, Options)
    if (!ret_value) then Throw()

   Return(1)
    
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

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

        //drive letter
    iftoll=Options[2]		                    // indicate if toll is used, 0 means no toll.
    fixgdwy=Options[3]                          // indicate if fixed-guideway is used, 0 means no fixed-guideway
    userben=Options[4]                          // indicate if user benefits are to be written, 0 means no user benefits
    
    executableString = ".\\programs\\HNL5AIRP.exe"

    //build options string
    if(iftoll <> 0 or fixgdwy <> 0 or userben <> 0 ) then do
        optionString = "-" 
        if(iftoll <> 0) then optionString = optionString + "t"
        if(fixgdwy <> 0) then optionString = optionString + "g"
        if(userben <> 0) then optionString = optionString + "u"
   
    end
        
    controls = {".\\controls\\AIRP5VIS.CTL",
                ".\\controls\\AIRP5RES.CTL",
                ".\\controls\\AIRP5TOUR.CTL"}

    tripTable = {"AIR_VIS.BIN",
                 "AIR_RES.BIN",
                 "AIR_TOUR.BIN"}

 
 
    for i = 1 to controls.length do

        controlString = controls[i]

        if(optionString != null) then controlString = controls[i] + " " + optionString

        ret_value = RunMacro("Run Program",scenarioDirectory,executableString, controlString)
        if(!ret_value) then Throw()
    
        ret_value = RunMacro("Convert Binary to Mtx",{scenarioDirectory+"\\outputs\\"+tripTable[i]}) 
        if(!ret_value) then Throw()
        
    end
    

    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro  
      
