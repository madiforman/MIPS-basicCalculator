#Author: Madison Sanchez-Forman
#Date: 10.21.21
##########################################################################################################################################
.data
	#the two prompts that will need to be displayed to the user
	int_prompt:	.asciiz "Please enter an integer: "
	op_prompt:	.asciiz "Please enter an operation(+,-,*,/): "
	#three possible success or error messages after operation is executed
	exit_msg: 	.asciiz "Thank you. "					#successfully executed; String representation of the input will be concatenated later
	overflow_msg:	.asciiz "I'm sorry, that would overflow."		#error message; the arithmetic operation entered resulted in an overflow
	div_by_0: 	.asciiz "I'm sorry, you cannot divide by zero" 		#division by 0; user entered the division operator, and then attempted to divide by 0, which is not a thing
	#for aesthetics when displaying to screen
	newLine:	.asciiz "\n"						#self explanatory, print new line
	space:		.asciiz " "						#for printing out input integers and operator cleanly
	remainder:	.asciiz "r"						#used when operator is division, will print in the format: quotient r remainder
	period:		.asciiz "."						#used for printing final result
##########################################################################################################################################
.text 		
main:	
	#prompt user to enter first integer, and store it	
	li 	 $v0, 4		 		#tell system its going to be printing a string	
	la 	 $a0, int_prompt		#load the address of the string		
	syscall					#print it
	li  	 $v0, 5		 		#tell system its going to need to read in an integer
	syscall					#read in intege
	move	$s0, $v0			#store integer in $s0
	#prompt user to enter operation to be performed, and store it
	li	$v0, 4				#tell system its going to be printing a string	
	la	$a0, op_prompt			#load the address of the string	
	syscall					#print it
	li	$v0, 12				#tell system its going to need to read in a character
	syscall					#read character
	move	$s1, $v0			#store character in $s1
	li	$v0, 4				#tell system its going to be printing a string	
	la	$a0, newLine			#load the address of the string	
	syscall					#print it
	#prompt user to enter second integer, and store it			
	li 	 $v0, 4				#tell system its going to be printing a string	
	la 	 $a0, int_prompt		#load the address of the string	
	syscall					#print it
	li  	 $v0, 5				#tell system its going to be reading an integer
	syscall					#read integer
	move	$s2, $v0			#store integer in $s2	
	
	li	$t0, '+'				# if($s1 == ‘+’){
	beq	$s1, $t0, addition			# addition();
	li	$t0, '-'				# } else if ($s1 == ‘-’){
	beq	$s1, $t0, subtraction			# subtraction();
	li	$t0, '*'				# } else if ($s1 == ‘*’) {
	beq	$s1, $t0, multiplication		# multiplication();
	li	$t0, '/'				# } else if ($s1 == ‘/‘) {
	beq	$s1, $t0, division			#division();
							# }
exit: 
	li $v0, 10					#when subroutine/s terminate successfully or with an error, exit the program cleanly	
	syscall
##########################################################################################################################################
addition:
	xor	$t1, $a0, $a1				#start by checking for overflow between the two input values,
	bltz	$t1, a_no_overflow			#if they have different signs addition will never overflow
	
	addu	$t0, $s0, $s2				#addu to avoid throwing error
	xor	$t3, $t0, $s0				#check to see if result of addu has the same sign as the summands
	bltz	$t3, is_overflow			#if it does have the same sign, there was overflow, if it doesnt, there wasnt
   a_no_overflow:					#a_no_overflow stands for addition no overflow
	jal	print_boilerplate
	#calculate and print result		
	add 	$v1, $s0, $s2				#add the values 
	li	$v0, 1					#prepare to print an int
	addi 	$a0, $v1, 0				#move value of result into $a0
	syscall						#print
	#print period
	li	$v0, 4
	la	$a0, period
	syscall
	j exit	
##########################################################################################################################################
subtraction:
	xor	$t1, $a0, $a1				#check to see if they have the same sign, if they do not, no overflow (vs in addition overflow wouldnt happen if they do have the same sign)
	bgtz	$t1, s_no_overflow
	
	subu	$t0, $s0, $s2				#same process as addition, add them with addu to avoid an error, and check if the result has the same sign or different
	xor	$t3, $t0, $s0				#doing check
	bltz	$t3, is_overflow			
	
	s_no_overflow:					#same process for printing input equation as addition
	jal	print_boilerplate
	#calculate and print result
	sub	$v1, $s0, $s2					#calculate result of operation
	li	$v0, 1						#prepare to print it
	addi 	$a0, $v1, 0					#move result to $a0
	syscall							#print it
	#print period
	li	$v0, 4
	la	$a0, period
	syscall
	j exit							#exit program
##########################################################################################################################################
multiplication:
	mult	$s0, $s2					#multiply two input ints
	mfhi	$t0						#store hi in $t0
	mflo	$t1						#store lo in $t1
	
	sra	$t1, $t1, 31					#shift right arithmetic on lo by 31, to get the sign bit
	beq	$t0, $t1, m_no_overflow				#if sign bits are the same, no overflow
	bne 	$t0, $t1, is_overflow				#else overflow
	
	m_no_overflow:						
	jal	print_boilerplate
	#calculate and print result
	mflo	$t1						#retreive orignal lo again, store in $t1
	move	$v1, $t1					#move it to $v1
	li	$v0, 1						#prepare to print
	addi 	$a0, $v1, 0					
	syscall							#print and exit
	#print period
	li	$v0, 4
	la	$a0, period
	syscall
	j exit							#print and exit
##########################################################################################################################################
division:
	beqz	$s2, zero_denom					#case for an attempt to divide by zero, if denominator == 0, branch to zero_denom
	li 	$t0, 0x80000000					#case for only overflow in division case: 0x80000000 / -1, if the numerator is 0x80000000, branch to denomCheck 
	beq	$s0, $t0, denomCheck
	jal	d_no_overflow					#else, go to no overflow
	
	d_no_overflow:						#stands for division no overflow, will also be the same as previous unitl line 255
	jal print_boilerplate
	#calculate and print quotient				
	div	$s0, $s2					#first, calculate the divison
	mflo	$t0						#load the quotient
	move	$v0, $t0					#store the quotient in $v0
	li	$v0, 1						#prepare to print
	move 	$a0, $t0					#print
	syscall
	#print space
	li	$v0, 11
	la	$a0, space
	syscall
	#print r
	li	$v0, 4						#printing 'r' to signify remainder
	la	$a0, remainder
	syscall
	#print space
	li	$v0, 11
	la	$a0, space
	syscall
	#get and print remainder			
	li	$v0, 1						#prepare to print integer
	mfhi	$a0						#load remainder from mfhi
	syscall							#print integer
	#print period
	li	$v0, 4
	la	$a0, period
	syscall
	j exit								
	denomCheck:						#case for 0x80000000 / -1
	li	$t1, -1						#load $t1 == -1 as temporary variable
	beq	$s2, $t1, is_overflow				#if the denominator == $t1, branch to is overflow
	bne	$s2, $t1, d_no_overflow				#else go back up to division no overflow
	zero_denom:						#case for divison by zero
  	li	$v0, 4						#prepare to print string
  	la	$a0, div_by_0					#print error message
  	syscall 						#exit
  	j exit
 ##########################################################################################################################################
is_overflow:
	li	$v0, 4						#overflow case: prepare to print string
	la	$a0, overflow_msg				#load address of string
	syscall							#print it
	j exit							#exit program
 ##########################################################################################################################################
 print_boilerplate:					#prints standard information of operation and result, Thank you. ++ input value ++ operation ++ second value ++ equals
 li	$v0, 4						#prepare system to print string
	la	$a0, exit_msg				#load address of string
	syscall						#print string
	#print first int
	li	$v0, 1					#preparing system to print integer
	move	$a0, $s0				#print the value the user originally passed in first
	syscall
	#Print space
	li	$v0, 11					#prepare system to print char
	la	$a0, space				#load address of char	
	syscall
	#print operator				
	move	$a0, $s1				#print originally input operator
	li	$v0, 11					#prepare system to print char
	syscall
	#print space
	li	$v0, 11					#prepare to print char
	la	$a0, space				#print space
	syscall
	#second int
	li	$v0, 1					#prepare to print int
	move	$a0, $s2				#that int
	syscall						#print int
	#print space
	li	$v0, 11					#prepare to print char
	la	$a0, space				#print space
	syscall
	#equals
	li 	$a0, '='				#load '=' into $a0
	li	$v0, 11					#prepare to print char
	syscall
	#print space
	li	$v0, 11					#prepare to print char
	la	$a0, space				#print space
	syscall
	jr	$ra					#return to whichever arithmetic function hence you came
##########################################################################################################################################