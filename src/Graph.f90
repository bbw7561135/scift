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

module Graph_
	use Math_
	use String_
	use IOStream_
	use RealVector_
	use IntegerVector_
	use IntegerHyperVector_
	use Node_
	use Edge_
	use NodeVector_
	use EdgeVector_
	use Matrix_
	implicit none
	private
	
	public :: &
		Graph_test
		
	type, public :: Graph
		type(IntegerHyperVector), private :: node2Neighbors
		type(IntegerHyperVector), private :: node2InEdges
		type(IntegerHyperVector), private :: node2OutEdges
		
		type(NodeVector), private :: nodeProperties
		type(EdgeVector), private :: edgeProperties
		
		logical, private :: directed
		
		! These variables are related with the Dijkstra algorithm
		integer, private :: sNode = -1
		real(8), private, allocatable :: minDistance(:)
		type(IntegerVector), private :: previous
		
		contains
		
		generic :: init => initGraph
		generic :: assignment(=) => copyGraph
		
		procedure :: initGraph
		procedure :: copyGraph
		final :: destroyGraph
		procedure :: clear
		
		procedure :: show
		procedure :: str
		procedure :: nNodes
		procedure :: nEdges
		procedure :: isDirected
		procedure :: isConnected
		procedure :: newNode
		procedure :: newNodes
		procedure :: deleteNode
		procedure, private :: newEdgeBase
		procedure :: newEdge
		procedure :: newEdges
		procedure :: deleteEdge
		procedure :: getEdgeId
		procedure :: computeDijkstraPaths
		procedure :: distance
		procedure :: shortestPath
		procedure :: adjacencyMatrix
		procedure :: distanceMatrix
		procedure :: laplacianMatrix
		procedure :: resistanceDistanceMatrix
		procedure :: diameter
		procedure :: randicIndex
		procedure :: wienerIndex
		procedure :: inverseWienerIndex
		procedure :: balabanIndex
		procedure :: molecularTopologicalIndex
		procedure :: kirchhoffIndex
		procedure :: kirchhoffSumIndex
		procedure :: wienerSumIndex
		procedure :: JOmegaIndex
		
	end type Graph
	
	contains
	
	!>
	!! @brief Constructor
	!!
	subroutine initGraph( this, directed )
		class(Graph) :: this
		logical, optional :: directed
		
		this.directed = .false.
		if( present(directed) ) this.directed = directed
		
		call this.clear()
		
		call this.node2Neighbors.init()
		call this.node2InEdges.init()
		call this.node2OutEdges.init()
		
		call this.nodeProperties.init()
		call this.edgeProperties.init()
	end subroutine initGraph
	
	!>
	!! @brief Copy constructor
	!!
	subroutine copyGraph( this, other )
		class(Graph), intent(inout) :: this
		class(Graph), intent(in) :: other
		
		write(*,*) "### ERROR ### Graph.copyGraph  is not implemented yet"
		stop
	end subroutine copyGraph
	
	!>
	!! @brief Destructor
	!!
	subroutine destroyGraph( this )
		type(Graph), intent(inout) :: this
		
		call this.clear()
	end subroutine destroyGraph
	
	!>
	!! @brief
	!!
	subroutine clear( this )
		class(Graph), intent(inout) :: this
		
		call this.node2Neighbors.clear()
		call this.node2InEdges.clear()
		call this.node2OutEdges.clear()
		
		call this.nodeProperties.clear()
		call this.edgeProperties.clear()
		
		this.sNode = -1
		if( allocated(this.minDistance) ) deallocate(this.minDistance)
		call this.previous.clear()
	end subroutine clear
	
	!>
	!! @brief Show 
	!!
	subroutine show( this, unit, formatted )
		class(Graph) :: this
		integer, optional, intent(in) :: unit
		logical, optional :: formatted
		
		integer :: effunit
		
		effunit = 6
		if( present(unit) ) effunit = unit
		
		write(effunit,"(a)") trim(this.str(formatted=formatted))
	end subroutine show
	
	!>
	!! @brief Convert to string
	!!
	function str( this, formatted ) result( output )
		class(Graph), target :: this 
		character(:), allocatable :: output
		logical, optional :: formatted
		
		logical :: effFormatted
		
		integer :: i, j
		type(IntegerVector), pointer :: ivec
		type(Node), pointer :: node1
		type(Edge), pointer :: edge1
		integer :: edgeStep
		
		effFormatted = .false.
		if( present(formatted) ) effFormatted = formatted
		
		edgeStep = 1
		if( .not. this.isDirected() ) edgeStep = 2
		
		output = ""
		
		if( .not. effFormatted ) then
			output = trim(output)//"<Graph:"
			output = trim(output)//">"
		else
			output = trim(output)//"Graph"//new_line('')
			output = trim(output)//"----------------"//new_line('')
			output = trim(output)//"Number of nodes = "//trim(FString_fromInteger(this.nNodes()))//new_line('')
			output = trim(output)//"Number of edges = "//trim(FString_fromInteger(this.nNodes()))//new_line('')
			output = trim(output)//"      Directed? = "//trim(FString_fromLogical(this.isDirected()))//new_line('')
			output = trim(output)//new_line('')
			
			output = trim(output)//"node2Neighbors"//new_line('')
			do i=1,this.nNodes()
				ivec => this.node2Neighbors.data(i)
				output = trim(output)//"   "//trim(FString_fromInteger(i))//" --> "
				
				do j=1,ivec.size()
					if( j /= ivec.size() ) then
						output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))//","
					else
						output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))
					end if
				end do
				
				output = trim(output)//new_line('')
			end do
			
			output = trim(output)//new_line('')
			output = trim(output)//"Node properties"//new_line('')
			do i=1,this.nNodes()
				node1 => this.nodeProperties.data(i)
				output = trim(output)//"   "//trim(FString_fromInteger(i))//" -->   ("
				output = trim(output)//" "//trim(FString_fromReal(node1.weight,format="(F5.3)"))
				output = trim(output)//", "//trim(FString_fromInteger(node1.id))//" )"//new_line('')
			end do
			
			output = trim(output)//new_line('')
			output = trim(output)//"node2InEdges"//new_line('')
			do i=1,this.nNodes()
				ivec => this.node2InEdges.data(i)
				output = trim(output)//"   "//trim(FString_fromInteger(i))//" --> "
				
				do j=1,ivec.size()
! 					if( this.isDirected() .or. ( .not. this.isDirected() .and. mod(ivec.at(j),2) /= 0 ) ) then
						if( j /= ivec.size() ) then
							output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))//","
						else
							output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))
						end if
! 					end if
				end do
				
				output = trim(output)//new_line('')
			end do
			
			output = trim(output)//new_line('')
			output = trim(output)//"node2OutEdges"//new_line('')
			do i=1,this.nNodes()
				ivec => this.node2OutEdges.data(i)
				output = trim(output)//"   "//trim(FString_fromInteger(i))//" --> "
				
				do j=1,ivec.size()
! 					if( this.isDirected() .or. ( .not. this.isDirected() .and. mod(ivec.at(j),2) /= 0 ) ) then
						if( j /= ivec.size() ) then
							output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))//","
						else
							output = trim(output)//"   "//trim(FString_fromInteger(ivec.at(j)))
						end if
! 					end if
				end do
				
				output = trim(output)//new_line('')
			end do
			
			output = trim(output)//new_line('')
			output = trim(output)//"Edge properties"//new_line('')
! 			do i=1,this.nEdges(),edgeStep
			do i=1,this.nEdges()
				edge1 => this.edgeProperties.data(i)
				output = trim(output)//"  "//trim(FString_fromInteger(i,format="(I2)"))//" -->   ("
				output = trim(output)//" "//trim(FString_fromInteger(edge1.sNode))
				output = trim(output)//", "//trim(FString_fromInteger(edge1.tNode))
				output = trim(output)//", "//trim(FString_fromReal(edge1.weight,format="(F5.3)"))
				output = trim(output)//", "//trim(FString_fromInteger(edge1.id))//" )"//new_line('')
			end do
		end if
		
		ivec => null()
	end function str
	
	!>
	!! @brief
	!!
	pure function nNodes( this ) result( output )
		class(Graph), intent(in) :: this
		integer :: output
		
		output = this.nodeProperties.size()
	end function nNodes
	
	!>
	!! @brief
	!!
	pure function nEdges( this ) result( output )
		class(Graph), intent(in) :: this
		integer :: output
		
		output = this.edgeProperties.size()
	end function nEdges
	
	!>
	!! @brief
	!!
	pure function isDirected( this ) result( output )
		class(Graph), intent(in) :: this
		logical :: output
		
		output = this.directed
	end function isDirected
	
	!>
	!! @brief
	!!
	function isConnected( this, nComponents ) result( output )
		class(Graph), intent(in) :: this
		integer, optional, intent(out) :: nComponents
		logical :: output
		
		integer :: i, nComp
		type(Matrix) :: L
		real(8), allocatable :: diagL(:)
		
		allocate( diagL(this.nNodes()) )
		
		L = this.laplacianMatrix()
		call L.eigen( eValues=diagL )
		
		nComp = 0
		do i=1,this.nNodes()
			if( abs(diagL(i)) < 1e-5 ) then
				nComp = nComp + 1
			end if
		end do
		
		output = .false.
		if( nComp == 1 ) output = .true.
		
		if( present(nComponents) ) nComponents = nComp
		
		deallocate( diagL )
		
	end function isConnected
	
	!>
	!! @brief
	!!
	subroutine newNode( this, id )
		class(Graph) :: this
		integer, optional, intent(out) :: id
		
		integer :: effId
		type(Node) :: node1
		type(IntegerVector) :: ivec
		
		call ivec.init()
		call this.node2Neighbors.append( ivec )
		call this.node2InEdges.append( ivec )
		call this.node2OutEdges.append( ivec )
		
		effId = this.nodeProperties.size()+1
		call node1.init( id=effId )
		call this.nodeProperties.append( node1 )
		
		if( present(id) ) id = effId
	end subroutine newNode
	
	!>
	!! @brief
	!!
	subroutine newNodes( this, n )
		class(Graph) :: this
		integer, intent(in) :: n
		
		integer :: i
		
		do i=1,n
			call this.newNode()
		end do
	end subroutine newNodes
	
	!>
	!! @brief
	!!
	subroutine deleteNode( this, nodeId )
		class(Graph), target :: this
		integer, intent(in) :: nodeId
		
		integer :: i
		type(IntegerVector), pointer :: ivec1
		
! 		type(IntegerHyperVector), private :: node2Neighbors
! 		type(IntegerHyperVector), private :: node2InEdges
! 		type(IntegerHyperVector), private :: node2OutEdges
! 		
! 		type(NodeVector), private :: nodeProperties
! 		type(EdgeVector), private :: edgeProperties

		!        (1)          
		!         |           1 -->   2
		!        (2)          2 -->   1,   3,   4
		!       /   \         3 -->   2,   5
		!     (3)   (4)       4 -->   2,   5
		!       \   /         5 -->   3,   4
		!        (5)
		
		!        (2)          
		!       /   \         2 -->   3,   4
		!     (3)   (4)       3 -->   2,   5
		!       \   /         4 -->   2,   5
		!        (5)          5 -->   3,   4
		
		!        (1)          1 -->   2,   3
		!       /   \         2 -->   1,   4
		!     (2)   (3)       3 -->   1,   4
		!       \   /         4 -->   2,   3
		!        (4)

		
! 		call this.node2Neighbors.erase( nodeId )
		do i=1,this.node2Neighbors.size()
			ivec1 => this.node2Neighbors.data(i)
			call ivec1.remove( nodeId )
		end do
		
! 		call this.node2Neighbors.remove( nodeId )

	end subroutine deleteNode
	
	!>
	!! @brief
	!!
	subroutine newEdgeBase( this, sNode, tNode, weight, id )
		class(Graph), target :: this
		integer, intent(in) :: sNode, tNode
		real(8), optional :: weight
		integer, optional, intent(out) :: id
		
		integer :: effId
		type(Edge) :: edge1
		type(IntegerVector), pointer :: ivec1
		
		! Busco en las vecindades
		ivec1 => this.node2Neighbors.data(sNode)
		if( .not. ivec1.contains(tNode) ) then  ! Si no ha sido agregado ...
			call ivec1.append( tNode )      ! lo adiciono
			
			ivec1 => this.node2OutEdges.data(sNode) ! Busco en las aristas salientes de sNode ...
			effId = this.edgeProperties.size()+1    ! calculo el id que tendra la siguiente arista
			call ivec1.append( effId )   ! Agrego la nueva arista como una arista saliente de sNode
			
			ivec1 => this.node2InEdges.data(tNode) ! Busco en las aristas entrantes de tNode ...
			effId = this.edgeProperties.size()+1    ! calculo el id que tendra la siguiente arista
			call ivec1.append( effId )   ! Agrego la nueva arista como una arista entrantes de tNode
			
			! Creo una nueva arista en las propiedades de arista con el id que he calculado
			call edge1.init( sNode, tNode, id=effId, weight=weight )
			call this.edgeProperties.append( edge1 )
			
			if( present(id) ) id = effId
		end if
		
		ivec1 => null()
	end subroutine newEdgeBase
	
	!>
	!! @brief
	!!
	subroutine newEdge( this, sNode, tNode, weight, id )
		class(Graph), target :: this
		integer, intent(in) :: sNode, tNode
		real(8), optional :: weight
		integer, optional, intent(out) :: id
		
		if( this.directed ) then
			call this.newEdgeBase( sNode, tNode, weight, id )
		else
			call this.newEdgeBase( sNode, tNode, weight, id )
			call this.newEdgeBase( tNode, sNode, weight )
		end if
	end subroutine newEdge
	
	!>
	!! @brief
	!!
	subroutine newEdges( this, sNode, tNodesVec, weights )
		class(Graph) :: this
		integer, intent(in) :: sNode
		integer, intent(in) :: tNodesVec(:)
		real(8), optional, intent(in) :: weights(:)
		
		integer :: i
		
		do i=1,size(tNodesVec)
			call this.newEdge( sNode, tNodesVec(i), weights(i) )
		end do
	end subroutine newEdges
	
	!>
	!! @brief
	!!
	subroutine deleteEdge( this, edgeId )
		class(Graph) :: this
		integer, intent(in) :: edgeId
		
	end subroutine deleteEdge
	
	!>
	!! @brief
	!!
	function getEdgeId( this, sNode, tNode ) result( output )
		class(Graph), target :: this
		integer, intent(in) :: sNode
		integer, intent(in) :: tNode
		integer :: output
		
		type(IntegerVector), pointer :: ivec
		integer :: i, j, idEdge
		
		! Busco en las aristas salientes de sNode
		ivec => this.node2OutEdges.data(sNode)
		
		output = -1
		do i=1,ivec.size()
			idEdge = ivec.at(i)
			
			if( this.edgeProperties.data(idEdge).tNode == tNode ) then
				output = this.edgeProperties.data(idEdge).id
			end if
		end do
		
		ivec => null()
	end function getEdgeId
	
	!>
	!! @brief Breadth First Search
	!!
	subroutine computeDijkstraPaths( this, sNode )
		class(Graph) :: this
		integer, intent(in) :: sNode
		
		integer :: i, n
		type(RealVector) :: nodeDist
		type(IntegerVector) :: nodeSource
		real(8) :: dist
		integer :: u, v
		real(8) :: distance_through_u
		type(IntegerVector) :: neighbors
		
		this.sNode = sNode
		if( allocated(this.minDistance) ) deallocate(this.minDistance)
		call this.previous.clear()
		
		n = this.node2Neighbors.size()
		allocate( this.minDistance(n) )
		
		this.minDistance = Math_INF
		this.minDistance(sNode) = 0
		call this.previous.init( n, value=-1 )
		
		call nodeDist.init()
		call nodeDist.append( this.minDistance(sNode) )
		call nodeSource.append( sNode )
		
		do while( .not. nodeSource.isEmpty() )
			dist = nodeDist.first()
			u = nodeSource.first()
			
			call nodeDist.erase( 1 )
			call nodeSource.erase( 1 )
			
			!! Visit each edge exiting u
			neighbors = this.node2Neighbors.at(u)
			
			do i=1,neighbors.size()
				v = neighbors.at(i)
				distance_through_u = dist + this.edgeProperties.data( this.getEdgeId(u,v) ).weight
				
				if( distance_through_u < this.minDistance(v) ) then
					call nodeDist.remove( this.minDistance(v) )
					call nodeSource.remove( v )
			
					this.minDistance(v) = distance_through_u
					call this.previous.set( v, u )
					
					call nodeDist.append( this.minDistance(v) );
					call nodeSource.append( v );
				end if
			end do
		end do
	end subroutine computeDijkstraPaths
	
	!>
	!! @brief Returns the distance from source node (@see computeDijkstraPaths) to node tNode.
	!!        If tNode was not reached, it returns -1
	!!
	function distance( this, tNode ) result( output )
		class(Graph), intent(in) :: this
		integer, intent(in) :: tNode
		real(8) :: output
		
		if( this.sNode == -1 ) then
			output = -1
			return
		end if
		
		output = this.minDistance( tNode )
		if( Math_isInf(output) ) output = -1
	end function distance
	
	!>
	!! @brief Returns the distance from source node (@see computeDijkstraPaths) to node tNode.
	!!        If tNode was not reached, it returns -1
	!!
	function shortestPath( this, tNode ) result( output )
		class(Graph), intent(in) :: this
		integer, intent(in) :: tNode
		type(IntegerVector) :: output
		
		integer :: node
		
		if( this.sNode == -1 ) return
		
		call output.clear()
		
		node = tNode
		do while( node /= -1 )
			call output.prepend( node )
			node = this.previous.at(node)
		end do
	end function shortestPath
	
	!>
	!! @brief 
	!!
	function adjacencyMatrix( this ) result( output )
		class(Graph), target :: this
		type(Matrix) :: output
		
		integer :: i, j
		type(IntegerVector), pointer :: iNeighbors
		
		call output.init( this.nNodes(), this.nNodes(), val=0.0_8 )
		
		! Hago todos los i y todos los j para no tener que asumir que es
		! simetrica en el caso no dirigido. Se obtebdra automaticamente
		do i=1,this.nNodes()
			iNeighbors => this.node2Neighbors.data(i)
			
			do j=1,this.nNodes()
				if( i/=j .and. iNeighbors.contains(j) ) then
					call output.set( i, j, 1.0_8 )
				end if
			end do
		end do
		
		iNeighbors => null()
	end function adjacencyMatrix
	
	!>
	!! @brief Returns the distance from source node (@see computeDijkstraPaths) to node tNode.
	!!        If tNode was not reached, it returns -1
	!!
	function distanceMatrix( this ) result( output )
		class(Graph) :: this
		type(Matrix) :: output
		
		integer :: i, j
		
		call output.init( this.nNodes(), this.nNodes(), val=0.0_8 )
		
		! Hago todos los i y todos los j para no tener que asumir que es
		! simetrica en el caso no dirigido. Se obtebdra automaticamente
		do i=1,this.nNodes()
			call this.computeDijkstraPaths( i )
			
			do j=1,this.nNodes()
				call output.set( i, j, real(this.distance(j),8) )
			end do
		end do
	end function distanceMatrix
	
	!>
	!! @brief
	!!
	function laplacianMatrix( this ) result( output )
		class(Graph), target, intent(in) :: this
		type(Matrix) :: output
		
		integer :: i, j
		type(IntegerVector), pointer :: iNeighbors
		
		call output.init( this.nNodes(), this.nNodes(), val=0.0_8 )
		
		! Hago todos los i y todos los j para no tener que asumir que es
		! simetrica en el caso no dirigido. Se obtebdra automaticamente
		do i=1,this.nNodes()
			iNeighbors => this.node2Neighbors.data(i)
			
			do j=1,this.nNodes()
				if( i==j ) then
					call output.set( i, i, real(iNeighbors.size(),8) )
				else if( i/=j .and. iNeighbors.contains(j) ) then
					call output.set( i, j, -1.0_8 )
				end if
			end do
		end do
		
		iNeighbors => null()
	end function laplacianMatrix
	
	!>
	!! @brief
	!!
	function resistanceDistanceMatrix( this, laplacianMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: laplacianMatrix
		type(Matrix) :: output
		
		integer :: i, j
		type(Matrix) :: L, Phi, Gamma
		
		if( present(laplacianMatrix) ) then
			L = laplacianMatrix
		else
			L = this.laplacianMatrix()
		end if
		
		call Phi.init( this.nNodes(), this.nNodes(), val=1.0_8/real(this.nNodes(),8) )
		
		Gamma = L + Phi
		Gamma = Gamma.inverse()
		
		call output.init( this.nNodes(), this.nNodes() )
		
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				call output.set( i, j, Gamma.get(i,i)+Gamma.get(j,j)-Gamma.get(i,j)-Gamma.get(j,i) )
			end do
		end do
	end function resistanceDistanceMatrix
	
	!>
	!! @brief 
	!!
	function diameter( this, distanceMatrix ) result( output )
		class(Graph) :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		real(8) :: output
		
		type(Matrix) :: dMatrix
		integer :: i, j
		
		if( present(distanceMatrix) ) then
			dMatrix = distanceMatrix
		else
			dMatrix = this.distanceMatrix()
		end if
		
		output = maxval(dMatrix.data)
	end function diameter
	
	!>
	!! @brief 
	!!
	function randicIndex( this ) result( output )
		class(Graph), target :: this
		real(8) :: output
		
		integer :: i
		real(8) :: vs, vt
		type(Edge), pointer :: edgei
		type(IntegerVector), pointer :: neighbors
		
		output = 0.0_8
		
		do i=1,this.nEdges()
			edgei => this.edgeProperties.data(i)
			
			neighbors => this.node2Neighbors.data(edgei.sNode)
			vs = neighbors.size()
			
			neighbors => this.node2Neighbors.data(edgei.tNode)
			vt = neighbors.size()
			
			output = output + 1.0_8/sqrt(vs*vt)
		end do
		
		if( .not. this.isDirected() ) output = output/2.0_8
		
		neighbors => null()
	end function randicIndex
	
	!>
	!! @brief 
	!!
	function wienerIndex( this, distanceMatrix ) result( output )
		class(Graph) :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		real(8) :: output
		
		type(Matrix) :: dMatrix
		integer :: i, j
		
		if( present(distanceMatrix) ) then
			dMatrix = distanceMatrix
		else
			dMatrix = this.distanceMatrix()
		end if
		
		output = 0.0_8
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				output = output + dMatrix.get(i,j)
			end do
		end do
		output = output/2.0_8
	end function wienerIndex
	
	!>
	!! @brief 
	!!
	function inverseWienerIndex( this, distanceMatrix ) result( output )
		class(Graph) :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		real(8) :: output
		
		type(Matrix) :: dMatrix
		integer :: i, j
		real(8) :: diam
		
		if( present(distanceMatrix) ) then
			dMatrix = distanceMatrix
		else
			dMatrix = this.distanceMatrix()
		end if
		
		diam = this.diameter( distanceMatrix=dMatrix )
		
		output = 0.0_8
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				if( i/=j ) then
					output = output + ( diam - dMatrix.get(i,j) )
				end if
			end do
		end do
		output = output/2.0_8
	end function inverseWienerIndex
	
	!>
	!! @brief 
	!!
	function balabanIndex( this, distanceMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		real(8) :: output
		
		type(Matrix) :: dMatrix
		integer :: i
		real(8) :: ds, dt
		type(Edge), pointer :: edgei
		
		if( present(distanceMatrix) ) then
			dMatrix = distanceMatrix
		else
			dMatrix = this.distanceMatrix()
		end if
		
		output = 0.0_8
		
		do i=1,this.nEdges()
			edgei => this.edgeProperties.data(i)
			
			ds = sum( dMatrix.data(edgei.sNode,:) )
			dt = sum( dMatrix.data(edgei.tNode,:) )
			
			output = output + 1.0_8/sqrt(ds*dt)
		end do
		
		output = this.nEdges()*output/real(this.nEdges()-this.nNodes()+2,8)
		
		if( .not. this.isDirected() ) output = output/2.0_8
	end function balabanIndex
	
	!>
	!! @brief
	!!         Molecular topological index: a relation with the Wiener index
	!!         Douglas J. Klein, Zlatko Mihalic, Dejan Plavsic, Nenad Trinajstic
	!!         J. Chem. Inf. Comput. Sci., 1992, 32 (4), pp 304–305
	!!
	function molecularTopologicalIndex( this, adjacencyMatrix, distanceMatrix ) result( output )
		class(Graph), target, intent(in) :: this
		type(Matrix), optional, intent(in) :: adjacencyMatrix
		type(Matrix), optional, intent(in) :: distanceMatrix
		real(8) :: output
		
		type(Matrix) :: A, D
		integer :: i, j
		integer :: vj
		
		if( present(adjacencyMatrix) ) then
			A = adjacencyMatrix
		else
			A = this.adjacencyMatrix()
		end if
		
		if( present(distanceMatrix) ) then
			D = distanceMatrix
		else
			D = this.distanceMatrix()
		end if
		
		! Hago todos los i y todos los j para no tener que asumir que es
		! simetrica en el caso no dirigido. Se obtebdra automaticamente
		output = 0.0_8
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				vj = this.node2Neighbors.data(j).size()
				output = output + real(vj,8)*( A.get(i,j) + D.get(i,j) )
			end do
		end do
	end function molecularTopologicalIndex
	
	!>
	!! @brief 
	!!
	function kirchhoffIndex( this, resistanceDistanceMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: resistanceDistanceMatrix
		real(8) :: output
		
		type(Matrix) :: Omega
		
		if( present(resistanceDistanceMatrix) ) then
			Omega = resistanceDistanceMatrix
		else
			Omega = this.resistanceDistanceMatrix()
		end if
		
		output = this.wienerIndex( distanceMatrix=Omega )
	end function kirchhoffIndex
	
	!>
	!! @brief 
	!!
	function kirchhoffSumIndex( this, distanceMatrix, resistanceDistanceMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		type(Matrix), optional, intent(in) :: resistanceDistanceMatrix
		real(8) :: output
		
		integer :: i, j
		type(Matrix) :: D, Omega, OmegaD
		
		if( present(distanceMatrix) ) then
			D = distanceMatrix
		else
			D = this.distanceMatrix()
		end if
		
		if( present(resistanceDistanceMatrix) ) then
			Omega = resistanceDistanceMatrix
		else
			Omega = this.resistanceDistanceMatrix()
		end if
		
		OmegaD = Omega
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				if( i/=j ) then
					call OmegaD.set( i, j, OmegaD.get(i,j)/D.get(i,j) )
				end if
			end do
		end do
		
		output = this.wienerIndex( distanceMatrix=OmegaD )
	end function kirchhoffSumIndex
	
	!>
	!! @brief 
	!!
	function wienerSumIndex( this, distanceMatrix, resistanceDistanceMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		type(Matrix), optional, intent(in) :: resistanceDistanceMatrix
		real(8) :: output
		
		integer :: i, j
		type(Matrix) :: D, Omega, DOmega
		
		if( present(distanceMatrix) ) then
			D = distanceMatrix
		else
			D = this.distanceMatrix()
		end if
		
		if( present(resistanceDistanceMatrix) ) then
			Omega = resistanceDistanceMatrix
		else
			Omega = this.resistanceDistanceMatrix()
		end if
		
		DOmega = Omega
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				if( i/=j ) then
					call DOmega.set( i, j, D.get(i,j)/DOmega.get(i,j) )
				end if
			end do
		end do
		
		output = this.wienerIndex( distanceMatrix=DOmega )
	end function wienerSumIndex
	
	!>
	!! @brief 
	!!
	function JOmegaIndex( this, distanceMatrix, resistanceDistanceMatrix ) result( output )
		class(Graph), target :: this
		type(Matrix), optional, intent(in) :: distanceMatrix
		type(Matrix), optional, intent(in) :: resistanceDistanceMatrix
		real(8) :: output
		
		integer :: i, j
		type(Matrix) :: D, Omega, OmegaD
		
		if( present(distanceMatrix) ) then
			D = distanceMatrix
		else
			D = this.distanceMatrix()
		end if
		
		if( present(resistanceDistanceMatrix) ) then
			Omega = resistanceDistanceMatrix
		else
			Omega = this.resistanceDistanceMatrix()
		end if
		
		OmegaD = Omega
		do i=1,this.nNodes()
			do j=1,this.nNodes()
				if( i/=j ) then
					call OmegaD.set( i, j, OmegaD.get(i,j)/D.get(i,j) )
				end if
			end do
		end do
		
		output = this.balabanIndex( distanceMatrix=OmegaD )
	end function JOmegaIndex
	
	!>
	!! @brief Test method
	!!
	subroutine Graph_test()
		type(Graph) :: mygraph
! 		class(IntegerHyperVectorIterator), pointer :: iter

		type(IntegerVector) :: ivec
		integer :: id
		type(IntegerVector) :: path
		
		type(Matrix) :: AMatrix, dMatrix, LMatrix, OmegaMatrix
		
		integer :: i
		
		call mygraph.init()
		
		!------------------------------------------
		! Ejemplo 1
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		
! 		call mygraph.newEdges( 1, [2,3,6] )
! 		call mygraph.newEdges( 2, [1,3,4] )
! 		call mygraph.newEdges( 3, [1,2,4,6] )
! 		call mygraph.newEdges( 4, [2,3,5] )
! 		call mygraph.newEdges( 5, [4,6] )
! 		call mygraph.newEdges( 6, [1,3,5] )

! 		!------------------------------------------
! 		! Ejemplo 3
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		call mygraph.newNode()
! 		
! 		call mygraph.newEdges( 1, [2,3,4] )
! 		call mygraph.newEdges( 2, [5,1] )
! 		call mygraph.newEdges( 3, [8] )
! 		call mygraph.newEdges( 4, [1] )
! 		call mygraph.newEdges( 5, [2,6,7] )
! 		call mygraph.newEdges( 6, [5] )
! 		call mygraph.newEdges( 7, [5] )
! 		call mygraph.newEdges( 8, [3] )
! 
! 		!------------------------------------------
! 		! Ejemplo 2
! ! 		call mygraph.newNode()
! ! 		call mygraph.newNode()
! ! 		call mygraph.newNode()
! ! 		call mygraph.newNode()
! ! 		call mygraph.newNode()
! ! 		call mygraph.newNode()
! ! 		
! ! 		call mygraph.newEdges( 1, [2] )
! ! 		call mygraph.newEdges( 2, [1,3,4] )
! ! 		call mygraph.newEdges( 3, [2,4] )
! ! 		call mygraph.newEdges( 4, [2,3,5] )
! ! 		call mygraph.newEdges( 5, [4,6] )
! ! 		call mygraph.newEdges( 6, [5] )
! 
! 		call mygraph.show()
! 		
! 		call mygraph.computeDijkstraPaths( 8 )
! 		write(*,*) "distance from 1 to 6 = ", mygraph.distance(7)
! 		path = mygraph.shortestPath(7)
! 		call path.show()

		!------------------------------------------
		! Ejemplo Diego
		call mygraph.newNode()
		call mygraph.newNode()
		call mygraph.newNode()
		call mygraph.newNode()
		
		call mygraph.newEdges( 1, [2,3,4], [1.01_8,1.43_8,1.01_8] )
		call mygraph.newEdges( 2, [1,4,3], [1.01_8,1.43_8,1.01_8] )
		call mygraph.newEdges( 3, [2,1,4], [1.01_8,1.43_8,1.01_8] )
		call mygraph.newEdges( 4, [1,2,3], [1.01_8,1.43_8,1.01_8] )
		
		call mygraph.show( formatted=.true. )
		
		call mygraph.computeDijkstraPaths( 1 )
		write(*,*) "Distance from 1 to 3 = ", mygraph.distance(3)
		path = mygraph.shortestPath(3)
		write(*,*) "Path(1,3) = "
		call path.show()
		
		write(*,*) "Adjacency matrix"
		AMatrix = mygraph.adjacencyMatrix()
		call AMatrix.show( formatted=.true. )
		write(*,*) ""
		write(*,*) "Distance matrix"
		dMatrix = mygraph.distanceMatrix()
		call dMatrix.show( formatted=.true. )
		write(*,*) ""
		write(*,*) "Laplacian matrix"
		LMatrix = mygraph.laplacianMatrix()
		call LMatrix.show( formatted=.true. )
		write(*,*) ""
		write(*,*) "Resistance-Distance matrix"
		OmegaMatrix = mygraph.resistanceDistanceMatrix( laplacianMatrix=LMatrix )
		call OmegaMatrix.show( formatted=.true. )
		write(*,*) ""
		write(*,*) "Indices"
		write(*,*) "-------"
		write(*,*) "Randic               = ", mygraph.randicIndex()
		write(*,*) "Wiener               = ", mygraph.wienerIndex( distanceMatrix=dMatrix )
		write(*,*) "Wiener               = ", mygraph.inverseWienerIndex( distanceMatrix=dMatrix )
		write(*,*) "Balaban              = ", mygraph.balabanIndex( distanceMatrix=dMatrix )
		write(*,*) "MolecularTopological = ", mygraph.molecularTopologicalIndex( adjacencyMatrix=AMatrix, distanceMatrix=dMatrix )
		write(*,*) "Kirchhoff            = ", mygraph.kirchhoffIndex( resistanceDistanceMatrix=OmegaMatrix )
		write(*,*) "KirchhoffSum         = ", mygraph.kirchhoffSumIndex( distanceMatrix=dMatrix, resistanceDistanceMatrix=OmegaMatrix )
		write(*,*) "wienerSum            = ", mygraph.wienerSumIndex( distanceMatrix=dMatrix, resistanceDistanceMatrix=OmegaMatrix )
		write(*,*) "JOmega               = ", mygraph.JOmegaIndex( distanceMatrix=dMatrix, resistanceDistanceMatrix=OmegaMatrix )
		
! 		write(*,*) "idEdge(3,4) = ", mygraph.getEdgeId( 3, 4 )
! 		write(*,*) "idEdge(4,3) = ", mygraph.getEdgeId( 4, 3 )
! 		write(*,*) "idEdge(2,4) = ", mygraph.getEdgeId( 2, 4 )
		
		write(*,*) ""
		write(*,*) "Apollonian Network 2"
		write(*,*) "--------------------"
		call mygraph.init()
		
		call mygraph.newNodes( 7 )
		call mygraph.newEdges( 1, [2,5,4,6,3] )
		call mygraph.newEdges( 2, [1,5,4,7,3] )
		call mygraph.newEdges( 3, [1,6,4,7,2] )
		call mygraph.newEdges( 4, [1,5,2,7,3,6] )
		call mygraph.newEdges( 5, [1,2,4] )
		call mygraph.newEdges( 6, [1,4,3] )
		call mygraph.newEdges( 7, [3,4,2] )
		
		write(*,*) "Index                             expected                obtained"
		write(*,*) "Wiener                 ", 27.0_8, mygraph.wienerIndex()
		write(*,*) "MolecularTopological   ", 360.0_8, mygraph.molecularTopologicalIndex()
		write(*,*) "Kirchhoff              ", 834.0_8/85.0_8, mygraph.kirchhoffIndex()
		write(*,*) "KirchhoffSum           ", 672.0_8/85.0_8, mygraph.kirchhoffSumIndex()
		
		write(*,*) ""
		write(*,*) "Testing delete nodes and edges"
		write(*,*) "------------------------------"
		call mygraph.clear()
		call mygraph.newNode()
		call mygraph.newNode()
		call mygraph.newNode()
		call mygraph.newNode()
		call mygraph.newNode()
		
		call mygraph.newEdges( 1, [2], [1.01_8] )
		call mygraph.newEdges( 2, [3,4], [1.01_8,1.43_8] )
		call mygraph.newEdges( 3, [5], [1.01_8] )
		call mygraph.newEdges( 4, [5], [1.01_8] )
		
		!        (1)
		!         |
		!        (2)
		!       /   \
		!     (3)   (4)
		!       \   /
		!        (5)
		
		call mygraph.show( formatted=.true. )
		
		call mygraph.deleteNode( 1 )
		
		!        (2)
		!       /   \
		!     (3)   (4)
		!       \   /
		!        (5)
		
		!        (1)
		!       /   \
		!     (2)   (3)
		!       \   /
		!        (4)
		
		call mygraph.show( formatted=.true. )
		
	end subroutine Graph_test

end module Graph_
