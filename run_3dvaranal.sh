#!/bin/sh
# do hybrid analysis.
echo "Time starting run_3dvaranal `date` "
tstart=`date +%s`

export iaufhrs="6"
export iau_delthrs="-1" # iau_delthrs < 0 turns IAU off
export CO2DIR=$fixgsi
export beta1_inv=1.0
export readin_beta=.false.

export SIGANL03=${datapath2}/sanl_${analdate}_fhr03_${charnanal}
export SIGANL04=${datapath2}/sanl_${analdate}_fhr04_${charnanal}
export SIGANL05=${datapath2}/sanl_${analdate}_fhr05_${charnanal}
export SIGANL06=${datapath2}/sanl_${analdate}_fhr06_${charnanal}
export SIGANL07=${datapath2}/sanl_${analdate}_fhr07_${charnanal}
export SIGANL08=${datapath2}/sanl_${analdate}_fhr08_${charnanal}
export SIGANL09=${datapath2}/sanl_${analdate}_fhr09_${charnanal}
export BIASO=${datapath2}/${PREINP}abias 
export BIASO_PC=${datapath2}/${PREINP}abias_pc 
export SATANGO=${datapath2}/${PREINP}satang
export DTFANL=${datapath2}/${PREINP}dtfanl.nc

if [ $cleanup_observer == 'true' ]; then
   /bin/rm -f ${BIASO}
   /bin/rm -f ${datapath2}/diag*${charnanal2}*nc4
fi

niter=1
alldone='no'
if [ -s $BIASO ]; then
   alldone="yes"
fi 

while [ $alldone == "no" ] && [ $niter -le $nitermax ]; do

export JCAP_A=$JCAP
export JCAP_B=$JCAP
#if [ $hybgain == 'true' ] || [ $controlfcst == "false" ] || [ $replay_controlfcst == "true" ]; then
#  export JCAP_B=$JCAP # ens mean background
#else
#  export JCAP_B=$JCAP_CTL # high res control background
#fi
export HXONLY='NO'
export VERBOSE=YES  
export OMP_NUM_THREADS=$gsi_control_threads
export OMP_STACKSIZE=2048M
#cores=`python -c "print (${NODES} - 1) * ${corespernode}"`
export nprocs=`expr $nprocs_gsi \/ $OMP_NUM_THREADS`
export mpitaskspernode=`expr $corespernode \/ $OMP_NUM_THREADS`
export mpitaskspernode=`expr $mpitaskspernode \/ 2`
echo "running with $OMP_NUM_THREADS threads ..."

export YYYYMMDD=`echo $analdatem1 | cut -c1-8`
export HH=`echo $analdatem1 | cut -c9-10`
if [ -z $biascorrdir ]; then # cycled bias correction files
    export GBIAS=${datapathm1}/${PREINPm1}abias
    export GBIAS_PC=${datapathm1}/${PREINPm1}abias_pc
    export GBIASAIR=${datapathm1}/${PREINPm1}abias_air
    export ABIAS=${datapath2}/${PREINP}abias
else # externally specified bias correction files.
    export GBIAS=${biascorrdir}/${analdate}//${PREINP}abias
    export GBIAS_PC=${biascorrdir}/${analdate}//${PREINP}abias_pc
    export GBIASAIR=${biascorrdir}/${analdate}//${PREINP}abias_air
    export GBIAS=${biascorrdir}/gdas.${YYYYMMDD}/${HH}//${PREINPm1}abias
    export GBIAS_PC=${biascorrdir}/gdas.${YYYYMMDD}/${HH}/${PREINPm1}abias_pc
    export GBIASAIR=${biascorrdir}/gdas.${YYYYMMDD}/${HH}/${PREINPm1}abias_air
    export ABIAS=${biascorrdir}/${analdate}//${PREINP}abias
fi
export GSATANG=$fixgsi/global_satangbias.txt # not used, but needs to exist

export tmpdir=$datapath2/hybridtmp$$
if [ "$cold_start_bias" == "true" ]; then
    export lread_obs_save=".true."
    export lread_obs_skip=".false."
    echo "${analdate} compute gsi observer to cold start bias correction"
    export HXONLY='YES'
    /bin/rm -rf $tmpdir
    mkdir -p $tmpdir
    tend=`date +%s`
    dt=`expr $tend - $tstart`
    echo "gsi pre step took $dt seconds"
    tstart1=`date +%s`
    sh ${scriptsdir}/${rungsi}
    tend=`date +%s`
    dt=`expr $tend - $tstart1`
    tstart2=`date +%s`
    echo "gsi run step took $dt seconds"
    /bin/rm -rf $tmpdir
    if [  ! -s ${datapath2}/diag_conv_uv_ges.${analdate}_${charnanal2}.nc4 ]; then
       echo "gsi observer step failed"
       exit 1
    fi
fi
export lread_obs_save=".false."
export lread_obs_skip=".false."
export HXONLY 'NO'
if [ -s $BIASO ]; then
  echo "gsi hybrid already completed"
  echo "yes" > ${current_logdir}/run_gsi_observer.log
  exit 0
fi
echo "${analdate} compute gsi hybrid analysis increment `date`"
/bin/rm -rf $tmpdir
mkdir -p $tmpdir
/bin/cp -f $datapath2/hybens_info $tmpdir
sh ${scriptsdir}/${rungsi}
status=$?
if [ "$cold_start_bias" == "true" ]; then
  export GBIAS=${datapath2}/${PREINP}abias
  export GBIAS_PC=${datapath2}/${PREINP}abias_pc
  export GBIASAIR=${datapath2}/${PREINP}abias_air
  echo "${analdate} re-compute gsi hybrid analysis increment `date`"
  sh ${scriptsdir}/${rungsi}
  status=$?
fi
if [ $status -ne 0 ]; then
  echo "gsi hybrid analysis did not complete sucessfully"
  exitstat=1
else
  if [ ! -s $BIASO ]; then
    echo "gsi hybrid analysis did not complete sucessfully"
    exitstat=1
  else
    echo "gsi hybrid completed sucessfully"
    exitstat=0
  fi
fi

if [ $exitstat -eq 0 ]; then
   alldone='yes'
else
   echo "some files missing, try again .."
   niter=$((niter+1))
fi
done

if [ $alldone == 'no' ]; then
    echo "Tried ${nitermax} times and to do gsi hybrid analysis and failed"
    echo "no" > ${current_logdir}/run_gsi_observer.log 2>&1
else
    echo "yes" > ${current_logdir}/run_gsi_observer.log 2>&1
    /bin/rm -rf $tmpdir
fi
tend=`date +%s`
dt=`expr $tend - $tstart2`
echo "gsi post step took $dt seconds"
