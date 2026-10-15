#!/bin/bash


## on hera load module files in config.sh then
## module load zlib/1.2.13
## module load ncio/1.1.2

#NETCDF=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/netcdf-fortran-4.6.1-xrcdtrj
#NETCDFC=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/netcdf-c-4.9.2-ec5aufq/
#ZLIB_LIBRARIES=/contrib/spack-stack/spack-stack-1.6.0/envs/gnu-fms-2024.01/install/gcc/13.3.0/zlib-1.2.13-gcjencl/lib
mpiifort -O -traceback -o exec_hera/calc_increment_ncio.x -O3 -I${NCIO_INC} -I${NETCDF}/include \
calc_increment_ncio.f90 ${NCIO_LIB} ${W3EMC_LIB4} -L${NETCDF}/lib -lnetcdff \
-lnetcdf -L${HDF5_LIBRARIES} -lhdf5_hl -lhdf5 -L${ZLIB_LIBRARIES} -lz
#mpiifort -O3 -o exec_hera/calc_increment_ncio_tst.x -O3 -I${NCIO_INC} -I${NETCDF}/include calc_increment_ncio.f90 -L${NETCDF}/lib -lnetcdff -L${NETCDFC}/lib -lnetcdf  ${NCIO_LIB}
