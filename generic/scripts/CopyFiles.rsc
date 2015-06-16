/**************************************************************************************************************
* Copy Files						
*
* Copies all files from one directory to another.  Creates the target directory if it does not exist.
*
* Arguments:
*   fromDir     The directory to copy from
*   toDir       The directory to copy to
*
*
**************************************************************************************************************/
Macro "Copy Files" (fromDir, toDir)

    //check for directory of output turns
    if GetDirectoryInfo(toDir, "Directory")=null then do
        CreateDirectory( toDir)   
    end
    
    
   // copy the files
    file_names = GetDirectoryInfo(fromDir+"\\*.*", "File")
    for i=1 to file_names.length do
        oldFile = fromDir+"\\"+file_names[i][1]
        newFile = toDir+"\\"+file_names[i][1]
        CopyFile(oldFile,newFile)
    end
    
    Return(1)
EndMacro
