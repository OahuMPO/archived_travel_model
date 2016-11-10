/********************************************************************************************************************************
*
* Recode Null Values
*
* Recodes null values in line layer to 0.  Logs number of cases with null values by facility type to logger before recoding.
*
* Arguments:
*       hwyfile             Highway line layer
*       fields              An array of field strings
*       fromValues          An array of values to recode from, one per fields
*       toValues            An array of values to recode missing to, one per fields
*       factilityTypes      An array of facility types to recode
*
********************************************************************************************************************************/
Macro "Recode Values" (hwyfile, fields, fromValues, toValues, facilityTypes)

    // RunMacro("TCB Init")
	{node_lyr, link_lyr} = RunMacro("TCB Add DB Layers", hwyfile)
    LayerInfo = {hwyfile + "|" + link_lyr, link_lyr}
    SetLayer(link_lyr) 
    
    for i = 1 to fields.length do
        
        field = fields[i]
        dir = Left(field, 2)
            
        if(dir = "AB") then do
            dirQuery = "(dir = 0 | dir = 1)"
            end
        else do
            dirQuery = "(dir = 0 | dir = -1)"
        end
        
        for j = 1 to facilityTypes.length do
        
            facilityType = String(facilityTypes[j])

            if(dir = "AB") then do
                ftQuery = "([AB FACTYPE] = "+facilityType+")"
                end
            else do
                ftQuery = "([BA FACTYPE] = "+facilityType+")"
            end
            
            if(fromValues[i] = null) then do
                queryString = dirQuery+" and "+ftQuery+ " and "+field+" = null"
                end
            else do
                queryString = dirQuery+" and "+ftQuery+ " and "+field+" = "+String(fromValues[i])
            end
            
            nSelected = SelectByQuery("SelectFieldFacttype","Several","Select * where "+queryString,)
            
            on notfound do
                AppendToLogFile(0, "Number where "+queryString+ " is 0")
                goto next
            end

            AppendToLogFile(0, "Number where "+queryString+ " is "+String(nSelected))
            if(nSelected > 0) then do
                Opts = null
        	    Opts.Input.[Dataview Set] = {hwyfile+"|"+link_lyr, link_lyr, "SelectFieldFacttype"}
    	        Opts.Global.Fields = {field}                               // the field to fill                   
    	        Opts.Global.Method = "Value"                               // fill with a single value
    	        Opts.Global.Parameter = {toValues[i]}                        // fill with value from array
    	        ret_value = RunMacro("TCB Run Operation", "Fill Dataview", Opts, &Ret)
    	        if !ret_value then Throw()
            end
            
            next:    
            on notfound default
        end
    end
    
    RunMacro("Close All")
    
    Return(1)
    
    quit:
        Return( RunMacro("TCB Closing", 0, True ) )

EndMacro
    
