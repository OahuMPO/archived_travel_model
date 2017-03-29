/*
The macros in this script create an adjusted highway network at the
end of each model run (called during the "Summaries" step). There are two
adjustments:

1. Adjustment for base year model compared to counts.
This adjustment modifies model volumes based on model performance in the base
year. Adjustments are made by facility type and area type. For example, if the
model, on average, under-predicts volume on urban arterials by 5%, then a
future-year scenario will have urban arterial volumes adjusted up by 5%.

2. Adjustment for centroid spot loading
Centroids condense driveways, subdivision streets, etc into a single point
where traffic loads. The second adjustment is to spread the volume out around
the centroid connection. Total VMT is maintained.
*/

Macro "Volume Adjustment"

  RunMacro("Copy Highway Network")
  RunMacro("Yinan's Macro")
  RunMacro("Kyle's Macro")
EndMacro

/*
Create a copy of the highway network to be adjusted. Share the highway file name
with the other macros of this script. The variable "path" is how the main dbox
shares info with other macros.
*/

Macro "Copy Highway Network"
  shared path, hwy_dbd
  
  scen_dir = path[2]
  orig_hwy = scen_dir + "/inputs/network/Scenario Line Layer.dbd"
  output_dir = scen_dir + "/reports/volume_adjustment"
  // Create output_dir if it doesn't exist
  if GetDirectoryInfo(output_dir, "All") = null then CreateDirectory(output_dir)
  hwy_dbd = output_dir + "/adjusted_highway.dbd"
  CopyDatabase(orig_hwy, hwy_dbd)
EndMacro

/*
Volume adjustment based on base year model performance.
*/

Macro "Yinan's Macro"
  shared path, hwy_dbd
  
  scen_dir = path[2]
EndMacro

/*
Volume adjustment based on centroid loading.
*/

Macro "Kyle's Macro"
  shared hwy_dbd
  
EndMacro
