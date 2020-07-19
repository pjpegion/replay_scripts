import matplotlib
matplotlib.use('Agg')
import matplotlib.pyplot as plt
import numpy as np
import sys
filename1t = sys.argv[1]
filename1q = sys.argv[2]
filename2t = sys.argv[3]
filename2q = sys.argv[4]
data1t = np.loadtxt(filename1t)
data1q = np.loadtxt(filename1q)
data2t = np.loadtxt(filename2t)
data2q = np.loadtxt(filename2q)
fig = plt.figure(figsize=(11,6))
plt.subplot(1,2,1)
plt.plot(data1t[:,1],data1t[:,0],color='r',linewidth=2,marker=None,label='control')
plt.plot(data2t[:,1],data2t[:,0],color='b',linewidth=2,marker=None,label='expt1')
plt.ylabel('model level')
plt.title('mean T increment (GFS-IFS)')
plt.xlabel('K')
plt.axis('tight')
plt.xlim(-0.25,0.25)
plt.ylim(0,100)
plt.grid(True)
plt.subplot(1,2,2)
plt.plot(data1q[:,1],data1q[:,0],color='r',linewidth=2,marker=None,label='control')
plt.plot(data2q[:,1],data2q[:,0],color='b',linewidth=2,marker=None,label='expt1')
plt.ylabel('model level')
plt.title('mean q increment (GFS-IFS)')
plt.xlabel('g/kg')
plt.axis('tight')
plt.xlim(-0.35,0.35)
plt.ylim(0,100)
plt.grid(True)
plt.legend(loc=0)
plt.savefig('test.png')
