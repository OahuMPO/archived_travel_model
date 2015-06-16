&FILES
  FZDATA     = '.\inputs\taz\Scenario TAZ Layer.ASC'
  FDEQUIV    = '.\inputs\other\26dequiv.dat'
  FSKTOUR    = '.\inputs\other\tourcost.bin'
  FPERSN     = '.\inputs\vist5trp.bas.bin'
  FSKLOC     = '.\outputs\transit_wloc_op.bin'
  FSKPRM     = '.\outputs\transit_wfxg_op.bin'
  FSKHWY     = '.\outputs\hwymd_sov.bin'
  FVSTOUT    = '.\outputs\vist5trp.bin'
  FCALOUT    = '.\outputs\vismodedest.dat'
  FRPT       = '.\reports\hnl5vist.rpt'
  FUSERB     = '.\outputs\visitorub.bin'
&end
&PARAMS
  NZONES=764,
  NZDATA=71,
  ZDIND      =     57,     55,     55,     66,     67,     34,     35
&end
              prk cst,  orgtt,  dsttt,  prcau, prctr, hotel, resrt-condo

&OPTIONS
  DRYRUN=F,
  DEBUG=F,
  TFARE=F
&end
&SELECTS
  REPORTS=1,
  I=1,-764
&end
&PARMS
FLTFAR=68.0,
WAIKIKIDIST=4,
AMDIST=26,
CONST(1)=-1.7296,  
CONST(2)=0.1943,   
CONST(3)=-2.4151,  
CONST(4)=-2.8745,  
CONST(5)=-3.4149,  
CONST(6)=-2.0372,  
CONST(7)=-0.8782,  
CONST(8)=-1.5975,  
CONST(9)=-1.1365,  
CONST(10)=-0.9409, 
CONST(11)=-3.3479, 
CONST(12)=0.2466,  
CONST(13)=-2.2282, 
CONST(14)=-23.7629,
CONST(15)=-1.0307, 
CONST(16)=-1.3626, 
CONST(17)=-2.5546, 
CONST(18)=-1.2638, 
CONST(19)=-1.2885, 
CONST(20)=-1.5933, 
CONST(21)=-4.3204, 
CONST(22)=-2.7268, 
CONST(23)=-3.5598, 
CONST(24)=0.6218,  
CONST(25)=-1.4215, 
KAUTO=-3.8691,     
KBUS=-6.0,       
KRAIL=-6.0,      
KTAXI=-6.5,     
KTOUR=-6.4583,     
KWALK=2.945,       
KWLKWAIKIKI=1.5408,
KTOURAM=-2.5247,   
KWLKAM=-3.9665,    
KAUTAM=-0.8135,    
KTAXIAM=0.0386     
&end
