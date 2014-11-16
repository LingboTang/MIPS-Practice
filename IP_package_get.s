#---------------------------------------------------------------
# Assignment:           3
# Due Date:             October 28, 2013
# Name:                 Lingbo Tang
# Unix ID:              ann
# Lecture Section:      A2
# Instructor:           Jose Amaral
# Lab Section:          LAB D02 (T 2:00 - 4:50)
# Teaching Assistant:   Mike Mills
#---------------------------------------------------------------
#---------------------------------------------------------------
# The handlePacket is a function in the program
# It uses the given address of the instruction to find
# Whether the packet is valid to send
# When it is valid, it return the address of packet to send and valid sign
# Else it return an unvalid sign and it reason of fail
#
# Register Usage:
#	a0:address of the packet(const)
#	a1:packet header length(const)
#	s0:address of the packet(use and change)
#	s1:address of the packet(use and change)
#	s2:sum in checksum
#	s3:checksum
#	s7:whether to do recalcuate of checksum
#	t1:version
#	t2:every word
#	t3:every carryout
#	t4:TTL
#	v0:valid sign in handlePacket
#	v1:address of packet to send or the reason of fail
#---------------------------------------------------------------


#----------------------------------------------------------------------
#start the branch to handle the packet
#----------------------------------------------------------------------
handlePacket:   
	#get the place and save the register address
	addi	$sp $sp -4 
	sw	$ra 0($sp)
	#copy the address and set the recalulate checksum to zero
	add	$s0 $a0 $0
	add	$s7 $0 $0
#---------------------------------------------------------------------
#check the version
#---------------------------------------------------------------------
	#get the version code in the first byte
	lb	$t0 0($a0)
	srl	$t1 $t0 4
	bne	$t1 4 WrongVersion
	#get to wrong version branch if it is 
#----------------------------------------------------------------------
#get the packet header length
#----------------------------------------------------------------------
	#get the packet header length code in the first byte
        li	$t4 0xf
        and	$a1 $t0 $t4

#----------------------------------------------------------------------
#calculate the checksum
#----------------------------------------------------------------------

checksum:
	#coyp the version code and the packet header length code for use
        add	$s0 $a0 $0
        add	$s1 $a1 $0
	#initialize t0 for the sum
	add	$s2 $0 $0

check_loop:
	#low each 4 bytes and adding them without overflow 
	lw	$t2 0($s0)
	addu	$s2 $s2 $t2
	#set and add the carryout
	sltu	$t3 $s2 $t2
	addu	$s2 $s2 $t3
	#increase the address and reduce the length
	addi	$s0 $s0 4
	addi	$s1 $s1 -1
	bne     $s1 $0 check_loop
        
	#add the first 16 bit and the last 16 bit
	#add at the higher bit to set the carryout
	sll	$t2 $s2 16
	addu	$s2 $s2 $t2
	#set the carryout
	sltu	$t3 $s2 $t2
	#put put the value to the right position and add carryout	
	srl	$s2 $s2 16 
	add	$s2 $s2 $t3
	#negation the sum
	sll	$s2 $s2 16
	nor	$s2 $s2 $0
	srl	$s3 $s2 16
	#when the recalcuation=1, get back to the position of calls
	#else continue to the check valid checksume
	bnez	$s7 continue

#----------------------------------------------------------------------
#check valid checksum
#----------------------------------------------------------------------
	bne	$s3 $0 ChecksumFail

#----------------------------------------------------------------------
#get time to live and upload it
#----------------------------------------------------------------------
	#get the code for TTL
	lb	$t4 8($a0)
	#if TTL is less than two
	slti	$t5 $t4 2
	#go to the Wrong TTL branch
	bnez	$t5 WrongTTL
	#else save the new TTL
	add	$t4 $t4 -1
	sb	$t4 8($a0)

#----------------------------------------------------------------------
#recalculate checksum
#----------------------------------------------------------------------
	#put the byte of header checksum to zero
	#and calculate the new checksum
	sb	$0 10($a0)
	sb	$0 11($a0)
	#set the recalculate to 1
	addi	$s7 $s7 1
        j	checksum
continue:
	#save the new checksum in it position
	sb	$s3 10($a0)
	srl	$t6 $s3 8
	sb	$t6 11($a0)

#----------------------------------------------------------------------
#success end
#----------------------------------------------------------------------
	#end set the return value
	#v1=address of header
	#v0=1
	li	$v0 1
	add	$v1, $a0 $0
	j	End

#----------------------------------------------------------------------
#fail end
#----------------------------------------------------------------------
	#end set the return value
	#v1=reason for fail
	#v0=0
ChecksumFail:   

	li	$v0 0
	li	$v1 0
        j	End

WrongTTL:    
	li	$v0 0   
	li	$v1 1
        j	End

WrongVersion:   
	li	$v0 0
	li	$v1 2
        j	End
        
#----------------------------------------------------------------------
#final end
#----------------------------------------------------------------------
End:    
	#load the value of register address
	#reset the stack pointer
	#return to the main function
	lw	$ra 0($sp)
        addi	$sp $sp 4
        jr	$ra       
