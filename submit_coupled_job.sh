# sh submit_job.sh <machine>
# if using SLURM, set env var USE_SLURM
export coupled=ATM_OCN_ICE
machine=$1
USE_SLURM=1
if [ -z $USE_SLURM ]; then
   cat ${machine}_preamble config.sh > job.sh
   if [ $machine == 'wcoss' ]; then
       bsub < job.sh
   elif [ $machine == 'gaea' ]; then
       msub job.sh
   else
       qsub job.sh
   fi
else
   if [ "$coupled"  == 'ATM_OCN_ICE' ];then
      cat ${machine}_preamble_cpld_slurm config.sh > job.sh
   else
      cat ${machine}_preamble_slurm config.sh > job.sh
   fi
   sbatch job.sh
fi
