# need envars:  machine, analdate, datapath, hsidir
echo "starting archiving at "`date`
module load aws-utils/latest
nccompress=/lustre/Philip.Pegion/bin/nccompress
#module load intelpython/2022.1.2


YYYY=`echo $analdate | cut -c1-4`
MM=`echo $analdate | cut -c5-6`
DD=`echo $analdate | cut -c7-8`
HH=`echo $analdate | cut -c9-10`
#python is_monday_or_thursday.py $analdate > ${datapath}/Mon_or_Thurs_${analdate}.txt
#save_rest=`cat ${datapath}/Mon_or_Thurs_${analdate}.txt`

cd $datapath
# move increment file up 2 directories to save with diagnostics
/bin/mv ${analdate}/control/INPUT/fv3_increment6.nc ${analdate}
if [ $HH -eq 12 ]; then
   /bin/mv ${analdate}/control/INPUT/mom_increment6.nc ${analdate}
fi
#if [ $save_rest == 'YES' ];then
if [ $HH == '06' ];then
   tar -cvf ${analdate}.restart.tar ${analdate}/control ${analdate}/GFS*
   if [ $? -ne 0 ];then
      echo "creating restart tar file failed"
   else
      /bin/rm -rf ${analdate}/control ${analdate}/GFS*
      #echo "should be removing restart files"
      gzip --fast ${analdate}.restart.tar
      if [ $? -ne 0 ];then
         echo "zipping restart tar file failed"
      else 
         aws s3 cp ${analdate}.restart.tar.gz s3://noaa-bmc-none-ca-ufs-rnr/replay/outputs/${exptname}/restarts/
         if [ $? -eq 0 ];then
            /bin/rm ${analdate}.restart.tar.gz
            touch ${analdate}.rst.ready
            aws s3 cp ${analdate}.rst.ready s3://noaa-bmc-none-ca-ufs-rnr/replay/outputs/${exptname}/transfer_log/
         else
            echo "sending restart tar file to s3 failed"
            echo "proceeding without removing tar file"
         fi
      fi
   fi
else
   echo "not an restart archiving time, just deleting old restarts"
   /bin/rm -rf ${analdate}/control ${analdate}/GFS*
   echo "shoud be removing restart files without saving them"
fi
tar -cvf ${analdate}.history.tar ${analdate}/sfg* ${analdate}/bfg* ${analdate}/ocn_${YYYY}_${MM}_${DD}_${HH}.nc ${analdate}/fv3_increment6.nc
if [ $? -ne 0 ];then
      echo "creating history tar file failed"
else
   /bin/rm  ${analdate}/sfg* ${analdate}/bfg* ${analdate}/ocn_* ${analdate}/fv3_increment6.nc
   echo "should be removing history files"
   gzip --fast ${analdate}.history.tar
   if [ $? -ne 0 ];then
      echo "zipping history tar file failed"
   else 
      aws s3 cp ${analdate}.history.tar.gz s3://noaa-bmc-none-ca-ufs-rnr/replay/outputs/${exptname}/history/${YYYY}/${MM}/
      if [ $? -eq 0 ];then
         /bin/rm ${analdate}.history.tar.gz
            touch ${analdate}.history.ready
            aws s3 cp ${analdate}.history.ready s3://noaa-bmc-none-ca-ufs-rnr/replay/outputs/${exptname}/transfer_log/
      else
         echo "sending history tar file to s3 failed"
         echo "proceeding without removing tar file"
      fi
   fi
fi

echo "finsihed archiving at "`date`
#/bin/rm ${datapth}/Mon_or_Thurs_${analdate}.txt
