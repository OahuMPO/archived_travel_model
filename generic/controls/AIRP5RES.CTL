&FILES
   FPAVST = '.\outputs\airpends.dat'
   FRPT = '.\reports\AIRP5RES.RPT'
   FSKBUS = '.\outputs\transit_wloc_md.bin'
   FSKHWY = '.\outputs\hwymd_sov.bin'
   FSKRAL = '.\outputs\transit_wfxg_md.bin'
   FMDEOUT = '.\outputs\AIR_RES.bin'
   FLOGSUM = '.\outputs\ALOGIT_LOGSUM.bin'
   FPROB = '.\outputs\ALOGIT_PROB.bin'
   FUBEN  ='.\outputs\AIR_RES_UBEN.bin'
   /
&PARAMS
   NZONES=764,
   TPURP=1
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
   SHBUSCR=1000.0000,
   RCPM   = 50.50000,
   TXWAIT =  5.00000,
   TRWAIT = 10.00000,
   NOAUTO =  0.00000,
   KAUTO  =  0.28234
   KTAXI  = -0.14844
   KPBUS  = -1.50443
   KSBUS  =  2.27998
   KTOUR  =  0.00000
   KRAIL  = -1.50443
   /
