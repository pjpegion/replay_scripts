#!/bin/sh
tstart=`date +%s`
charnanal='control'
cd ${datapath2}/${charnanal}/INPUT
ORES3=025
ORESA=100
ln -sf ${FIXDIR}/mom6/20250128/${ORES3}/ocean_hgrid.nc .
ln -sf ${FIXDIR}/mom6/20250128/${ORES3}/ocean_mask.nc ocean_mask_mx025.nc
ln -sf ${FIXDIR}/mom6/20250128/${ORESA}/ocean_mask.nc ocean_mask_mx100.nc
CDATE=`echo $analdate | cut -c1-8`
YYYY=`echo $analdate | cut -c1-4`
export "PGM=${execdir}/calc_ocean_increments_from_GLORe $analdate $datapath2 $ocnanaldir/${YYYY} ${iau_forcing_factor_ocn}"
$PGM
#nprocs=1 mpitaskspernode=1 ${scriptsdir}/runmpi 
if [ $? -ne 0 ]; then
   echo "calc_ocean_increment failed..."
   exit 1
else
   echo "done calculating ocean increment... `date`"
fi
tend=`date +%s`
dt=`expr $tend - $tstart`
echo "ocn_inc step took $dt seconds"
exit 0
