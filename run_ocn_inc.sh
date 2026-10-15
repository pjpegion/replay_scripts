#!/bin/sh
export cold_start="false"
export iaufhrs=6
export analdate=2003040112
export machine="ursa"
export incdate=incdate
export OCNRES=mx025
export ANALINC=6
export OMP_NUM_THREADS=1
export datapath2=/scratch3/BMC/ufs-artic/Philip.Pegion/SFS_tst1_200305/${analdate}
export scriptsdir=/scratch3/BMC/ufs-artic/Philip.Pegion/scripts/SFS_tst1_200305
export execdir=${scriptsdir}/exec_ursa
#export execdir=${scriptsdir}/exec_ursa_gnu
export ocnanaldir=/scratch4/BMC/gsienkf/${USER}/replay_data/input/GLOR-E
export analfileprefix="C${RES_INC}_era5anl"
export current_logdir=$scriptsdir
export FIXDIR=/scratch3/NCEPDEV/global/role.glopara/fix/
export iau_forcing_factor_ocn=25

#export MSAN_SYMBOLIZER_PATH=$(which llvm-symbolizer)
#export MSAN_OPTIONS="print_stats=1:help=1"

sh -x ocn_inc_step.sh
