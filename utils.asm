# utils.asm
.text
    .globl generate_random

# Generate a random number between 0 and $a0-1
# Input: $a0 = upper bound
# Output: $v0 = random number
generate_random:
    # Save return address
    addi $sp, $sp, -4
    sw $ra, ($sp)
    
    # Generate random number using syscall 42
    li $v0, 42          # Random int range
    move $a1, $a0       # Upper bound
    li $a0, 0           # Random generator ID
    syscall             # Random number will be in $a0
    
    # Move result to $v0
    move $v0, $a0
    
    # Restore return address and return
    lw $ra, ($sp)
    addi $sp, $sp, 4
    jr $ra
    jr $ra
    
