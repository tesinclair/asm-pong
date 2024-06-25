; Little endian

; TODO: 
;   - File i/o with /dev/fb0 ✅
;   - Basic Pong Shapes
;   - User Input
;   - Ball physics
;   - Game Loop
;   - Scores
;   - Quit on q

%define WIDTH 3200
%define HEIGHT 2160
%define BYTES_PER_PIXEL 4 ; 24 bit depth

%define RECT_WIDTH 100
%define RECT_HEIGHT 300
%define BALL_DIAMETER 60

global _start

section .text
_start:
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
    ; rect 1
    mov rdi, 1
    mov rsi, 1
    call draw_rectangle

    ; rect 2
    mov rdi, 3099
    mov rsi, 1
    call draw_rectangle

    ; ball
    mov rdi, 1500
    mov rsi, 100
    call draw_ball
 
    ; sleep 0.01s
    mov rsi, 10
    call sleep

    jmp game_loop

    jmp exit_success

; @params: takes a time in millisecond in rsi
sleep:
    imul rsi, 1000000 ; get time in milliseconds
    mov rax, 1
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

exit_failure:
    call close_file
    mov rax, 60
    mov rdi, 1
    syscall

exit_success:
    call close_file
    mov rax, 60
    xor rdi, rdi
    syscall

; @params: takes a buf and count in rsi, and rdx
print:
    push rax
    push rdi
    mov rax, 1
    mov rdi, 1
    syscall
    pop rdi
    pop rax
    ret

; @params: takes an xpos and ypos in rdi and rsi, and assumes fb0_fd has the fd
draw_ball:
    ; check ball is a safe size
    push rdi
    push rsi
    add rdi, BALL_DIAMETER
    add rsi, BALL_DIAMETER
    cmp rdi, WIDTH
    jae exit_failure
    cmp rsi, HEIGHT
    jae exit_failure
    pop rsi
    pop rdi

    mov r8, BALL_DIAMETER ; Offset
    push rax
    push rcx
    mov rax, r8
    cqo
    mov rcx, 3
    idiv rcx
    pop rax
    pop rcx
    mov r9, r8 ; edge_count
    mov r10, 0 ; edge_index
    mov r11, 0 ; row offset

    ; top left corner offset = (y_pos * WIDTH + x_pos) * BYTES_PER_PIXEL

decr_ball_loop:
    cmp r8, 0
    jle edge_ball_loop

    ; offset is top left corner offset + row offset + r8 offset
    push rsi ; preserve rsi and rdi
    push rdi
    add rsi, r11 ; (y_pos + row index)
    add rdi, r8 ; (x_pos + offset index)

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

    pop rdi
    pop rsi

    inc r11 ; next line

    cmp r8, r9 ; if offset == edge_count
    jl incr_ball_loop

    ret


; @params: takes the currently offset pixels in r8
draw_ball_line:
    push r10
    push r11

    mov r10, 0 ; to index drawing
    mov r11, BALL_DIAMETER
    sub r11, r8
    sub r11, r8 ; draw diameter - 2* offset pixels
decr_ball_draw_loop:

    ; sys_write
    mov rax, 1
    mov rsi, [fb0_fd]
    mov rsi, white
    mov rdi, BYTES_PER_PIXEL
    syscall

    test rax, rax
    js exit_failure

    inc r10
    cmp r10, r11
    jle decr_ball_draw_loop ; while <= diameter - 2 * offset

    pop r11
    pop r10

    ret

; @params: takes an xpos and ypos in rdi, and rsi, and assumes fb0_fd has the fd
draw_rectangle:
    ; check rect is a safe size
    push rdi ; preserve 
    push rsi
    ; Check against the full rect size
    add rdi, RECT_WIDTH
    add rsi, RECT_HEIGHT
    cmp rdi, WIDTH
    jae exit_failure
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
    push rsi ; preserve rsi and rdi
    push rdi
    add rsi, r8 ; (y_pos + index)
    add rdi, r9 ; (x_pos + index)

    mov rax, rsi 
    imul rax, WIDTH ; (y_pos + index) * width
    add rax, rdi ; ^ + (x_pos + index)
    imul rax, BYTES_PER_PIXEL ; ^ * bytes_per_pixel
    mov [offset], rax

    ; lseek
    mov rax, 8
    mov rdi, [fb0_fd]
    mov rsi, [offset]
    xor rdx, rdx
    syscall

    ; write
    mov rax, 1
    mov rdi, [fb0_fd]
    mov rsi, white
    mov rdx, BYTES_PER_PIXEL
    syscall

    test rax, rax
    js exit_failure

    pop rdi
    pop rsi
    
    inc r9
    cmp r9, RECT_WIDTH
    jl width_loop

    inc r8
    cmp r8, RECT_HEIGHT
    jl height_loop

    ret

section .data
    fb0_path db "/dev/fb0", 0
    white db 0xFF, 0xFF, 0xFF
    red db 0x00, 0x00, 0xFF



section .bss
    fb0_fd resq 1
    offset resq 1
    timespec resb 16
