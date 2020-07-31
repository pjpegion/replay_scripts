# main driver script
# single resolution hybrid using jacobian in the EnKF

# allow this script to submit other scripts on WCOSS
unsetenv LSB_SUB_RES_REQ 

source $datapath/fg_only.csh # define fg_only variable (true for cold start).
echo "nodes = $NODES"

setenv startupenv "${datapath}/analdate.csh"
source $startupenv

#------------------------------------------------------------------------
mkdir -p $datapath

echo "BaseDir: ${basedir}"
echo "DataPath: ${datapath}"

############################################################################
# Main Program

env
echo "starting the cycle"

# substringing to get yr, mon, day, hr info
setenv yr `echo $analdate | cut -c1-4`
setenv mon `echo $analdate | cut -c5-6`
setenv day `echo $analdate | cut -c7-8`
setenv hr `echo $analdate | cut -c9-10`
setenv ANALHR $hr
# set environment analdate
setenv datapath2 "${datapath}/${analdate}/"

# current analysis time.
setenv analdate $analdate
# previous analysis time.
set FHOFFSET=`expr $ANALINC \/ 2`
setenv analdatem1 `${incdate} $analdate -$ANALINC`
# next analysis time.
setenv analdatep1 `${incdate} $analdate $ANALINC`
# beginning of current assimilation window
setenv analdatem3 `${incdate} $analdate -$FHOFFSET`
# beginning of next assimilation window
setenv analdatep1m3 `${incdate} $analdate $FHOFFSET`
setenv hrp1 `echo $analdatep1 | cut -c9-10`
setenv hrm1 `echo $analdatem1 | cut -c9-10`
setenv hr `echo $analdate | cut -c9-10`
setenv datapathp1 "${datapath}/${analdatep1}/"
setenv datapathm1 "${datapath}/${analdatem1}/"
mkdir -p $datapathp1
setenv CDATE $analdate

date
echo "analdate minus 1: $analdatem1"
echo "analdate: $analdate"
echo "analdate plus 1: $analdatep1"

# make log dir for analdate
setenv current_logdir "${datapath2}/logs"
echo "Current LogDir: ${current_logdir}"
mkdir -p ${current_logdir}

setenv PREINP "${RUN}.t${hr}z."
setenv PREINP1 "${RUN}.t${hrp1}z."
setenv PREINPm1 "${RUN}.t${hrm1}z."

if ($fg_only == 'false') then
    if ($replay_run_observer == "true") then
       setenv charnanal 'control'
       setenv charnanal2 'control'
       setenv lobsdiag_forenkf '.false.'
       setenv skipcat "false"
       echo "$analdate run gsi observer with `printenv | grep charnanal` `date`"
       if ( ! $?biascorrdir ) then # 3DVar to cycle bias correction files
          sh ${scriptsdir}/run_3dvaranal.sh >&! ${current_logdir}/run_gsi_observer.out 
       else
          csh ${scriptsdir}/run_gsiobserver.csh >&! ${current_logdir}/run_gsi_observer.out 
       endif
       # once observer has completed, check log files.
       set hybrid_done=`cat ${current_logdir}/run_gsi_observer.log`
       if ($hybrid_done == 'yes') then
         echo "$analdate gsi observer completed successfully `date`"
       else
         echo "$analdate gsi observer did not complete successfully, exiting `date`"
         exit 1
       endif
    endif
endif

echo "$analdate run high-res control first guess `date`"
csh ${scriptsdir}/run_fg_control.csh  >&! ${current_logdir}/run_fg_control.out  
set control_done=`cat ${current_logdir}/run_fg_control.log`
if ($control_done == 'yes') then
  echo "$analdate high-res control first-guess completed successfully `date`"
else
  echo "$analdate high-res control did not complete successfully, exiting `date`"
  exit 1
endif

if ($fg_only == 'false') then

# cleanup
if ($do_cleanup == 'true') then
   csh ${scriptsdir}/clean.csh >&! ${current_logdir}/clean.out
endif # do_cleanup = true

cd $homedir
if ( $save_hpss == 'true' ) then
if ( ! -z $SLURM_JOB_ID ) then
   cat ${machine}_preamble_hpss_slurm hpss.sh > job_hpss.sh
else
   cat ${machine}_preamble_hpss hpss.sh > job_hpss.sh
endif
if ( ! -z $SLURM_JOB_ID )  then
   #sbatch --export=ALL job_hpss.sh
   sbatch --export=machine=${machine},analdate=${analdate},datapath2=${datapath2},hsidir=${hsidir} job_hpss.sh
else if ( $machine == 'wcoss' ) then
   bsub -env "all" < job_hpss.sh
else if ( $machine == 'gaea' ) then
   msub -V job_hpss.sh
else
   qsub -V job_hpss.sh
endif
endif

endif # skip to here if fg_only = true

echo "$analdate all done"

# next analdate: increment by $ANALINC
setenv analdate `${incdate} $analdate $ANALINC`

echo "setenv analdate ${analdate}" >! $startupenv
echo "setenv analdate_end ${analdate_end}" >> $startupenv
echo "setenv fg_only false" >! $datapath/fg_only.csh
echo "setenv cold_start false" >> $datapath/fg_only.csh

cd $homedir
echo "$analdate all done `date`"

if ( ${analdate} <= ${analdate_end}  && ${resubmit} == 'true') then
   echo "current time is $analdate"
   if ($resubmit == "true") then
      echo "resubmit script"
      echo "machine = $machine"
      if ( $?SLURM_JOB_ID ) then
         cat ${machine}_preamble_slurm config.sh >! job.sh
      else
         cat ${machine}_preamble config.sh >! job.sh
      endif
      if ( $?SLURM_JOB_ID ) then
          sbatch --export=ALL job.sh
      else if ($machine == 'wcoss') then
          bsub < job.sh
      else if ($machine == 'gaea') then
          msub job.sh
      else if ($machine == 'cori') then
          sbatch job.sh
      else
          qsub job.sh
      endif
   endif
endif

exit 0
