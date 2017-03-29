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
  
  // Create a map of the highwa network
  map = RunMacro("G30 new map", hwy_dbd)
  {nlyr, llyr} = GetDBLayers(hwy_dbd)
  
  // Create the various selection sets to be used
  SetLayer(llyr)
  block_set = CreateSet("block")
  cc_set = CreateSet("CCs")
  adjusted_set = CreateSet("adjusted")
  SetLayer(nlyr)
  processed_node_set = CreateSet("processed")
  
  // Define centroids.
  // The arrays used below mean that any link with a 12 in either
  // "AB FACTYPE" or "BA FACTYPE" will be treated as a centroid.
  // Other facility types could be included - for example, you
  // may want to smooth out local street loading.
  a_type_fields = {"AB FACTYPE", "BA FACTYPE"}
  a_type_values = {12}
  
  // Create selection set and get link IDs
  SetLayer(llyr)
  qry = "Select * where"
  for f = 1 to a_type_fields.length do
    field = a_type_fields[f]
    
    for v = 1 to a_type_values.length do
      value = a_type_values[c]
      
      if TypeOf(value) = "string" then value = "'" + value + "'"
      else value = String(value)
      
      if f + v = 2 then qry = qry + " " + field + " = " + value
      else qry = qry + " or " + field + " = " + value
    end
  end
  SelectByQuery(cc_set, "several", qry)
  v_lid = GetDataVector(llyr + "|" + cc_set, "ID", )
  
  // loop over each centroid connector's link id
  for i = 1 to v_lid.length do
    lid = v_id[i]
    
    // Check both endpoints of the link
    v_nid = GetEndpoints(lid)
    for n = 1 to v_nid.length do
      nid = v_nid[n]
      
      // Classify the node
      {class, a_non_cc} = RunMacro("Classify Node", llyr, cc_set, nid)
      
      // If the node is midblock, define the block as a series of link IDs
      if class = "midblock"  then do
        SetLayer(llyr)
        block_set = CreateSet("block")
        a_block = RunMacro("Define Block", llyr, cc_set, nid)
      end
    end
  end
EndMacro

/*
Helper macro used to classify a node.

Input
  llyr
    String
    Name of link layer
  set
    String
    Name of centroid selection set
  nid
    Integer
    Node ID

Returns
  String classifying the node as either a centroid, midblock, or intersection.
  "na" is returned if the node is connected to a single CC and non CC.
*/

Macro "Classify Node" (llyr, set, nid)

  SetLayer(llyr)
  nlyr = GetNodeLayer(llyr)
  a_links = GetNodeLinks(nid)
  
  // Array of CC and non-CC IDs connected to the node
  a_cc = {}
  a_non_cc = {}
  for l = 1 to a_links.length do
    lid = a_links[l]
    
    rh = ID2RH(lid)
    if IsMember(set) then cc = cc + {lid}
    else non_cc = non_cc + {lid}
  end
  
  // Classify the node based on non-centroid count
  class = if non_cc.length = 0 then "centroid"
    else if non_cc.length = 1 then "na"
    else if non_cc.length = 2 then "midblock"
    else if non_cc.length > 2 then "intersection"
    
  return({class, a_non_cc})
EndMacro

/*
Macro that defines a block by recursively calling "Classify Node".

Input
  llyr
    String
    Name of link layer
  set
    String
    Name of centroid selection set
  nid
    Integer
    Node ID

Returns
  An array of link IDs that make up a block. A block is defined as the links
  between two "intersection"-class nodes.
*/

Macro "Define Block" (llyr, set, nid)

  {class, a_non_cc} = RunMacro("Classify Node", llyr, cc_set, nid)
  
  if class = "midblock" then do
    for l = 1 to a_non_cc.length do
      lid = a_non_cc[l]
      
      v_nid = GetEndpoints()
    end
  end
EndMacro
