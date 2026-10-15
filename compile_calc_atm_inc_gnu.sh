#!/bin/bash


## on hera load module files in config.sh then
## module load zlib/1.2.11
## module load ncio/1.1.2

#NETCDF=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/netcdf-fortran-4.6.1-xrcdtrj
#NETCDFC=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/netcdf-c-4.9.2-ec5aufq/
#ZLIB_LIBRARIES=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/zlib-1.2.13-gcjencl/lib
#mpiifort -C -O -traceback -o exec_hera/calc_increment_ncio.x -O3 -I${NCIO_INC} -I${NETCDF}/include \
#calc_increment_ncio.f90 ${NCIO_LIB} ${W3EMC_LIB4} -L${NETCDF}/lib -lnetcdff \
#-lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz
gfortran -fcheck=all -O3 -g -o exec_hera/calc_increment_ncio.x -O3 -I${ncio_ROOT}/include -I${netcdf_fortran_ROOT}/include \
calc_increment_ncio.f90 ${NCIO_LIB} ${W3EMC_LIB4} -L${netcdf_fortran_ROOT}/lib -lnetcdff \
-L${netcdf_c_ROOT}/lib -lnetcdf -L${HDF5}/lib -lhdf5_hl -lhdf5 -L${zlib_ROOT}/lib -lz
#mpiifort -O3 -o exec_hera/calc_increment_ncio_tst.x -O3 -I${NCIO_INC} -I${NETCDF}/include calc_increment_ncio.f90 -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf  ${NCIO_LIB}
