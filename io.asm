# io.asm
.data
    prompt1: .asciiz "Enter first card positions (0->15): "
    prompt2: .asciiz "Enter second card positions (0->15): "
    invalidMsg: .asciiz "\nInvalid input. Try again.\n"
    newline: .asciiz "\n"
    space: .asciiz "   "
    hidden: .asciiz " * "
    border_line: .asciiz "\n+---------+---------+---------+---------+\n"
    row_start_single: .asciiz "|  "    # For single digit numbers
    row_start_double: .asciiz "| "     # For double digit numbers

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
    li $s0, 0           # Row counter
    li $s1, 0           # Position counter
    la $s2, board       # Load board address
    
    # Print top border
    la $a0, border_line
    li $v0, 4
    syscall
    
print_row:
    # Print row start (handled in print_card now)
    
    # Print 4 cards in current row
    li $t0, 0          # Column counter
print_card:
    # Calculate current position in board
    sll $t1, $s1, 2    # Position * 4 (word aligned)
    add $t1, $s2, $t1  # Add board base address
    lw $t2, ($t1)      # Load card value
    
    # Check if card is revealed
    la $t3, revealed
    add $t3, $t3, $s1
    lb $t4, ($t3)
    
    # Determine which row start to use based on position number
    li $t5, 10         # Compare with 10 to check if double digit
    blt $s1, $t5, print_single_start
    la $a0, row_start_double
    j print_row_start
print_single_start:
    la $a0, row_start_single
print_row_start:
    li $v0, 4
    syscall
    
    # Print space before card
    la $a0, space
    li $v0, 4
    syscall
    
    # If revealed, print number; otherwise, print cell position
    beqz $t4, print_position
    
    # Print card value if revealed
    move $a0, $t2
    li $v0, 1
    syscall 
    j print_end_space
    
print_position:
    # Print cell number if hidden
    li $v0, 1
    move $a0, $s1
    syscall

print_end_space:    
    # Print space after card
    la $a0, space
    li $v0, 4
    syscall
    
    # Move to the next column
    addi $t0, $t0, 1   # Increment column counter
    addi $s1, $s1, 1   # Increment position counter
    
    # Check if we're at the end of the row
    bne $t0, 4, print_card
    
    # Print the closing separator "|" at the end of the row
    la $a0, row_start_single
    li $v0, 4
    syscall
    
    # Print row border
    la $a0, border_line
    li $v0, 4
    syscall
    
    # Move to the next row
    addi $s0, $s0, 1   # Increment row counter
    blt $s0, 4, print_row
    
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
    
    li $v0, 5  # Read integer
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
    
    li $v0, 5  # Read integer
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
    move $a1, $v0    # Second input goes to $a1
    move $a0, $t2    # First input goes to $a0
    
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
