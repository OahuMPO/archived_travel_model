macro "modify route system"
    shared d_exts_rs

    rtpath = ChooseFile(d_exts_rs
    					,"File Open",
                        {{"ReadOnly Box", "Yes"}})

	ll_db = GetLayerDB()
    layers = GetDBLayers(ll_db)
    ModifyRouteSystem(rtpath, {{"Geography", ll_db, layers[2]}})
endMacro
