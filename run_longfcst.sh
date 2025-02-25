# run high-res control first guess.
# first, clean up old long fcst.

#export analdate=2016010106 # restart file at analdatem3
# substringing to get yr, mon, day, hr info
export yr=`echo $analdate | cut -c1-4`
export mon=`echo $analdate | cut -c5-6`
export day=`echo $analdate | cut -c7-8`
export hr=`echo $analdate | cut -c9-10`
export ANALHR=$hr
# environment analdate
export datapath2="${datapath}/${analdate}/"

# previous analysis time.
FHOFFSET=`expr $ANALINC \/ 2`
export analdatem1=`${incdate} $analdate -$ANALINC`
# next analysis time.
export analdatep1=`${incdate} $analdate $ANALINC`
# beginning of current assimilation window
export analdatem3=`${incdate} $analdate -$FHOFFSET`
# beginning of next assimilation window
export analdatep1m3=`${incdate} $analdate $FHOFFSET`
export hrp1=`echo $analdatep1 | cut -c9-10`
export hrm1=`echo $analdatem1 | cut -c9-10`
export hr=`echo $analdate | cut -c9-10`
export datapathp1="${datapath}/${analdatep1}/"
export datapathm1="${datapath}/${analdatem1}/"
export CDATE=$analdate
export save_hpss="true"
export WRITE_DOPOST=".true."
export DIAG_TABLE=${scriptsdir}/diag_table_coupled_long

export charnanal="control"
echo "charnanal = $charnanal"
export DATOUT="${datapath}/${analdatem1}/longfcst"
echo "DATOUT = $DATOUT"
mkdir -p ${DATOUT}
# output interval and forecast length
export FHMAX=243 
export FHMIN=6
export FHOUT=6
# save only these
export FHMAX_LONG=240  
export FHMIN_LONG=24
export FHOUT_LONG=24

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
   /bin/rm -f ${DATOUT}/sfg_${analdatem1}*${charnanal}
   /bin/rm -f ${DATOUT}/bfg_${analdatem1}*${charnanal} 
fi
export current_logdir=$DATOUT

outfiles=""
fhr=$FHMIN
while  [ $fhr -le $FHMAX ]; do
   charhr="fhr`printf %02i $fhr`"
   outfiles="${outfiles} ${DATOUT}/sfg_${analdatem1}_${charhr}_${charnanal} ${DATOUT}/bfg_${analdatem1}_${charhr}_${charnanal}"
   fhr=$((fhr+FHOUT))
done

echo "${analdate} compute long fcst `date`"
echo "DATOUT=$DATOUT"
sh ${scriptsdir}/run_coupled.sh > ${DATOUT}/run_longfcst.log 2>&1

alldone="yes"
for outfile in $outfiles; do
  if [ ! -s $outfile ]; then
    echo "${outfile} is missing"
    alldone="no"
  fi
done

# archive long forecast to HPSS
if [ $save_hpss == 'true' ]; then
   cat ${machine}_preamble_hpss_slurm hpss_longfcst.sh > job_hpss_longfcst.sh
   echo "submitting job_hpss_longfcst.sh ..."
   sbatch job_hpss_longfcst.sh
fi

if [ $alldone == "yes" ]; then
   echo "all done"
fi
