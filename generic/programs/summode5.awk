# summode5.awk
# 
# This awk script appends all mode5 mode choice report files output trips by mode (Table 1) to a text
# file for easy pasting into a spreadsheet.
#
# Make sure gawk is in system path or directory.
# type:
# gawk -f summode5.awk > mode5.csv
#
BEGIN{

    files[1] = "MODE5WH.RPT" 
    files[2] = "MODE5WO.RPT" 
    files[3] = "MODE5WW.RPT" 
    files[4] = "MODE5WN.RPT" 
    files[5] = "MODE5AW.RPT" 
    files[6] = "MODE5AN.RPT" 
    files[7] = "MODE5NK.RPT" 
    files[8] = "MODE5NC.RPT" 
    files[9] = "MODE5NS.RPT" 
    files[10] ="MODE5NO.RPT" 
    files[11] ="MODE5NN.RPT"
    
    for(i=1;i<=11;++i){
        
        file=files[i]
        printf("%s\n",file)
        writeLine=0
        pnr=0
        while(getline <file > 0 ){
            
            if(match($0,"REPORT 1:  Market Shares by Mode")>0)
                writeLine=1
            
            if(match($0,"REPORT 1a:  Toll Trips By Occupancy")>0)
                writeLine=0

            if(writeLine==1){
             
                if(match($0,"pnr-gdwy")>0)
                    pnr=1
             
                if(pnr==0)
                    for(j=1;j<=NF;++j)
                        printf("%s,",$j)
             
                if(pnr==1 && NF==4)
                    printf("%s,0,%s,0,0,%s,0,0,%s,0",$1,$2,$3,$4)
                
                printf("\n")
            }
        
        }
 
    }
 
}
