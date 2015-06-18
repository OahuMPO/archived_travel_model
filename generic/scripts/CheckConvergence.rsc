/**************************************************************************************************************
* Check Convergence						
*
* Compares two matrices and performs and returns RMSE
*
* Arguments:
*   matrix1    An array of matrix file, coreNumber
*   matrix2    An array of matrix file, coreNumber
*
* Returns 
*   percent_rmse    The percent RMSE
*
**************************************************************************************************************/
Macro "Check Convergence" ( matrix1, matrix2 )		

    previous_skim_matrix = matrix1[1]
    current_skim_matrix = matrix2[1]
    core1 = matrix1[2]
    core2 = matrix2[2]
    
    m_prev_skim = OpenMatrix(previous_skim_matrix,)
    m_curr_skim = OpenMatrix(current_skim_matrix,)

    core_names1 = GetMatrixCoreNames(m_prev_skim)
    core_names2 = GetMatrixCoreNames(m_curr_skim)
    
    mc_prev_skim = CreateMatrixCurrency(m_prev_skim, core_names1[core1],,,)
    mc_curr_skim = CreateMatrixCurrency(m_curr_skim, core_names2[core2],,,)

    rmse_array = MatrixRMSE(mc_prev_skim, mc_curr_skim)
    rmse = rmse_array.RMSE
    
    Return(rmse)

EndMacro