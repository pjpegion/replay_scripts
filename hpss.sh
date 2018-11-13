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
exit $exitstat
