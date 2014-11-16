#---------------------------------------------------------------
# Assignment:           1
# Due Date:             January 27, 2014
# Name:                 Lingbo Tang
# Unix ID:              lingbo
# Lecture Section:      B1
# Instructor:           Jacqueline Smih
# Lab Section:          H01
# Teaching Assistant:   Michael Mills
#---------------------------------------------------------------

#---------------------------------------------------------------
# The main program ask as to read an interger from te terminal
# ,invert the byte order of that integer,and then print out the
# new big-endian integer.

# Register Usage:
#
#       a0: used for syscall arguments
#       v0: used for syscall arguments
#       t0: N, the integer we want to convert
#       t1: the first signaficant bytes of te integer
#       t3: the second signaficant bytes of te integer
#       t4: the third signaficant bytes of te integer
#       t5: the fourth signaficant bytes of te integer
#
#---------------------------------------------------------------

        .data
input:
	.asciiz "Input N: \n"
newline:
	.asciiz "\n"
output:
	.asciiz "New integer is: \n"

	.text

main:
	# Print the input
	li $v0, 4
	la $a0, input
	syscall

	# Read in N
	li $v0, 5
	syscall
	
	# Move N to $t0
	move $t0, $v0
	
	
	# Get the bytes
	andi $t1,$t0,0xFF000000
	andi $t2,$t0,0x00FF0000
	andi $t3,$t0,0x0000FF00
	andi $t4,$t0,0x000000FF
	
	# Bit shifting
	srl $t1,$t1,24
	srl $t2,$t2,8
	sll $t3,$t3,8
	sll $t4,$t4,24
	
	# Reconstruct
	or $t0,$t1,$t2
	or $t0,$t0,$t3
	or $t0,$t0,$t4
	
	
	
	

	# Print the output instruction
	
	li $v0, 4
	la $a0, output
	syscall

	# Print the new number that has been converted

	li $v0, 1
	move $a0, $t0
	syscall
	
	li $v0, 4
	la $a0, newline
	syscall

	jr $ra
	
