#!/usr/bin/env python
import numpy as np
import sys
if len(sys.argv) != 3:
   print('usage geticstep.py <icdate> <timestep in seconds>')
   sys.exit()

analdate=sys.argv[1]
dt=np.int(sys.argv[2])
yyyy=analdate[0:4]
mm=analdate[4:6]
dd=analdate[6:8]
time0=np.datetime64('%s-01-01' %yyyy)
time1=np.datetime64('%s-%s-%s' %(yyyy,mm,dd))
dt=np.int((time1-time0)/ np.timedelta64(dt,'s'))
print(dt)
