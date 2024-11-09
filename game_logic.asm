# game_logic.asm
.data
    .globl board        # Make board accessible to other files
    .align 2
    board: .space 64    # Reserve space for 16 cards (4x4 grid)
    .globl cards        # Make cards accessible if needed
    cards: .word 1, 1, 2, 2, 3, 3, 4, 4, 5, 5, 6, 6, 7, 7, 8, 8
    .globl num_matched  # Make num_matched accessible
    num_matched: .word 0
    .globl revealed     # Make revealed accessible to other files
    revealed: .space 16 # Array to track revealed cards

.text
    .globl init_board
    .globl check_match
    .globl is_game_over

# Initialize the board with shuffled cards
init_board:
    # Save registers
    addi $sp, $sp, -20
    sw $ra, 16($sp)
    sw $s0, 12($sp)
    sw $s1, 8($sp)
    sw $s2, 4($sp)
    sw $s3, 0($sp)
    
    # Initialize counter
    li $s0, 15          # Start from last position (15)
    la $s1, board       # Load board address
    la $s2, cards       # Load cards array address
    
shuffle_loop:
    # Generate random index between 0 and current position
    addi $a0, $s0, 1    # Upper bound = current position + 1
    jal generate_random
    move $s3, $v0       # Save random index
    
    # Swap current position with random position
    # Calculate addresses
    sll $t0, $s0, 2     # Current position * 4
    sll $t1, $s3, 2     # Random position * 4
    add $t2, $s2, $t0   # Address of current card
    add $t3, $s2, $t1   # Address of random card
    
    # Perform swap
    lw $t4, ($t2)       # Load current card
    lw $t5, ($t3)       # Load random card
    sw $t5, ($t2)       # Store random card in current position
    sw $t4, ($t3)       # Store current card in random position
    
    # Decrement counter and continue if not done
    addi $s0, $s0, -1   # Decrement counter
    bgez $s0, shuffle_loop
    
    # Copy shuffled cards to board
    li $t0, 0           # Counter
    li $t1, 16          # Number of cards
copy_loop:
    sll $t2, $t0, 2     # Calculate offset (counter * 4)
    add $t3, $s2, $t2   # Source address
    add $t4, $s1, $t2   # Destination address
    lw $t5, ($t3)       # Load card value
    sw $t5, ($t4)       # Store in board
    
    addi $t0, $t0, 1    # Increment counter
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
    move $s0, $a0       # First position
    move $s1, $a1       # Second position

    # Load board base address
    la $s2, board

    # Calculate addresses of selected cards
    sll $t0, $s0, 2     # pos1 * 4 (word aligned)
    sll $t1, $s1, 2     # pos2 * 4 (word aligned)
    add $t0, $s2, $t0   # Address of first card
    add $t1, $s2, $t1   # Address of second card

    # Load card values
    lw $s2, ($t0)       # Value of first card
    lw $s3, ($t1)       # Value of second card

    # Mark cards as revealed
    la $t0, revealed    # Load revealed array address
    add $t1, $t0, $s0   # Address for first card revealed status
    add $t2, $t0, $s1   # Address for second card revealed status
    li $t3, 1
    sb $t3, ($t1)       # Mark first card as revealed
    sb $t3, ($t2)       # Mark second card as revealed

    # Compare cards
    bne $s2, $s3, no_match   # If cards don't match, branch

    # Cards match - increment matched pairs counter
    lw $t0, num_matched
    addi $t0, $t0, 1
    sw $t0, num_matched

    # Return true (cards match)
    li $v0, 1
    j check_match_end

no_match:
    # Cards don't match - hide them after a delay
    li $v0, 32          # Sleep syscall
    li $a0, 1000        # Sleep for 1 second (1000ms)
    syscall

    # Reset revealed status
    la $t0, revealed
    add $t1, $t0, $s0
    add $t2, $t0, $s1
    sb $zero, ($t1)     # Hide first card
    sb $zero, ($t2)     # Hide second card

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
    li $t1, 8           # Total pairs to match
    beq $t0, $t1, game_over
    li $v0, 0           # Game not over
    jr $ra

game_over:
    li $v0, 1           # Game over
    jr $ra
