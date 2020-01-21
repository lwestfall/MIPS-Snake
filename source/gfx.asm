	.data
ColorTable:
	.word	0x000000	# [0] black
	.word	0x0000ff	# [1] blue
	.word	0x00ff00	# [2] green
	.word	0xff0000	# [3] red
	.word	0x00ffff	# [4] cyan (blue + green)
	.word	0xff00ff	# [5] purple (blue + red)
	.word	0xffff00	# [6] yellow (red + green)
	.word	0xffffff	# [7] white

Colors: .word   0x000000        # background color (black)
        .word   0xffffff        # foreground color (white)

DigitTable:
        .byte   ' ', 0,0,0,0,0,0,0,0,0,0,0,0
        .byte   '0', 0x7e,0xff,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '1', 0x38,0x78,0xf8,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18,0x18
        .byte   '2', 0x7e,0xff,0x83,0x06,0x0c,0x18,0x30,0x60,0xc0,0xc1,0xff,0x7e
        .byte   '3', 0x7e,0xff,0x83,0x03,0x03,0x1e,0x1e,0x03,0x03,0x83,0xff,0x7e
        .byte   '4', 0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7f,0x03,0x03,0x03,0x03,0x03
        .byte   '5', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0x7f,0x03,0x03,0x83,0xff,0x7f
        .byte   '6', 0xc0,0xc0,0xc0,0xc0,0xc0,0xfe,0xfe,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '7', 0x7e,0xff,0x03,0x06,0x06,0x0c,0x0c,0x18,0x18,0x30,0x30,0x60
        .byte   '8', 0x7e,0xff,0xc3,0xc3,0xc3,0x7e,0x7e,0xc3,0xc3,0xc3,0xff,0x7e
        .byte   '9', 0x7e,0xff,0xc3,0xc3,0xc3,0x7f,0x7f,0x03,0x03,0x03,0x03,0x03
        .byte   '+', 0x00,0x00,0x00,0x18,0x18,0x7e,0x7e,0x18,0x18,0x00,0x00,0x00
        .byte   '-', 0x00,0x00,0x00,0x00,0x00,0x7e,0x7e,0x00,0x00,0x00,0x00,0x00
        .byte   '*', 0x00,0x00,0x00,0x66,0x3c,0x18,0x18,0x3c,0x66,0x00,0x00,0x00
        .byte   '/', 0x00,0x00,0x18,0x18,0x00,0x7e,0x7e,0x00,0x18,0x18,0x00,0x00
        .byte   '=', 0x00,0x00,0x00,0x00,0x7e,0x00,0x7e,0x00,0x00,0x00,0x00,0x00
        .byte   'A', 0x18,0x3c,0x66,0xc3,0xc3,0xc3,0xff,0xff,0xc3,0xc3,0xc3,0xc3
        .byte   'B', 0xfc,0xfe,0xc3,0xc3,0xc3,0xfe,0xfe,0xc3,0xc3,0xc3,0xfe,0xfc
        .byte   'C', 0x7e,0xff,0xc1,0xc0,0xc0,0xc0,0xc0,0xc0,0xc0,0xc1,0xff,0x7e
        .byte   'D', 0xfc,0xfe,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xfe,0xfc
        .byte   'E', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xff,0xff
        .byte   'F', 0xff,0xff,0xc0,0xc0,0xc0,0xfe,0xfe,0xc0,0xc0,0xc0,0xc0,0xc0
        .byte	'O', 0x7e,0xff,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xc3,0xff,0x7e
        .byte	'R', 0xfe,0xff,0xc3,0xc3,0xc3,0xfc,0xfc,0xe6,0xc3,0xc3,0xc3,0xc3
        .byte	'S', 0x7f,0xff,0xc0,0xc0,0xc0,0xfe,0x7f,0x03,0x03,0x83,0xff,0x7e

	.text
.globl	GetTileCoordinateAddr
.globl	DrawBox
.globl	DrawFood
.globl	DrawHead
.globl	DrawBody
.globl	DrawBodyTile
.globl	ClearTile
.globl	OutText
####################################################################################################
# DrawFood
# Draws the food image at the given coordinates
# Arguments: none
# Returns: none
DrawFood:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lhu	$a0,foodPos	# get current food position from memory
	addiu	$a1,$0,2	# food is green
	jal	DrawTile
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawHead
# Draws the head
# Arguments: none
# Returns: none
DrawHead:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lhu	$a0, headPos	# get current head position from memory
	addiu	$a1,$0,6	# head is yellow
	jal	DrawTile
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawBody
# Draws all of the body tiles in the queue
# Arguments: none
# Returns: none
DrawBody:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	lh	$s0,bodyTail		# counter / offset starts at body start
	sll	$s0,$s0,1		# shift left to multiply by 2 for halfword offset
	lh	$s1,bodyFront		# load the end position of the body
	sll	$s1,$s1,1		# shift left to multiply by 2 for halfword offset
_bodyDrawLoop:
	lh	$a0,bodyQueue($s0)	# get current body part position from memoryge
	addiu	$s0,$s0,2		# increment offset by 2 for next body part
	jal	DrawBodyTile		
	ble	$s0,$s1,_bodyDrawLoop	# repeat loop if counter <= end
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawBody
# Draws all of the body tiles in the queue
# Arguments:
# $a0: tile position for body tile
# Returns: none
DrawBodyTile:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$a1,$0,5		# body is purple
	jal	DrawTile		# draw this body part
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawBody
# Draws all of the body tiles in the queue
# Arguments:
# $a0: tile position for body tile
# Returns: none
ClearTile:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	addiu	$a1,$0,0		# clear by drawing black
	jal	DrawTile		# draw black tile to erase
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawTile
# Draws a tile with a given color
# Arguments:
# $a0: the tile x, y position to draw the food
# $a1: color code to fill tile
# Returns: none
DrawTile:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	jal	GetTileCoordinateAddr
	move	$a0,$v0
	addiu	$a2,$0,8
	jal	DrawBox
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# HorzLine
# Draws a horizontal line with single pixel thickness
# Arguments
# $a0: memory address of video buffer to start from
# $a1: color code (0-7)
# $a2: length of line (1-256)
HorzLine:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	mul	$a1,$a1,4
	lw	$t0,ColorTable($a1)	# get color
_horzLoop:
	sw	$t0,0($a0)		
	addiu	$a0,$a0,4		# increment memory address	
	addiu	$a2,$a2,-1		# decrement line length
	bgt	$a2,$0,_horzLoop	# repeat loop if $a3 > 0
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra
####################################################################################################
# DrawBox
# Draws a filled box (square)
# Arguments:
# $a0: memory address of video buffer to start from
# $a1: color code (0-7)
# $a2: size of box (1-256)
DrawBox:
### stack ops
	addiu   $sp,$sp,-20
	sw      $ra,0($sp)
	sw      $s0,4($sp)
	sw      $s1,8($sp)
	sw      $s2,12($sp)
	sw      $s3,16($sp)
### end stack ops
	move	$s0,$a0
	move	$s1,$a1
	move	$s2,$a2
	move	$s3,$a2
	
	mul	$a1,$a1,4
	lw	$t0,ColorTable($a1)	# get color
_boxLoop:
	sw	$t0,0($a0)		# draw pixel
	addiu	$a0,$a0,4		# increment memory address	
	addiu	$a2,$a2,-1		# decrement line length
	bgt	$a2,$0,_boxLoop		# repeat loop if $a3 > 0
	# end horizontal line
	addiu	$s0,$s0,1024		# increment y coordinate
	move	$a0,$s0
	addiu	$s2,$s2,-1		# decrement box size
	move	$a2,$s3			# restore line length
	bne	$s2,$0,_boxLoop		# repeat loop if $a3 > 0
### stack ops
	lw      $s3,16($sp)
	lw      $s2,12($sp)
	lw      $s1,8($sp)
	lw      $s0,4($sp)
	lw      $ra,0($sp)
	addiu   $sp,$sp,20
### end stack ops
	jr	$ra
####################################################################################################
# GetTileCoordinateAddr
# Converts a tile x,y coordinate pair (from 32x32 grid) to a memory address
# Arguments:
# $a0: the tile position
# Returns:
# $v0: the address for the given coordinates
GetTileCoordinateAddr:
### stack ops
	addiu   $sp,$sp,-8
	sw      $ra,0($sp)
### end stack ops
	# address = x*32 + y * 8192 + 0x10040000 (buffer start)
	srl	$t0,$a0,8	# shift a copy of position right 1 byte for x position
	andi	$t0,$t0,0xFF	# get x position
	andi	$t1,$a0,0xFF	# get y position
	mul	$v0,$t1,8192	# calculate y coordinate
	mul	$t0,$t0,32	# calculate x coordinate
	addu	$v0,$v0,$t0
	addiu	$v0,$v0,0x10040000
### stack ops
	lw      $ra,0($sp)
	addiu   $sp,$sp,8
### end stack ops
	jr	$ra

####################################################################################################
#
#				Provided procedures
#
####################################################################################################
# OutText: display ascii characters on the bit mapped display
# $a0 = horizontal pixel co-ordinate (0-255)
# $a1 = vertical pixel co-ordinate (0-255)
# $a2 = pointer to asciiz text (to be displayed)
OutText:
        addiu   $sp, $sp, -24
        sw      $ra, 20($sp)

        li      $t8, 1          # line number in the digit array (1-12)
_text1:
        la      $t9, 0x10040000 # get the memory start address
        sll     $t0, $a0, 2     # assumes mars was configured as 256 x 256
        addu    $t9, $t9, $t0   # and 1 pixel width, 1 pixel height
        sll     $t0, $a1, 10    # (a0 * 4) + (a1 * 4 * 256)
        addu    $t9, $t9, $t0   # t9 = memory address for this pixel

        move    $t2, $a2        # t2 = pointer to the text string
_text2:
        lb      $t0, 0($t2)     # character to be displayed
        addiu   $t2, $t2, 1     # last character is a null
        beq     $t0, $zero, _text9

        la      $t3, DigitTable # find the character in the table
_text3:
        lb      $t4, 0($t3)     # get an entry from the table
        beq     $t4, $t0, _text4
        beq     $t4, $zero, _text4
        addiu   $t3, $t3, 13    # go to the next entry in the table
        j       _text3
_text4:
        addu    $t3, $t3, $t8   # t8 is the line number
        lb      $t4, 0($t3)     # bit map to be displayed

        sw      $zero, 0($t9)   # first pixel is black
        addiu   $t9, $t9, 4

        li      $t5, 8          # 8 bits to go out
_text5:
        la      $t7, Colors
        lw      $t7, 0($t7)     # assume black
        andi    $t6, $t4, 0x80  # mask out the bit (0=black, 1=white)
        beq     $t6, $zero, _text6
        la      $t7, Colors     # else it is white
        lw      $t7, 4($t7)
_text6:
        sw      $t7, 0($t9)     # write the pixel color
        addiu   $t9, $t9, 4     # go to the next memory position
        sll     $t4, $t4, 1     # and line number
        addiu   $t5, $t5, -1    # and decrement down (8,7,...0)
        bne     $t5, $zero, _text5

        sw      $zero, 0($t9)   # last pixel is black
        addiu   $t9, $t9, 4
        j       _text2          # go get another character

_text9:
        addiu   $a1, $a1, 1     # advance to the next line
        addiu   $t8, $t8, 1     # increment the digit array offset (1-12)
        bne     $t8, 13, _text1

        lw      $ra, 20($sp)
        addiu   $sp, $sp, 24
        jr      $ra