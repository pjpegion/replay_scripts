echo "clean up files `date`"
cd $datapath2

/bin/rm -f hostfile*
/bin/rm -f fort*
/bin/rm -f *log control/PET*
/bin/rm -f ozinfo convinfo satinfo scaninfo anavinfo
/bin/rm -rf gsitmp* gfstmp* nodefile* machinefile*
/bin/rm -rf diag*iasi* diag*cris* diag*airs* *control2
echo "unwanted files removed `date`"
