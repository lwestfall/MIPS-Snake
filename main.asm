	.data
Stack:
stack_beg: 	.word   0:16
stack_end:

currentScore:	.word	0				# to be incremented by 1 for each piece of food eaten

# Tiles:
# 	Tiles are 8x8 squares, and has a position on an 32x32 grid within the 256x256 pixel grid
# How positions work:
# 	Each position is a half word (2 bytes)
#	Upper byte is **tile** x position (0-31), lower byte is **tile** y coordinate (0-31)
headPos:	.half 	0x1210				# starting head pos x = 18, y = 16
foodPos:	.half	0x0000				# to be calculated randomly at game start
bodyQueue:	.half	0x0F10,				# tail
		.half	0x1010,
		.half	0x1110,				# behind head
		.half	0:1021
bodyTail:	.half	0				# queue position of tail
bodyFront:	.half 	2				# queue position of the first body part behind head
# Directions:
# There are 4 directions (up=1, left=2, down=4, and right=8), anything else is undefined
currentDir:	.byte	8				# start in right direction

scoreOut:	.asciiz "SCORE     "			# message to print on graphics screen with score at game end
							# bytes with offset 6 thru 9 to be replaced with score digits


.globl headPos
.globl foodPos
.globl bodyQueue
.globl bodyTail
.globl bodyFront

.text

init:
# Enable keyboard interrupts
	li      $t0, 0xffff0000     # Receiver control register
	li      $t1, 0x00000002     # Interrupt enable bit
	sw      $t1, ($t0)
# clear bitmap screen
	addiu	$a0,$0,0x10040000
	addiu	$a1,$0,0
	addiu	$a2,$0,256
	jal	DrawBox
# draw head
	jal	DrawHead
# draw body parts
	jal	DrawBody
# draw food
	jal	GetNewFoodPosition
	jal	DrawFood
# goto frame update
	j	FrameUpdate
Exit:
	addiu	$v0,$0,10
	syscall

####################################################################################################
# FrameUpdate
# Updates all positions necessary, runs the event checking
# Arguments: none
# Returns: none
FrameUpdate:
# check for new position input and change if necessary
	jal	UpdateDirection
# calculate new position of head
	lh	$s0,headPos
	lb	$s1,currentDir
	beq	$s1,1,_goUp
	beq	$s1,2,_goLeft
	beq	$s1,4,_goDown
	beq	$s1,8,_goRight
_goUp:
# go up decrements y position of head
	subi	$s2,$s0,1
	j	_gotPos
_goLeft:
# go left decrements x position of head
	subi	$s2,$s0,0x0100
	j	_gotPos
_goDown:
# go down increments y position of head
	addiu	$s2,$s0,1
	j	_gotPos
_goRight:
# go right increments x position of head
	addiu	$s2,$s0,0x0100
	j	_gotPos
_gotPos:
	sh	$s2,headPos		# store new head position
	move	$a0,$s2
	jal	CheckCollisions
	bgt	$v0,1,LoseGame
	move	$s1,$v0			# copy flag for later use
# draw head
	jal	DrawHead
# draw body part where head was before	
	lh	$t0,bodyFront		# get previous body index
	addiu	$t0,$t0,1		# increment body front index
	andi	$t0,0x3FF		# handles overflow of index
	sll	$t1,$t0,1		# shift left to multiply by 2 for halfword offset
	sh	$s0,bodyQueue($t1)	# store previous head position as new bodyFront
	sh	$t0,bodyFront		# overwrite body front index
	move	$a0,$s0			# s0 has previous head position
	jal	DrawBodyTile
# if no food eaten this frame, clear tail tile
	bne	$s1,$0,_doFramePause
	jal	UpdateTail
# repeat
_doFramePause:
	addiu	$a0,$0,200
	jal	Pause
	j	FrameUpdate
####################################################################################################
# WinCheck
# Checks to see if player has won by checking the length of the snake
# If there are 1023 active body tiles then the screen is filled (the head takes up one more tile)
# Arguments: none
# Returns: none
WinCheck:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lh	$t0,bodyTail
	lh	$t1,bodyFront
	bgt	$t1,$t0,_frontIsAhead	# need to check if front is already greater than tail
	addiu	$t1,$t1,1024		# otherwise add 1024 first to force it ahead
_frontIsAhead:
	sub	$t2,$t1,$t0		# get difference between head and tail
	bge	$t2,1022,WinGame	# if difference is >= 1022, player wins
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# WinGame
# Stops the game and indicates the final score to the user
# Arguments: none
# Returns: none
WinGame:
	addiu	$a0,$0,500
	jal	Pause		# pause briefly before playing tone
	jal	DisplayScore
	jal	PlayWinTone
	j 	Exit
####################################################################################################
# LoseGame
# Stops the game and indicates the final score to the user
# Arguments: none
# Returns: none
LoseGame:
	jal	PlayLoseTone
	jal	DisplayScore
	j 	Exit
####################################################################################################
# CheckCollisions
# Checks and handles collisions with food, borders, and body
# Arguments:
# $a0: the next position of the snake's head
# Returns:
# $v0: collision flag (0 = no collision, 1 = food collision, 2 = body or border collision)
CheckCollisions:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	move	$v0,$0			# reset flag register
	lh	$t0,foodPos		# get current food position
	beq	$a0,$t0,_gotFood	# if next head position = food position, branch
	blt	$a0,0,_badCollision	# check for border collision (-x or -y)
	srl	$t0,$a0,8		# shift a copy of position right 1 byte for x position
	andi	$t0,$t0,0xFF		# get x position
	bgt	$t0,31,_badCollision	# check for border collision (+x)
	andi	$t0,$a0,0xFF		# get y position
	bgt	$t0,31,_badCollision	# check for border collision (+y)
	jal	CheckBodyCollision	
	beq	$v0,1,_badCollision	# if CheckBodyCollision return 1 then head collides with body
	j	_returnCollision	# else return
_badCollision:
	addiu	$v0,$0,2		# set bad collision flag for loss condition
	j	_returnCollision	# return
_gotFood:
	lw	$t0,currentScore	# get current score
	addiu	$t0,$t0,1		# increment score
	sw	$t0,currentScore	# overwrite score
	jal	PlayFoodTone
	jal	WinCheck		# must check for win before getting new food pos else it loops infinitely
	jal	GetNewFoodPosition	
	jal	DrawFood		# draw food at new random position
	addiu	$v0,$0,1		# set food collision flag
	j	_returnCollision	# return
_returnCollision:
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# CheckBodyCollision
# Checks if given position is in body queue (used for both head-body collision and for new food position
# Arguments:
# $a0: the position to check for in body
# Returns:
# $v0: collision flag (0 = no collision, 1 = collision)
CheckBodyCollision:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lh	$t0,bodyTail		# get tail
	lh	$t1,bodyFront		# get body front
	move	$v0,$0
_bodyCheckLoop:
	andi	$t0,$t0,0x3FF		# handles overflow of bodyQueue index
	sll	$t2,$t0,1		# multiply by 2 for halfword offset
	lh	$t2,bodyQueue($t2)	# get the body position at current index
	beq	$a0,$t2,_bodyCollision	# if given position = current body position, handle collision
	addiu	$t0,$t0,1		# increment index
	ble	$t0,$t1,_bodyCheckLoop	# repeat while current index <= bodyFront
	j	_returnBodyCollision	# skip to return without setting flag
_bodyCollision:
	addiu	$v0,$0,1		# set return collision flag
_returnBodyCollision:
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# GetNewFoodPosition
# Stores a randomized tile x,y position for a piece of food at foodPos
# Arguments: none
# Returns: none
GetNewFoodPosition:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
_getNewPos:
# get random number for x (0 to 31)
	jal	Rand31
	sll	$t0,$a0,8		# copy and move random x left 1 byte
# get random number for y (0 to 31)
	jal	Rand31
	addu	$a0,$t0,$a0		# add shifted x position and new y position
# if position is the same as any body part, repeat
	jal	CheckBodyCollision
	beq	$v0,1,_getNewPos	# get another new position if there was a collision
	lh	$t0,headPos
	beq	$a0,$t0,_getNewPos	# also check against head position
	sh	$a0,foodPos		# store new random position to foodPos
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# UpdateTail
# Updates the tail position in memory and clears the old tail position
# Arguments: none
# Returns: none
UpdateTail:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lh	$t0,bodyTail
	mul	$t1,$t0,2		# get offset for previous tail position
	addiu	$t0,$t0,1		# increment tail index
	andi	$t0,0x3FF		# handles overflow of index
	sh	$t0,bodyTail		# overwrite tail index
	lh	$a0,bodyQueue($t1)	# clear previous tail position
	jal	ClearTile
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# UpdateDirection
# Updates the direction of the snake's movement by checking the last keypress
# Arguments: none
# Returns: none
UpdateDirection:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	jal	GetLastChar
	beqz	$v0,_returnDir		# return without memory update if no new char
	lb	$t1,currentDir		# get current direction
	beq	$v0,'w',_setUp
	beq	$v0,'W',_setUp
	beq	$v0,'a',_setLeft
	beq	$v0,'A',_setLeft
	beq	$v0,'s',_setDown
	beq	$v0,'S',_setDown
	beq	$v0,'d',_setRight
	beq	$v0,'D',_setRight
	j	_returnDir			# ignore any other char
_setUp:
	beq	$t1,4,_returnDir	# skip update if opposite direction (can't do 180)
	addiu	$t0,$0,1
	j	_dirGot
_setLeft:
	beq	$t1,8,_returnDir	# skip update if opposite direction (can't do 180)
	addiu	$t0,$0,2
	j	_dirGot
_setDown:
	beq	$t1,1,_returnDir	# skip update if opposite direction (can't do 180)
	addiu	$t0,$0,4
	j	_dirGot
_setRight:
	beq	$t1,2,_returnDir	# skip update if opposite direction (can't do 180)
	addiu	$t0,$0,8
	j	_dirGot
_dirGot:
	sb	$t0,currentDir
_returnDir:
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# WriteScoreToString
# Converts integer score to 1-4 digit ascii string, stored in bytes 6 thru 9 of scoreOut
# Arguments: none
# Returns: none
WriteScoreToString:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$t2,$0,6		# $t2 is digit offset, starts at 6
	#move	$t3,$0			# $t3 is string start flag
	lw	$t0,currentScore	# get final score
_thousandsDigitString:
	div	$t1,$t0,1000			# integer divide by 1000 to get thousands
	mul	$t3,$t1,1000
	subu	$t0,$t0,$t3			# subtract the thousands
	#beqz	$t1,_hundredsDigitString	# skip thousands place if quotient was 0
	addiu	$t1,$t1,'0'			# add ascii for 0 to get char code for digit
	sb	$t1,scoreOut($t2)		# store digit in score out at digit offset
	addiu	$t2,$t2,1			# increment digit offset

_hundredsDigitString:
	div	$t1,$t0,100			# integer divide by 100 to get hundreds
	mul	$t3,$t1,100
	subu	$t0,$t0,$t3			# subtract the hundreds
	#beqz	$t1,_tensDigitString	# skip thousands place if quotient was 0
	addiu	$t1,$t1,'0'			# add ascii for 0 to get char code for digit
	sb	$t1,scoreOut($t2)		# store digit in score out at digit offset
	addiu	$t2,$t2,1			# increment digit offset
_tensDigitString:
	div	$t1,$t0,10			# integer divide by 10 to get tens
	mul	$t3,$t1,10
	subu	$t0,$t0,$t3			# subtract the tens
	#beqz	$t1,_onesDigitString		# skip thousands place if quotient was 0
	addiu	$t1,$t1,'0'			# add ascii for 0 to get char code for digit
	sb	$t1,scoreOut($t2)		# store digit in score out at digit offset
	addiu	$t2,$t2,1			# increment digit offset
_onesDigitString:
	div	$t1,$t0,1			# integer divide by 1 to get thousands
	addiu	$t1,$t1,'0'			# add ascii for 0 to get char code for digit
	sb	$t1,scoreOut($t2)		# store digit in score out at digit offset
_scoreStringReturn:
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DisplayScore
# Displays the final score on the graphics screen
# Arguments: none
# Returns: none
DisplayScore:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	jal	WriteScoreToString	# convert integer score to string and store at scoreOut
	addiu	$a0,$0,86	# put in x coordinate (text will be roughly centered for 3 digit score)
	addiu	$a1,$0,121	# put in y coordinate (text will be roughly centered
	la	$a2,scoreOut	# get score string address
	jal	OutText
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# PlayFoodTone
# Plays a tone if user eats food
# Arguments: none
PlayFoodTone:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$a0,$0,92	# pitch
	addiu	$a1,$0,200	# duration
	addiu	$a2,$0,16	# instrument
	addiu	$a3,$0,127	# volume
	addiu	$v0,$0,31	# syscall 31 is play tone and return immediately
	syscall
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# PlayLoseTone
# Plays a tone if user loses
# Arguments: none
PlayLoseTone:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$a0,$0,44	# pitch
	addiu	$a1,$0,750	# duration
	addiu	$a2,$0,127	# instrument
	addiu	$a3,$0,127	# volume
	addiu	$v0,$0,31	# syscall 31 is play tone and return immediately
	syscall
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# PlayWinTone
# Plays a tone if user wins
# Arguments: none
PlayWinTone:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$a2,$0,32	# instrument
	addiu	$a3,$0,127	# volume
	addiu	$v0,$0,33	# syscall 33 is play tone and block until complete
	addiu	$a0,$0,67
	addiu	$a1,$0,100
	syscall
	addiu	$a0,$0,72
	syscall
	addiu	$a0,$0,76
	syscall
	addiu	$a0,$0,79
	addiu	$a1,$0,400
	syscall
	addiu	$a0,$0,76
	addiu	$a1,$0,100
	syscall
	addiu	$a0,$0,79
	addiu	$a1,$0,800
	syscall
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
