# main.asm
.data
    	win_message: .asciiz "Congratulations! You've matched all cards!\n"
.text
    .globl main

main:
    # Initialize the game board and necessary data
    jal init_board       # Calls function from game_logic.asm to initialize board
    # Start timer
    jal display_board    # Calls function from io.asm to display board
    
    jal startTimer
    jal updateTimer

game_loop:
    jal get_user_input   # Get player's card positions (from io.asm)
    jal check_match      # Check if cards match (from game_logic.asm)
    
    # Check if the game is over
    jal is_game_over     # Check if all cards are matched (from game_logic.asm)
    beq $v0, 1, end_game # If game is over, jump to end_game

    jal display_board    # Display updated board
    # Update timer
    jal updateTimer
    j game_loop          # Continue loop

end_game:
    # Print winning message
    la $a0, win_message
    li $v0, 4
    syscall

    # Exit the game
    li $v0, 10           # Exit syscall
    syscall
