#!/bin/sh
cd $scriptsdir
#source ./module-setup.sh
#module use $( pwd -P )
#module purge
#module load modules.calc_inc
cd ${datapath2}/${charnanal}/INPUT
${execdir}/calc_ocean_increments_from_ORAS5 $analdate $datapath2 $ocnanaldir ${iau_forcing_factor_ocn}
if [ $? -ne 0 ]; then
   exit 1
fi
