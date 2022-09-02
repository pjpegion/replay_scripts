#!/bin/sh
cd $scriptsdir
#source ./module-setup.sh
#module use $( pwd -P )
#module purge
#module load modules.calc_inc
# need to make sure incdate is in your path
analdatep1=`incdate $analdate 1`
analdatem2=`incdate $analdate -2`
analdatem5=`incdate $analdate -5`
cd ${datapath2}/${charnanal}/INPUT
${execdir}/calc_ocean_increments_from_NG-GODAS $analdate $analdatem2 $analdatep1 $datapath2 $ocnanaldir ${iau_forcing_factor_ocn}
if [ $? -ne 0 ]; then
   exit 1
else
   yyyym2=`echo $analdatem2 |cut -c 1-4`
   mmm2=`echo $analdatem2 |cut -c 5-6`
   ddm2=`echo $analdatem2 |cut -c 7-8`
   hhm2=`echo $analdatem2 |cut -c 8-10`
   yyyym5=`echo $analdatem5 |cut -c 1-4`
   mmm5=`echo $analdatem5 |cut -c 5-6`
   ddm5=`echo $analdatem5 |cut -c 7-8`
   hhm5=`echo $analdatem5 |cut -c 8-10`
   cdo cat ${datapath2}/ocn_${yyyym5}_${mmm5}_${dd}_${hhm5}.nc ${datapath2}/ocn_${yyyym2}_${mmm2}_${ddm2}_${hhm2}.nc ocn_cat.nc
   cdo timmean ocn_cat.nc ${datapath2}/firstguess.SOCA.ocean.3dvar.${analdate}00000.nc
   /bin/rm -f ocn_cat.nc
   exit 0
fi
