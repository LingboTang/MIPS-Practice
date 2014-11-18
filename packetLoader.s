#-------------------------------
# Packet Forwarding Student Test Environment
# Author: Taylor Lloyd
# Date: June 4, 2012
#
# This code loads in a packet from a file named 
# packet.in and calls handlePacket with the 
# appropriate argument.
#
# Nothing is done with the returned values, it is up
# to the student to check them.
#
#-------------------------------

.data

packetFile:
.asciiz "./packet.dat"
.align 2
packetData:
.space 200
nl:
.asciiz "\n"
.text
main:
#Open the packet file
	la	$a0 packetFile #filename
	li	$a1 0x00 #flags
	li	$a2 0x0644 #file mode
	li	$v0 13 
	syscall #file_open
#Read into buffer
	move 	$a0 $v0
	la	$a1 packetData
	li	$a2 200
	li	$v0 14
	syscall #file_read
#Close the reading file
	li	$v0 16
	syscall

#Run the appended solution
	la	$a0 packetData
	jal	handlePacket
################### Here the solution can be checked for accuracy #######
	move   $t0, $v1
    	move   $a0, $v0
    	li      $v0, 1
    	syscall
    
    	la      $a0, nl
    	li      $v0, 4
    	syscall

    	move    $a0, $t0
    	li      $v0, 1
    	syscall

	la      $a0, nl
    	li      $v0, 4
    	syscall

	li	$v0 10
	syscall
################### Student handlePacket code begins here ###############
handlePacket:
# set up stack pointer and get the registers saved 
	addi $sp,$sp,-4
	sw $ra,0($sp)
# initialize the checksum and carryout
	add $s0,$a0,$0
	li $s7,0
# Mask and get the version of the IP

	lb $t0,0($a0)
	srl $t1,$t0,4

# Check if the the version is IPv4

	bne $t1, 4, Drop1

# Verify the header checksum is valid
# Mask and get the header length

	addi $t2,$zero,0xf
        and $a1,$t0,$t2

# Mask the checksum and convert it to big-Endianness order
# This should be done in a loop
# Check the sum from the 0 bit
setupsum:
#coyp the version code and the packet header length code for use
        add $s0,$a0,$0
        add $s1,$a1,$0
#initialize t0 for the sum
	addi $s2,$zero,0
        lhu $s6,10($a0)
	sb $zero,10($a0)
	sb $zero,11($a0)
	
loop2:
	#load the address and add them as unsigned integer
	lw $t3,0($s0)
	# Get the bytes
	srl $t4,$t3,16
	andi $t4,$t4,0x000000ff
	srl $t5,$t3,24
	andi $t5,$t5,0x000000ff
	andi $t6,$t3,0x0000ff00
	andi $t7,$t3,0x000000ff
	
	# Bit shifting
	sll $t4,$t4,8
	srl $t6,$t6,8
	sll $t7,$t7,8

	# Reconstruct
	or $t3,$t4,$t5
	sll $t3,$t3,16
	or $t3,$t3,$t6
	or $t3,$t3,$t7
	
	srl $t4,$t3,16
	andi $t4,$t4,0x0000ffff
	andi $t5,$t3,0x0000ffff
	addu $t5,$t4,$t5
	addu $s2,$s2,$t5
	addi $s0,$s0,4
	addi $s1,$s1,-1
	bne  $s1,$zero,loop2


	srl $t0,$s2,16
        sll $s2 $s2 16
        srl $s2 $s2 16
	add $s2,$s2,$t0
	xor $s2,$s2,0xffff
	andi $t0,$s2,0x000000ff
	srl $s2,$s2,8
	sll $t0,$t0,8
	or $s2,$t0,$s2
	bne $s7,$zero,countinue
        bne $s2,$s6,Drop3	


checkTTL:
	#get the code for TTL
	lb $t4, 8($a0)
	#if TTL is less than two
	slti $t5,$t4,2
	#go to the Wrong TTL branch
	bnez $t5,Drop2
	#else save the new TTL
	addi $t4,$t4,-1
	sb $t4, 8($a0)


recalculate:
	#save the new checksum in it position
	addi $s7,$s7,1
	j setupsum

countinue:
	sh $s2,10($a0)
	li $v0,1
	add $v1,$a0,$0
	j done

Drop1:
	li $v1,2
	li $v0,0
	j done

Drop2:
	li $v1,1
	li $v0,0
	j done

Drop3:
	li $v0 0
	li $v1 0
	j done

done:
	lw $ra,0($sp)
	addi $sp,$sp,4
	jr $ra
