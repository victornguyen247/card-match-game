# main.asm
.data
    	win_message: .asciiz "Congratulations! You've matched all cards!\n"
 	prompt:     .asciiz "Play again? (y/n): "  # Prompt message
	yes_msg:    .asciiz "You chose to play again.\n"
	no_msg:     .asciiz "You chose to exit.\n"
	invalid_msg:.asciiz "Invalid input. Please enter 'y' or 'n'.\n"
.text
	.globl main

main:
    	# Initialize the game board and necessary data
    	jal init_board       	# Calls function from game_logic.asm to initialize board
    
    	jal display_board    	# Calls function from io.asm to display board
    
    	jal startTimer		# Start timer from timer.asm
    	jal updateTimer 	# print the begin time

game_loop:
    	jal get_user_input   	# Get player's card positions (from io.asm)
    	jal check_match      	# Check if cards match (from game_logic.asm)
    
    	# Check if the game is over
    	jal is_game_over     	# Check if all cards are matched (from game_logic.asm)
    	beq $v0, 1, end_game 	# If game is over, jump to end_game

    	jal display_board    	# Display updated board
    	# Update timer
    	jal updateTimer
    	j game_loop          	# Continue loop

end_game:
    	# Print winning message
    	la $a0, win_message
    	li $v0, 4
    	syscall
    
    	# print total time
    	jal updateTimer
# ask user play game again 
ask_again:
    	# Display the prompt
    	la $a0, prompt        	# Load address of prompt message
    	li $v0, 4             	# Syscall for print string
    	syscall               	# Print "Play again? (y/n): "

    	# Read a single character from the user
    	li $v0, 12            	# Syscall for reading a character
    	syscall               	# Read character into $v0
    	move $t0, $v0         	# Move the character into $t0 for comparison

    	# Check if the character is 'y' (ASCII 121) or 'n' (ASCII 110)
    	li $t1, 121           	# ASCII value of 'y' 
    	li $t2, 110           	# ASCII value of 'n'

    	beq $t0, $t1, play_again   # If input is 'y', go to play_again
    	beq $t0, $t2, exit_game    # If input is 'n', go to exit_game

    	# If input is neither 'y' nor 'n', print an invalid message and ask again
    	la $a0, invalid_msg    	# Load address of invalid message
    	li $v0, 4              	# Syscall for print string
    	syscall                	# Print "Invalid input. Please enter 'y' or 'n'."
    	j ask_again            	# Repeat asking the user

play_again:
    	# Print a message for playing again
    	la $a0, yes_msg        	# Load address of yes message
    	li $v0, 4              	# Syscall for print string
    	syscall                	# Print "You chose to play again."
    
    	j main            	   # Go back to main

exit_game:
    	# Print a message for exiting the game
    	la $a0, no_msg         	# Load address of no message
    	li $v0, 4              	# Syscall for print string
    	syscall                	# Print "You chose to exit."

    	# Exit the program
    	li $v0, 10             	# Syscall to exit
    	syscall
