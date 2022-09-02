import f90nml
import sys
nml1 = f90nml.read(open(sys.argv[1]))
nml2 = f90nml.read(open(sys.argv[2]))
block = 'gfs_physics_nml'
#block = 'fv_core_nml'
d1 = nml1[block]
d2 = nml2[block]
k1 = sorted(d1)
k2 = sorted(d2)
for k in k1:
    if k in k2:
        if d1[k] != d2[k]:
            print(k,d1[k],d2[k])
    else:
        print(k,d1[k],'--')
