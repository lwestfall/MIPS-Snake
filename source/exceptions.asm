	.data
save_at:		.word	0

keyLastPressed:		.byte	0

keyPressMsg:		.asciiz "Key pressed (ASCII Code): "
unhandledExceptionMsg:	.asciiz	"Unhandled Exception!\nCode: "

	.text
.globl GetLastChar
####################################################################################################
# GetLastChar
# Gets last stored char value (0 means no new keys pressed since last check)
# Arguments: none
# Returns:
# $v0: Ascii character
GetLastChar:
### stack ops
	addiu   $sp,$sp,-4
	sw      $ra,0($sp)
### end stack ops
	lb	$v0,keyLastPressed	# get key
	sb	$0,keyLastPressed	# reset key
_returnChar:
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,4
### end stack ops
	jr	$ra

#########################################################################################################
#########################################################################################################
#########################################################################################################
#########                                   KERNEL SPACE                                        #########
#########################################################################################################
#########################################################################################################
#########################################################################################################
#########################################################################################################
#########################################################################################################
	########################################################################
	# Exception handling code.  This must go first!
	# this is copied from exceptions.s - not my code!
			.kdata
	__start_msg_:   .asciiz "  Exception "
	__end_msg_:     .asciiz " occurred and ignored\n"
	
	# Messages for each of the 5-bit exception codes
	__exc0_msg:     .asciiz "  [Interrupt] "
	__exc1_msg:     .asciiz "  [TLB]"
	__exc2_msg:     .asciiz "  [TLB]"
	__exc3_msg:     .asciiz "  [TLB]"
	__exc4_msg:     .asciiz "  [Address error in inst/data fetch] "
	__exc5_msg:     .asciiz "  [Address error in store] "
	__exc6_msg:     .asciiz "  [Bad instruction address] "
	__exc7_msg:     .asciiz "  [Bad data address] "
	__exc8_msg:     .asciiz "  [Error in syscall] "
	__exc9_msg:     .asciiz "  [Breakpoint] "
	__exc10_msg:    .asciiz "  [Reserved instruction] "
	__exc11_msg:    .asciiz ""
	__exc12_msg:    .asciiz "  [Arithmetic overflow] "
	__exc13_msg:    .asciiz "  [Trap] "
	__exc14_msg:    .asciiz ""
	__exc15_msg:    .asciiz "  [Floating point] "
	__exc16_msg:    .asciiz ""
	__exc17_msg:    .asciiz ""
	__exc18_msg:    .asciiz "  [Coproc 2]"
	__exc19_msg:    .asciiz ""
	__exc20_msg:    .asciiz ""
	__exc21_msg:    .asciiz ""
	__exc22_msg:    .asciiz "  [MDMX]"
	__exc23_msg:    .asciiz "  [Watch]"
	__exc24_msg:    .asciiz "  [Machine check]"
	__exc25_msg:    .asciiz ""
	__exc26_msg:    .asciiz ""
	__exc27_msg:    .asciiz ""
	__exc28_msg:    .asciiz ""
	__exc29_msg:    .asciiz ""
	__exc30_msg:    .asciiz "  [Cache]"
	__exc31_msg:    .asciiz ""
	
	__level_msg:    .asciiz "Interrupt mask: "
	
	
	#########################################################################
	# Lookup table of exception messages
	__exc_msg_table:
		.word   __exc0_msg, __exc1_msg, __exc2_msg, __exc3_msg, __exc4_msg
		.word   __exc5_msg, __exc6_msg, __exc7_msg, __exc8_msg, __exc9_msg
		.word   __exc10_msg, __exc11_msg, __exc12_msg, __exc13_msg, __exc14_msg
		.word   __exc15_msg, __exc16_msg, __exc17_msg, __exc18_msg, __exc19_msg
		.word   __exc20_msg, __exc21_msg, __exc22_msg, __exc23_msg, __exc24_msg
		.word   __exc25_msg, __exc26_msg, __exc27_msg, __exc28_msg, __exc29_msg
		.word   __exc30_msg, __exc31_msg
# begin my code (except nocahr
.ktext  0x80000180

	move	$k0,$a0
	move	$k1,$v0
	
	# $at is the temporary register reserved for the assembler.
	# It may be modified by pseudo-instructions in this handler.
	# Since an interrupt could have occurred during a pseudo
	# instruction in user code, $at must be restored to ensure
	# that that pseudo instruction completes correctly.
	.set    noat
	sw      $at, save_at
	.set    at
	
	# Determine cause of the exception
	mfc0    $a0,$13	        	# Get cause register from coprocessor 0
	andi    $a0,$a0,0x3c		# throw away unneeded data
	srl	$a0,$a0,2		# move exception code for lookup
	andi    $a0, $a0, 0x1f
		
	# Check for program counter issues (exception 6)
	bne     $a0, 6, ok_pc
	nop

	mfc0    $a0, $14        # EPC holds PC at moment exception occurred
	andi    $a0, $a0, 0x3   # Is EPC word-aligned (multiple of 4)?
	beqz    $a0, ok_pc
	nop

	# Bail out if PC is unaligned
	# Normally you don't want to do syscalls in an exception handler,
	# but this is MARS and not a real computer
	li      $v0, 4
	la      $a0, __exc3_msg
	syscall
	li      $v0, 10
	syscall

ok_pc:
	mfc0    $k0, $13
	srl     $a0, $k0, 2     # Extract exception code from $k0 again
	andi    $a0, $a0, 0x1f
	bnez    $a0, non_interrupt  # Code 0 means exception was an interrupt
	nop

		# External interrupt handler
	# Don't skip instruction at EPC since it has not executed.
	# Interrupts occur BEFORE the instruction at PC executes.
	# Other exceptions occur during the execution of the instruction,
	# hence for those increment the return address to avoid
	# re-executing the instruction that caused the exception.
	
	     # check if we are in here because of a character on the keyboard simulator
		# go to nochar if some other interrupt happened
keyboardQueueHandler:
# BEGIN  DEBUG
	lw	$a0,0xFFFF0004		# get code of key pressed
	sb	$a0,keyLastPressed	# store ASCII code of keypress to keyLastPressed
	j 	return
	
nochar:
	# not a character
	# Print interrupt level
	# Normally you don't want to do syscalls in an exception handler,
	# but this is MARS and not a real computer
	li      $v0, 4          # print_str
	la      $a0, __level_msg
	syscall
	
	li      $v0, 1          # print_int
	mfc0    $k0, $13        # Cause register
	srl     $a0, $k0, 11    # Right-justify interrupt level bits
	syscall
	
	li      $v0, 11         # print_char
	li      $a0, 10         # Line feed
	syscall
	
	j       return

non_interrupt:
	# Print information about exception.
	# Normally you don't want to do syscalls in an exception handler,
	# but this is MARS and not a real computer
	li      $v0, 4          # print_str
	la      $a0, __start_msg_
	syscall

	li      $v0, 1          # print_int
	mfc0    $k0, $13        # Extract exception code again
	srl     $a0, $k0, 2
	andi    $a0, $a0, 0x1f
	syscall

	# Print message corresponding to exception code
	# Exception code is already shifted 2 bits from the far right
	# of the cause register, so it conveniently extracts out as
	# a multiple of 4, which is perfect for an array of 4-byte
	# string addresses.
	# Normally you don't want to do syscalls in an exception handler,
	# but this is MARS and not a real computer
	li      $v0, 4          # print_str
	mfc0    $k0, $13        # Extract exception code without shifting
	andi    $a0, $k0, 0x7c
	lw      $a0, __exc_msg_table($a0)
	nop
	syscall

	li      $v0, 4          # print_str
	la      $a0, __end_msg_
	syscall

	# Return from (non-interrupt) exception. Skip offending instruction
	# at EPC to avoid infinite loop.
	mfc0    $k0, $14
	addiu   $k0, $k0, 4
	mtc0    $k0, $14
	
return:
	# Restore registers and reset processor state
	move	$a0,$k0			# restore registers
	move	$v0,$k1		

	.set    noat            # Prevent assembler from modifying $at
	lw      $at, save_at
	.set    at

	mtc0    $zero, $13      # Clear Cause register

	# Re-enable interrupts, which were automatically disabled
	# when the exception occurred, using read-modify-write cycle.
	mfc0    $k0, $12        # Read status register
	andi    $k0, 0xfffd     # Clear exception level bit
	ori     $k0, 0x0001     # Set interrupt enable bit
	mtc0    $k0, $12        # Write back

	# Return from exception on MIPS32:
	eret
