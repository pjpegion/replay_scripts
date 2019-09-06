# run high-res control first guess.
# first, clean up old first guesses.

setenv charnanal "control"
echo "charnanal = $charnanal"
setenv DATOUT "${datapath}/${analdatep1}"
echo "DATOUT = $DATOUT"
mkdir -p ${DATOUT}

# save netcdf unless observer will be run
if ( $replay_run_observer == "false") then
   setenv fileformat "netcdf"
else
   setenv fileformat "nemsio"
endif

setenv OMP_NUM_THREADS $control_threads
setenv OMP_STACKSIZE 256M
echo "OMP_NUM_THREADS = $OMP_NUM_THREADS"
setenv nprocs `expr $control_proc \/ $OMP_NUM_THREADS`
echo "nprocs = $nprocs"
setenv mpitaskspernode `expr $corespernode \/ $OMP_NUM_THREADS`
echo "mpitaskspernode = $mpitaskspernode"
if ( ! $?SLURM_JOB_ID && $machine == 'theia') then
   if ($OMP_NUM_THREADS == 1) then
      setenv HOSTFILE $PBS_NODEFILE
   else
      setenv HOSTFILE ${datapath2}/hostfile_control
      awk "NR%${OMP_NUM_THREADS} == 1" ${PBS_NODEFILE} >&! $HOSTFILE
   endif
   echo "HOSTFILE = $HOSTFILE"
endif

echo "RES = $RES"
echo "write_groups = $write_groups"
echo "layout = $layout"
echo "dt_atmos = $dt_atmos"
echo "fv_sg_adj = $fv_sg_adj"
echo "cdmbgwd = $cdmbgwd"
echo "nprocs = $nprocs"

# turn off stochastic physics
setenv SKEB 0
setenv SPPT 0
setenv SHUM 0
echo "SKEB SPPT SHUM = $SKEB $SPPT $SHUM"

if ($cleanup_fg == 'true') then
   echo "deleting existing files..."
   if ($fileformat == 'netcdf') then
      /bin/rm -f ${DATOUT}/sfg_${analdatep1}*${charnanal}*nc4
      /bin/rm -f ${DATOUT}/bfg_${analdatep1}*${charnanal}*nc4
   else
      /bin/rm -f ${DATOUT}/sfg_${analdatep1}*${charnanal}
      /bin/rm -f ${DATOUT}/bfg_${analdatep1}*${charnanal} 
   endif
endif

setenv niter 1
set outfiles=""
if ($fileformat == 'netcdf') then
   set charhr="fhr`printf %02i $ANALINC`"
   set outfiles = "${datapath}/${analdatep1}/sfg_${analdatep1}_${charhr}_${charnanal}.nc4 ${datapath}/${analdatep1}/bfg_${analdatep1}_${charhr}_${charnanal}.nc4"
else
   set fhr=$FHMIN
   while ($fhr <= $FHMAX)
      set charhr="fhr`printf %02i $fhr`"
      set outfiles = "${outfiles} ${datapath}/${analdatep1}/sfg_${analdatep1}_${charhr}_${charnanal} ${datapath}/${analdatep1}/bfg_${analdatep1}_${charhr}_${charnanal}"
      @ fhr = $fhr + $FHOUT
   end
endif
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
