#!/bin/sh -x
tstart=`date +%s`
export charnanal='control'
if [ $update_seaice == 'true' ];then
   # update ice restart file from previous cycle
   if [ $ANALHR -eq '12' ]; then
      if [ -f INPUT/bkg_iced.${year_start}-${mon_start}-${day_start}-${secondofday}.nc ];then
         echo "skipping ice update"
      else
         echo "running ice update"
         cd $scriptsdir
         ./update_ice.sh
         if [ $? -ne 0 ]; then
           echo "ice update failed"
           exit 3
         fi
         cd ${datapath2}/${charnanal}
      fi
   fi
fi
tend=`date +%s`
dt=`expr $tend - $tstart`
echo "gsi step took $dt seconds"
exit 0
