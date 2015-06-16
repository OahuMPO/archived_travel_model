//*************************************************************
//
// A utility macro that will close all open map windows
//
//*************************************************************
Macro "Close All"
    // RunMacro("TCB Init")
    maps = GetMapNames()
    
    if(maps = null) then goto view
    for i = 1 to maps.length do
	    CloseMap(maps[i])
    end
    
    view:
    views = GetViewNames()
    if(views = null) then goto quit
    for i = 1 to views.length do
        if( !Left(views[i],2)="c:") then CloseView(views[i])
    end

    return(RunMacro("G30 File Close All"))

    quit:
    Return(1)
EndMacro
