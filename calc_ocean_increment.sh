#!/bin/sh
cd $scriptsdir
#source ./module-setup.sh
#module use $( pwd -P )
#module purge
#module load modules.calc_inc
cd ${datapath2}/${charnanal}/INPUT
${execdir}/calc_ocean_increments_from_ORAS5 $analdate $datapath2 $ocnanaldir
if [ $? -ne 0 ]; then
   exit 1
else
   yyyy=`echo $analdate |cut -c 1-4`
   mm=`echo $analdate |cut -c 5-6`
   dd=`echo $analdate |cut -c 7-8`
   cdo cat ${datapath2}/ocn_${yyyy}_${mm}_${dd}_07.nc ${datapath2}/ocn_${yyyy}_${mm}_${dd}_10.nc ocn_cat.nc
   cdo timmean ocn_cat.nc ${datapath2}/firstguess.SOCA.ocean.3dvar.${analdate}00000.nc
   /bin/rm -f ocn_cat.nc
   exit 0
fi
