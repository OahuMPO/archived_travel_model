OMPO Model Development Project, 23009A
Control File for Trip Distribution Application TD.EXE
Truck Trips:  Garage-based, 2-axle

&files
  ftends     = '.\outputs\trckends.dat'
  fimpeds    = '.\outputs\hwyam_sov.bin'
  fequivs    = '.\inputs\other\764to23.eqv'
  ftripo     = '.\outputs\dist5g2.bin'
  frpt       = '.\reports\dist5g2.rpt'
  title      = 'TD for trucks: grg-based, 2-axle'
/
NOTE:  Replace %%% with 3-character alternative specification

&params
  nzones     = 764
  ndists     =  23
  nfends     =  14
  nfProds    =   1
  nfAttrs    =   8
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
