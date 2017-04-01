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

SelectByLinks() / SelectByNodes()
*/

Macro "Kyle's Macro"
  shared hwy_dbd
  
  // Create a map of the highwa network
  map = RunMacro("G30 new map", hwy_dbd)
  {nlyr, llyr} = GetDBLayers(hwy_dbd)
  
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
  
  // Classify all nodes on network
  RunMacro("Classify Nodes")
  
  // Create a set of midblock links
  SetLayer(llyr)
  midblock_link_set = CreateSet("midblock")
  SelectByNodes(midblock_link_set, Several, midblock_node_set)
  
  // Adjust block volumes until all midblock nodes have been processed
  ntp = GetSetCount(midblock_node_set)
  while ntp > 0 do
    
    // create set of midblock nodes that haven't been processed
    not_processed = SetInvert("not processed", processed_node_set)
    target_set = SetAND("target", {midblock_node_set, not_processed})
    a_nid = GetSetIDs(nlyr + "|" + target_set)
    
    nid = a_nid[1]
    RunMacro("Create Block Set", llyr, nlyr, nid)
  
    ntp = GetSetCount(midblock_node_set) - GetSetCount(processed_node_set)
  end
  
EndMacro

/*
Classifies nodes as either a centroid, midblock, or intersection.

Input
  llyr
    String
    Name of link layer
  cc_set
    String
    Name of CC link selection set
*/

Macro "Classify Nodes" (llyr, cc_set)

  SetLayer(llyr)
  nlyr = GetNodeLayer(llyr)
  v_nid = GetDataVector(nlyr + "|", "ID", )
  
  SetLayer(nlyr)
  for n = 1 to v_nid.length do
    nid = v_nid[n]
    
    // Set node as current record and get connected links
    rh = ID2RH(nid)
    SetRecord(rh)
    a_links = GetNodeLinks(nid)
    
    // Array of CC and non-CC link IDs connected to the node
    a_cc = 0
    a_non_cc = 0
    for l = 1 to a_links.length do
      lid = a_links[l]
      
      rh = ID2RH(lid)
      if IsMember(cc_set) then cc = cc + 1
      else non_cc = non_cc + 1
    end
    
    // Classify the node based on non-centroid count
    // Add them to the appropriate selection set
    if non_cc.length = 0 SelectRecord(centroid_node_set)
    else if non_cc.length = 1 then SelectRecord(intersection_node_set)
    else if non_cc.length = 2 then SelectRecord(midblock_node_set)
    else if non_cc.length > 2 then SelectRecord(intersection_node_set)
  end
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

/*

*/

Macro "Create Block Set" (llyr, nlyr, nid)

  link_block_set = CreateSet(llyr, "block links")
EndMacro
