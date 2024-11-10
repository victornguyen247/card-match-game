.data
    	.globl board        	# Make board accessible to other files
    	.align 2		
    	board: .space 64    	# Reserve space for 16 cards (4x4 grid)
    	.globl cards        	# Make cards accessible if needed
    	cards: .word 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8
    	.globl expressions
    	expressions: .space 80	# Reserve space for 16 strings, each with 5 letters
            #expstring: .asciiz "exp1 exp1 exp2 exp2 exp3 exp3 exp4 exp4 exp5 exp5 exp6 exp6 exp7 exp7 exp8 exp8 "
    	expstring_hard: .asciiz " 2-1  1/1 14/7  1*2 12/4  2+1  9-5 16/4  3+2 25/5 36/6  2*3 14/2  3+4  5+3  2*4 " 
    	expstring_easy: .asciiz " A    A    B    B    C    C    D    D    E    E    G    G    M    M    R    R   "      
    	.globl num_matched  	# Make num_matched accessible
    	num_matched: .word 0
    	.globl revealed     	# Make revealed accessible to other files
    	revealed: .space 16 	# Array to track revealed cards
    	prompt:         .asciiz "Select difficulty level (1 for hard, 0 for easy): "
	invalid:        .asciiz "Invalid choice, please enter 1 or 0.\n"
	newline:        .asciiz "\n"
	hard_version: .asciiz "Hard mode expressions"
	easy_version: .asciiz "Easy mode expressions"

.text
    	.globl init_board
    	.globl check_match
    	.globl is_game_over

# Initialize the board with shuffled cards
init_board:
    # Display prompt to select difficulty level
    la $a0, prompt       # Load address of the prompt string
    li $v0, 4            # Syscall for print string
    syscall              # Display prompt
    
    # Read user input (expecting '1' or '0')
    li $v0, 5            # Syscall for reading integer
    syscall              # Get input from user
    move $t0, $v0        # Move input value to $t0 for checking
    
    # Check if input is 1 (hard)
    li $t1, 1            # Set $t1 to 1
    beq $t0, $t1, hard_select # If user input is 1, go to hard_select
    
    # Check if input is 0 (easy)
    li $t1, 0            # Set $t1 to 0
    beq $t0, $t1, easy_select # If user input is 0, go to easy_select
    
    # If input is neither 1 nor 0, show invalid choice message
invalid_choice:
    la $a0, invalid      # Load address of invalid choice message
    li $v0, 4            # Syscall for print string
    syscall              # Display invalid choice message
    j init_board               # Retry by calling main again

hard_select:
    # Load expstring_hard if user selected hard mode
    la $t1, expstring_hard	# Source address
    la $a0, hard_version     
    li $v0, 4            # Syscall for print string
    syscall              
    j save_register     

easy_select:
    # Load expstring_easy if user selected easy mode
    la $t1, expstring_easy	# Source address
    la $a0, easy_version     
    li $v0, 4            # Syscall for print string
    syscall
    j save_register     
 
save_register:   
    # Save registers
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    
    # ask user version hard/easy
    
    

    # Initialize expressions array from expstring
    la $t0, expressions      # Destination address     
    li $t2, 0               # Counter
    li $t3, 80              # Total bytes to copy (16 * 5 bytes)

copy_expressions:
    lb $t4, ($t1)           # Load byte from expstring
    sb $t4, ($t0)           # Store byte to expressions
    addi $t0, $t0, 1        # Increment destination address
    addi $t1, $t1, 1        # Increment source address
    addi $t2, $t2, 1        # Increment counter
    blt $t2, $t3, copy_expressions  # Continue if not done copying

    # Continue with card shuffling
    li $s0, 15              # Start from last position (15)
    la $s1, board           # Load board address
    la $s2, cards           # Load cards array address
    la $s3, expressions     # Load expressions address

    # Reset revealed array to 0
    la $t0, revealed      # Load the base address of revealed array into $t0
    li $t1, 16            # Set loop counter to 16 (for 16 cards)
reset_loop:
    beq $t1, 0, end_reset # If counter is 0, exit loop
    sb $zero, 0($t0)      # Store 0 in the current byte (revealed[i] = 0)
    addi $t0, $t0, 1      # Move to the next byte in the array
    addi $t1, $t1, -1     # Decrement counter
    j reset_loop          # Repeat until all 16 bytes are set to 0

end_reset:
    # Shuffle the cards
shuffle_loop:
    # Generate random index between 0 and current position
    addi $a0, $s0, 1      # Upper bound = current position + 1
    jal generate_random
    move $t3, $v0         # Save random index to $t3

    # Swap cards in board and expstring at random position with current position
    # Calculate addresses for cards
    sll $t4, $s0, 2       # Current position * 4
    sll $t5, $t3, 2       # Random position * 4
    add $t6, $s2, $t4     # Address of current card in cards array
    add $t7, $s2, $t5     # Address of random card in cards array

    # Perform card swap
    lw $t8, ($t6)         # Load current card
    lw $t9, ($t7)         # Load random card
    sw $t9, ($t6)         # Store random card in current position
    sw $t8, ($t7)         # Store current card in random position

     # Calculate addresses for expressions (5 bytes per expression)
    mul $t4, $s0, 5         # Current position * 5
    mul $t5, $t3, 5         # Random position * 5
    add $t6, $s3, $t4       # Address of current expression in expressions array
    add $t7, $s3, $t5       # Address of random expression in expressions array

    # Perform expression swap (copy 5 bytes for each expression)
    li $t1, 5               # Counter for copying 5 bytes
expression_swap:
    lb $t8, ($t6)           # Load byte from current expression
    lb $t9, ($t7)           # Load byte from random expression
    sb $t9, ($t6)           # Store random byte in current position
    sb $t8, ($t7)           # Store current byte in random position
    addi $t6, $t6, 1        # Move to next byte in current expression
    addi $t7, $t7, 1        # Move to next byte in random expression
    addi $t1, $t1, -1       # Decrement byte counter
    bgtz $t1, expression_swap # Repeat until 5 bytes are swapped

    # Decrement counter and continue if not done
    addi $s0, $s0, -1     # Decrement counter
    bgez $s0, shuffle_loop

    # Copy shuffled cards to board
    li $t0, 0             # Counter
    li $t1, 16            # Number of cards
copy_loop:
    sll $t2, $t0, 2       # Calculate offset (counter * 4)
    add $t3, $s2, $t2     # Source address in cards
    add $t4, $s1, $t2     # Destination address in board
    lw $t5, ($t3)         # Load card value from shuffled cards
    sw $t5, ($t4)         # Store in board

    addi $t0, $t0, 1      # Increment counter
    blt $t0, $t1, copy_loop

    # Reset number of matched pairs
    sw $zero, num_matched

    # Restore registers and return
    lw $ra, 16($sp)
    lw $s0, 12($sp)
    lw $s1, 8($sp)
    lw $s2, 4($sp)
    lw $s3, 0($sp)
    addi $sp, $sp, 20
    jr $ra

# Check if two chosen positions match
# Input: $a0 = pos1, $a1 = pos2
# Output: $v0 = 1 if match, 0 if no match
check_match:
    	# Save registers
    	addi $sp, $sp, -20
    	sw $ra, 16($sp)
    	sw $s0, 12($sp)
    	sw $s1, 8($sp)
    	sw $s2, 4($sp)
    	sw $s3, 0($sp)

    	# Save input positions
    	move $s0, $a0       	# First position
    	move $s1, $a1       	# Second position

    	# Load board base address
    	la $s2, board

    	# Calculate addresses of selected cards
    	sll $t0, $s0, 2     	# pos1 * 4 (word aligned)
    	sll $t1, $s1, 2     	# pos2 * 4 (word aligned)
    	add $t0, $s2, $t0   	# Address of first card
    	add $t1, $s2, $t1   	# Address of second card

    	# Load card values
    	lw $s2, ($t0)       	# Value of first card
    	lw $s3, ($t1)       	# Value of second card

    	# Mark cards as revealed
    	la $t0, revealed    	# Load revealed array address
    	add $t1, $t0, $s0   	# Address for first card revealed status
    	add $t2, $t0, $s1   	# Address for second card revealed status
    	li $t3, 1
    	sb $t3, ($t1)       	# Mark first card as revealed
    	sb $t3, ($t2)       	# Mark second card as revealed

    	# Compare cards
    	bne $s2, $s3, no_match  # If cards don't match, branch

    	# Cards match - increment matched pairs counter
    	lw $t0, num_matched
    	addi $t0, $t0, 1
    	sw $t0, num_matched

    	# Return true (cards match)
    	li $v0, 1
    	j check_match_end

no_match:
    	# Show the cards for 1 seconds
    	# Save $ra since we're calling display_board
    	sw $ra, 16($sp)
    
    	# Display board with cards revealed
    	jal display_board
    
    	# Sleep for 1.25 second
    	li $v0, 32          
    	li $a0, 1250        
    	syscall
    
    	# Reset revealed status
    	la $t0, revealed
	add $t1, $t0, $s0
    	add $t2, $t0, $s1
    	sb $zero, ($t1)     	# Hide first card
    	sb $zero, ($t2)     	# Hide second card
    
    	# Restore $ra
    	lw $ra, 16($sp)
    
    	# Return false (cards don't match)
    	li $v0, 0

check_match_end:
    	# Restore registers
    	lw $ra, 16($sp)
    	lw $s0, 12($sp)
    	lw $s1, 8($sp)
    	lw $s2, 4($sp)
    	lw $s3, 0($sp)
    	addi $sp, $sp, 20
    	jr $ra
# Check if the game is over (all cards matched)
# Output: $v0 = 1 if game over, 0 if not
is_game_over:
    	lw $t0, num_matched
    	li $t1, 8           	# Total pairs to match
    	beq $t0, $t1, game_over
    	li $v0, 0           	# Game not over
    	jr $ra

	game_over:
    	li $v0, 1           	# Game over
    	jr $ra
