; NOTE: angles are anticlockwise. Don't ask me why

%define WIDTH 3200
%define HEIGHT 2160
%define USABLE_HEIGHT 2160 - 165
%define BYTES_PER_PIXEL 4 ; 32 bit depth

%define RECT_WIDTH 100
%define RECT_HEIGHT 300
%define BALL_RADIUS 30

%define MOVE_SPEED 7

; c_lflags for termios
%define ECHO 8
%define ECHONL 64
%define ICANON 2
%define IEXTEN 32768

; flag for fcntl nonblocking
%define O_NONBLOCK 2048
%define F_SETFL 4

global _start

extern tcgetattr
extern tcsetattr
extern read
extern fcntl

; LIB Functions:
; libdraw
extern draw_ball
extern draw_rectangle
extern clear_screen
; libphysics
extern move_ai
extern move_ball
; libcollision
extern collide
; libmath
extern random

section .text
_start:
    ; termios
    ; save current terminal attr
    xor rdi, rdi
    mov rsi, term_conf
    call tcgetattr

    mov rsi, term_conf
    mov rdi, old_conf
    mov rcx, 60
    rep movsb

    ; modify to allow non-cononical mode 
    ; sizeof flags: 4 bytes. 
    xor rax, rax
    mov eax, ECHO | ECHONL | ICANON | IEXTEN
    not eax
    and dword [term_conf + 12], eax

    ; set new terminal attr
    xor rdi, rdi
    xor rsi, rsi
    mov rdx, term_conf
    call tcsetattr

    test rax, rax
    js exit_failure

    ; sys_fcntl
    mov rax, 72
    xor rdi, rdi
    mov rsi, F_SETFL
    mov rdx, O_NONBLOCK
    syscall

    test rax, rax
    js exit_failure

    ; Open /dev/fb0
    mov rax, 2
    mov rdi, fb0_path
    mov rsi, 2
    mov rdx, 0o666
    syscall

    ; Error check
    test rax, rax
    js exit_failure
    mov [fb0_fd], rax

     ; sys_mmap
    mov rax, 9
    xor rdi, rdi
    mov rsi, WIDTH * HEIGHT * BYTES_PER_PIXEL
    mov rdx, 3
    mov r10, 1
    mov r8, [fb0_fd]
    xor r9, r9
    syscall

    test rax, rax
    js exit_failure
    mov [fb_mmap], rax

    ; start angle for ball
    mov rdi, 0
    mov rsi, 360
    call random
    test rax, rax
    js exit_failure ; result should not be negative
    mov qword [ball_theta], rax

game_loop:
    mov rdi, [fb_mmap] ; frame buf base addr
    call clear_screen

    mov rdi, [player_score]
    mov rsi, [ai_score]
    cmp rdi, 10
    jge player_wins
    cmp rsi, 10
    jge ai_wins

    mov rdi, [rect_1_y]
    mov rsi, [rect_2_y]
    mov rdx, [ball_x]
    mov r10, [ball_y]
    mov r8, ball_theta
    call collide

    test rax, rax
    js exit_failure

    cmp rax, 0 ; point to ai
    je ai_scores
    cmp rax, 1 ; point to player
    je player_scores

    ; rect 1
    mov rdi, 1 ; xpos
    mov rsi, [rect_1_y] ;ypos
    mov rdx, [fb_mmap] ; frame buf base addr
    mov rcx, RECT_HEIGHT
    mov r10, RECT_WIDTH
    call draw_rectangle

    test rax, rax
    js exit_failure

    ; rect 2
    mov rdi, 3099 ; xpos
    mov rsi, [rect_2_y] ; ypos
    mov rdx, [fb_mmap] ; frame buf base addr
    mov rcx, RECT_HEIGHT
    mov r10, RECT_WIDTH
    call draw_rectangle
        
    test rax, rax
    js exit_failure

    ; move ball
    mov rdi, ball_x
    mov rsi, ball_y
    mov rdx, [ball_theta]
    call move_ball
    
    test rax, rax
    js exit_failure

    ; ball
    mov rdi, [ball_x] ; xpos
    mov rsi, [ball_y] ; ypos
    mov rdx, [fb_mmap] ; frame buf base addr
    mov rcx, BALL_RADIUS
    call draw_ball

    test rax, rax
    js exit_failure
    
    ; Ai follow
    mov rdi, rect_2_y
    mov rsi, [ball_y]
    call move_ai ; update ai after everthing has moved

    mov rsi, 10
    call sleep

    ; termios
    xor rdi, rdi
    mov rsi, char
    mov rdx, 1
    call read ; calls a non blocking read

    test rax, rax
    jg .handle_keystroke ; if a key press is returned

    jmp game_loop

    jmp exit_success

.handle_keystroke:
    cmp byte [char], 'q'
    je exit_success

    cmp byte [char], 'w'
    je .handle_player_up

    cmp byte [char], 's'
    je .handle_player_down

    jmp game_loop

.handle_player_down:
    mov rax, [rect_1_y]
    add rax, MOVE_SPEED
    cmp rax, USABLE_HEIGHT - RECT_HEIGHT
    jg game_loop ; if out of bounds, ignore

    mov [rect_1_y], rax
    
    jmp game_loop

.handle_player_up:
    mov rax, [rect_1_y]
    sub rax, MOVE_SPEED
    test rax, rax
    js game_loop ; if out of bounds, ignore

    mov [rect_1_y], rax

    jmp game_loop

ai_scores:
    push rdi
    mov rdi, [ai_score]
    inc rdi
    mov qword [ai_score], rdi

    call _reset

    jmp game_loop
player_scores:
    push rdi
    mov rdi, [player_score]
    inc rdi
    mov qword [player_score], rdi

    call _reset

    jmp game_loop

player_wins:
    jmp exit_success
ai_wins:
    jmp exit_success

_reset:
    mov qword [ball_x], WIDTH / 2
    mov qword [ball_y], HEIGHT / 2
    mov qword [rect_1_y], HEIGHT / 2
    mov qword [rect_2_y], HEIGHT / 2
     
    push rdi
    push rsi
    ; start angle for ball
    mov rdi, 0
    mov rsi, 360
    call random
    mov qword [ball_theta], rax
    pop rsi
    pop rdi

    ret
    
unmap:
    ; unmap_fb
    push rdi
    push rsi

    mov rax, 11
    mov rdi, [fb_mmap]
    mov rsi, WIDTH * HEIGHT * BYTES_PER_PIXEL
    syscall

    pop rsi
    pop rdi

    ret

; @params: takes a time in millisecond in rsi
sleep:
    imul rsi, 1000000 ; get time in nanoseconds
    mov rax, 0
    mov [timespec], rax
    mov [timespec + 8], rsi

    ; nanosleep
    mov rax, 35
    mov rdi, timespec
    xor rsi, rsi
    syscall

    test rax, rax
    js exit_failure
    ret

; closes fb0
close_file:
    mov rax, 4
    mov rdi, [fb0_fd]
    syscall

    ret

restore_term:
    xor rdi, rdi
    xor rsi, rsi
    mov rdx, old_conf
    call tcsetattr

    ret

exit_failure:
    call unmap
    call restore_term
    call close_file
    mov rax, 60
    mov rdi, 1
    syscall

exit_success:
    call unmap
    call restore_term
    call close_file
    mov rax, 60
    xor rdi, rdi
    syscall

section .data
    fb0_path db "/dev/fb0", 0
    white equ 0xFFFFFFFF ; aBGR
    black equ 0xFF000000 
    rect_1_y dq 900
    rect_2_y dq 900
    ball_y dq HEIGHT / 2
    ball_x dq WIDTH / 2
    ball_theta dq 1
    player_score dq 0
    ai_score dq 0

section .bss
    fb0_fd resq 1
    fb_mmap resq 1 
    offset resq 1
    timespec resb 16

    ; termios
    term_conf resb 60
    old_conf resb 60
    char resb 1
