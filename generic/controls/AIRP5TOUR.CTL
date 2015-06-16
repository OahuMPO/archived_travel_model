&FILES
   FPAVST = '.\outputs\airpends.dat'
   FRPT = '.\reports\AIRP5TOUR.RPT'
   FSKBUS = '.\outputs\transit_wloc_md.bin'
   FSKHWY = '.\outputs\hwymd_sov.bin'
   FSKRAL = '.\outputs\transit_wfxg_md.bin'
   FMDEOUT = '.\outputs\AIR_TOUR.bin'
   FLOGSUM = '.\outputs\ALOGIT_LOGSUM.bin'
   FPROB = '.\outputs\ALOGIT_PROB.bin'
   FUBEN  ='.\outputs\AIR_TOUR_UBEN.bin'
   /
&PARAMS
   NZONES=764,
   TPURP=2
   /
&OPTIONS
   DRYRUN=F,
   DEBUG=F,
   CALIB=F
   /
&SELECTS
   I=1,-764
   /
&PARMS
   CPROB  =  0.90000,
   CIVT   = -0.03274,
   COVT   = -0.04910,
   COCOST = -0.00550,
   CDIST  =  0.20400,
   TCPM   = 48.00000,
   TXBASE =225.00000,
   SHBUSH = 20.00000,
   SHBUSCR=  0.00000
   RCPM   = 50.50000,
   TXWAIT =  5.00000,
   TRWAIT = 10.00000,
   NOAUTO =  0.99999,
   KAUTO  =  0.00000,
   KTAXI  =-15.00000,
   KPBUS  =-15.00000,
   KSBUS  = -0.27389,
   KTOUR  =  0.57681,
   KRAIL  =-15.00000
   /
