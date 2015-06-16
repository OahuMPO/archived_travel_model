OMPO Model Development Project, 23009A
Control File for Trip Distribution Application TD.EXE
Truck Trips:  Port-based

&files
  ftends     = '.\outputs\trckends.dat'
  fimpeds    = '.\outputs\hwyam_sov.bin'
  fequivs    = '.\inputs\other\764to23.eqv'
  ftripo     = '.\outputs\dist5po.bin'
  frpt       = '.\reports\dist5po.rpt'
  title      = 'TD for trucks: port-based'
/
NOTE:  Replace %%% with 3-character alternative specification

&params
  nzones     = 764
  ndists     =  23
  nfends     =  14
  nfProds    =   7
  nfAttrs    =  14
  tabimp     =   1
  nincr      =   1
  p1beg      =  -0.03
  p2beg      =   0.00
  maxiter    =  10
  reltol     =   2
  abstol     =  10
  width      =   2
  nintervs   =  50
  scale      =   1.0
  offset     =   0.0
/
&options
  prteqv     = F
  calib      = F
/
