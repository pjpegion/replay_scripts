# replay_scripts
scripts to replay UFS to ERA-5 and ORAS5 analyses

* `config.sh` is the main driver script.  It sets parameters (via env variables) and then
  runs `main.sh`.  It can be submitted via `> sh submit_coupled_job.sh <machine_name>`  where
  `<machine_name>` must be hera, orion or gaea.  Executables for each platform live
  in `exec_<machine_name>` (except for the model executable `ufs_coupled.exe` which must be copied into
  the `exex_<machine_name>` directory by the user.  
  All scripts and executables live in basedir/scripts/exptname (basedir and exptname set in config.sh).
  Data generated from replay cycle lives in basedir/exptname.

* the physics suite is specified via the `SUITE` env in `config.sh`. `${SUITE}.nml`, `field_tagble_${SUITE}`
  must exist in this (the scripts) directory. The nml file is templated and some variables are
  substituted via sed in the model run script (`run_coupled.sh`) based on env vars set in `config.sh`

* main.sh performs the replay cycle.  This includes
  1)  running the GSI observer to compute the fit of the predictor segment to obs
      (requires prepbbufr data from data directory specified as obs_datapath in config.sh)
       Uses run_gsiobserver.sh which calls run_gsi_4densvar.sh.
  2)  Run the corrector segment and the predictor segment for the next cycle (using
      run_fg_control.sh which calls run_coupled.sh).  Model forecast data is written out
      in netcdf files of the form sfg_YYYYYMMDDHH_fhr##_control, where YYYYMMDDHH is the 
      center of the current window (corrector segment), and ## is fhr forecast hour
      relative to YYYYMMDDHH.  These files are written to basedir/exptname/YYYYMMDHHnext, where
      YYYYMMDDHHnext is YYYYMMDDH + 6hours.
      run_coupled.sh runs utilities to compute analysis increments
      force the model using ERA5 analysis data in replayanaldir and ORAS5 analyses
      in ocnanaldir.
  3)  clean.sh removes uneeded files, and hpss.sh backs up remaining data to HPSS in 
      directory specified by hsidir.

Setting up a new run:
   1) create an experiement directory, which is $datadir/$exptname in config.sh
   2) populate analdate.sh and fg_only.sh files
      example for a warm start on Sept 1 2019:
      ```
      > cat analdate.txt
      export analdate=2019090100
      export analdate_end=2019100100
      > cat fg_only.sh
      export fg_only=false
      export cold_start=false
      ```
   3) untar an archived replay tar file for 2019090100 into this directory, or see Phil and Jeff
      to set up a cold start (which will require setting fg_only=T and cold_start=T in fg_only.sh). 

Slurm preamble templates (`<machine_name>_cpld_preamble_slurm` and `<machine_name>_hpss_preamble_slurm`)
will need to be updated for the user's project. Similarly the hsidir env var in config.sh will also need 
to be updated. On orion, hpss archiving is not done.


To run uncoupled (ATM only):
1) set `coupled=NO` in config.sh
2) model executable should be named `fv3_atm.exe`.
3) submit with `submit_job.sh` instead of `submit_coupled_job.sh` (uses `<machine>_preamble_slurm`
   instead of `<machine>_cpld_preamble_slurm`).

To run the snow DA: 
1) set do_snowDA='true' in config.sh 
2) run git submodule update --init 
3) cd land-DA_update, follow readme instructions to install 
