#!/bin/sh -x

# tiled data
source ./analdate.sh
YYYY=`echo $analdate | cut -c1-4`
MM=`echo $analdate | cut -c5-6`
DD=`echo $analdate | cut -c7-8`
HH=`echo $analdate | cut -c9-10`

mkdir -p $analdate/control/INPUT
cd $analdate/control/INPUT

for file in MOM.res.nc MOM.res_1.nc MOM.res_2.nc MOM.res_3.nc;do
  if [ $YYYY -eq 1993 ];then
     aws s3 cp --no-sign-request s3://noaa-ufs-gefsv13replay-pds/spinup/${YYYY}/${MM}/${analdate}/${file} .
  else
     aws s3 cp --no-sign-request s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${analdate}/${file} .
  fi
done
#cd ..
#aws s3 cp --no-sign-request s3://noaa-ufs-gefsv13replay-pds/${YYYY}/${MM}/${analdate}/iced.${YYYY}-${MM}-${DD}-10800.nc cice5_model_0.25.ic.nc
