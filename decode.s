#---------------------------------------------------------------
# Assignment:           1
# Due Date:             Febuary 10, 2014
# Name:                 Lingbo Tang
# Unix ID:              lingbo
# Lecture Section:      B1
# Instructor:           Jacqueline Smih
# Lab Section:          H01
# Teaching Assistant:   Michael Mills
#---------------------------------------------------------------

.data
	type1: .asciiz "bgez" 
	type2: .asciiz "bgezal"
	type3: .asciiz "bltz"
	type4: .asciiz "bltzal"
	type5: .asciiz "beq"
	type6: .asciiz "bne"
	type7: .asciiz "blez"
	type8: .asciiz "bgtz"
	space: .asciiz " "
	dollar: .asciiz "$"
	comma: .asciiz ","

.text

disassembleBranch:
	#Read bin file and store them to the global address

	move $s1,$a0
	lw $s0,0($a0)

	#Mask the first 6bits

	srl $t0,$s0,26
	andi $t0,$t0,0x000000ff

	#masking 000001

	beq $t0,1,six_zero_branch
	
	#masking 000100

	beq $t0,4,beqflag

	#masking 000101

	beq $t0,5,bneflag

	#maksing 000110

	beq $t0,6,blezflag

	#masking 000111

	beq $t0, 7,bgtzflag

	#if nothing in input file, jump to the end

	j done

six_zero_branch:
	#masking the five bits after $s

	srl $t0,$s0,16
	andi $t0,$t0,0x0000001f

	#masking bgezflag

	beq $t0,1,bgezflag

	#masking bgezalflag

	beq $t0,17,bgezalflag

	#masking bltzflag
	
	beq $t0,0,bltzflag

	#masking bltzalflag

	beq $t0,16,bltzalflag

# print the flag
bgezflag:
	
	li $v0,4
	la $a0, type1
	syscall
	li $v0,4
	la $a0,space
	syscall	
	j decode_source	

bgezalflag:
	li $v0,4
	la $a0, type2
	syscall	
	li $v0,4
	la $a0,space
	syscall	
	j decode_source	

bltzflag:
	li $v0,4
	la $a0, type3
	syscall	
	li $v0,4
	la $a0,space
	syscall	
	j decode_source

bltzalflag:
	li $v0,4
	la $a0, type4
	syscall	
	li $v0,4
	la $a0,space
	syscall	
	j decode_source

beqflag:
	li $v0,4
	la $a0, type5
	syscall
	li $v0,4
	la $a0,space
	syscall	
	j decode_target # Because this branch will contain a register $rt
	
	
bneflag:
	li $v0,4
	la $a0, type6
	syscall
	li $v0,4
	la $a0,space
	syscall	
	j decode_target

	
blezflag:
	li $v0,4
	la $a0, type7
	syscall
	li $v0,4
	la $a0,space
	syscall	
	j decode_source

bgtzflag:
	li $v0,4
	la $a0, type8
	syscall
	li $v0,4
	la $a0,space
	syscall	
	j decode_source

decode_source: 
	# mask the rs

	srl $t0, $s0,21
	andi $t0,$t0,0x0000001f

	#print the dollar sign

	
	li $v0,4
	la $a0,dollar
	syscall

	#print the value of the rs
	li $v0,1
	move $a0, $t0
	syscall

	#print the comma and space

	li $v0,4
 	la $a0,comma
	syscall
	li $v0,4
	la $a0,space
	syscall
	j decode_address

decode_target:
	# mask the rs

	srl $t0,$s0,21
	andi $t0,$t0,0x0000001f

	#print the dollar sign

	
	li $v0, 4
	la $a0,dollar
	syscall

	#print the value of the rs

	li $v0,1
	move $a0,$t0
	syscall

	# mask the rt

	srl $t0,$s0,16
	andi $t0,$t0,0x0000001f

	# print the comma,space and dollar sign

	li $v0,4
	la $a0,comma
	syscall
	li $v0,4
	la $a0,space
	syscall
	li $v0,4
	la $a0,dollar
	syscall

	#print the value of the rt

	li $v0,1
	move $a0,$t0
	syscall	

	#print the comma and space
	li $v0,4
	la $a0,comma
	syscall
	li $v0,4
	la $a0,space
	syscall
	j decode_address

decode_address:
	# mask the address

	andi $t3, $s0,0x0000ffff
	addi $t2, $s1, 4
	sll $t0,$t3,16
	sra $t0,$t0,14
	add $t2,$t2,$t0
	j address_offset


address_offset:
	#print the address
	li $v0,11

	#print the "0x" by ascii code
	#it's better not direct the "0x" at the very beginning
	#Because if we parse some value in $a0, it might change the PC
	
	add $a0,$zero,48
	syscall	
	add $a0,$zero,120
	syscall
	
	#Since the MIPS output the value in decimal form by default,
	#We have to print out the value by each byte(4 bits)
	# Mask them by a loop
 
	li $t1,0xf0000000
	li $t5,28
	li $t6, -4
	printloop:
		bne $t5,$t6,loop
	j done

loop:	
	# Mask each byte by large Endianness order
	
	and $t4,$t1,$t2
	srl $t1,$t1,4
	srl $t4,$t4,$t5
	
	#Hex number can be 0-9 and a-f, so we have to make a comparison to the bound value
	ble $t4,9,small
	bge $t4,10,large
	small:
		li $v0,1 #print out the integer
		addi $a0,$t4,0
		syscall	
		addi $t5,$t5,-4
		j printloop
	large:
		li $v0, 11 #print out the char
		addi $a0,$t4,87
		syscall	
		addi $t5,$t5,-4
		j printloop

done:
	jr $ra
