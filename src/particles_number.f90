! $Id: particles_number.f90,v 1.3 2005-11-25 12:52:07 ajohan Exp $
!
!  This module takes care of everything related to internal particle number.
!
!** AUTOMATIC CPARAM.INC GENERATION ****************************
!
! Declare (for generation of cparam.inc) the number of f array
! variables and auxiliary variables added by this module
!
! MPVAR CONTRIBUTION 1
! CPARAM logical, parameter :: lparticles_number=.true.
!
!***************************************************************
module Particles_number

  use Cdata
  use Particles_cdata
  use Particles_sub

  implicit none

  include 'particles_number.h'

  real :: np_tilde0
  integer, dimension (mpar_loc) :: ineighbour
  integer, dimension (mx,my,mz) :: ishepherd
  character (len=labellen), dimension(ninit) :: initnptilde='nothing'

  integer :: idiag_nptm=0

  namelist /particles_number_init_pars/ &
      initnptilde

  namelist /particles_number_run_pars/ &
      initnptilde

  contains

!***********************************************************************
    subroutine register_particles_number()
!
!  Set up indices for access to the fp and dfp arrays.
!
!  24-nov-05/anders: adapted
!
      use Messages, only: fatal_error, cvs_id
!
      logical, save :: first=.true.
!
      if (.not. first) call fatal_error('register_particles_number: called twice','')
      first = .false.
!
      if (lroot) call cvs_id( &
           "$Id: particles_number.f90,v 1.3 2005-11-25 12:52:07 ajohan Exp $")
!
!  Index for particle internal number.
!
      inptilde=npvar+1
!
!  Increase npvar accordingly.
!
      npvar=npvar+1
!
!  Check that the fp and dfp arrays are big enough.
!
      if (npvar > mpvar) then
        if (lroot) write(0,*) 'npvar = ', npvar, ', mpvar = ', mpvar
        call fatal_error('register_particles: npvar > mpvar','')
      endif
!
    endsubroutine register_particles_number
!***********************************************************************
    subroutine initialize_particles_number(lstarting)
!
!  Perform any post-parameter-read initialization i.e. calculate derived
!  parameters.
!
!  24-nov-05/anders: adapted
!
      logical :: lstarting
!
      np_tilde0=rhop_tilde/mp_tilde
      if (lroot) print*, 'initialize_particles_number: '// &
          'number density per particle np_tilde0=', np_tilde0
!
    endsubroutine initialize_particles_number
!***********************************************************************
    subroutine init_particles_number(f,fp)
!
!  Initial internal particle number.
!
!  24-nov-05/anders: adapted
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mpar_loc,mpvar) :: fp
!
      integer :: j
!
      do j=1,ninit
        
        select case(initnptilde(j))

        case('nothing')
          if (lroot.and.j==1) print*, 'init_particles_number: nothing'

        case('constant')
          if (lroot) then
            print*, 'init_particles_number: constant internal number'
            print*, 'init_particles_number: np_tilde0=', np_tilde0
          endif
          fp(1:npar_loc,inptilde)=np_tilde0

        endselect

      enddo
!
    endsubroutine init_particles_number
!***********************************************************************
    subroutine dnptilde_dt(f,df,fp,dfp)
!
!  Evolution of internal particle number.
!
!  24-oct-05/anders: coded
!
      use Messages, only: fatal_error
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mx,my,mz,mvar) :: df
      real, dimension (mpar_loc,mpvar) :: fp, dfp
!
      real :: deltavp, sigma_jk, deltanptilde, cc, rho
      integer :: j, k, l, m, n
      logical :: lheader, lfirstcall=.true.
!
      intent (in) :: f, fp
      intent (out) :: dfp
!
!  Print out header information in first time step.
!
      lheader=lfirstcall .and. lroot
!
!  Identify module and boundary conditions.
!
      if (lheader) print*,'dnptilde_dt: Calculate dnptilde_dt'
!
!  Store information about which grid point each particle is closest to.
!
      call nearest_gridpoint_map(f,fp)
!
!  Fragmentation inside each superparticle.
!      
      do l=l1,l2; do m=m1,m2; do n=n1,n2
!  Get index number of shepherd particle at grid point.
        k=ishepherd(l,m,n)
        if (ip<=6.and.lroot) then
          print*, 'dnptilde_dt: l, m, n=', l, m, n
          print*, 'dnptilde_dt: ishepherd, np(l,m,n)=', k, f(l,m,n,inp)
          print*, 'dnptilde_dt: x(l), y(m), z(n)  =', x(l), y(m), z(n)
        endif
!  Only continue of the shepherd particle has a neighbour.
        do while (ineighbour(k)/=0)
          j=k
!  Consider neighbours one at a time.
          do while (ineighbour(j)/=0)
            j=ineighbour(j)
            if (ip<=6.and.lroot) then
              print*, 'dnptilde_dt: fragmentation between ', k, 'and', j
            endif
!  Collision speed.
            deltavp=sqrt( &
                (fp(k,ivpx)-fp(j,ivpx))**2 + &
                (fp(k,ivpy)-fp(j,ivpy))**2 + &
                (fp(k,ivpz)-fp(j,ivpz))**2 )
!  Collision cross section.
            sigma_jk=pi*(fp(j,iap)+fp(k,iap))**2
!  Smoluchowski equation for fragmentation.
            deltanptilde = -sigma_jk*fp(j,inptilde)*fp(k,inptilde)*deltavp
!  Colliding superparticles lose equal number of internal particles.            
            dfp(j,inptilde) = dfp(j,inptilde) + deltanptilde
            dfp(k,inptilde) = dfp(k,inptilde) + deltanptilde
!  Put fragments in small grains.
            if (lpscalar_nolog) then
              rho=f(l,m,n,ilnrho)
              if (.not. ldensity_nolog) rho=exp(rho)
              df(l,m,n,ilncc) = df(l,m,n,ilncc) - &
                  1/rho*4/3.*pi*rhops* &
                  (fp(j,iap)**3+fp(k,iap)**3)*deltanptilde
            else
              rho=f(l,m,n,ilnrho)
              if (.not. ldensity_nolog) rho=exp(rho)
              cc=f(l,m,n,ilncc)
              if (.not. lpscalar_nolog) cc=exp(cc)
              df(l,m,n,ilncc) = df(l,m,n,ilncc) - &
                  1/cc*1/rho*4/3.*pi*rhops* &
                  (fp(j,iap)**3+fp(k,iap)**3)*deltanptilde
            endif
          enddo
          k=ineighbour(k)
        enddo
      enddo; enddo; enddo
!
!  Diagnostic output
!
      if (ldiagnos) then
        if (idiag_nptm/=0) call sum_par_name(fp(1:npar_loc,inptilde),idiag_nptm)
      endif
!
      lfirstcall=.false.
!
    endsubroutine dnptilde_dt
!***********************************************************************
    subroutine nearest_gridpoint_map(f,fp)
!
!  Attach information about present particles to each grid point.
!
!  24-oct-05/anders: coded
!
      use Messages, only: fatal_error
!
      real, dimension (mx,my,mz,mvar+maux) :: f
      real, dimension (mpar_loc,mpvar) :: fp
!
      integer :: k, ix0, iy0, iz0
!
      intent (in) :: fp
!
      f(l1:l2,m1:m2,n1:n2,inp)=0.0
      ineighbour=0
      ishepherd=0
!
      do k=1,npar_loc
        call find_closest_gridpoint(fp(k,ixp:izp),ix0,iy0,iz0)
        f(ix0,iy0,iz0,inp)=f(ix0,iy0,iz0,inp)+1
        ineighbour(k)=ishepherd(ix0,iy0,iz0)
        ishepherd(ix0,iy0,iz0)=k
      enddo
!
    endsubroutine nearest_gridpoint_map
!***********************************************************************
    subroutine get_nptilde(fp,k,np_tilde)
!
!  Get internal particle number.
!
!  25-oct-05/anders: coded
!
      use Messages, only: fatal_error
!
      real, dimension (mpar_loc,mpvar) :: fp
      real :: np_tilde
      integer :: k
!
      intent (in)  :: fp, k
      intent (out) :: np_tilde
!
      if (k<1 .or. k>mpar_loc) then
        if (lroot) print*, 'get_nptilde: k out of range, k=', k
        call fatal_error('get_nptilde','')
      endif
!
      np_tilde=fp(k,inptilde)
!
    endsubroutine get_nptilde
!***********************************************************************
    subroutine read_particles_num_init_pars(unit,iostat)
!    
      integer, intent (in) :: unit
      integer, intent (inout), optional :: iostat
!
      if (present(iostat)) then
        read(unit,NML=particles_number_init_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=particles_number_init_pars,ERR=99)
      endif
!
99    return
!
    endsubroutine read_particles_num_init_pars
!***********************************************************************
    subroutine write_particles_num_init_pars(unit)
!    
      integer, intent (in) :: unit
!
      write(unit,NML=particles_number_init_pars)
!
    endsubroutine write_particles_num_init_pars
!***********************************************************************
    subroutine read_particles_num_run_pars(unit,iostat)
!    
      integer, intent (in) :: unit
      integer, intent (inout), optional :: iostat
!
      if (present(iostat)) then
        read(unit,NML=particles_number_run_pars,ERR=99, IOSTAT=iostat)
      else
        read(unit,NML=particles_number_run_pars,ERR=99)
      endif
!
99    return
!
    endsubroutine read_particles_num_run_pars
!***********************************************************************
    subroutine write_particles_num_run_pars(unit)
!    
      integer, intent (in) :: unit
!
      write(unit,NML=particles_number_run_pars)
!
    endsubroutine write_particles_num_run_pars
!***********************************************************************
    subroutine rprint_particles_number(lreset,lwrite)
!   
!  Read and register print parameters relevant for internal particle number.
!
!  24-aug-05/anders: adapted
!
      use Cdata
      use Sub, only: parse_name
!
      logical :: lreset
      logical, optional :: lwrite
!
      integer :: iname
      logical :: lwr
!
!  Write information to index.pro
! 
      lwr = .false.
      if (present(lwrite)) lwr=lwrite
      if (lwr) write(3,*) 'inptilde=', inptilde
!
!  Reset everything in case of reset
!
      if (lreset) then
        idiag_nptm=0
      endif
!
!  Run through all possible names that may be listed in print.in
!
      if (lroot.and.ip<14) &
          print*, 'rprint_particles_number: run through parse list'
      do iname=1,nname
        call parse_name(iname,cname(iname),cform(iname),'nptm',idiag_nptm)
      enddo
!
    endsubroutine rprint_particles_number
!***********************************************************************

endmodule Particles_number
