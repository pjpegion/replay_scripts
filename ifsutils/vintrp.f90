subroutine interpolate_vertical(nlons,nlats,nlevsin,nlevsout,pressin,uin,vin,tin,qin,ozin,&
                                pressout,uout,vout,tout,qout,ozout)
! f2py -c --f90flags='-fopenmp -fbacktrace' -m vint vint.f90 -lgomp (gfortran)
! f2py -c --fcompiler=intelem --opt='-xHOST -O3 -openmp -traceback'
! -m vint vint.f90 -liomp5 (intel)
! **vertical interpolation linear in log pressure**
 implicit none
 integer, intent(in) :: nlons,nlats,nlevsin,nlevsout
 real, intent(in)    :: pressout(nlevsout,nlats,nlons)
 real, intent(in),  dimension(nlevsin,nlats,nlons)  :: pressin,uin,vin,tin,qin,ozin
! u,v are winds, t is sensible temp, q is specific humidity, oz is ozone mixing
! ratio. press is pressure
 real, intent(out), dimension(nlevsout,nlats,nlons) :: uout,vout,tout,qout,ozout
! parameters for underground extrapolation of temp and humidity
 real, parameter :: dltdz=-6.5E-3*287.05/9.80665
 real, parameter :: dlpvdrt=-2.5E6/461.50
! local variables
 real logpout(nlevsout,nlats,nlons), logpin(nlevsin,nlats,nlons), dlogp
 integer i,j,kin,kout
 logical interp_flag
 logpout = -log(pressout); logpin = -log(pressin)
!$OMP PARALLEL DO DEFAULT(SHARED) &
!$OMP PRIVATE(kout,kin,i,j,dlogp,interp_flag)
 do i=1,nlons
    do j=1,nlats
       do kout=1,nlevsout
          if( logpout(kout,j,i) < logpin(1,j,i) ) then
              uout(kout,j,i) = uin(1,j,i)
              vout(kout,j,i) = vin(1,j,i)
              !tout(kout,j,i) = tin(1,j,i)
              !qout(kout,j,i) = qin(1,j,i)
              ozout(kout,j,i) = ozin(1,j,i)
! extrapolate temp below input domain using std atm lapse rate.
! extrapolate specific humidity assuming relative humidity is constant. 
              dlogp=logpout(kout,j,i)-logpin(1,j,i)
              tout(kout,j,i) = tin(1,j,i)*exp(dltdz*dlogp)
              qout(kout,j,i) = &
              qin(1,j,i)*exp(dlpvdrt*(1./tout(kout,j,i)-1./tin(1,j,i))-dlogp)
          else if ( logpout(kout,j,i) > -logpin(nlevsin,j,i) ) then
              uout(kout,j,i) = uin(nlevsin,j,i)
              vout(kout,j,i) = vin(nlevsin,j,i)
              tout(kout,j,i) = tin(nlevsin,j,i)
              qout(kout,j,i) = qin(nlevsin,j,i)
              ozout(kout,j,i) = ozin(nlevsin,j,i)
          else 
              interp_flag = .false.
              do kin=1,nlevsin-1
                 if( logpout(kout,j,i) <= logpin(kin+1,j,i) .and. logpout(kout,j,i) >= logpin(kin,j,i) ) then
                     dlogp = (logpout(kout,j,i)-logpin(kin,j,i))/(logpin(kin+1,j,i)-logpin(kin,j,i))
                     uout(kout,j,i) = uin(kin,j,i) + (uin(kin+1,j,i)-uin(kin,j,i))*dlogp
                     vout(kout,j,i) = vin(kin,j,i) + (vin(kin+1,j,i)-vin(kin,j,i))*dlogp
                     tout(kout,j,i) = tin(kin,j,i) + (tin(kin+1,j,i)-tin(kin,j,i))*dlogp
                     qout(kout,j,i) = qin(kin,j,i) + (qin(kin+1,j,i)-qin(kin,j,i))*dlogp
                     ozout(kout,j,i) = ozin(kin,j,i) + (ozin(kin+1,j,i)-ozin(kin,j,i))*dlogp
                     interp_flag = .true.
                     exit ! done, jump out of do loop
                 endif
              enddo
              ! check to see that interpolation was done.
              if (.not. interp_flag) then
                 print *,'no bounding interval found, stopping...'
                 stop
              endif
          endif
       enddo
    enddo
 enddo
!$OMP END PARALLEL DO
end subroutine interpolate_vertical
