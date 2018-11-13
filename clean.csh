echo "clean up files `date`"
cd $datapath2

/bin/rm -f hostfile*
/bin/rm -f fort*
/bin/rm -f *log control/PET*
/bin/rm -f ozinfo convinfo satinfo scaninfo anavinfo
/bin/rm -rf gsitmp* gfstmp* nodefile* machinefile*
echo "unwanted files removed `date`"
