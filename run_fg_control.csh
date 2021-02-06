# run high-res control first guess.
# first, clean up old first guesses.

setenv charnanal "control"
echo "charnanal = $charnanal"
setenv DATOUT "${datapath}/${analdatep1}"
echo "DATOUT = $DATOUT"
mkdir -p ${DATOUT}
setenv VERBOSE YES

setenv OMP_NUM_THREADS $control_threads
setenv OMP_STACKSIZE 2048M   
echo "OMP_NUM_THREADS = $OMP_NUM_THREADS"
setenv nprocs `expr $control_proc \/ $OMP_NUM_THREADS`
echo "nprocs = $nprocs"
setenv mpitaskspernode `expr $corespernode \/ $OMP_NUM_THREADS`
echo "mpitaskspernode = $mpitaskspernode"

echo "RES = $RES"
echo "write_groups = $write_groups"
echo "layout = $layout"
echo "dt_atmos = $dt_atmos"
echo "nprocs = $nprocs"

if ($cleanup_fg == 'true') then
   echo "deleting existing files..."
   /bin/rm -f ${DATOUT}/sfg_${analdatep1}*${charnanal}
   /bin/rm -f ${DATOUT}/bfg_${analdatep1}*${charnanal} 
endif

setenv niter 1
set outfiles=""
set fhr=$FHMIN
while ($fhr <= $FHMAX)
   set charhr="fhr`printf %02i $fhr`"
   set outfiles = "${outfiles} ${datapath}/${analdatep1}/sfg_${analdatep1}_${charhr}_${charnanal} ${datapath}/${analdatep1}/bfg_${analdatep1}_${charhr}_${charnanal}"
   @ fhr = $fhr + $FHOUT
end
set alldone='yes'
foreach outfile ($outfiles) 
  if ( ! -s $outfile) then
    echo "${outfile} is missing"
    set alldone='no'
  else
    echo "${outfile} is OK"
  endif
end
echo "${analdate} compute first guesses `date`"
while ($alldone == 'no' && $niter <= $nitermax)
    echo "running forecast niter = $niter"
    sh ${scriptsdir}/${rungfs}
    set exitstat=$status
    if ($exitstat == 0) then
       set alldone='yes'
       foreach outfile ($outfiles) 
         if ( ! -s $outfile) then
           echo "${outfile} is missing"
           set alldone='no'
         else
           echo "${outfile} is OK"
         endif
       end
    else
       set alldone='no'
       echo "some files missing, try again .."
       @ niter = $niter + 1
       setenv niter $niter
    endif
end

if($alldone == 'no') then
    echo "Tried ${nitermax} times to run high-res control first-guess and failed: ${analdate}"
    echo "no" >&! ${current_logdir}/run_fg_control.log
    exit 1
else
    echo "yes" >&! ${current_logdir}/run_fg_control.log
    exit 0
endif
