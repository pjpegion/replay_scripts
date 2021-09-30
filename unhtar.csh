#!/bin/csh
#SBATCH -q normal  
#SBATCH --clusters es
#SBATCH --partition=rdtn
#SBATCH -t 6:00:00
#SBATCH -A nggps_psd
#SBATCH -N 1    
#SBATCH -J unhtar
#SBATCH -e unhtar.err
#SBATCH -o unhtar.out
set htar=/sw/rdtn/hpss/default/bin/htar

#set date=2015120912
#set exptname=C96cpld_replay_test
#setenv hpssdir /ESRL/BMC/gsienkf/2year/whitaker/${exptname}
#cd /lustre/f2/scratch/Jeffrey.S.Whitaker/${exptname}
#$htar -xvf $hpssdir/${date}.tar

set hsi=/sw/rdtn/hpss/default/bin/hsi
set date=2015120100
set exptname=C96cpld_replay_test
setenv hpssdir /ESRL/BMC/gsienkf/2year/Philip.Pegion/1-deg_ICS
cd /lustre/f2/scratch/Jeffrey.S.Whitaker/${exptname}
$hsi get $hpssdir/cice5_model_1.00.ic.nc
$hsi get $hpssdir/ORAS5.mx100.ic.nc
