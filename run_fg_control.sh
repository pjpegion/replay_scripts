# run high-res control first guess.
# first, clean up old first guesses.

export charnanal="control"
echo "charnanal = $charnanal"
export DATOUT="${datapath}/${analdatep1}"
echo "DATOUT = $DATOUT"
mkdir -p ${DATOUT}

export OMP_NUM_THREADS=$control_threads
export OMP_STACKSIZE=2048m
echo "OMP_NUM_THREADS = $OMP_NUM_THREADS"
export nprocs=`expr $control_proc \/ $OMP_NUM_THREADS`
echo "nprocs = $nprocs"
export mpitaskspernode=`expr $corespernode \/ $OMP_NUM_THREADS`
echo "mpitaskspernode = $mpitaskspernode"

echo "RES = $RES"
echo "LONB = ${LONB}"
echo "LATB = ${LATB}"
echo "write_groups = $write_groups"
echo "write_tasks = $write_tasks"
echo "layout = $layout"
echo "dt_atmos = $dt_atmos"
echo "cdmbgwd = $cdmbgwd"

# turn off stochastic physics
export SKEB=0
export DO_SKEB=F
export SPPT=0
export DO_SPPT=F
export SHUM=0
export DO_SHUM=F
echo "SKEB SPPT SHUM = $SKEB $SPPT $SHUM"

if [ $cleanup_fg == 'true' ]; then
   echo "deleting existing files..."
   /bin/rm -f ${datapath2}/fv3${charnanal}_historyp_${analdate}_latlon.nc
   /bin/rm -f ${DATOUT}/sfg_${analdatep1}*${charnanal}
   /bin/rm -f ${DATOUT}/bfg_${analdatep1}*${charnanal} 
fi

export niter=1
outfiles=""
fhr=$FHMIN
while  [ $fhr -le $FHMAX ]; do
   charhr="fhr`printf %02i $fhr`"
   outfiles="${outfiles} ${datapath}/${analdatep1}/sfg_${analdatep1}_${charhr}_${charnanal} ${datapath}/${analdatep1}/bfg_${analdatep1}_${charhr}_${charnanal}"
   fhr=$((fhr+FHOUT))
done
alldone='yes'
for outfile in $outfiles; do
  if [ ! -s $outfile ]; then
    echo "${outfile} is missing"
    alldone='no'
  else
    echo "${outfile} is OK"
  fi
done
echo "${analdate} compute first guesses `date`"
while [ $alldone == 'no' ] && [ $niter -le $nitermax ]; do
    sh ${scriptsdir}/${rungfs}
    exitstat=$?
    if [ $exitstat -eq 0 ]; then
       alldone='yes'
       for outfile in $outfiles; do
         if [ ! -s $outfile ]; then
           echo "${outfile} is missing"
           alldone='no'
         else
           echo "${outfile} is OK"
         fi
       done
    else
       alldone='no'
       echo "some files missing, try again .."
       niter=$((niter+1))
       export niter=$niter
    fi
done

if [ $alldone == 'no' ]; then
    echo "Tried ${nitermax} times to run high-res control first-guess and failed: ${analdate}"
    echo "no" > ${current_logdir}/run_fg_control.log 2>&1
else
    echo "yes" > ${current_logdir}/run_fg_control.log 2>&1
fi
