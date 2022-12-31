# need envars:  machine, analdate, datapath, hsidir

exitstat=0
source $MODULESHOME/init/sh
if [ $machine == "gaea" ]; then
   #module load hsi
   htar=/sw/rdtn/hpss/default/bin/htar
   hsi=/sw/rdtn/hpss/default/bin/hsi
   module load netcdf
else
   module load hpss
   module use /scratch2/NCEPDEV/nwprod/hpc-stack/libs/hpc-stack/modulefiles/stack
   module load hpc/1.2.0
   module load hpc-intel/2022.1.2
   module load hpc-impi/2022.1.2
   module load netcdf/4.7.4
   module load nco/4.9.1
   htar=`which htar`
   hsi=`which hsi`
   nccopy=`which nccopy`
   ncdump=`which ncdump`
   ncks=`which ncks`
fi
#env
#$hsi ls -l $hsidir
$hsi mkdir -p ${hsidir}/
datapath2=${datapath}/${analdate}
YYYY=`echo $analdate | cut -c1-4`
MM=`echo $analdate | cut -c5-6`
DD=`echo $analdate | cut -c7-8`
HH=`echo $analdate | cut -c9-10`

# move increment file up 2 directories to save with diagnostics
/bin/mv -f ${datapath2}/control/INPUT/fv3_increment6.nc ${datapath2}

cd ${datapath2}/control
find -type l -delete # delete symlinks
/bin/rm -f core

$hsi mkdir -p ${hsidir}

# archive restarts only at 06Z (for 00Z 'analysis' time)
if [ $HH == '06' ]; then
   # re-write restarts compressed
   cd ${datapath2}/control/INPUT
   for file in *nc; do
       compressed=`$ncdump -sh $file | grep Deflate`
       if [ ! -z "$compressed" ]; then
          echo "$file already compressed"
       else
          #$nccopy -4 -d 1 -s $file ${file}.compressed
          $ncks -O -4 -L 1 $file ${file}.compressed
          if [ $? -eq 0 ]; then
             /bin/mv -f ${file}.compressed $file
          else
             echo "$file not compressed"
             /bin/rm -f ${file}.compressed
          fi
       fi
   done
   cd ${datapath}
   /bin/rm -f ${analdate}/control/*.out_grd.ww3 ${analdate}/control/*.restart.ww3
   $htar -cvf ${hsidir}/${analdate}.restart.tar ${analdate}/control ${analdate}/GFSPRS.GrbF03 ${analdate}/GFSFLX.GrbF03 
   exitstat=$?
   if [ $exitstat -ne 0 ]; then
      echo "creating restart tar file failed"
      exit $exitstat
   fi
fi
cd $datapath
/bin/rm -f ${analdate}/control/*.out_grd.ww3 ${analdate}/control/*.restart.ww3
/bin/mv -f ${analdate}/control control.save
/bin/rm -rf ${analdate}/GFS*06 ${analdate}/GFS*09 # remove restarts, keep fh=3 grib files
# compress ocean history file(s)
cd $datapath2
for file in ocn_*nc; do
   compressed=`$ncdump -sh $file | grep Deflate`
   if [ ! -z "$compressed" ]; then
      echo "$file already compressed"
   else
      #$nccopy -4 -d 1 -s $file ${file}.compressed
      $ncks -O -4 -L 1 $file ${file}.compressed
      if [ $? -eq 0 ]; then
         /bin/mv -f ${file}.compressed $file
      else
         echo "$file not compressed"
         /bin/rm -f ${file}.compressed
      fi
   fi
done
cd $datapath
htar -cvf ${hsidir}/${analdate}.history.tar ${analdate}
exitstat=$?
/bin/mv -f control.save ${analdate}/control
if [ $exitstat -ne 0 ]; then
   echo "creating history tar file failed"
   exit $exitstat
fi
exit 0
