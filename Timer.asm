.data
    # Timer variables
    startTime:      .word 0
    currentTime:    .word 0
    elapsedTime:    .word 0
    timeMsg:        .asciiz "Time elapsed: "
    secondsMsg:     .asciiz " seconds\n"
.text 
.globl startTimer
.globl updateTimer
# Timer module
startTimer:
    li $v0, 30             # Get system time
    syscall
    sw $a0, startTime      # Save start time
    jr $ra

updateTimer:
    li $v0, 30             # Get current time
    syscall
    sw $a0, currentTime
    
    # Calculate elapsed time
    lw $t0, startTime
    sub $t1, $a0, $t0
    div $t1, $t1, 1000    # Convert to seconds
    sw $t1, elapsedTime
    
    # Display time
    li $v0, 4
    la $a0, timeMsg
    syscall
    
    li $v0, 1
    lw $a0, elapsedTime
    syscall
    
    li $v0, 4
    la $a0, secondsMsg
    syscall
    
    jr $ra
