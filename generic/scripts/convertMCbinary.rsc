Macro "Convert Mode Choice to Binary" (scenarioDirectory)
    RunMacro("TCB Init")
        scenarioDirectory="F:\\projects\\OMPO\\ORTP2009\\C_Model\\2030tsm_setdist_110427"
        ret_value = RunMacro("Convert Binary to Mtx",{scenarioDirectory+"\\outputs\\mode5nn.bin"}) 
        if(!ret_value) then Throw()
        
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro  

/***********************************************************************************************************************************
*
* Convert Binary to Mtx
* Converts bin files to mtx file.  Assumes files are to be placed in same directory as input files
*
* Args:
*   An array of file names to convert
*
*
***********************************************************************************************************************************/
Macro "Convert Binary to Mtx" (files)

    // RunMacro("TCB Init")
 	for i = 1 to files.length do
        path = SplitPath(files[i])
        in_trips_bin = files[i]
        out_trips_mtx = path[1]+path[2]+path[3]+".mtx"

        mtab = OpenTable("tab","FFB", {in_trips_bin})
	    flds = GetFields(mtab,"All")
        flds_import = Subarray(flds[1], 3, flds[1].length-2)
        ifld = flds[1][1]
        jfld = flds[1][2]
        Opts = null
        Opts.[File Name] = out_trips_mtx
        Opts.Compression = 1
        m = CreateMatrixFromView(out_trips_mtx, mtab + "|",ifld,jfld, flds_import,Opts )
        m = null
        CloseView(mtab)
    end
    Return(1)
EndMacro
