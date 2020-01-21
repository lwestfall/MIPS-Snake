.globl Rand31
.globl Pause
####################################################################################################
# Rand31
# Generates a pseudorandom number from a given seed and upper bound of 31. Generator id is always 0
# Arguments: none
# Returns:
# $a0: Random number
Rand31:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	li	$v0,30		# syscall 30 is get system time
	syscall
	move 	$a1,$a0		# copy seed to $a1
	move	$a0,$0		# set generator id to zero
	li	$v0,40		# syscall 40 is set seed
	syscall
	li	$a1,31		# upper bound of 4 in $a1
	li	$v0,42		# syscall 42 is get random int
	syscall
	#addiu	$a0,$a0,1	# add 1 (for lower bound = 1)
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# Pause
# Pauses for a given amount of time (this routine was basically copied from the lecture slides)
# Arguments:
# $a0: time to pause in milliseconds
# Returns: none
Pause:
### stack ops
	addiu   $sp,$sp,-8
	sw      $a0,0($sp)
	sw      $a1,4($sp)
### end stack ops
	move	$t0,$a0		# copy time out
	li	$v0,30		# sycall 30 gets time
	syscall
	move	$t1,$a0		# copy low order time to $t1
ploop:	syscall			# get current time
	subu	$t2,$a0,$t1	# get elapsed time (current time - initial)
	bltu	$t2,$t0,ploop
### stack ops
	lw      $a1,4($sp)
	lw      $a0,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
