
Macro "Redistribute College Trips" (scenarioDirectory)

//            RunMacro("TCB Init")

            //scenarioDirectory = "C:\\Projects\\ompo\\tcad_040109.b"
            RenameFile(scenarioDirectory+"\\outputs\\DIST5NC.mtx", "DIST5NC_temp.mtx")
            matFile = scenarioDirectory+"\\outputs\\DIST5NC_temp.mtx"
            tazFile = scenarioDirectory+"\\inputs\\taz\\Scenario TAZ Layer.dbd"

            m1 = RunMacro("TCB OpenMatrix", matFile,)
            cores = GetMatrixCoreNames(m1)
						trips1 = CreateMatrixCurrency(m1, cores[1],,,)
						trips2 = CreateMatrixCurrency(m1, cores[2],,,)
						trips3 = CreateMatrixCurrency(m1, cores[3],,,)

				    {taz_lyr} = RunMacro("TCB Add DB Layers", tazFile,,)
						row_names = {taz_lyr+".TAZ", taz_lyr+".TD"}
            col_names = {taz_lyr+".TAZ", taz_lyr+".TD"}

						AggregateMatrix(trips1, row_names, col_names, {{"File Name", scenarioDirectory+"\\outputs\\trips1.mtx"}, {"Label", "trips1"}, {"File Based", "Yes"}})
						AggregateMatrix(trips2, row_names, col_names, {{"File Name", scenarioDirectory+"\\outputs\\trips2.mtx"}, {"Label", "trips2"}, {"File Based", "Yes"}})
						AggregateMatrix(trips3, row_names, col_names, {{"File Name", scenarioDirectory+"\\outputs\\trips3.mtx"}, {"Label", "trips3"}, {"File Based", "Yes"}})

						m1 = OpenMatrix(scenarioDirectory+"\\outputs\\trips1.mtx", "True")
						mc1 = CreateMatrixCurrency(m1, cores[1],,,)
						v1 = GetMatrixVector(mc1, {{"Column", 25}})

						m2 = OpenMatrix(scenarioDirectory+"\\outputs\\trips2.mtx", "True")
						mc2 = CreateMatrixCurrency(m2, cores[2],,,)
						v2 = GetMatrixVector(mc2, {{"Column", 25}})

						m3 = OpenMatrix(scenarioDirectory+"\\outputs\\trips3.mtx", "True")
						mc3 = CreateMatrixCurrency(m3, cores[3],,,)
						v3 = GetMatrixVector(mc3, {{"Column", 25}})

						v = v1 + v2 + v3

						districtGroupsFile = scenarioDirectory+"\\inputs\\other\\District Groups.bin"
						districtGroups = OpenTable("District Groups", "FFB", {districtGroupsFile})
						districtGroup = GetDataVector(districtGroups + "|", "[District Group]",{{"Sort Order", {{"District", "Ascending"}}}})

            numGroups = VectorStatistic(districtGroup, "Max", )
            numDistricts = VectorStatistic(districtGroup, "Count", )
            modelShare = Vector(R2I(numGroups), "Float",{{"Constant", 0.0}})

            for i = 1 to numDistricts do
                modelShare[districtGroup[i]] = modelShare[districtGroup[i]] + v[i]
            end

						districtGroupShareFile = scenarioDirectory+"\\inputs\\other\\District Group Share.bin"
						districtGroupShares = OpenTable("District Groups", "FFB", {districtGroupShareFile})
						districtGroupShare = GetDataVector(districtGroupShares + "|", "Share",{{"Sort Order", {{"[District Group]", "Ascending"}}}})

            groupFactors = Vector(R2I(numGroups), "Float",{{"Constant", 0.0}})
            for i = 1 to numGroups do
                groupFactors[i] = (districtGroupShare[i]/100)*(VectorStatistic(modelShare, "Sum", )/modelShare[i])
            end

            districtFactors = Vector(R2I(numDistricts), "Float",{{"Constant", 0.0}})
            for i = 1 to numDistricts do
                districtFactors[i] = groupFactors[districtGroup[i]]
            end

            path = SplitPath(tazFile)
            tazDataFile = path[1]+path[2]+path[3]+".bin"
						tazData = OpenTable("Taz Data", "FFB", {tazDataFile})
						tazDistrictEqn = GetDataVector(tazData + "|", "TD",{{"Sort Order", {{"TAZ", "Ascending"}}}})
            CloseView("Taz Data")
            tazFactors = Vector(R2I(764), "Float",{{"Constant", 0.0}})
            tazIdentity = Vector(R2I(764), "Float",{{"Constant", 1.0}})
            for i = 1 to 764 do
                tazFactors[i] = districtFactors[tazDistrictEqn[i]]
            end

            factorMatrixFile = scenarioDirectory+"\\outputs\\factors.mtx"
            mat = CreateMatrix({taz_lyr+"|", taz_lyr+".TAZ", "Row Index"},
													     {taz_lyr+"|", taz_lyr+".TAZ", "Column Index"},
													     {{"File Name", factorMatrixFile}, {"Type", "Float"}})
			      mc = CreateMatrixCurrency(mat, "Table",,,)

			      for i = 1 to 764 do
			          IF(tazDistrictEqn[i]=25) then do
			          		SetMatrixVector(mc, tazFactors, {{"Column",i}})
			          End
			          Else do
			          		SetMatrixVector(mc, tazIdentity, {{"Column",i}})
			          End
			      end

						MatrixCellbyCell(trips1, mc, {{"File Name", scenarioDirectory+"\\outputs\\output1.mtx"},
						     {"Label", "trips1"},
						     {"Type", "Float"},
						     {"Sparse", "No"},
						     {"Column Major", "No"},
						     {"File Based", "Yes"},
						     {"Force Missing", "No"},
						     {"Operator", 1},
						     {"Scale Left", 1.0}})

						MatrixCellbyCell(trips2, mc, {{"File Name", scenarioDirectory+"\\outputs\\output2.mtx"},
						     {"Label", "trips2"},
						     {"Type", "Float"},
						     {"Sparse", "No"},
						     {"Column Major", "No"},
						     {"File Based", "Yes"},
						     {"Force Missing", "No"},
						     {"Operator", 1},
						     {"Scale Left", 1.0}})

						MatrixCellbyCell(trips3, mc, {{"File Name", scenarioDirectory+"\\outputs\\output3.mtx"},
						     {"Label", "trips3"},
						     {"Type", "Float"},
						     {"Sparse", "No"},
						     {"Column Major", "No"},
						     {"File Based", "Yes"},
						     {"Force Missing", "No"},
						     {"Operator", 1},
						     {"Scale Left", 1.0}})

						mo1 = OpenMatrix(scenarioDirectory+"\\outputs\\output1.mtx", )
						core_names = GetMatrixCoreNames(mo1)
						SetMatrixCoreName(mo1,core_names[1],"trips 1")
						mo2 = OpenMatrix(scenarioDirectory+"\\outputs\\output2.mtx", )
						core_names = GetMatrixCoreNames(mo2)
						SetMatrixCoreName(mo2,core_names[1],"trips 2")
						mo3 = OpenMatrix(scenarioDirectory+"\\outputs\\output3.mtx", )
						core_names = GetMatrixCoreNames(mo3)
						SetMatrixCoreName(mo3,core_names[1],"trips 3")

						moc1 = CreateMatrixCurrency(mo1,,,,)
						moc2 = CreateMatrixCurrency(mo2,,,,)
						moc3 = CreateMatrixCurrency(mo3,,,,)

						new_mat = CombineMatrices({moc1, moc2, moc3}, {{"File Name", scenarioDirectory+"\\outputs\\DIST5NC.mtx"},
						     {"Label", "New Matrix"},{"Operation", "Union"}})

					DeleteFile(scenarioDirectory+"\\outputs\\DIST5NC_temp.mtx")

    Return(1)
    
    	
EndMacro
