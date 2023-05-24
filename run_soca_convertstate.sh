#!/bin/bash
jedi_exec=$1
yaml_file=$2
echo $jedi_exec
echo $yaml_file
ls -l $jedi_exec
. /etc/profile.d/z10_spack_environment.sh
ldd $jedi_exec
ulimit -s unlimited
ulimit -v unlimited
#mpirun -np 1 --oversubscribe ${jedi_exec} ${yaml_file}
mpirun -np 1 --verbose ${jedi_exec} ${yaml_file}
