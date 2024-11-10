# io.asm
.data
    	prompt1: .asciiz "Enter first card positions (0->15): "
    	prompt2: .asciiz "Enter  second card positions (0->15): "
    	invalidMsg: .asciiz "\nInvalid input. Try again.\n"
    	newline: .asciiz "\n"
    	space: .asciiz " "
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
    li $s0, 0               # Row counter
    li $s1, 0               # Position counter
    la $s2, board           # Load board address
    la $s3, expressions     # Load expressions base address

    # Print initial border with position labels
    li $t8, 0               # Start loop counter
    li $t9, 3               # End loop counter

print_row:
    # Print a newline
    la $a0, newline
    li $v0, 4
    syscall

    # Print position labels border
loop_start:
    bgt $t8, $t9, end_loop   # Exit loop if counter > 3

    # Print border part "+-P" and position number
    la $a0, border1
    li $v0, 4
    syscall

    move $a0, $t8            # Move loop counter to $a0 to print
    li $v0, 1
    syscall

    # Print the border based on position
    bgt $t8, 9, print_border3

    la $a0, border2          # Print "-----+"
    li $v0, 4
    syscall
    j counter

print_border3:
    la $a0, border3          # Print "---+"
    li $v0, 4
    syscall

counter:
    # Increment the loop counter
    addi $t8, $t8, 1
    j loop_start

end_loop:
    addi $t9, $t9, 4         # Update end position for next border row

    # Print newline at end of border
    la $a0, newline
    li $v0, 4
    syscall

    # Print row start
    la $a0, row_start
    li $v0, 4
    syscall

    # Print 4 cards in the current row
    li $t0, 0                # Column counter

print_card:
    # Calculate position in revealed array to check if card is revealed
    la $t1, revealed
    add $t1, $t1, $s1        # Calculate revealed[s1]
    lb $t2, ($t1)            # Load revealed value (0 or 1)
    
    # Print space
    la $a0, space
    li $v0, 4
    syscall
    
    # Check if card is revealed
    beqz $t2, print_hidden   # If not revealed, print hidden placeholder
    

    # Print the label from expressions if card is revealed
    mul $t3, $s1, 5          # Calculate offset in expressions (s1 * 5)
    add $t4, $s3, $t3        # Get address of label in expressions

    # Print the 5-character label
    li $t5, 5
print_label:
    lb $a0, ($t4)            # Load byte from expressions
    li $v0, 11               # Syscall for printing a character
    syscall
    addi $t4, $t4, 1         # Move to next character
    addi $t5, $t5, -1        # Decrement counter
    bgtz $t5, print_label    # Repeat for all 5 characters

    # Print space after expression
    la $a0, space
    li $v0, 4
    syscall
    j go_next

print_hidden:
    # Print hidden placeholder "[XXX]" if card is not revealed
    la $a0, hidden
    li $v0, 4
    syscall
    
    # Print space after hidden
    la $a0, space
    li $v0, 4
    syscall

go_next:
    # Print row separator between cards
    la $a0, row_start2
    li $v0, 4
    syscall

    # Increment counters and check end of row
    addi $t0, $t0, 1         # Increment column counter
    addi $s1, $s1, 1         # Increment position counter
    blt $t0, 4, print_card   # Print next card in row if not done

    # Move to the next row
    addi $s0, $s0, 1         # Increment row counter
    blt $s0, 4, print_row    # Print next row if not done

    # Print the final border line
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
