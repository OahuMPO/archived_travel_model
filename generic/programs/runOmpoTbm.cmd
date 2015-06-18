set PROJECT_DRIVE=%1
set PROJECT_DIRECTORY=%2
set SAMPLERATE=%3
set ITERATION=%4

%PROJECT_DRIVE%
cd %PROJECT_DIRECTORY%\programs
call %PROJECT_DIRECTORY%\programs\CTRampEnv.bat


rem ### First save the JAVA_PATH environment variable so it s value can be restored at the end.
set OLDJAVAPATH=%JAVA_PATH%
set OLDPATH=%PATH%

rem ### Set the directory of the jdk version desired for this model run
rem ### Note that a jdk is required; a jre is not sufficient, as the UEC class generates
rem ### and compiles code during the model run, and uses javac in the jdk to do this.
set JAVA_PATH=%JAVA_64_PATH%

rem ### Name the project directory.  This directory will hava data and runtime subdirectories
set CONFIG=%PROJECT_DIRECTORY%/controls

rem ### Set the name of the properties file the application uses by giving just the base part of the name (with ".xxx" extension)
set PROPERTIES_NAME=ompo_tbm

set LIB_JAR_PATH=%PROJECT_DIRECTORY%/programs/ompo.jar


rem ### Define the CLASSPATH environment variable for the classpath needed in this model run.
set OLDCLASSPATH=%CLASSPATH%
set CLASSPATH=%TRANSCAD_PATH%/GISDK/Matrices/TranscadMatrix.jar;%CONFIG%;%RUNTIME%;%LIB_JAR_PATH%;

rem ### Change the PATH environment variable so that JAVA_HOME is listed first in the PATH.
rem ### Doing this ensures that the JAVA_HOME path we defined above is the on that gets used in case other java paths are in PATH.
set PATH=%TRANSCAD_PATH%;%JAVA_PATH%\bin;%OLDPATH%


rem run ping to add a pause so that hhMgr and mtxMgr have time to fully start
ping -n 10 %MAIN% > nul

REM **************************************************************************************************************************************************
REM ESTIMATION FILE CREATION TOOLS

rem Run resident destination choice model estimation file creation tool
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.CreateDestChoiceEstFile %PROPERTIES_NAME% -inputFile %PROJECT_DIRECTORY%/TourDcEstimationInputs.csv  -outputFile %PROJECT_DIRECTORY%/TourDCOutFile.csv

rem Run resident intermediate stop destination choice model estimation file creation tool
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.CreateStopDestChoiceEstFile %PROPERTIES_NAME% -inputFile %PROJECT_DIRECTORY%/StopDC.csv  -outputFile %PROJECT_DIRECTORY%/StopDCOutFile.csv

rem Run visitor mode choice model estimation file creation tool
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.common.AppendSkims %PROPERTIES_NAME% -inputFile %PROJECT_DIRECTORY%/visInputData.csv -inputUEC %PROJECT_DIRECTORY%/controls/Skims.xls -outputFile %PROJECT_DIRECTORY%/visOutputData.csv -tourFormat true

rem Run visitor destination choice model estimation file creation tool
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.visitormodel.CreateDestChoiceEstFile %PROPERTIES_NAME% -inputFile %PROJECT_DIRECTORY%/VisitorDestChoiceInput.csv  -outputFile %PROJECT_DIRECTORY%/VisitorDestChoiceOutput.csv

rem Run mandatory logsum file creation tool
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.CreateMandatoryLogsumFile %PROPERTIES_NAME% -inputFile %PROJECT_DIRECTORY%/MandPersonData.csv  -outputFile %PROJECT_DIRECTORY%/MandPersonDataOut.csv 

rem Create accessibilities
rem %JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.CreateAccessibilities %PROPERTIES_NAME% 

REM **************************************************************************************************************************************************

rem Run resident tour-based models
%JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.ResidentModelRunner %PROPERTIES_NAME% -iteration %ITERATION%  -sampleRate %SAMPLERATE% 2>&1 | %GNUWIN32_PATH%\tee.exe ..\reports\ResidentModelRunnerScreen_%ITERATION%.log

rem Build resident tour-based model trip tables
%JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.residentmodel.ResidentTripTables %PROPERTIES_NAME% -iteration %ITERATION%  2>&1 | %GNUWIN32_PATH%\tee.exe ..\reports\ResidentTripTablesScreen_%ITERATION%.log



rem Run visitor tour-based models
%JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.visitormodel.VisitorModelRunner %PROPERTIES_NAME% -iteration %ITERATION%  -sampleRate %SAMPLERATE%  2>&1 | %GNUWIN32_PATH%\tee.exe ..\reports\VisitorModelRunnerScreen_%ITERATION%.log

rem Build visitor tour-based model trip tables
%JAVA_64_PATH%\bin\java -server -Xms10000m -Xmx10000m -cp "%CLASSPATH%" -Dlog4j.configuration=log4j.xml -Dproject.folder=%PROJECT_DIRECTORY% com.pb.ompo.visitormodel.VisitorTripTables %PROPERTIES_NAME% -iteration %ITERATION%  2>&1 | %GNUWIN32_PATH%\tee.exe ..\reports\VisitorTripTables_%ITERATION%.log


rem ### restore saved environment variable values, and change back to original current directory
set JAVA_PATH=%OLDJAVAPATH%
set PATH=%OLDPATH%
set CLASSPATH=%OLDCLASSPATH%
