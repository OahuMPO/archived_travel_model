OMPO Model Development Project
Trip Generation for Airport Access

&files
  fzdata     = '.\inputs\taz\Scenario TAZ Layer.ASC'
  ftends     = '.\outputs\airpends.dat'
  frpt       = '.\reports\airgen5.rpt'
  title      = 'apply airport-acc gen model '
&end
NOTE:  Replace %%% with 3-character alternative specification
       purposes: 1= residents, 2= visitor/tour, 3= visitor/independent

&params
  nzones     = 764
  npurps     =   3
  nzdata     = 71
  nzdata     =  71
  zspec      = 762
  zdind      =     34,     53
&end

  zdat type:    htlrm     hld
&prods
  prates1    =     0., 11500.
  prates2    =     0., 18300.
  prates3    =     0., 39000.
&end
Note: In the base year the second parameter of prates1 was 10000
      of prates2 with 16000, of prates3 was 34000
&attrs
  arates1    =     0.,     1.
  arates2    =     1.,     0.
  arates3    =    25.,     1.
&end

&options
  detail     =   f,
  pspec      =   1,1,1,
  recto      =   1,1,1,
  aeqp       =   F,F,F,
&end
