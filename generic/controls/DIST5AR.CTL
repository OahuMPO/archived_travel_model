Honolulu models
Control File for Trip Distribution Application TD.EXE
Airport-Access Trips: Residents

&files
  ftends     = '.\outputs\airpends.dat'
  fimpeds    = '.\outputs\ones764.bin'
  fequivs    = '.\inputs\other\764to23.eqv'
  ftripo     = '.\outputs\dist5ar.bin'
  frpt       = '.\reports\dist5ar.rpt'
  title      = 'TD for ap acc: res'
/
NOTE:  Replace %%% with 3-character alternative specification
       BAS extension designates BASE file (matrix of 1's in this case)

&params
  nzones     = 764
  ndists     =  23
  ntables    =   1
  nfends     =   6
  nfProds    =   1
  nfAttrs    =   4
  tabimp     =   1
  nincr      =   1
  p1beg      =   0.00
  p2beg      =   0.00
  maxiter    =   1
  reltol     =   0.005
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
