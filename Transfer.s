.data
nl:
  .asciiz"\n"
.text
.globl main

main:
	li $v0 5 										# Read in N
	syscall
	move $t0, $v0
 							# Move N to $t0
  srl  $t1 $s0 31
  andi $t1 $t0 0x00000001 # get S
  beqz $t1 positive
  sub  $t0 $0 $t0 # change to positive

  move $a0 $t0								# Print the new number
	li	$v0 1
	syscall
	li	$v0 4										# Print the last \n
	la	$a0 nl
	syscall

positive:

  srl $t4 $t0 16
  andi $t5 $t4 0x000000ff
  andi $t1 $t0 0x0000ffff
  sll $t5 $t4 16
  or $t1 $t5 $t1 
  addi $t2 $0 0 # 2^n, n = 0
  addi $s1 $0 127 # exp

loop:
  srl $t1 $t1 1
  beqz $t1 exponent
  addi $t2 1
  j loop

exponent:
  add $s1 $s1 $t2
  sll $s1 $s1 23              # the exponent is done
  
fraction:
  srl $t4 $t0 16
  andi $t5 $t4 0x000000ff
  andi $t1 $t0 0x0000ffff
  sll $t5 $t4 16
  or $t1 $t5 $t1 
  li   $t3 32
  sub  $t3 $t3 $t2
  sll  $t1 $t1 $t3
  srl  $s2 $t1 9

done:
  add  $s0 $s0 $s1
  add  $s0 $s0 $s2

  mtc1  $s0 $f0
  mov.s $f12 $f0
  li $v0 2
	syscall
	jr $ra

