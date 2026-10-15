#!/bin/sh
export cold_start="false"
export iaufhrs=6
export analdate=2003040106
export machine="ursa"
export incdate=incdate
export RES=192
export RES_INC=96
export ANALINC=6
export OMP_NUM_THREADS=1
export datapath2=/scratch3/BMC/ufs-artic/Philip.Pegion/SFS_replay_tst1/${analdate}
export scriptsdir=/scratch3/BMC/ufs-artic/Philip.Pegion/scripts/SFS_replay_tst1
export execdir=${scriptsdir}/exec_ursa
export replayanaldir=/scratch4/BMC/gsienkf/Philip.Pegion/replay_data/input/era5/c${RES_INC}
export analfileprefix="C${RES_INC}_era5anl"
export current_logdir=$scriptsdir

export MSAN_SYMBOLIZER_PATH=$(which llvm-symbolizer)
export MSAN_OPTIONS="print_stats=1:help=1"

sh -x atm_inc_step.sh
