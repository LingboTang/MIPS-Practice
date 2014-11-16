
    .data
arena:
    .space 32768            # The space we're managing
fence:
    .word 0xffffffff
sizeb0:
    .word 0x0               # Same structure as chunk header, for zero'th busy chunk
addrb0:
    .word 0x0               # Note that both lists have been initialized as empty
sizef0:
    .word 0x0               # Same structure as chunk header, for zero'th free chunk
addrf0:
    .word 0x0
BusyQuestion:
    .asciiz "How many busy chunks? "
FreeQuestion:
    .asciiz "How many free chunks? "
ChunkAddressQuestion:
    .asciiz "What is the address offset of this chunk (must be multiple of 4)? "
ChunkSizeQuestion:
    .asciiz "What is the size of this chunk (in words, minimum is 3)? "
Answer:
    .asciiz " chunks were coalesced.\n"
newline:
    .asciiz "\n"
   
    .text
    .globl main
    .globl coalesce
   
main:
    subu $sp, $sp, 4   # Adjust the stack to save $fp
    sw $fp, 0($sp)     # Save $fp
    move $fp, $sp      # $fp <-- $fp
    subu $sp, $sp, 4   # Adjust stadk to save $ra
    sw $ra, -4($fp)    # Save the return address ($ra)
    la $t7, sizeb0     # t7 will always have the address of the previous header

    # First, build the list of busy chunks
   
    # How many busy chunks are there?
    li $v0, 4
    la $a0, BusyQuestion
    syscall
    li $v0,4
    la $a0, newline
    syscall
    li $v0, 5
    syscall
    move $t0, $v0        # t0 will have the number of chunks to read
    move $a0, $t0
    li $v0 1
    syscall
    li $v0,4
    la $a0, newline
    syscall
  

    # Skip to building free list if no busy chunks
    beq $t0, $0, skipB
   
    # Read the address offset of this chunk
busyHdr:
    li $v0, 4
    la $a0, ChunkAddressQuestion
    syscall
    li $v0,4
    la $a0,newline
    syscall
    li $v0, 5
    syscall
    move $t1, $v0
    move $a0, $t1
    li $v0 1
    syscall
    li $v0,4
    la $a0,newline
    syscall

    # Calculate the absolute address
    la $t3, arena
    addu $t1, $t1, $t3

    # Write this into the header of the previous chunk
    sw $t1, 4($t7)

    # Read the size of this chunk
    li $v0, 4
    la $a0, ChunkSizeQuestion
    syscall
    li $v0,4
    la $a0,newline
    syscall
    li $v0, 5
    syscall
    move $t2, $v0
    move $a0, $t2
    li $v0 1
    syscall
    li $v0,4
    la $a0,newline
    syscall 
 
    # Write the header of this chunk
    sw $t2, 0($t1)   # size of chunk
    sw $0,  4($t1)   # set next NULL

    # Loop control
    add $t7, $t1, $0  # current becomes previous
    addi $t0, $t0, -1  # decrement count
    bnez $t0, busyHdr
   
skipB:
    la $t7, sizef0     # t7 will always have the address of the previous header

    # How many free chunks are there?
    li $v0, 4
    la $a0, FreeQuestion
    syscall
    li $v0,4
    la $a0,newline
    syscall
    li $v0, 5
    syscall
    move $t0, $v0        # t0 will have the number of chunks to read
    move $a0, $t0
    li $v0 1
    syscall
    li $v0,4
    la $a0 newline
    syscall

    # Skip to end if none
    bne $t0, $0, freeHdr
    li $t0, 2
    sw $t0, sizef0
    la $a0, sizef0
    j skipF
  
    # Read the address offset of this chunk
freeHdr:
    li $v0, 4
    la $a0, ChunkAddressQuestion
    syscall
    li $v0,4
    la $a0,newline
    syscall
    li $v0, 5
    syscall
    move $t1, $v0
    move $a0, $t1
    li $v0 1
    syscall
    li $v0, 4
    la $a0, newline
    syscall

    # Calcuate the absolute address
    la $t3, arena
    addu $t1, $t1, $t3

    # Write this into the header of the previous chunk
    sw $t1, 4($t7)

    # Read the size of this chunk
    li $v0, 4
    la $a0, ChunkSizeQuestion
    syscall
    li $v0 4
    la $a0 newline
    syscall
    li $v0, 5
    syscall
    move $t2, $v0
    move $a0, $t2
    li $v0 1
    syscall
    li $v0,4
    la $a0,newline
    syscall
    # Write the header of this chunk
    sw $t2, 0($t1)   # size of chunk
    sw $0,  4($t1)   # set next NULL
   

    # Loop control
    add $t7, $t1, $0  # current becomes previous
    addi $t0, $t0, -1  # decrement count
    bnez $t0, freeHdr

    # Call coalesce
    lw $a0, addrf0
        lw $s2 4($a0)
       

skipF:
    jal coalesce

    # Print the return value
    move $a0, $v0
    li $v0, 1
    syscall
    li $v0, 4
    la $a0, Answer
    syscall
    li $v0,4
    la $a0,newline
    syscall

    # Usual stuff at the end of the main
    lw $ra, -4($fp)
    addu $sp, $sp, 4
    lw $fp, 0($sp)
    addu $sp, $sp, 4



#---------------------------------------------------------------
# Assignment:           5
# Due Date:             April 7th, 2014
# Name:                 Lingbo Tang
# Unix ID:              lingbo
# Lecture Section:      B1
# Instructor:           Jacqueline smith
# Lab Section:          LAB H01
# Teaching Assistant:   Michael Mills
#---------------------------------------------------------------

#-----------------------Register Using---------------------------------------
# This function is the subroutine that coalesce the linked free chunck
# It will identify all the free chunck and check the size and next of a chunck
# If pointer + offset = next then coalesce happens
# Otherwise just keep checking
# It will return how much free chunck has been coalesced and rearrage the memory.
#
# Register Usage in clock:
#	a0:address of the free chunck
#	v0:sum of the number of the free chunck that has been coalesced
#	t8:counter
#	t4:previous size
#	t5:previous next
#	s1:next size
#	s2:next next
#---------------------------------------------------------------

# ------------------------------ program header ------------------------------ #
# This function is the subroutine that coalesce the linked free chunck
# It will identify all the free chunck and check the size and next of a chunck
# If pointer + offset = next then coalesce happens
# Otherwise just keep checking
# It will return how much free chunck has been coalesced and rearrage the memory.
#-------------------------------------------------------------------------------

# -------------------------- subroutine description -------------------------- #
# coalesce: main part of the subroutine,which initialize the first header
# merge: coalesce the two linked chunck
# checkstatus: when pointer + offset != next we have to check
#		if next is null or not.
# resetHdr:	After checking status,if next != NULL
#		set pointer to next and set the new size and new counter
# end:		if next == NULL just end the subroutine and return the sum
#-------------------------------------------------------------------------------

#===============================================================================

#-------------------------------------------------------------------------------
# coalesce: main part of the subroutine,which initialize the first header
#--------------------------------------------------------------------------------

coalesce:
	li $t8 0		#set the counters

loop:
	lw $t4 0($a0)		#get the first free header size
        lw $t5 4($a0)		#get the first free header next
	beqz $t5 end	#if next is null stop the subrountine
        sll $t4 $t4 2		#get the actual offset
	add $a0 $a0 $t4		#shift pointer by actual offset
        beq $a0 $t5 merge	#if pointer + offset = next address just coalesce them

#-------------------------------------------------------------------------------
# merge: coalesce the two linked chunck
#--------------------------------------------------------------------------------

merge:
        lw $s1 0($a0)		#get the size of the next free chunck
        lw $s2 4($a0)		#get the next of the next free chunck
	sub $a0 $a0 $t4		#set the pointer back to the previous
        srl $t4 $t4 2	 	#set the previous size back to the original scale
        add $t4 $t4 $s1		#add both size up to get the sum
        add $t5 $s2 $0		#current next become previous
        sw $t4 0($a0)		#save the new size to the previous chunck to coalesce
        sw $t5 4($a0)		#save the new next to the previous chunck to coalesce
	add $t8 $t8 1		#adding up the counter
        #beq $a0 $t5 loop 		#if pointer + offset = next address just keep running the loop
	bne $a0 $t5 checkstatus	#if pointer + offset != next address just check the status
       	
  
#-------------------------------------------------------------------------------
# checkstatus: when pointer + offset != next we have to check
#		if next is null or not.
#--------------------------------------------------------------------------------

checkstatus:  
	beqz $t5 end	#if next is null stop the subroutine
	bnez $t5 resetHdr	#if next is not null set the pointer to new address

#-------------------------------------------------------------------------------
# resetHdr:	After checking status,if next != NULL
#		set pointer to next and set the new size and new counter
#--------------------------------------------------------------------------------

resetHdr:
	add $a0 $t5 $0		#set the poitner to new address
	add $t4 $0 $0		#set the size as the new chunck size
	#sub $t8 $t8 1		#get rid of the effect of natural join
	j merge			#back to the loop
#---------------------------------------------------------------------------------
# end:	if next == NULL just end the subroutine and return the sum
#---------------------------------------------------------------------------------

end:
	addi $v0 $t8 0		#return the number of chunck which has been coalesced
	jr $ra			#return the result!
