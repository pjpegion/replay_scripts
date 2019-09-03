date=2019081218
datem1=`incdate $date -6`
YYYY=`echo $datem1 | cut -c1-4`
YYYYMM=`echo $datem1 | cut -c1-6`
YYYYMMDD=`echo $datem1 | cut -c1-8`
HH=`echo $datem1 | cut -c9-10`
htar -tvf /NCEPPROD/hpssprod/runhistory/rh${YYYY}/${YYYYMM}/${YYYYMMDD}/gpfs_dell1_nco_ops_com_gfs_prod_gdas.${YYYYMMDD}_${HH}.gdas_restart.tar
# copy restart file to INPUT directory for next analysis time.
mkdir -p ../../../control/INPUT
cd gdas.${YYYYMMDD}/${HH}/RESTART
ls -l
YYYY=`echo $date | cut -c1-4`
YYYYMM=`echo $date | cut -c1-6`
YYYYMMDD=`echo $date | cut -c1-8`
HH=`echo $date | cut -c9-10`
datestring="${YYYYMMDD}.${HH}0000."
for file in ${datestring}*nc; do
   file2=`echo $file | cut -f3-10 -d"."`
   /bin/mv -f $file  ../../../control/INPUT/$file2
   if [ $? -ne 0 ]; then
     echo "restart file missing..."
     exit 1
   fi
   done
cd ../../..
/bin/rm -rf gdas.${YYYYMMDD}
