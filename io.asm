# io.asm
.data
    	prompt1: .asciiz "Enter first card positions (0->15): "
    	prompt2: .asciiz "Enter  second card positions (0->15): "
    	invalidMsg: .asciiz "\nInvalid input. Try again.\n"
    	newline: .asciiz "\n"
    	space: .asciiz "   "
	space2: .asciiz " "
    	hidden: .asciiz "[XXX]"
    	border_line: .asciiz "\n+-------++-------++-------++-------++\n"
    	border1: .asciiz "+-P"        
    	border2: .asciiz "----+"    
    	border3: .asciiz "---+"
    	row_start: .asciiz "|"
    	row_start2: .asciiz "||"

.text
    	.globl display_board
    	.globl get_user_input

# Display the current board state
display_board:
    	# Save registers
    	addi $sp, $sp, -16
    	sw $ra, 12($sp)
    	sw $s0, 8($sp)
    	sw $s1, 4($sp)
    	sw $s2, 0($sp)
    
    	# Initialize variables
    	li $s0, 0           	# Row counter
    	li $s1, 0           	# Position counter
    	la $s2, board       	# Load board address
    
     	# print border with postion 
     	# Initialize the loop counter
    	li $t8, 0               # Start from 0
    	li $t9, 3               # End at 3
    
print_row:
    	# Print a newline
    	la $a0, newline         # Load address of newline
    	li $v0, 4               # Syscall for printing string
    	syscall                 # Print newline
    
    	# print border
loop_start:
    	bgt $t8, $t9, end_loop  # If counter > 4, exit loop

    	# Print border part 1 "+-P"
    	la $a0, border1         # Load address of part1
    	li $v0, 4               # Syscall for printing string
    	syscall                 # Print "+-P"

    	# Print the loop counter as "1", "2", etc.
   	move $a0, $t8           # Move loop counter to $a0
    	li $v0, 1               # Syscall for printing integer
    	syscall                 # Print the number
    
    	bgt $t8, 9, print_border3	
    	# Print border part 2 "-----+"
    	la $a0, border2         # Load address of part2
    	li $v0, 4               # Syscall for printing string
    	syscall                 # Print "-----+"
    	j counter
print_border3:
    	# Print border part3 "----+"
	la $a0, border3         # Load address of part3
    	li $v0, 4               # Syscall for printing string
    	syscall                 # Print "----+"
counter:    
    	# Increment the loop counter
    	addi $t8, $t8, 1        # counter++

    	# Repeat loop
    	j loop_start

end_loop:
    	# increase position value for next border
    	addi $t9, $t9, 4
    
    	# Print a newline at the end border
    	la $a0, newline         # Load address of newline
    	li $v0, 4               # Syscall for printing string
    	syscall                 # Print newline
    
    	# Print row start
    	la $a0, row_start
    	li $v0, 4
    	syscall
    
    	# Print 4 cards in current row
    	li $t0, 0          	# Column counter
print_card:
    	# Calculate current position in board
    	sll $t1, $s1, 2    	# Position * 4 (word aligned)
    	add $t1, $s2, $t1  	# Add board base address
    	lw $t2, ($t1)      	# Load card value
    
    	# Check if card is revealed
    	la $t3, revealed
    	add $t3, $t3, $s1
    	lb $t4, ($t3)
    
    	# If revealed, print number, otherwise print #
    	beqz $t4, print_hidden
	# Print space before card
    	la $a0, space
    	li $v0, 4
    	syscall
    
    	# Print card value
    	move $a0, $t2
    	li $v0, 1
    	syscall 
	# Print space after card
    	la $a0, space
    	li $v0, 4
    	syscall
    	j go_next
    
print_hidden:
	# Print space2 before hidden
    	la $a0, space2
    	li $v0, 4
    	syscall
	# print hidden character
    	la $a0, hidden
    	li $v0, 4
    	syscall
	# Print space2 after hidden
    	la $a0, space2
    	li $v0, 4
    	syscall
    
go_next:            
    	# Print row end
    	la $a0, row_start2
    	li $v0, 4
    	syscall
    
    	# Print row end if at last column
    	addi $t0, $t0, 1   	# Increment column counter
    	addi $s1, $s1, 1   	# Increment position counter
    
    	blt $t0, 4, print_card
    
    	# Move to next row
    	addi $s0, $s0, 1   	# Increment row counter
    	blt $s0, 4, print_row
    
    	# Print the end border
    	la $a0, border_line
    	li $v0, 4
    	syscall
    
    	# Restore registers and return
    	lw $ra, 12($sp)
    	lw $s0, 8($sp)
    	lw $s1, 4($sp)
    	lw $s2, 0($sp)
    	addi $sp, $sp, 16
    	jr $ra

# Get user input for two card positions
get_user_input:
    	# Save return address since we're making nested calls
    	addi $sp, $sp, -4
    	sw $ra, ($sp)
    
    	# Get first input
    	li $v0, 4
    	la $a0, prompt1
    	syscall
    
    	li $v0, 5  	# Read integer
    	syscall
    
    	# Validate first input
    	bltz $v0, invalidInput
    	bge $v0, 16, invalidInput
    
    	# Check if first card is already revealed
    	la $t0, revealed
    	add $t0, $t0, $v0
    	lb $t1, ($t0)
    	bnez $t1, invalidInput
    
    	# Store first valid input temporarily
    	move $t2, $v0
    
    	# Get second input
    	li $v0, 4
    	la $a0, prompt2
    	syscall
    
    	li $v0, 5  	# Read integer
    	syscall
    
    	# Validate second input
    	bltz $v0, invalidInput
    	bge $v0, 16, invalidInput
    
    	# Check if second card is already revealed
    	la $t0, revealed
    	add $t0, $t0, $v0
    	lb $t1, ($t0)
    	bnez $t1, invalidInput
    
    	# Check if second input equals first input
    	beq $v0, $t2, invalidInput
    
    	# Store valid inputs in $a0 and $a1
    	move $a1, $v0    	# Second input goes to $a1
    	move $a0, $t2    	# First input goes to $a0
    
    	# Restore return address and return
    	lw $ra, ($sp)
    	addi $sp, $sp, 4
    	jr $ra

invalidInput:
    	li $v0, 4
    	la $a0, invalidMsg
    	syscall
    
    	# Restore stack pointer before jumping back
    	addi $sp, $sp, 4
    	j get_user_input
