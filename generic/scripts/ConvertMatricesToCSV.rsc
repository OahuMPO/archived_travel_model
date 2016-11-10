/***************************************************************
*
* A macro to convert mtx files to bin format
*
*
***************************************************************/
Macro "Convert Matrices to CSV" (matrices)

    // RunMacro("TCB Init")
    
    	for i = 1 to matrices.length do
		    m = OpenMatrix(matrices[i],)
		    path = SplitPath(matrices[i])
		    matrix_cores = GetMatrixCoreNames(m)
		    
		    for j = 1 to matrix_cores.length do
		        mc1 = CreateMatrixCurrency(m, matrix_cores[j], , , )
                mc1 := Nz(mc1)
            end
    	    CreateTableFromMatrix(m, path[1]+path[2]+path[3]+".csv", "CSV", {{"Complete", "Yes"}})
		end

    return(1)
    
        

EndMacro
