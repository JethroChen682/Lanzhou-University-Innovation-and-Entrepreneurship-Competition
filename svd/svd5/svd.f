cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c       This program is an example of svd analysis                         c
c            (Coded by Jincheng Wang and Jianping Li)                      c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c                       ---------NOTE-------                               c
c                          Stack Overflow                                  c
c   Compaq visual fortran 6.5:                                             c
c     Project -> settings | link | output | stack allocations              c
c     Modify 'reserve' and 'commit' value: default value 0x400000 means 4M c
c   Intel fortran + vs.net 2003:                                           c
c     Properties | link | system                                           c
c     Modify the 'stack reserve size' and 'stack commit size'              c
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      program svd_test
	implicit none
cccccccc---Parameters that you can modify---cccccccc
      integer,parameter::NY=8640
      integer,parameter::NZ=13041
      integer,parameter::NT=38
      integer,parameter::NMIN=NY
      integer,parameter::NP=10
      real,parameter::YMV=-999.0
      real,parameter::ZMV=-999.0

cccccccc---The main variables for input and output---cccccccc
      real   ::Y(NY,NT),Z(NZ,NT)
      real   ::A(NT,NP),B(NT,NP)
      real   ::cekma(NMIN)
      real   ::scfk(NP)
      real   ::cscfk(NP)
      real   ::rab(NP)
      real   ::lcovf(NP)
      real   ::rcovf(NP)
      real   ::vara(NP)
      real   ::varb(NP)
      real   ::lhomo(NY,NP),lhete(NY,NP)
      real   ::rhomo(NZ,NP),rhete(NZ,NP)

      integer::i,j,k,l,m,n

ccccccccc---Main program---cccccccc
!----Read the left field----!
      open(unit=1,file=
     $"LeftArcticSic.txt")
!	n=0
!	do j=1,NT
!	   do i=1,NY
!	      n=n+1
!	      read(1,rec=n)Y(i,j)
!	   enddo
!	enddo
!      close(1)
      read(1,*) ((Y(i,j),j=1,NT),i=1,NY)
	close(1)
     
!----Read the right field----!
!      open(unit=1,file=
!     $"djf_gpcc_africa_lon-3025_4575_lat_-1525_1575.dat"
!     $,form="unformatted",
!     $access="direct",recl=4)
      open(unit=2,file=
     $"RightTibetSnow.txt") 
!	n=0
!	do j=1,NT
!	   do i=1,NZ
!	      n=n+1
!	      read(1,rec=n)Z(i,j)
!	   enddo
!	enddo
 !     close(1)
      read(2,*) ((Z(i,j),j=1,NT),i=1,NZ)
	close(2)

!----Call the subroutine meteo_miss_svd----!
      call svd(NY,NZ,NMIN,NT,Y,Z,YMV,ZMV,np,A,B,cekma,
     $   scfk,cscfk,rab,lcovf,rcovf,vara,varb,lhomo,lhete,rhomo,rhete)

!----Output the left and right time coeffecient series matrices-------!
	open(unit=2,file="ltime.dat")
	open(unit=3,file="rtime.dat")
	do j=1,NT
	  write(2,500)(a(j,i),i=1,NP)
	  write(3,500)(b(j,i),i=1,NP)
	enddo
      close(2);close(3)

!----Output the left homogeneous and heterogeneous correlation maps----!
      open(unit=2,file="lhomo.dat")
	open(unit=3,file="lhete.dat")
      do i=1,NY
	write(2,500)(lhomo(i,j),j=1,NP)
	write(3,500)(lhete(i,j),j=1,NP)
	enddo
      close(2)
	close(3)

!----Output the right homogeneous and heterogeneous correlation maps----!
      open(unit=2,file="rhomo.dat")
	open(unit=3,file="rhete.dat")
      do i=1,NY
	write(2,500)(rhomo(i,j),j=1,NP)
	write(3,500)(rhete(i,j),j=1,NP)
	enddo
      close(2);close(3)

500   format(10(f12.2,'  '))

      end program svd_test



ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c----------------subroutine meteo_miss_svd----------------------------------------c
c This subroutine is for SVD analysing Fields with missing values in Atmospheric  c
c                           and Oceanic Sciences                                  c
c              (Coded by Jincheng Wang and Jianping Li, 24 June, 2009)            c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c-----------------------------------INPUT-----------------------------------------c
c Y	 :Left data field  that consists of NT observations with missing values     c
c	  ,each of which has NY grid points.			                            c
c Z	 :Right data field  that contains of the same number of                     c
c	  observations, each of which has NZ grid points.	                        c
c NY	 :Number of grid points in left field including the grids of missing value  c
c NZ	 :Number of grid points in right field including the grids of missing value c
c NT	 :Number of observation (Time length)                                       c
c NMIN : NMIN=min(NY,NZ)                                                       c
c YMV  :Missing Value of the  Left data Y                                         c
c ZMV  :Missing Value of the Right data Z                                         c
c NP	 :Integer,how many pairs of SVD mode are required ? (In general np<10)	    c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c-----------------------------------OUTPUT----------------------------------------c
c A	 :Time coeffecient series matrix of left field.                             c
c B	 :Time coeffecient series matrix of right field.	                        c
c cekma:Singular values					                                        c
c scfk :The percentage of the total squared covariance explained                  c
c	  by a single pair of patterns			                                    c
c cscfk:The percentage of the cumulative squared covariance	                    c
c	  explained by the leading K modes			                                c
c rab	 :The correlation coefficient between the corresponding                     c
c	  expansion coefficents r(a,b)			                                    c
c lcovf:The  percentages of  the  variance  of left  field	                    c
c	  explained by a single singular vector		                                c
c rcovf:The  percentages of  the  variance  of right field	                    c
c	  explained by a single singular vector		                                c
c vara :The variances of expansion coefficient of left field 	                    c
c varb :The variances of expansion coefficient of right field                     c
c lhomo:The left homogeneous correlation maps		                                c
c lhete:The left heterogeneous correlation maps		                            c
c rhomo:The right homogeneous correlation maps		                            c
c rhete:The right heterogeneous  correlation maps		                            c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c----------------------------------WORK ARRAY------------------------------------ c
c NYM	 :Number of grid points in left field without the grids of missing value    c
c NZM	 :Number of grid points in right field without the grids of missing value   c
c YM	 :Left data field  that consists of NT observations                         c
c	  ,each of which has NY grid points without missing values.	       	        c
c ZM	 :right data field  that contains of the same number of                     c
c	  observations, each of which has NZ grid points without missing values     c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      subroutine svd(NY,NZ,NMIN,NT,Y,Z,YMV,ZMV,np,A,B,cekma,
     $     scfk,cscfk,rab,lcovf,rcovf,vara,varb,lhomo,lhete,rhomo,rhete)
	implicit none
!!!---The input and output variables---!!!
      integer::NY,NZ,NT,NMIN
	real   ::Y(NY,NT),Z(NZ,NT)
	real   ::YMV,ZMV
	integer::NP
	real   ::A(NT,NP),B(NT,NP)
	real   ::cekma(NMIN)
	real   ::scfk(NP)
	real   ::cscfk(NP)
	real   ::rab(NP)
	real   ::lcovf(NP)
	real   ::rcovf(NP)
	real   ::vara(NP)
	real   ::varb(NP)
	real   ::lhomo(NY,NP),lhete(NY,NP)
	real   ::rhomo(NZ,NP),rhete(NZ,NP)

!------Work Variables--------!
      integer::MNY,MNZ
	real,allocatable::ym(:,:)
      real,allocatable::zm(:,:)
	real,allocatable::lhomom(:,:),lhetem(:,:)
      real,allocatable::rhomom(:,:),rhetem(:,:)

      integer::yc(NY)
	integer::zc(NZ)

      integer::NYM
	integer::NZM
      integer::i,j,k,n,ka
 

      print*,"The number of grids before removing missing values:"
	print*,"Left : ",NY
	print*,"Right: ",NZ
c-----Calculate the number of the grids without missing values----c
cccccccc----Left Field------cccccc
      yc=0
	NYM=0
	do i=1,NY
	   if(Y(i,1).ne.YMV)then
	      NYM=NYM+1
	      yc(i)=1
	   endif
      enddo

cccccccc----Right Field------ccccc
      zc=0
	NZM=0
	do i=1,NZ
	   if(Z(i,1).ne.ZMV)then
	      NZM=NZM+1
	      zc(i)=1
	   endif
      enddo

      print*,"The number of grids after removing missing values:"
	print*,"Left : ",NYM
	print*,"Right: ",NZM
     
c-----Allocate the work array----c
      KA=max(NYM,NZM)+1

      allocate(ym(NYM,NT))
      allocate(zm(NZM,NT))
      allocate(lhomoM(NYM,NP))
	allocate(lheteM(NYM,NP))
      allocate(rhomoM(NZM,NP))
	allocate(rheteM(NZM,NP))

      print*,"Start meteo_miss_svd"
c-----Remove the missing values----c
      do j=1,NT
	   n=0
	   do i=1,NY
	      if(yc(i).eq.1)then
	         n=n+1
	         ym(n,j)=y(i,j)
		  endif
	   enddo
	enddo   

      do j=1,NT
	   n=0
	   do i=1,NZ
	      if(zc(i).eq.1)then
	         n=n+1
	         zm(n,j)=z(i,j)
		  endif
	   enddo
	enddo   
	

c-----Call meteo_svd subroutine------c
      print*,"   Call subroutine meteo_svd"
      call meteo_svd(NYM,NZM,NT,NMIN,KA,YM,ZM,NP,A,B,cekma,scfk,
     $  cscfk,rab,lcovf,rcovf,vara,varb,lhomom,lhetem,rhomom,rhetem)
      print*,"   Successfully run meteo_svd"
c-----

      print*,"   Reconstruct left and right homogeneous and
     $ heteogeneous correlation maps"
      do j=1,NP
	   n=0
	   do i=1,NY
	      if(yc(i).eq.1)then
	         n=n+1
	         lhomo(i,j)=lhomom(n,j)
	         lhete(i,j)=lhetem(n,j)
            else
	         lhomo(i,j)=YMV
	         lhete(i,j)=YMV
	      endif
	   enddo
      enddo

      do j=1,NP
	   n=0
	   do i=1,NZ
	      if(zc(i).eq.1)then
	         n=n+1
	         rhomo(i,j)=rhomom(n,j)
	         rhete(i,j)=rhetem(n,j)
            else
	         rhomo(i,j)=ZMV
	         rhete(i,j)=ZMV
	      endif
	   enddo
      enddo
      print*,"Successfully run meteo_miss_svd"

      return

      end


ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c----------------subroutine meteo_miss_svd----------------------------------------c
c	     This subroutine uses for SVD analysing in Atmospheric Sciences         c
c                         (Coded by Hongbao Wu)                                   c
c          (Modified by Jincheng Wang and Jianping Li, 24 June, 2009)             c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c-----------------------------------INPUT-----------------------------------------c
c Y	 :Left data field  that consists of NT observations                         c
c	  ,each of which has NY grid points.			                            c
c Z	 :right data field  that contains of the same number of                     c
c	  observations, each of which has NZ grid points.	                        c
c NY	 :Number of grid points in left field                                       c
c NZ	 :Number of grid points in right field                                      c
c NT	 :Number of observation (Time length)                                       c
c NMIN :NMIN=min(NY,NZ)                                                        c
c KA   :KA=NY+1
c np	 :Integer,how many pairs of SVD mode are required ? (In general np<10)	    c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c-----------------------------------OUTPUT----------------------------------------c
c A	 :Time coeffecient series matrix of left field.                             c
c B	 :Time coeffecient series matrix of right field.	                        c
c cekma:Singular values					                                        c
c scfk :The percentage of the total squared covariance explained                  c
c	  by a single pair of patterns			                                    c
c cscfk:The percentage of the cumulative squared covariance	                    c
c	  explained by the leading K modes			                                c
c rab	 :The correlation coefficient between the corresponding                     c
c	  expansion coefficents r(a,b)			                                    c
c lcovf:The  percentages of  the  variance  of left  field	                    c
c	  explained by a single singular vector		                                c
c rcovf:The  percentages of  the  variance  of right field	                    c
c	  explained by a single singular vector		                                c
c vara :The variances of expansion coefficient of left field 	                    c
c varb :The variances of expansion coefficient of right field                     c
c lhomo:The left homogeneous	correlation maps		                            c
c lhete:The left heterogeneous  correlation maps		                            c
c rhomo:The right homogeneous  correlation maps		                            c
c rhete:The right heterogeneous  correlation maps		                            c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c------------------------------------WORK ARRAY---------------------------------- c	
c P	 :Left singular vector matrix,(u)			                                c
c Q	 :Right singular vector matrix,(v)			                                c
c Cyz	 :Work Array, Cross-covarince matrix between the left and right fields      c
c C	 :C is an NY*NZ matrix whose elements equal zero except                     c
c	  for the first R( R<=min(NS,NZ)) diagonal elements(cekma)                  c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc

      subroutine meteo_svd(NY,NZ,NT,NMIN,KA,Y,Z,NP,A,B,cekma,scfk,
     $    cscfk,rab,lcovf,rcovf,vara,varb,lhomo,lhete,rhomo,rhete)
c--------------------------------------------------------------------
!-----*Input and Output Variables*----------
      integer::NY,NZ,NT,NMIN,KA
	real   ::Y(NY,NT),Z(NZ,NT)
	integer::NP
	real   ::A(NT,NP),B(NT,NP)
	real   ::cekma(NMIN)
	real   ::scfk(NP)
	real   ::cscfk(np)
	real   ::rab(NP)
	real   ::lcovf(NP)
	real   ::rcovf(NP)
	real   ::vara(NP)
	real   ::varb(NP)
	real   ::lhomo(NY,NP),lhete(NY,NP)
	real   ::rhomo(NZ,NP),rhete(NZ,NP)
!-------------------------------------
!--------Work Variables---------------	
	real::P(NY,NY),Q(NZ,NZ)
	real::s(KA),e(KA),work(KA)
      real::y8(ny,nt),rain(nt,nz)
      real::ym(ny),zm(nz),yd(ny),zd(nz)
      real::cyz(ny,nz)
	real::c(ny,nz)

      real::xxx(nt),yyy(nt)
!-------------------------------
!-------------Start-------------
cccc******************************************************************

      OPEN(6,FILE='svd_info.txt',STATUS='unknown')
c      if(job1.eq.1) then
c         write(6,111)
c         do i=1,ny
c            write(6,110) i
c            write(6,112) (y(i,k),k=1,nt)
c         enddo
c         write(6,113)
c         do i=1,nz
c            write(6,110) i
c           write(6,112) (z(i,k),k=1,nt)
c         enddo
c      end if
 110  format(5x,' No. of station  ',i3)
 112  format(10f12.2)
 111  format(/5x,'The  original data of left  field')
 113  format(/5x,'The  original data of right  field')

      fny=real(ny)
      fnz=real(nz)
      fnt=real(nt)

      do i=1,ny
         ym(i)=0.0
         do k=1,nt
            ym(i)=ym(i)+y(i,k)
         enddo
         ym(i)=ym(i)/fnt
         yd(i)=0.0
         do k=1,nt
            yd(i)=yd(i)+(y(i,k)-ym(I))**2
         enddo
         yd(i)=sqrt(yd(i)/fnt)
      enddo

      do i=1,nz
         zm(i)=0.0
         do k=1,nt
            zm(i)=zm(i)+z(i,k)
         enddo
         zm(i)=zm(i)/fnt
         zd(i)=0.0
         do k=1,nt
            zd(i)=zd(i)+(z(i,k)-zm(I))**2
	   enddo
         zd(i)=sqrt(zd(i)/fnt)
      enddo

      do i=1,ny
         do k=1,nt
            y(i,k)=(y(i,k)-ym(I))/yd(I)
         enddo
	enddo

      do i=1,nz
         do k=1,nt
            z(i,k)=(z(i,k)-zm(I))/zd(I)
         enddo
	enddo

c      if(job1.eq.0) then
c         write(6,100)
c         write(6,101)
c         write(6,102) ym
c         write(6,103)
c         write(6,102) yd
c         write(6,105)
c         write(6,102) zm
c         write(6,107)
c         write(6,102) zd
c      end if

 100  format(/5x,'The  basic statistical quantity')
 101  format(/5x,'The  mean value at each point of left data field')
 102  format(1x,10f12.4)
 103  format(/5x,'The  standard deviation at each point of  left  data
     $  field')
 105  format(/5x,'The  mean value at each point of right data field')
 107  format(/5x,'The  standard deviation at each point of  right  data
     &field')

      do i=1,ny
         do j=1,nz
            cyz(i,j)=0.0
            do k=1,nt
               cyz(i,j)=cyz(i,j)+y(i,k)*z(j,k)
            enddo
            cyz(i,j)=cyz(i,j)/fnt
         enddo
      enddo


c	if(job2.eq.1) then
c	   write(6,78)
c	   write(6,49)((cyz(i,j),j=1,nz),i=1,ny)
c	end if
  78	format(1x,'the cross-coverence matrix:')
  49	format(1x,10f12.4)

	sss=0.0
	do i=1,ny
	   do j=1,nz
	      sss=sss+cyz(i,j)**2
	   enddo
      enddo
	write(6,76) sss
76	format(/2x,' The total squared covariance=',f12.5)
	eps=0.000001

c******************************************
	call uav(cyz,ny,nz,p,q,l,eps,ka,s,e,work)

	write(6,9)l
   9	format(/5x,'l=',i1,'(l=0 indicate that call subroutine UAV(SVD)
     & normal finished,else unnormal finished)')

	ir=nz
	if(ny.lt.nz) ir=ny
	do k=1,ir
         cekma(k)=cyz(k,k)
      enddo

	ss=0.0
	do k=1,ir
	   ss=ss+cekma(k)**2
      enddo

	write(6,56) ss
56	format(/2x,' The sum of squared singular value=',f12.5)
	write(6,55)
55	format(/4x,'According to properties of SVD, the sum of squared
     &singular value must'/2x,'be equal to the total squared covariance
     & ! ')

	 write(6,53) (cekma(k),k=1,np)
53     format(/2x,'The singular values:',(/1x,8f10.3))

	do k=1,np
         scfk(K)=(cekma(k)**2/ss)*100.0
      enddo

	write(6,44)
44	format(/4x,'The percentage of the squared covariance explained
     * by a single pair of patterns (give first NP pairs) is:')
      write(6,382) (scfk(k),k=1,np)
382   format((10f12.2))

      cscfk(1)=scfk(1)
      do k=2,np
         j=k-1
         cscfk(k)=cscfk(j)+scfk(k)
      enddo

	write(6,43)
43	format(/4x,'The percentage of the cumulative squared covariance
     $ explained by the leading K modes is:')
      write(6,382) (cscfk(k),k=1,np)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
c   Note that:						                  c
c   Output from subroutine uav: 			              c
c   Column of matrix p is left singular vectors 	      c
c   rows   of matrix q is right singular vectors	      c
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
  29    format(1x,10f12.4)
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccc
      do i=1,nz-1
         do j=i+1,nz
            ggg=q(i,j)
            q(i,j)=q(j,i)
            q(j,i)=ggg
         enddo
      enddo

c     write(6,509)
c509  format(/2x,'After transpose Q output singular vectors again')
c     write(6,511)
c511  format(/4x,'The  left singular vector')
c     write(6,512)
c512  format(/4x,'The  right singular vector')

	do id=1,np
	   do k=1,nt
	      a(k,id)=0.0
	      b(k,id)=0.0
	      do i=1,ny
               a(k,id)=a(k,id)+p(i,id)*y(i,k)
            enddo
	      do j=1,nz
               b(k,id)=b(k,id)+q(j,id)*z(j,k)
            enddo
         enddo
      enddo

c      write(6,311)
c      do id=1,np
c         write(6,317) id
c         write(6,316) (a(k,id),k=1,nt)
c      enddo
c      write(6,312)

c      do id=1,np
c         write(6,317) id
c         write(6,316) (b(k,id),k=1,nt)
c      enddo
 311  format(/4x,'The time coeffecient series of left singular vector')
 312  format(/4x,'The time coeffecient series of right singular vector')
 317  format(/4x,i2,'-th')
 316  format(10f12.3)
cccccccccccccc*********************************************
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
      rnt=real(nt)
      do id=1,np
         vara(id)=0.
         varb(id)=0.
	   do k=1,nt
	      vara(id)=vara(id)+a(k,id)**2/rnt
	      varb(id)=varb(id)+b(k,id)**2/rnt
	   enddo
	enddo

      do id=1,np
         lcovf(id)=100.0*vara(id)/fny
         rcovf(id)=100.0*varb(id)/fnz
 	enddo

      do id=1,np
         do k=1,nt
            xxx(k)=a(k,id)
            yyy(k)=b(k,id)
         enddo
         rab(id)=rxy(xxx,yyy,nt)
      enddo
c*******************************************************
      write(6,463)
 463  format(/2x,'The correlation coefficient between the corresponding
     & expansion coefficents r(a,b) (first to NP-th pair) are: ')
      write(6,382) (rab(id),id=1,np)
      write(6,481)
 481   format(/3x,'The  percentages of  the  variance  of left  field
     & explained by a single singular vector are:')
      write(6,382) (lcovf(id),id=1,np)
      write(6,482)
 482   format(/3x,'The  percentages of  the  variance  of right field
     & explained by a single singular vector are:')
      write(6,382) (rcovf(id),id=1,np)
c*****************************************
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
	do id=1,np
	   do is=1,ny
	      do k=1,nt
	         xxx(k)=a(k,id)
               yyy(k)=y(is,k)
	      enddo
	      lhomo(is,id)=rxy(xxx,yyy,nt)
	   enddo
	enddo
c*****************************************
	do id=1,np
	   do is=1,ny
	      do k=1,nt
	         xxx(k)=b(k,id)
	         yyy(k)=y(is,k)
 	      enddo
	      lhete(is,id)=rxy(xxx,yyy,nt)
 	   enddo
 	enddo
c*****************************************
	do id=1,np
	   do is=1,nz
	      do k=1,nt
	         xxx(k)=b(k,id)
	         yyy(k)=z(is,k)
 	      enddo
	      rhomo(is,id)=rxy(xxx,yyy,nt)
 	   enddo
  	enddo
c*****************************************
	do id=1,np
	   do is=1,nz
	      do k=1,nt
	         xxx(k)=a(k,id)
	         yyy(k)=z(is,k)
 	      enddo
	      rhete(is,id)=rxy(xxx,yyy,nt)
         enddo
	enddo
c********************************************************
c      open(11,file='left.dat',STATUS='unknown')

c	write(11,812)
 812  format(/4x,'The  left heterogeneous correlation maps')

c      do id=1,np
c         write(11,317) id
c         write(11,382)(lhete(j,id),j=1,ny)
c      enddo

c	write(11,814)
 814  format(/4x,'The  left homogeneous correlation maps')

c     do id=1,np
c        write(11,317) id
c        write(11,382)(lhomo(j,id),j=1,ny)
c     enddo
c	close(11)
c***********************************************************
c	open(12,file='g:\svd\right.dat',STATUS='unknown')

c      write(12,817)
c 817  format(/4x,'The right heterogeneous correlation maps')

c      do id=1,np
c         write(12,317) id
c         write(12,382) (rhete(j,id),j=1,nz)
c      enddo
c      write(12,819)
 819  format(/4x,'The right homogeneous correlation maps')

c      do id=1,np
c         write(12,317) id
c         write(12,382) (rhomo(j,id),j=1,nz)
c      enddo
c	close(12)


      end


c-----*----------------------------------------------------6---------7--
	subroutine uav(a,m,n,u,v,l,eps,ka,s,e,work)
	dimension a(m,n),u(m,m),v(n,n),s(ka),e(ka),work(ka)
        real  a,u,v,s,e,d,work,dd,f,g,cs,sn,
     *			 shh,sk,ek,b,c,sm,sm1,em1
     	it=60
	k=n
	if(m-1.lt.n)k=m-1
	l=m
	if(n-2.lt.m)l=n-2
	if(l.lt.0)l=0
	ll=k
	if(l.gt.k)ll=l
	if(ll.ge.1)then
	  do 150 kk=1,ll
	    if(kk.le.k)then
	      d=0.0
	      do 10 i=kk,m
	      d=d+a(i,kk)*a(i,kk)
  10	      continue
	      s(kk)=sqrt(d)
	      if(s(kk).ne.0.0)then
		if(a(kk,kk).ne.0.0)s(kk)=sign(s(kk),a(kk,kk))
		do 20 i=kk,m
  20		a(i,kk)=a(i,kk)/s(kk)
		a(kk,kk)=1.0+a(kk,kk)
	      end if
	      s(kk)=-s(kk)
	    end if
	    if(n.ge.kk+1)then
	      do 50 j=kk+1,n
		if((kk.le.k).and.(s(kk).ne.0.0))then
		  d=0.0	   
		  do 30 i=kk,m 
  		  d=d+a(i,kk)*a(i,j)
30          continue
		  d=-d/a(kk,kk)   
		  do 40 i=kk,m
  40		  a(i,j)=a(i,j)+d*a(i,kk)
		end if
		e(j)=a(kk,j)
  50	      continue
	    end if
	    if(kk.le.k)then
	       do 60 i=kk,m
  60	       u(i,kk)=a(i,kk)
	    end if
	    if(kk.le.l)then
	      d=0.0
	      do 70 i=kk+1,n
   70	      d=d+e(i)*e(i)
	      e(kk)=sqrt(d)
	      if(e(kk).ne.0.0)then
	      if(e(kk+1).ne.0.0)e(kk)=sign(e(kk),e(kk+1))
	      do 80 i=kk+1,n
   80	      e(i)=e(i)/e(kk)
	      e(kk+1)=1.0+e(kk+1)
	      end if
	      e(kk)=-e(kk)
	      if((kk+1.le.m).and.(e(kk).ne.0.0))then
	      do 90 i=kk+1,m
  90	      work(i)=0.0
	      do 110 j=kk+1,n
	       do 100 i=kk+1,m
  100	       work(i)=work(i)+e(j)*a(i,j)
  110	      continue
	      do 130 j=kk+1,n
		do 120 i=kk+1,m
  120		a(i,j)=a(i,j)-work(i)*e(j)/e(kk+1)
  130	    continue
	    end if
	    do 140 i=kk+1,n
  140	    v(i,kk)=e(i)
	  end if
  150	  continue

	  end if

	  mm=n
	  if(m+1.lt.n)mm=m+1
	  if(k.lt.n)s(k+1)=a(k+1,k+1)
	  if(m.lt.mm)s(mm)=0.0
	  if(l+1.lt.mm)e(l+1)=a(l+1,mm)
	  e(mm)=0.0
	  nn=m
	  if(m.gt.n)nn=n
	  if(nn.ge.k+1)then
	    do 190 j=k+1,nn
	      do 180 i=1,m
  180	      u(i,j)=0.0
	      u(j,j)=1.0
  190	    continue
	  end if
	  if(k.ge.1)then
	    do 250 ll=1,k
	      kk=k-ll+1
	      if(s(kk).ne.0.0)then
		if(nn.ge.kk+1)then
		   do 220 j=kk+1,nn
		     d=0.0
		     do 200 i=kk,m
  200		     d=d+u(i,kk)*u(i,j)/u(kk,kk)
		     d=-d
		     do 210 i=kk,m
  210		     u(i,j)=u(i,j)+d*u(i,kk)
  220		   continue
		 end if
		 do 225 i=kk,m
  225		 u(i,kk)=-u(i,kk)
		 u(kk,kk)=1.0+u(kk,kk)
		 if(kk-1.ge.1)then
		   do 230 i=1,kk-1
  230		   u(i,kk)=0.0
		 end if
		else
		  do 240 i=1,m
  240		  u(i,kk)=0.0
		  u(kk,kk)=1.0
	      end if
  250	    continue
	    end if
	    do 300 ll=1,n
	    kk=n-ll+1
	    if((kk.le.l).and.(e(kk).ne.0.0))then
	      do 280 j=kk+1,n
	       d=0.0
	       do 260 i=kk+1,n
  260	       d=d+v(i,kk)*v(i,j)/v(kk+1,kk)
	       d=-d
	       do 270 i=kk+1,n
  270	       v(i,j)=v(i,j)+d*v(i,kk)
  280	      continue
	    end if
	    do 290 i=1,n
  290	    v(i,kk)=0.0
	    v(kk,kk)=1.0
  300	   continue
	   do 305 i=1,m
	   do 305 j=1,n
  305	   a(i,j)=0.0
	   m1=mm
	   it=60
  310	   if(mm.eq.0)then
	    l=0
	    if(m.ge.n)then
	      i=n
	    else
	      i=m
	    end if
	    do 315 j=1,i-1
	      a(j,j)=s(j)
	      a(j,j+1)=e(j)
  315	    continue
	    a(i,i)=s(i)
	    if(m.lt.n)a(i,i+1)=e(i)
	    do 314 i=1,n-1
	      do 313 j=i+1,n
		d=v(i,j)
		v(i,j)=v(j,i)
		v(j,i)=d
  313	       continue
  314	     continue
	     return
	   end if
	   if(it.eq.0)then
	      l=mm
	      if(m.ge.n)then
		i=n
	      else
		i=m
	      end if
	   do 316 j=1,i-1
	     a(j,j)=s(j)
	     a(j,j+1)=e(j)
  316	   continue
	   a(i,i)=s(i)
	   if(m.lt.n)a(i,i+1)=e(i)
	   do 318 i=1,n-1
	     do 317 j=i+1,n
	       d=v(i,j)
	       v(i,j)=v(j,i)
	       v(j,i)=d
  317	     continue
  318	   continue
	   return
	  end if
	  kk=mm
  320	  kk=kk-1
	  if(kk.ne.0)then
	    d=abs(s(kk))+abs(s(kk+1))
	    dd=abs(e(kk))
	    if(dd.gt.eps*d)go to 320
	    e(kk)=0.0
	  end if
	  if(kk.eq.mm-1)then
	    kk=kk+1
	    if(s(kk).lt.0.0)then
	      s(kk)=-s(kk)
	      do 330 i=1,n
  330	      v(i,kk)=-v(i,kk)
	    end if
  335	    if(kk.ne.m1)then
	      if(s(kk).lt.s(kk+1))then
		d=s(kk)
		s(kk)=s(kk+1)
		s(kk+1)=d
		if(kk.lt.n)then
		  do 340 i=1,n
		    d=v(i,kk)
		    v(i,kk)=v(i,kk+1)
		    v(i,kk+1)=d
  340		  continue
		end if
		if(kk.lt.m)then
		  do 350 i=1,m
		    d=u(i,kk)
		    u(i,kk)=u(i,kk+1)
		    u(i,kk+1)=d
  350		  continue
		 end if
		 kk=kk+1
		 go to 335
		end if
	       end if
	       it=60
	       mm=mm-1
	       go to 310
	    end if
	    ks=mm+1
  360	    ks=ks-1
	    if(ks.gt.kk)then
	      d=0.0
	      if(ks.ne.mm)d=d+abs(e(ks))
	      if(ks.ne.kk+1)d=d+abs(e(ks-1))
	      dd=abs(s(ks))
	      if(dd.gt.eps*d)go to 360
	      s(ks)=0.0
	    end if
	    if(ks.eq.kk)then
	      kk=kk+1
	      d=abs(s(mm))
	      if(abs(s(mm-1)).gt.d)d=abs(s(mm-1))
	      if(abs(e(mm-1)).gt.d)d=abs(e(mm-1))
	      if(abs(s(kk)).gt.d)d=abs(s(kk))
	      if(abs(e(kk)).gt.d)d=abs(e(kk))
	      sm=s(mm)/d
	      sm1=s(mm-1)/d
	      em1=e(mm-1)/d
	      sk=s(kk)/d
	      ek=e(kk)/d
	      b=((sm1+sm)*(sm1-sm)+em1*em1)/2.0
	      c=sm*em1
	      c=c*c
	      shh=0.0
	      if((b.ne.0.0).or.(c.ne.0.0))then
		shh=sqrt(b*b+c)
		if(b.lt.0.0)shh=-shh
		shh=c/(b+shh)
	      end if
	      f=(sk+sm)*(sk-sm)-shh
	      g=sk*ek
	      do 400 i=kk,mm-1
		call sss(f,g,cs,sn)
		if(i.ne.kk)e(i-1)=f
		f=cs*s(i)+sn*e(i)
		e(i)=cs*e(i)-sn*s(i)
		g=sn*s(i+1)
		s(i+1)=cs*s(i+1)
		if((cs.ne.1.0).or.(sn.ne.0.0))then
		  do 370 j=1,n
		    d=cs*v(j,i)+sn*v(j,i+1)
		    v(j,i+1)=-sn*v(j,i)+cs*v(j,i+1)
		    v(j,i)=d
  370		  continue
		end if
		call sss(f,g,cs,sn)
		s(i)=f
		f=cs*e(i)+sn*s(i+1)
		s(i+1)=-sn*e(i)+cs*s(i+1)
		g=sn*e(i+1)
		e(i+1)=cs*e(i+1)
		if(i.lt.m)then
		  if((cs.ne.1.0).or.(sn.ne.0.0))then
		    do 380 j=1,m
		      d=cs*u(j,i)+sn*u(j,i+1)
		      u(j,i+1)=-sn*u(j,i)+cs*u(j,i+1)
		      u(j,i)=d
  380		      continue
		  end if
		end if
  400	       continue
	       e(mm-1)=f
	       it=it-1
	       go to 310
	     end if
	     if(ks.eq.mm)then
		kk=kk+1
		f=e(mm-1)
		e(mm-1)=0.0
		do 420 ll=kk,mm-1
		  i=mm+kk-ll-1
		  g=s(i)
		  call sss(g,f,cs,sn)
		  s(i)=g
		  if(i.ne.kk)then
		    f=-sn*e(i-1)
		    e(i-1)=cs*e(i-1)
		  end if
		  if((cs.ne.1.0).or.(sn.ne.0.0))then
		    do 410 j=1,n
		      d=cs*v(j,i)+sn*v(j,mm)
		      v(j,mm)=-sn*v(j,i)+cs*v(j,mm)
		      v(j,i)=d
  410		    continue
		   end if
  420		 continue
		go to 310
	      end if
	      kk=ks+1
	      f=e(kk-1)
	      e(kk-1)=0.0
	      do 450 i=kk,mm
		g=s(i)
		call sss(g,f,cs,sn)
		s(i)=g
		f=-sn*e(i)
		e(i)=cs*e(i)
		if((cs.ne.1.0).or.(sn.ne.0.0))then
		  do 430 j=1,m
		    d=cs*u(j,i)+sn*u(j,kk-1)
		    u(j,kk-1)=-sn*u(j,i)+cs*u(j,kk-1)
		    u(j,i)=d
  430		  continue
		end if
  450	       continue
	       go to 310
	       end

	 subroutine sss(f,g,cs,sn)
c         double precision f,g,cs,sn,d,r
	   real f,g,cs,sn,d,r
	 if((abs(f)+abs(g)).eq.0.0)then
	   cs=1.0
	   sn=0.0
	   d=0.0
	 else
	   d=sqrt(f*f+g*g)
	   if(abs(f).gt.abs(g))d=sign(d,f)
	   if(abs(g).ge.abs(f))d=sign(d,g)
	   cs=f/d
	   sn=g/d
	 end if
	 r=1.0
	 if(abs(f).gt.abs(g))then
	   r=sn
	 else
	   if(cs.ne.0.0)r=1.0/cs
	 end if
	 f=d
	 g=r
	 return
	 end

	 subroutine mul(a,b,m,n,k,c)
	 dimension a(m,n),b(n,k),c(m,k)
c         double precision a,b,c
       real a,b,c
	 do 50 i=1,m
	 do 50 j=1,k
	    c(i,j)=0.0
	    do 10 l=1,n
	      c(i,j)=c(i,j)+a(i,l)*b(l,j)
  10	    continue
  50	 continue
	 return
	 end

	 function rxy(x,y,n)
	 dimension x(n),y(n)
	 rn=real(n)
	 xm=0.0
	 ym=0.0
	 do  10  i=1,n
	 xm=xm+x(i)/rn
   10	 ym=ym+y(i)/rn
	 do  20  i=1,n
	 x(i)=x(i)-xm
   20	 y(i)=y(i)-ym
	  sxy=0.0
	  sx=0.0
	  sy=0.0
	 do  30  i=1,n
      sx=sx+x(i)*x(i)/rn
      sy=sy+y(i)*y(i)/rn
  30  sxy=sxy+x(i)*y(i)/rn
      sx=sqrt(sx)
      sy=sqrt(sy)
       rxy=sxy/(sx*sy)
	 return
	 end



