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
   htar=`which htar`
   hsi=`which hsi`
fi
nccompress=/home/Jeffrey.S.Whitaker/.local/bin/nccompress

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
find -type l -delete # delete symlinks and core files

$hsi mkdir -p ${hsidir}

# archive restarts only at 06Z (for 00Z 'analysis' time)
if [ $HH == '06' ]; then
   cd ${datapath2}/control/INPUT
   # compress restart files.
   if [ -f $nccompress ]; then
      $nccompress -d 1 -o -pa -m 50 *.nc
   else
      echo "nccompress not found, not compressing restarts"
   fi
   cd ${datapath}
   /bin/rm -f ${analdate}/control/INPUT/core.* ${analdate}/control/core.*
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
/bin/mv -f ${analdate}/control control.save # move directory out of the way
/bin/rm -rf ${analdate}/GFS*06 ${analdate}/GFS*09 # remove restarts, keep fh=3 grib files
cd $datapath2
# compress ocean history files
if [ -f $nccompress ]; then
   $nccompress -d 1 -o -pa -m 50 ocn_*nc
else
   echo "nccompress not found, not compressing ocn_*nc"
fi
cd $datapath
/bin/rm -f ${analdate}/core.*
htar -cvf ${hsidir}/${analdate}.history.tar ${analdate}
exitstat=$?
/bin/mv -f control.save ${analdate}/control # move directory back
if [ $exitstat -ne 0 ]; then
   echo "creating history tar file failed"
   exit $exitstat
fi
exit 0
