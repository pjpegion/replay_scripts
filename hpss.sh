# need envars:  machine, analdate, datapath2, hsidir

exitstat=0
source $MODULESHOME/init/sh
if [ $machine == "gaea" ]; then
   #module load hsi
   htar=/sw/rdtn/hpss/default/bin/htar
   hsi=/sw/rdtn/hpss/default/bin/hsi
else
   module load hpss
   htar=`which htar`
   hsi=`which hsi`
fi
#env
hsi ls -l $hsidir
hsi mkdir ${hsidir}/
cd ${datapath2}/control
find -type l -delete # delete symlinks
cd ../..
$hsi mkdir ${hsidir}
$htar -cvf ${hsidir}/${analdate}.tar ${analdate}
$hsi ls -l ${hsidir}/${analdate}.tar
#if [ $? -eq 0 ]; then
#   cd ${analdate}
#   /bin/rm -f *fg*fhr00* *fg*fhr03* *fg*fhr09* *fg*fhr06*
#   cd control/INPUT
#   /bin/rm -f *tile*nc
#fi
cd ${datapath2}
#/bin/rm -f diag*cris* diag*airs* diag*iasi* 
exit $exitstat
