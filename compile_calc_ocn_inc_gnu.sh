compiler=ifx
machine=ursa_gnu
mkdir exec_${machine}

#module purge
#module use -a /scratch3/BMC/ufs-artic/Philip.Pegion/ufs-weather-model.SFS_replay/modulefiles/
#module load ufs_ursa.intelllvm.lua
#module load ncio/1.1.2

#${compiler} -traceback -O2 -o exec_${machine}/calc_ocean_increments_from_GLORe -I${netcdf_c_ROOT}/include calc_ocean_increments_from_GLORe.F90 -L${netcdf_fortran_ROOT}/lib  -lnetcdff -L${netcdf_c_ROOT}/lib -lnetcdf  -L${hdf5_ROOT}/lib  -lhdf5_hl -lhdf5 -L${zlib_ROOT}/lib -lz
gfortran -ffree-line-length-none -fbacktrace -fcheck=bounds -O0 -g -o exec_${machine}/calc_ocean_increments_from_GLORe -I${netcdf_fortran_ROOT}/include calc_ocean_increments_from_GLORe.F90 -L${netcdf_fortran_ROOT}/lib -lnetcdff -L${netcdf_c_ROOT}/lib -lnetcdf -L${hdf5_ROOT}/lib -lhdf5_hl -lhdf5 -L${zlib_ROOT}/lib -lz
exit
