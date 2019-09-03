# need envars:  machine, analdate, datapath, hsidir

exitstat=0
source $MODULESHOME/init/sh
if [ $machine == "gaea" ]; then
   module load hsi
else
   module load hpss
fi
#env
hsi ls -l $hsidir
hsi mkdir ${hsidir}/
cd ${datapath}
htar -cvf ${hsidir}/${analdate}.tar ${analdate}
hsi ls -l ${hsidir}/${analdate}.tar
if [ $? -eq 0 ]; then
   cd ${analdate}
   /bin/rm -f *fg*fhr03* *fg*fhr09* *fg*fhr06_control
   cd control/INPUT
   /bin/rm -f *tile*nc
fi
cd ${datapath}/${analdate}
#/bin/rm -f diag*cris* diag*airs* diag*iasi* 
/bin/rm -f *fg*fhr00* 
exit $exitstat
