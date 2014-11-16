#---------------------------------------------------------------
# Assignment:           4
# Due Date:             March 17, 2014
# Name:                 Lingbo Tang
# Unix ID:              lingbo
# Lecture Section:      B1
# Instructor:           Jacqueline Smih
# Lab Section:          H01
# Teaching Assistant:   Michael Mills
#--------------------------------------------------------------

#---------------------------------------------------------------
# The function in MIPS assembly use the timer and memory-mapped IO
# To creat a timer that has the function of reset and quit
# After running the programe, the clock will start
# And it will print in the form "XX:XX"
# The input 's' or 'S' from the keyboard will start, pause or resume the clock
# The input "q" or "Q" from the keyboard will quit the clock
# The input "r" or "R" from the keyboard will reset the clock to zero
# I check the output use the spim in terminal
#
# Register Usage in clock:
#	a0:address of the keyboard interrupt(const)
#	a1:address of the timer interrupt(const)
#	v0:address of the keyboard instructions
#	s0: checking gal for keyboard condition
#	s1: counter for the time
# 	t0 : temporaliy using
#	t8:one's value in second
#	t7:ten's value in second
#	t4:converting register2
#	t3:cnoverting register1
#	t5:ten's value in minute
#	t6:one's value in minute
#	$t3: the counter for clean times (we need clean 5 times)
#	$t2: the backspace 
#	$t1: the display register used for update part
#---------------------------------------------------------------

# ------------------------------ program header ------------------------------ #
# this program does the following things:
# 	Upon starting, display 00:00 on screen.
#	When 's' is pressed on the keyboard, begin counting up, 
#	displaying the elapsed time in the following format: mm:ss.
#	Whenever 's' is pressed again, either pause or resume timing
#	Whenever 'r' is pressed, reset the timer back to 00:00
#	Whenever 'q' is pressed, quit the application
#	For all other key presses, do nothing.
#-------------------------------------------------------------------------------
# -------------------------- subroutine description -------------------------- #
# setupstopwatch: arrange the address for $t1,$t3,$t4,$t5,$t6
# runningpermanate: press 's' start, if no other instructions is input into system
#                   run timer permanately
# s_again: if 's' is pressed again,either pause or resume timing
# r_instruction: reset the timer back to 00:00
# q_instruction: quit the application,stop running the timer
#---------------------------------------------------------------

#print out the seconds one byte at a time , if  its keyboard
#enable the keyboard, ask the user to type and print out the 
#user input


# Define the exception handling code.  This must go first!

	.kdata

s1:	.word 0
s2:	.word 0
#===============================================================
# This is the exception handler code that the processor runs when
# an exception occurs. It only prints some information about the
# exception, but can server as a model of how to write a handler.
#
# Because we are running in the kernel, we can use $k0/$k1 without
# saving their old values.

# This is the exception vector address for MIPS32:
	.ktext 0x80000180
# Select the appropriate one for the mode in which SPIM is compiled.
	.set noat
	move $k1 $at		# Save $at
	.set at
	sw $v0 s1		# Not re-entrant and we can't trust $sp
	sw $a0 s2		# But we need to use these registers

	mfc0 $k0 $13		# Cause register

#-------------------------------------------------------------------
# Set the cause regiter $13
# bit 11 is for keyboard exceptions
# bit 15 is for timer exceptions
#-------------------------------------------------------------------
check_pc:

	srl $a0 $k0 2
	andi $a0 $a0 0x1f		#extract the exceptions field
	bne $a0 0 return	
    	srl $a1 $k0 11			#extract the keyboard_interrupt
    	srl $a0 $k0 15			#extract the timer_interrupt
	andi $a1 $a1 0x1
    	andi $a0 $a0 0x1
	beq $a1 1 keyboard_interrupt
	beq $a0 0 timer_interrupt


#----------------------------------------------------------------------
#Check Timer interrrupt every 0.01s if $9 == $11
#If interrupt happens, update the time, note that the maximum time is 99:59
#If not, do nothing
#----------------------------------------------------------------------
timer_interrupt:
	
	mtc0 $0  $9
        li $k1 100
        mtc0 $k1 $11
	beq $s1 5999 timelimit	# display limit

	beq $s2 2 stop
	li $s0 1
	addi $s1 $s1 1
	
stop: 
        j return
        nop

timelimit:
	li $s1 0
	li $s2 2
        j return
        nop


#----------------------------------------------------------------------
#Checkkeyboard interrupt
#The input 's' or 'S' from the keyboard will start, pause or resume the clock
# The input "q" or "Q" from the keyboard will quit the clock
# The input "r" or "R" from the keyboard will reset the clock to zero
#----------------------------------------------------------------------
keyboard_interrupt:	
	
	lw $v0 0xffff0000
	ori $v0 0x2
	sw $v0 0xffff0000

	lw $v0 0xffff0004
	beq $v0 0x71 quit #quit tap "q"
	beq $v0 0x51 quit
	
	lw $v0 0xffff0004
	beq $v0 0x72 reset #reset,tap"r"
	beq $v0 0x52 reset

	
	lw $v0 0xffff0004
	beq $v0 0x73 pause #stop,tap"s"
	beq $v0 0x53 pause

        j return
        nop	

#----------------------------------------------------------------------
#print a new line character at the end of the clock and quit
#----------------------------------------------------------------------
quit:
	lw $t0 0xffff0008
	andi $t0 $t0 0x1
	beqz $t0 quit
	li $t1, 0xa
	sw $t1 0xffff000c
	li $v0 10
	syscall                   

#---------------------------------------------------------------------
#reset the key board checking flag and time display to initial
#---------------------------------------------------------------------
reset:
	li $s0 1
	li $s1 0
	li $s2 2
        j return
        nop

#--------------------------------------------------------------------
# If already paused, restart
# If running stop
#--------------------------------------------------------------------
pause:
	beq $s2 2 restart
	li $s2 2
        j return
        nop

#--------------------------------------------------------------------
# Turn off the pause flag 
#--------------------------------------------------------------------
restart:
	li $s2 0
        j return
        nop

# Restore registers and reset procesor state
#
	return:
		lw $v0 s1		# Restore other registers
		lw $a0 s2

		.set noat
		move $at $k1		# Restore $at
		.set at

		mtc0 $0 $13		# Clear Cause register

		mfc0 $k0 $12		# Set Status register
		ori  $k0 0x1		# Interrupts enabled
		mtc0 $k0 $12

# Return from exception on MIPS32:
		eret

# Standard startup code.  Invoke the routine "main" with arguments:
#	main(argc, argv, envp)
#
	.text
	.globl __start
__start:
	lw $a0 0($sp)		# argc
	addiu $a1 $sp 4		# argv
	addiu $a2 $a1 4		# envp
	sll $v0 $a0 2
	addu $a2 $a2 $v0
	jal main
	nop


	.globl __eoth
__eoth:

#====================================================================	
	.data
		time_to_display: .asciiz "00:00"

	.text   


	main:
		lw $t0 0xffff0000	# enable the keyboard interruption
		ori $t0 0x2
		sw $t0 0xffff0000


		mfc0 $t1 $12
        	ori $t1 $t1 0x8801	# Set up the status register
        	mtc0 $t1 $12
				
        	mtc0 $0  $9		#Timer setup
        	addi $a3 $zero 100
        	mtc0 $a3 $11

		la $a0 time_to_display	#printbuffer setup
	
	
		li $s0 1     	#set the s0 as the check flag for the keyboard condition
		li $s1 0	# set s1 be the counter for the time
		li $s2 2	# set s2 be the stop 
				
#--------------------------------------------------------------------------------
#Keep running the first loop until q is pressed
#--------------------------------------------------------------------------------
	foreverloop:
		beq  $s0 0 foreverloop 		# always running if 'q' not pressed
		addi $t0 $s0 1		
		beq  $t0 $zero quit		#flag for quit the program

  		addi $sp $sp -4           
  		sw $ra 0($sp)	
		la $a0 time_to_display	
		jal displaytime
  		lw $ra 0($sp)
  		addi $sp $sp 4
		move $s0 $0
		j foreverloop
#--------------------------------------------------------------------------
# display the time and convert them in to the right scale
#--------------------------------------------------------------------------
	running_time:	
		move $t0 $a0
		li $t1 60		 #10's minute convert		
		div $s1 $t1		 
		mflo $t3		 # Set them to the first digit
		mfhi $t4		 
			
		li $t2 10		# 1's minute convert
		div $t3 $t2	         
		mflo $t5	 	# Set them to the second digit	 
		mfhi $t6

		div $t4 $t2	         # 10's second convert
		mflo $t7	 	 
		mfhi $t8
					
		addi $t5 $t5 48		# display buffer[0]
		sb $t5 0($t0)	
		addi $t0 $t0 1
		addi $t6 $t6 48		# display buffer[1]
		sb $t6 0($t0)

		addi $t0 $t0 2 		 #skip the ":"

		 
		addi $t7 $t7 48		# display buffer[3]
		sb $t7 0($t0)
		addi $t0 $t0 1
		addi $t8 $t8 48         # display buffer[4]
		sb $t8 0($t0)

		j over

#-------------------------------------------------------------------	
	displaytime:
#--------------------------------------------------------------------
# Erase the previous time at first 
#--------------------------------------------------------------------

		addi $sp $sp -4           
  		sw $ra 0($sp)	
		jal clean
  		lw $ra 0($sp)
  		addi $sp $sp 4
#--------------------------------------------------------------------
# display the current buffer time now 
#--------------------------------------------------------------------	
		addi $sp $sp -4           
  		sw $ra 0($sp)	
		jal running_time
  		lw $ra 0($sp)
  		addi $sp $sp 4	
		printpoll:
			lw $t1 0xffff0008
			andi $t1 $t1 0x1 
			beqz $t1 printpoll
			lb $t2 0($a0)
			sb $t2 0xffff000c
			addi $a0 $a0 1
			lb $t2 0($a0)
			beqz $t2 over
			j printpoll 
#------------------------------------------------------------------
# Clean the old and replace it by the new time through poll
#------------------------------------------------------------------
	clean:
		li $t3 5
	cleanloop:
		li $t2 0x8		# setup the clean flag
		beqz $t3 over 
		lw $t1 0xffff0008
		andi $t1 $t1 0x1 
		beqz $t1 cleanloop
		sb $t2 0xffff000c
		sub $t3 $t3 1
		j cleanloop	
over:
	jr $ra
