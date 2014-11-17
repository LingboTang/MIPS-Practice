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
	
	j fact
	
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

fact: 
	addi $sp,$sp,12
	sw $ra,8($sp)
	lw $sp,0($a0)
	add $s0,$zero,$sp
	slti $t0,$a0,2
	beq $t0,$zero,L1
	mul $v0,$s0,$v0
	addi $sp,$sp,-8
	jr $ra

L1:
	addi $a0,$a0,-1
	addi $v0,$zero,1
	lw $sp,0($a0)
	lw $ra,4($sp)
	addi $sp,$sp,-8
	jal fact
