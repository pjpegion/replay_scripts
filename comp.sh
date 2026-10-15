#!/bin/bash
## on hera load module files in config.sh then
module purge
module use -a /scratch3/BMC/ufs-artic/Philip.Pegion/ufs-weather-model.SFS_replay/modulefiles/
module load ufs_ursa.intelllvm.lua
module load ncio/1.1.2

#ifx -g -O0 -fno-omit-frame-pointer -C -O -g -traceback -o exec_ursa/calc_increment_ncio.x -I${NCIO_INC} -I${netcdf_c_ROOT}/include \
#calc_increment_ncio.f90 ${NCIO_LIB} ${W3EMC_LIB4} -L${netcdf_fortran_ROOT}/lib -lnetcdff \
#-L${netcdf_c_ROOT}/lib -lnetcdf -L${hdf5_ROOT}/lib -lhdf5_hl -lhdf5 -L${zlib_ROOT}/lib -lz
ifx -g -O0 -fno-omit-frame-pointer -C -O -traceback -o exec_ursa/calc_increment_ncio.x calc_increment_ncio.f90
