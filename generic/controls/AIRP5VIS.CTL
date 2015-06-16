&FILES
   FPAVST = '.\outputs\airpends.dat'
   FRPT = '.\reports\AIRP5VIS.RPT'
   FSKBUS = '.\outputs\transit_wloc_md.bin'
   FSKHWY = '.\outputs\hwymd_sov.bin'
   FSKRAL = '.\outputs\transit_wfxg_md.bin'
   FMDEOUT = '.\outputs\AIR_VIS.bin'
   FLOGSUM = '.\outputs\ALOGIT_LOGSUM.bin'
   FPROB = '.\outputs\ALOGIT_PROB.bin'
   FUBEN  ='.\outputs\AIR_VIS_UBEN.bin'
&end
&PARAMS
   NZONES=764,
   TPURP=3,
&end
&OPTIONS
   DRYRUN=F,
   DEBUG=F,
   CALIB=F
&end
&SELECTS
   I=1,-764
&end
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
   NOAUTO =  0.60000,
   KAUTO  =  0.09680,
   KTAXI  = -0.21261,
   KPBUS  = -2.44878,
   KSBUS  =  4.42362,
   KTOUR  =-15.00000,
   KRAIL  = -2.44878
&end
