!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!
!!  This file is part of scift (Scientific Fortran Tools).
!!  Copyright (C) by authors (2012-2016)
!!  
!!  Authors (alphabetic order):
!!    * Aguirre N.F. (nfaguirrec@gmail.com)  (2016-2016)
!!  
!!  Contributors (alphabetic order):
!!  
!!  Redistribution and use in source and binary forms, with or
!!  without modification, are permitted provided that the
!!  following conditions are met:
!!  
!!   * Redistributions of binary or source code must retain
!!     the above copyright notice and this list of conditions
!!     and/or other materials provided with the distribution.
!!   * All advertising materials mentioning features or use of
!!     this software must display the following acknowledgement:
!!     
!!     This product includes software from scift
!!     (Scientific Fortran Tools) project and its contributors.
!!
!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

module RealVector_
	use IOStream_
	use String_
	implicit none
	private
	
	public :: &
		RealVector_test

!>
!! This class use the Vector template declared into Vector.h90 file,
!! please take a look to this file for details
!!
#define Vector RealVector
#define VectorIterator RealVectorIterator
#define __CLASS_ITEMVECTOR__ real(8)
#define __TYPE_ITEMVECTOR__ real(8)
#define __ADD_ATTRIBUTES__
#define __ADD_METHODS__
#include "Vector.h90"
#undef Vector
#undef VectorIterator
#undef __CLASS_ITEMVECTOR__
#undef __TYPE_ITEMVECTOR__
#undef __ADD_ATTRIBUTES__
#undef __ADD_METHODS__

	!>
	!! @brief
	!!
	function equal( this, other ) result( output )
		class(RealVector), intent(in) :: this
		class(RealVector), intent(in) :: other
		logical :: output
		
! 		this.nItems = other.nItems
! 		this.resizeIncrement = other.resizeIncrement
		
		output = all( this.data(1:this.size()) == other.data(1:other.size()) )
	end function equal
	
	!>
	!! @brief Converts to string
	!!
	function str( this, formatted, prefix ) result( output )
		class(RealVector) :: this 
		character(:), allocatable :: output
		logical, optional :: formatted
		character(*), optional :: prefix
		
		logical :: effFormatted
		character(:), allocatable :: effPrefix
		
		integer :: i
		integer :: fmt
		character(200) :: fstr
		
		effFormatted = .false.
		if( present(formatted) ) effFormatted = formatted
		
		effPrefix = ""
		if( present(prefix) ) effPrefix = prefix
		
		output = ""
		
		if( .not. effFormatted ) then
			output = trim(output)//"<RealVector:("
			do i=1,this.size()
				if( i==1 ) then
					output = trim(output)//trim(FString_fromReal(this.at(i)))
				else
					output = trim(output)//","//trim(FString_fromReal(this.at(i)))
				end if
			end do
			output = trim(output)//")>"
! 		else
! 			LINE("Vector")
! 			LINE("---------")
! ! 			ITEMI( "min=", this.min )
! ! 			ITEMR( ",size=", this.size )
! 			LINE("")
		end if
	end function str
	
	!>
	!! Save the data in two column format in a
	!! selected unit
	!!
	subroutine toFStream( this, ofile )
		class(RealVector) :: this
		type(OFStream), optional, intent(in) :: ofile
		
		integer :: unitEff
		
		type(RealVectorIterator), pointer :: iter
		
		if( present(ofile) ) then
			unitEff = ofile.unit
		else
			unitEff = IO_STDOUT
		end if
		
		write(unitEff,"(a)") "#"//trim(str(this))
		
! 		iter => this.begin
! 		do while ( associated(iter) )
! 			write(unitEff,"(I15)") iter.data
! 			
! 			iter => iter.next
! 		end do
	end subroutine toFStream
	
	subroutine showMyVector( myvector )
		type(RealVector) :: myvector
		class(RealVectorIterator), pointer :: iter
		
! 		iter => myvector.begin
! 		do while( associated(iter) )
! 			write(*,"(I2,A)", advance="no") iter.data, "  --> "
! 			
! 			iter => iter.next
! 		end do
		
		integer :: i
		
		do i=1,myvector.size()
			write(*,"(I2,A)", advance="no") myvector.at(i), "  --> "
		end do
		
		write(*,*)
	end subroutine showMyVector
	
	!>
	!! @brief Test method
	!!
	subroutine RealVector_test()
		type(RealVector) :: myvector
		class(RealVectorIterator), pointer :: iter
		
		call myvector.init()
		
		write(*,*) "-------------------------"
		write(*,*) "Testing for append method"
		write(*,*) "-------------------------"
		
		write(*,*) "call myvector.append( 8.0 )"
		write(*,*) "call myvector.append( 5.0 )"
		write(*,*) "call myvector.append( 1.0 )"
		write(*,*)
		
		call myvector.append( 8.0_8 )
		call myvector.append( 5.0_8 )
		call myvector.append( 1.0_8 )
		
		call showMyVector( myvector )
		
		write(*,*) "--------------------------"
		write(*,*) "Testing for prepend method"
		write(*,*) "--------------------------"
		
		write(*,*) "call myvector.prepend( 8.0 )"
		write(*,*) "call myvector.prepend( 5.0 )"
		write(*,*) "call myvector.prepend( 1.0 )"
		write(*,*)
		
		call myvector.prepend( 8.0_8 )
		call myvector.prepend( 5.0_8 )
		call myvector.prepend( 1.0_8 )
		
		call showMyVector( myvector )
		
		write(*,*) "------------------------"
		write(*,*) "Testing for erase method"
		write(*,*) "------------------------"
		
		write(*,*) "call myvector.erase( 1 )"
		call myvector.erase( 1 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 2 )"
		call myvector.erase( 2 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 3 )"
		write(*,*)
		call myvector.erase( 3 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 1 )"
		write(*,*)
		call myvector.erase( 1 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 1 )"
		write(*,*)
		call myvector.erase( 1 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 1 )"
		write(*,*)
		call myvector.erase( 1 )
		call showMyVector( myvector )
		
		write(*,*) "call myvector.erase( 1 )"
		write(*,*)
		call myvector.erase( 1 )
		call showMyVector( myvector )

! 		
! 		write(*,*) "-------------------------"
! 		write(*,*) "Testing for insert method"
! 		write(*,*) "-------------------------"
! 		
! 		write(*,*) "iter => myvector.begin"
! 		write(*,*) "iter => iter.next"
! 		write(*,*) "iter => iter.next"
! 		write(*,*) "call myvector.insert( iter, 1 )"
! 		write(*,*)
! 		
! 		iter => myvector.begin
! 		iter => iter.next
! 		iter => iter.next
! 		
! 		call myvector.insert( iter, 1 )
! 		call showMyVector( myvector )
! 		
! 		write(*,*)
! 		write(*,*) "call myvector.insert( iter, 2 )"
! 		write(*,*)
! 		
! 		call myvector.insert( iter, 2 )
! 		call showMyVector( myvector )
! 		
! 		write(*,*)
! 		write(*,*) "call myvector.insert( myvector.end, 9 )"
! 		write(*,*)
! 				
! 		call myvector.insert( myvector.end, 9 )
! 		call showMyVector( myvector )

		write(*,*) "------------------------"
		write(*,*) "Testing for erase method"
		write(*,*) "------------------------"
		
		write(*,*) "call myvector.erase( 2 )"
		write(*,*)
		
		call myvector.erase( 2 )
		call showMyVector( myvector )

! 		write(*,*) "iter => myvector.begin"
! 		write(*,*) "iter => iter.next"
! 		write(*,*) "call myvector.erase( iter )"
! 		write(*,*)
! 		
! 		iter => myvector.begin
! 		iter => iter.next
! 		
! 		call myvector.erase( iter )
! 		call showMyVector( myvector )
! 		
! 		write(*,*)
! 		write(*,*) "call myvector.erase( myvector.begin )"
! 		write(*,*)
! 		
! 		call myvector.erase( myvector.begin )
! 		call showMyVector( myvector )
! 		
! 		write(*,*)
! 		write(*,*) "call myvector.erase( myvector.end )"
! 		write(*,*)
! 		call myvector.erase( myvector.end )
! 		call showMyVector( myvector )
		
		write(*,*) "------------------------"
		write(*,*) "Testing for clear method"
		write(*,*) "------------------------"
		
		write(*,*) "call myvector.clear()"
		write(*,*)
		call myvector.clear()
		call showMyVector( myvector )

		write(*,*) "call myvector.append( 1.0 )"
		write(*,*) "call myvector.append( 2.0 )"
		write(*,*) "call myvector.append( 3.0 )"
		write(*,*)
		
		call myvector.append( 1.0_8 )
		call myvector.append( 2.0_8 )
		call myvector.append( 3.0_8 )
		call showMyVector( myvector )

	end subroutine RealVector_test

end module RealVector_