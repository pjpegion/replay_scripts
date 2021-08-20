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
cd ${datapath}
$hsi mkdir ${hsidir}
$htar -cvf ${hsidir}/${analdatem1}_longfcst.tar ${analdatem1}/longfcst
exitstat=$?
$hsi ls -l ${hsidir}/${analdatem1}_longfcst.tar
exit $exitstat
