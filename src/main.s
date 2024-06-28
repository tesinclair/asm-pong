; Little endian

; TODO: 
;   - File i/o with /dev/fb0 ✅
;   - Basic Pong Shapes ✅
;   - User Input
;   - Ball physics
;   - Scores

%define WIDTH 3200
%define HEIGHT 2160
%define BYTES_PER_PIXEL 4 ; 32 bit depth

%define RECT_WIDTH 100
%define RECT_HEIGHT 300
%define BALL_DIAMETER 60

%define MOVE_SPEED 5

global _start

extern tcgetattr
extern tcsetattr
extern read
extern fcntl

section .text
_start:
    ; termios
    ; save current terminal attr
    mov rdi, [STDIN]
    mov rsi, old_termios
    call tcgetattr

    ; copy old attributes to new
    mov rcx, 60
    mov rsi, old_termios
    mov rdi, new_termios
    rep movsb

    ; modify to allow non-cononical mode
    and byte [new_termios + 12], 0xF9 ; clear ICANON 

    ; set new terminal attr
    mov rdi, [STDIN]
    mov rsi, [tcsetattr_cmd]
    mov rdx, [TCSANOW]
    mov rcx, new_termios
    call tcsetattr

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

    
game_loop:
    ; Map into memory
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

    call clear_screen

    ; rect 1
    mov rdi, 1
    mov rsi, [rect_1_y]
    call draw_rectangle

    ; rect 2
    mov rdi, 3099
    mov rsi, [rect_2_y]
    call draw_rectangle

    ; ball
    mov rdi, WIDTH / 2
    mov rsi, 1000
    call draw_ball

    call draw

    ; roughly 30 fps
    mov rsi, 30
    call sleep

    ; termios
    mov rdi, [STDIN]
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
    je .handle_player_1_up

    cmp byte [char], 's'
    je .handle_player_1_down

    cmp byte [char], 'i'
    je .handle_player_2_up

    cmp byte [char], 'k'
    je .handle_player_2_down

    jmp game_loop

.handle_player_1_down:
    mov rax, [rect_1_y]
    add rax, MOVE_SPEED
    cmp rax, HEIGHT - RECT_HEIGHT
    jg game_loop ; if out of bounds, ignore

    mov [rect_1_y], rax
    
    jmp game_loop

.handle_player_1_up:
    mov rax, [rect_1_y]
    sub rax, MOVE_SPEED
    test rax, rax
    js game_loop ; if out of bounds, ignore

    mov [rect_1_y], rax

    jmp game_loop

.handle_player_2_down:
    mov rax, [rect_2_y]
    add rax, MOVE_SPEED
    cmp rax, HEIGHT - RECT_HEIGHT
    jg game_loop ; if out of bounds, ignore

    mov [rect_2_y], rax

    jmp game_loop

.handle_player_2_up:
    mov rax, [rect_2_y]
    sub rax, MOVE_SPEED
    test rax, rax
    js game_loop ; if out of bounds, ignore

    mov [rect_2_y], rax

    jmp game_loop

draw:
    ; unmap_fb
    mov rax, 11
    mov rdi, [fb_mmap]
    mov rsi, WIDTH * HEIGHT * BYTES_PER_PIXEL
    syscall

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
    mov rdi, [STDIN]
    mov rsi, [tcsetattr_cmd]
    mov rdx, [TCSANOW]
    mov rcx, old_termios
    call tcsetattr

    ret

exit_failure:
    call restore_term
    call close_file
    mov rax, 60
    mov rdi, 1
    syscall

exit_success:
    call restore_term
    call close_file
    mov rax, 60
    xor rdi, rdi
    syscall

; @params: takes an xpos and ypos in rdi and rsi, and assumes fb0_fd has the fd
draw_ball:
    ; check ball is a safe size
    push rdi
    push rsi

    add rdi, BALL_DIAMETER
    cmp rdi, WIDTH
    jge exit_failure

    add rsi, BALL_DIAMETER
    cmp rsi, HEIGHT
    jge exit_failure

    pop rsi
    pop rdi

    mov r8, BALL_DIAMETER / 3 ; Offset
    mov r9, r8 ; edge_count
    mov r10, 0 ; edge_index
    mov r11, 0 ; row offset

    ; top left corner offset = (y_pos * WIDTH + x_pos) * BYTES_PER_PIXEL

decr_ball_loop:
    cmp r8, 0 ; if offset = 0 go to edge_ball_loop
    jle edge_ball_loop

    ; offset is top left corner offset + row offset + r8 offset
    push rsi ; preserve rsi and rdi
    push rdi
    add rsi, r11 ; (y_pos + row index)
    add rdi, r8 ; (x_pos + offset index)
    
    push r11

    mov rax, rsi
    imul rax, WIDTH ; (y_pos + index) * width
    add rax, rdi ; ^ + (x_pos + index)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    call draw_ball_line

    pop r11
    pop rdi
    pop rsi

    inc r11
    dec r8

    jmp decr_ball_loop

edge_ball_loop:
    cmp r10, r9 ; if edge_index == edge_count
    jge incr_ball_loop

    push rdi
    push rsi

    add rsi, r11

    push r11

    mov rax, rsi 
    imul rax, WIDTH ; (y_pos) * width
    add rax, rdi ; ^ + (x_pos)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    mov rax, 8
    mov rdi, [fb0_fd]
    mov rsi, [offset]
    xor rdx, rdx
    syscall

    test rax, rax
    js exit_failure

    call draw_ball_line

    pop r11

    pop rsi
    pop rdi

    inc r10 ; inc edge_index
    inc r11 ; move to next line

    jmp edge_ball_loop

incr_ball_loop:
    inc r8 ; inc offset

    ; offset is top left corner offset + row offset + r8 offset
    push rsi ; preserve rsi and rdi
    push rdi

    add rsi, r11 ; (y_pos + row index)
    add rdi, r8 ; (x_pos + offset index)

    push r11
    
    mov rax, rsi 
    imul rax, WIDTH ; (y_pos + index) * width
    add rax, rdi ; ^ + (x_pos + index)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    ;lseek
    mov rax, 8
    mov rdi, [fb0_fd]
    mov rsi, [offset]
    xor rdx, rdx
    syscall

    test rax, rax
    js exit_failure

    call draw_ball_line

    pop r11

    pop rdi
    pop rsi

    inc r11 ; next line

    cmp r8, r9 ; if offset == edge_count
    jl incr_ball_loop

    ret

; @params: assumes [offset] is the current offset
draw_ball_line:
    push r10
    push r11

    mov r10, 0 ; to index drawing
    mov r11, BALL_DIAMETER
    sub r11, r8 ; draw diameter - 2* offset pixels
    sub r11, r8

decr_ball_draw_loop:
    push rdi
    mov ebx, white
    call draw_pixel
    pop rdi
    add qword [offset], 4

    inc r10
    cmp r10, r11
    jle decr_ball_draw_loop ; while <= diameter - 2 * offset

    pop r11
    pop r10

    ret

; @params: takes an xpos and ypos in rdi, and rsi, and assumes fb0_fd has the fd
draw_rectangle:
    push rdi
    push rsi

    ; Check against the full rect size
    add rdi, RECT_WIDTH
    cmp rdi, WIDTH
    jae exit_failure

    add rsi, RECT_HEIGHT
    cmp rsi, HEIGHT
    jae exit_failure

    pop rsi
    pop rdi

    ; offset = ((y_pos + index) * WIDTH + (x_pos + index)) * BYTES_PER_PIXEL
    mov r8, 0 ; y_index
height_loop:
    mov r9, 0 ; x_index
width_loop:
    ; Add indexes
    push rsi
    push rdi

    add rsi, r8 ; (y_pos + index)
    add rdi, r9 ; (x_pos + index)

    mov rax, rsi
    imul rax, WIDTH ; (y_pos + index) * width
    add rax, rdi ; ^ + (x_pos + index)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    mov ebx, white
    call draw_pixel

    pop rdi
    pop rsi
    
    inc r9
    cmp r9, RECT_WIDTH
    jl width_loop

    inc r8
    cmp r8, RECT_HEIGHT
    jl height_loop

    ret

clear_screen:
    push rsi
    push rdi

    mov rsi, 0 ; draw whole heigt and width
    mov rdi, 0
    ; offset = (y_pos * WIDTH + x_pos ) * BYTES_PER_PIXEL
    mov r8, 0 ; y_index
clear_height_loop:
    mov r9, 0 ; x_index
clear_width_loop:
    ; Add indexes
    push rsi
    push rdi

    add rsi, r8 ; (y_pos + index)
    add rdi, r9 ; (x_pos + index)

    mov rax, rsi
    imul rax, WIDTH ; (y_pos + index) * width
    add rax, rdi ; ^ + (x_pos + index)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    mov ebx, black
    call draw_pixel

    pop rdi
    pop rsi
    
    inc r9
    cmp r9, WIDTH 
    jl clear_width_loop

    inc r8
    cmp r8, HEIGHT * 9 / 10
    jl clear_height_loop

    pop rdi
    pop rsi

    ret

; takes a color in ebx, and assumes fb_mmap, and offset
draw_pixel:
    push rcx
    push rax

    mov rcx, [fb_mmap]
    add rcx, [offset]
    mov eax, ebx
    mov [rcx], eax

    pop rax
    pop rcx

    ret

section .data
    fb0_path db "/dev/fb0", 0
    white equ 0xFFFFFFFF ; aBGR
    black equ 0xFF000000 
    rect_1_y dq 900
    rect_2_y dq 900

    ; termios
    tcgetattr_cmd dq 0x5401
    tcsetattr_cmd dq 0x5402
    STDIN dq 0
    TCSANOW dq 0

section .bss
    fb0_fd resq 1
    fb_mmap resq 1 
    offset resq 1
    timespec resb 16

    ; termios
    old_termios resb 60
    new_termios resb 60
    char resb 1
