Macro "Convert Percent Rail Walk to Binary" (scenarioDirectory)
    RunMacro("TCB Init")
        scenarioDirectory="F:\\projects\\OMPO\\ORTP2009\\C_Model\\2030MOSJ_setdist_110503"
        ret_value = RunMacro("Convert Matrices To Binary",{scenarioDirectory+"\\SUMMIT\\perwalkrailtcadmat.mtx"}) 
        if(!ret_value) then Throw()
        
    Return(1)
    quit:
    	Return( RunMacro("TCB Closing", ret_value, True ) )
EndMacro  

/***************************************************************
*
* A macro to convert mtx files to bin format
*
*
***************************************************************/
Macro "Convert Matrices To Binary" (matrices)

    // RunMacro("TCB Init")
    
    	for i = 1 to matrices.length do
		    m = OpenMatrix(matrices[i],)
		    path = SplitPath(matrices[i])
		    matrix_cores = GetMatrixCoreNames(m)
		    
		    for j = 1 to matrix_cores.length do
		        mc1 = CreateMatrixCurrency(m, matrix_cores[j], , , )
                mc1 := Nz(mc1)
            end
    	    CreateTableFromMatrix(m, path[1]+path[2]+path[3]+".bin", "FFB", {{"Complete", "Yes"}})
		end

    return(1)
    quit:
        Return( RunMacro("TCB Closing", ret_value, True ) )

EndMacro
