# run high-res control first guess.
# first, clean up old first guesses.

if ($machine == 'theia') then
   module purge
   module load intel/15.1.133
   module load impi/5.1.1.109
   module load netcdf/4.3.0
   module load hdf5
   module load pnetcdf
   module load wgrib
   module load nco/4.6.0
   module use /scratch4/NCEPDEV/nems/noscrub/emc.nemspara/soft/modulefiles
   module load esmf/7.1.0rp1bs01
   module load slurm
   setenv WGRIB `which wgrib`
   module list
else if ($machine == 'wcoss') then
   module load grib_util/1.0.3
   module load nco-gnu-sandybridge
else ($machine == 'gaea') then
   module load nco/4.6.4
   module load wgrib
   setenv WGRIB `which wgrib`
endif

setenv charnanal "control"
setenv charnanal2 "control2"
echo "charnanal = $charnanal"
setenv DATOUT "${datapath}/${analdatep1}"
echo "DATOUT = $DATOUT"
mkdir -p ${DATOUT}

setenv OMP_NUM_THREADS $control_threads
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
    if ($niter == 1) then
       sh ${scriptsdir}/${rungfs}
       set exitstat=$status
    else
       sh ${scriptsdir}/${rungfs}
       set exitstat=$status
    endif
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
