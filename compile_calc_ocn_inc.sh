#machine=gaea
#compiler=ftn
machine=hera
compiler=mpiifort
${compiler}  -O2 -o exec_${machine}/calc_ocean_increments_from_ORAS5 -I${NETCDF}/include calc_ocean_increments_from_ORAS5.F90 -L${NETCDF}/lib  -lnetcdff -lnetcdf  -L${HDF5_ROOT}/lib  -lhdf5_hl -lhdf5 -lz
#${compiler}  -O2 -o exec_${machine}/calc_ocean_increments_from_NG-GODAS -I${NETCDF}/include calc_ocean_increments_from_NG-GODAS.F90 -L${NETCDF}/lib  -lnetcdff -lnetcdf  -L${HDF5_ROOT}/lib  -lhdf5_hl -lhdf5 -lz
