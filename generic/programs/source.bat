C:
cd C:\projects\Honolulu\Version6\2012_6_calibration
call .\programs\HNL5AIRP.exe .\controls\AIRP5TOUR.CTL
IF NOT ERRORLEVEL = 0 ECHO .\controls\AIRP5TOUR.CTL > failed.txt
