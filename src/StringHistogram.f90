!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
!!
!!  This file is part of scift (Scientific Fortran Tools).
!!  Copyright (C) by authors (2013-2013)
!!  
!!  Authors (alphabetic order):
!!    * Aguirre N.F. (nfaguirrec@gmail.com)  (2013-2013)
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

!>
!! @brief
!!
module StringHistogram_
	use String_
	use StringList_
	use StringIntegerMap_
	use StringIntegerPair_
	use StringRealPair_
	use StringRealMap_
	implicit none
	private
	
	public :: &
		StringHistogram_test
		
	type, public, extends( StringList ) :: StringHistogram
		type(StringIntegerMap) :: counts
		type(StringRealMap) :: density
		
		contains
			generic :: init => initStringHistogram
			generic :: assignment(=) => copyStringHistogram
			
			procedure :: initStringHistogram
			procedure :: copyStringHistogram
			final :: destroyStringHistogram
			procedure :: str
			procedure :: show
			
			procedure :: countsBegin
			procedure :: densityBegin
			generic :: pair => countsPair, densityPair
			procedure, private :: countsPair
			procedure, private :: densityPair
			
			generic :: add => addValue, addFArray
			procedure, private :: addValue
			procedure, private :: addFArray
			
			procedure :: build
			procedure :: mean
			procedure :: stdev
			procedure :: mode
			procedure :: median
			procedure :: skewness
			procedure :: stderr
			
	end type StringHistogram
	
	contains
	
	!>
	!! @brief Constructor
	!!
	subroutine initStringHistogram( this )
		class(StringHistogram) :: this
		
		call this.initList()
	end subroutine initStringHistogram
	
	!>
	!! @brief Copy constructor
	!!
	subroutine copyStringHistogram( this, other )
		class(StringHistogram), intent(out) :: this
		class(StringHistogram), intent(in) :: other

		this.counts = other.counts
		this.density = other.density
	end subroutine copyStringHistogram
	
	!>
	!! @brief Destructor
	!!
	subroutine destroyStringHistogram( this )
		type(StringHistogram) :: this
		
		! @warning Hay que verificar que el desructor de la clase padre se llama automaticamente
! 		call this.destroyList()
	end subroutine destroyStringHistogram
	
	!>
	!! @brief Convert to string
	!!
	function str( this, formatted, prefix ) result( output )
		class(StringHistogram) :: this 
		character(:), allocatable :: output
		logical, optional :: formatted
		character(*), optional :: prefix
		
		logical :: effFormatted
		character(:), allocatable :: effPrefix
		
		integer :: fmt
		character(200) :: fstr
		
		effFormatted = .false.
		if( present(formatted) ) effFormatted = formatted
		
		effPrefix = ""
		if( present(prefix) ) effPrefix = prefix
		
		output = ""
		
		if( .not. effFormatted ) then
#define RFMT(v) int(log10(max(abs(v),1.0)))+merge(1,2,v>=0)
#define ITEMS(l,v) output = trim(output)//effPrefix//trim(l)//trim(adjustl(v))
#define ITEMI(l,v) output = trim(output)//l; fmt = RFMT(v); write(fstr, "(i<fmt>)") v; output = trim(output)//trim(fstr)
#define ITEMR(l,v) output = trim(output)//l; fmt = RFMT(v); write(fstr, "(f<fmt+7>.6)") v; output = trim(output)//trim(fstr)
		
			output = trim(output)//"<StringHistogram:"
! 			ITEMI( "min=", this.min )
! 			ITEMR( ",size=", this.size )
#undef RFMT
#undef ITEMS
#undef ITEMI
#undef ITEMR
			output = trim(output)//">"
		else
#define LINE(l) output = trim(output)//effPrefix//l//new_line('')
#define ITEMS(l,v) output = trim(output)//effPrefix//l; write(fstr, "(x,a)") trim(v); output = trim(output)//trim(fstr)//new_line('')
#define ITEMI(l,v) output = trim(output)//effPrefix//l; write(fstr, "(i10)") v; output = trim(output)//trim(fstr)//new_line('')
#define ITEMR(l,v) output = trim(output)//effPrefix//l; write(fstr, "(f10.5)") v; output = trim(output)//trim(fstr)//new_line('')

			LINE("StringHistogram")
			LINE("---------")
! 			ITEMI( "min=", this.min )
! 			ITEMR( ",size=", this.size )
			LINE("")
#undef LINE
#undef ITEMS
#undef ITEMI
#undef ITEMR
		end if
	end function str
	
	!>
	!! @brief Show 
	!!
	subroutine show( this, unit, formatted )
		class(StringHistogram) :: this
		integer, optional, intent(in) :: unit
		logical, optional :: formatted
		
		integer :: effunit
		logical :: effFormatted
		
		effFormatted = .false.
		if( present(formatted) ) effFormatted = formatted
		
		effunit = 6
		if( present(unit) ) effunit = unit
		
		write(effunit,"(a)") trim(str(this,effFormatted))
	end subroutine show
	
	!>
	!! @brief Returns a pointers to the first element of the counts
	!!
	subroutine countsBegin( this, iter )
		class(StringHistogram) :: this
		class(StringIntegerMapIterator), pointer :: iter
		
		iter => this.counts.begin
	end subroutine countsBegin
	
	!>
	!! @brief Returns a pointers to the first element of the density
	!!
	subroutine densityBegin( this, iter )
		class(StringHistogram) :: this
		class(StringRealMapIterator), pointer :: iter
		
		iter => this.density.begin
	end subroutine densityBegin
	
	!>
	!! @brief Returns a pointers to the first element of the density
	!!
	function countsPair( this, iter ) result( output )
		class(StringHistogram) :: this
		class(StringIntegerMapIterator), pointer :: iter
		type(StringIntegerPair) :: output
		
		output = this.counts.pair( iter )
	end function countsPair
	
	!>
	!! @brief Returns a pointers to the first element of the density
	!!
	function densityPair( this, iter ) result( output )
		class(StringHistogram) :: this
		class(StringRealMapIterator), pointer :: iter
		type(StringRealPair) :: output
		
		output = this.density.pair( iter )
	end function densityPair
	
	!>
	!! @brief
	!!
	subroutine addValue( this, value )
		class(StringHistogram) :: this
		type(String), intent(in) :: value
		
		call this.append( value )
	end subroutine addValue
	
	!>
	!! @brief
	!!
	subroutine addFArray( this, array )
		class(StringHistogram) :: this
		character(*), intent(in) :: array(:)
		
		integer :: i
		
		do i=1,size(array)
			call this.append( FString_toString( array(i) ) )
		end do
	end subroutine addFArray
	
	!>
	!! @brief
	!!
	subroutine build( this )
		class(StringHistogram) :: this
		
		class(StringListIterator), pointer :: iter
		integer :: cValue
		
		call this.counts.clear()
		call this.density.clear()
		
		iter => this.begin
		do while( associated(iter) )
			cValue = this.counts.at( iter.data, defaultValue=0 )
			
			call this.counts.set( iter.data, cValue+1 )
			call this.density.set( iter.data, real(cValue+1,8)/real(this.size(),8) )
			
			iter => iter.next
		end do
	end subroutine build
	
	!>
	!! @brief
	!!
	function mean( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
! 		class(RealListIterator), pointer :: iter
! 		
! 		output = 0.0_8
! 		iter => this.begin
! 		do while( associated(iter) )
! 			output = output + iter.data
! 			
! 			iter => iter.next
! 		end do
! 		
! 		output = output/real(this.size(),8)
	end function mean
	
	!>
	!! @brief
	!!
	function stdev( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
! 		class(RealListIterator), pointer :: iter
! 		real(8) :: mean
! 		
! 		if( this.size() == 1 ) then
! 			output = 0.0_8
! 			return
! 		end if
! 		
! 		mean = this.mean()
! 		
! 		output = 0.0_8
! 		iter => this.begin
! 		do while( associated(iter) )
! 			output = output + ( iter.data - mean )**2
! 			
! 			iter => iter.next
! 		end do
! 		
! 		! Bessel's correction
! 		! n->n-1
! 		! standard deviation of the sample (considered as the entire population) -> Corrected sample standard deviation
! 		! Standard deviation of the population -> sample standard deviation
! 		! sigma -> s
! 		output = sqrt( output/real(this.size()-1,8) )
	end function stdev
	
	!>
	!! @brief
	!!
	function mode( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
		stop "### ERROR ### StringHistogram.mode(): This function is unimplemented yet"
	end function mode
	
	!>
	!! @brief
	!!
	function median( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
		stop "### ERROR ### StringHistogram.median(): This function is unimplemented yet"
	end function median
	
	!>
	!! @brief
	!!
	function skewness( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
		stop "### ERROR ### StringHistogram.skewness(): This function is unimplemented yet"
	end function skewness
	
	!>
	!! @brief
	!!
	function stderr( this ) result( output )
		class(StringHistogram), intent(in) :: this
		real(8) :: output
		
		output = this.stdev()/sqrt( real(this.size(),8) )
	end function stderr
	
	!>
	!! @brief Test method
	!!
	subroutine StringHistogram_test()
		type(StringHistogram) :: histogram
		integer :: i
		
		class(StringRealMapIterator), pointer :: iter
		type(StringRealPair) :: pair
		
		call histogram.init()
		
		call histogram.add( ["A", "A", "T", "U", "T", "U", "P", "A", "C", "Z", "U"] )
		call histogram.add( ["B", "F", "G", "O", "T", "Q", "W", "T", "S", "X", "Q"] )
		call histogram.add( ["Y", "F", "I", "E", "U", "W", "H", "A", "D", "C", "W"] )
		call histogram.add( ["I", "F", "W", "O", "L", "R", "S", "H", "F", "V", "E"] )
		call histogram.add( ["W", "R", "T", "E", "I", "S", "V", "K", "G", "B", "R"] )
		call histogram.add( ["U", "I", "T", "U", "S", "G", "R", "X", "H", "N", "T"] )
		call histogram.add( ["I", "I", "P", "O", "N", "X", "C", "U", "J", "M", "Y"] )
		call histogram.add( ["D", "G", "D", "V", "I", "V", "B", "D", "K", "I", "U"] )
		call histogram.add( ["A", "P", "B", "I", "D", "H", "J", "G", "L", "R", "I"] )
		call histogram.add( ["S", "R", "Q", "M", "L", "S", "D", "J", "I", "U", "O"] )
		
		
		call histogram.build()
		
		write(*,"(A20,I15)")   "    size = ", histogram.size()
! 		write(*,"(A20,F15.5)") "    mean = ", histogram.mean()
! 		write(*,"(A20,F15.5)") "   stdev = ", histogram.stdev()
! 		write(*,"(A20,F15.5)") "  stderr = ", histogram.stderr()
! 		
		! plot "./counts.out" w boxes, "./counts.out" w p pt 7
		call histogram.counts.save("counts.out")
		call histogram.density.save("density.out")
		
		call histogram.densityBegin( iter )
		do while( associated(iter) )
			pair = histogram.pair( iter )
			write(*,"(A15,F15.5)") pair.first.fstr, pair.second
			
			iter => iter.next
		end do
		
! 		do i=1,1000000
! 			call histogram.add( 1.456_8 )
! 		end do
! 		
! 		write(*,"(A)")   ""
! 		write(*,"(A20,I15)")   "    size = ", histogram.size()
! 		write(*,"(A20,F15.5)") "    mean = ", histogram.mean()
! 
! ! 		write(*,"(A20,F15.5)") " mode = ", histogram.mode()
! ! 		write(*,"(A20,F15.5)") "stdev = ", histogram.median()
! ! 		mode = histogram.mode()
! ! 		median = histogram.skewness()
		
	end subroutine StringHistogram_test
	
end module StringHistogram_
