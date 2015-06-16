         OMPO Model Development Project
               Trip Generation for Trucks

&files
  fzdata     = '.\inputs\taz\Scenario TAZ Layer.ASC'
  ftends     = '.\outputs\trckends.dat'
  frpt       = '.\reports\hnl5trkg.rpt'
  title      = 'apply truck-trip generation model '
&end
NOTE:  Replace %%% with 3-character alternative specification

&params
  nzones     = 764
  npurps     =   7
  nzdata     = 68
  zspec      = 234, 330, 331, 332, 347, 350
  zdind      =     52,     42,     43,     44,     45,     46,     47,     48,     49,     50,     51
&end

  empl type:    total     mil     gov   hotel     agr    tran     ind    fisc     svc    retl   const
&prods
  prates1    = 0.0000, 0.2118, 0.2118, 0.2118, 0.2118, 0.2118, 0.0506, 0.2118, 0.0483, 0.0645, 0.2118
  prates2    = 0.0000, 0.0170, 0.0170, 0.0170, 0.0170, 0.0170, 0.0064, 0.0170, 0.0000, 0.0055, 0.0170
  prates3    = 0.0000, 0.0387, 0.0387, 0.0387, 0.0387, 0.0387, 0.0203, 0.0387, 0.0124, 0.0000, 0.0387
  prates4    = 0.1492, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000
  prates5    = 0.0180, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000
  prates6    = 0.0336, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000
  prates7    = 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 6310. 
&end
  For the base year the value in const prates 7 was 6310. truck trip ends
&attrs
  arates1    = 0.1077, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000, 0.0000
  arates2    = 0.0000, 0.0212, 0.0212, 0.0212, 0.0212, 0.0212, 0.0212, 0.0212, 0.0000, 0.0000, 0.0212
  arates3    = 0.0000, 0.0626, 0.0626, 0.0626, 0.0626, 0.0626, 0.0626, 0.0626, 0.0000, 0.0000, 0.0626
  arates7    = 0.0000, 0.0064, 0.0064, 0.0064, 0.0064, 0.0064, 0.0000, 0.0064, 0.0000, 0.0000, 0.0064
&end

&options
  detail     =   f
  pspec      =   0,0,0,0,0,0,1
  recto      =   1,1,1,0,0,0,1
  aeqp       =   f,f,f,t,t,t,f
&end
