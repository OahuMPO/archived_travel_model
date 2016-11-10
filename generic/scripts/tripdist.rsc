/**************************************************************
   tripdist.rsc
 
  TransCAD Macro used to run trip distribution

**************************************************************/
Macro "Trip Distribution" (scenarioDirectory, iftoll)

    executableString = ".\\programs\\HNL5DIST.exe"
   
      // truck trips
    truck:

    controls = {"DIST5G2.CTL",
                "DIST5G3.CTL",
                "DIST5G4.CTL",
                "DIST5N2.CTL",
                "DIST5N3.CTL",
                "DIST5N4.CTL",
                "DIST5PO.CTL"}
    
    
    ret_value = RunMacro("Run Distrib",scenarioDirectory,executableString,controls, iftoll)
    if(!ret_value) then Throw()

 
    // convert truck trips to mtx format 
    convert:
 
    files = {scenarioDirectory+"\\outputs\\DIST5G2.bin",
             scenarioDirectory+"\\outputs\\DIST5G3.bin",
             scenarioDirectory+"\\outputs\\DIST5G4.bin",
             scenarioDirectory+"\\outputs\\DIST5N2.bin",
             scenarioDirectory+"\\outputs\\DIST5N3.bin",
             scenarioDirectory+"\\outputs\\DIST5N4.bin",
             scenarioDirectory+"\\outputs\\DIST5PO.bin"}
             
   ret_value = RunMacro("Convert Binary to Mtx", files)
   if (!ret_value) then Throw()
   
      
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
/***********************************************************************************************************************************
*
* Run Distrib
* Runs the program for a set of control files 
*
***********************************************************************************************************************************/

Macro "Run Distrib" (scenarioDirectory, executableString, controls, iftoll)

    if(iftoll <> 0 ) then optionString = "-t"
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
        WriteLine(ptr,"IF NOT ERRORLEVEL = 0 ECHO "+controlString+" > failed.txt") 
        // WriteLine(ptr,"pause")
        CloseFile(ptr)
        
        // Before running the program, clear out any previous error files
        if GetFileInfo(scenarioDirectory+"\\failed.txt") <> null then DeleteFile(scenarioDirectory+"\\failed.txt")
        
        status = RunProgram(fileString, {{"Minimize", "True"}})
       
        info = GetFileInfo(scenarioDirectory+"\\failed.txt")
        if(info != null) then do
            ret_value=0
            Throw()
        end
    end

    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro
