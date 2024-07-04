%define WHITE 0xFFFFFFFF
%define BLACK 0xFF000000

%define SCREEN_HEIGHT 2160
%define SCREEN_WIDTH 3200
%define USABLE_SCREEN_HEIGHT 1995
%define BYTES_PP 4

; math
extern sqrt

global draw_ball
global draw_rectangle
global clear_screen

; @params:
;       - rdi: xpos
;       - rsi: ypos
;       - rdx: frame buf base addr
;       - rcx: radius
; @function:
;       - Draws a ball of radius onto the frame buffer
;         at pos (x, y)
draw_ball:
    push r10
    push r8
    push r9
    push r11
    push r12

    ; offset y = radius + y_pos
    mov r9, rcx ; offset y
    add r9, rdi
.draw_ball_loop:
    ; calculate offset x = sqrt(r^2 - (r9 - y_pos)^2) + x_pos
    mov r8, rcx ; offset x
    imul r8, rcx    ; r^2
    mov r11, r9
    sub r11, rsi    ; r9 - y_pos
    imul r11, r11
    sub r8, r11     ; r^2 - (r9 - y_pos)^2

    push rdi

    mov rdi, r8
    call sqrt
    mov r8, rax

    pop rdi

    add r8, rdi     ; x_pos

    ; calculate start offset [r12]
    ; x and y are (r8, r9)
    mov r12, r9
    imul r12, SCREEN_WIDTH
    add r12, r8

    ; num pixels to draw = (radius - offset.x) * 2
    mov r10, rcx
    sub r10, r8
    shl r10, 1

    ; draw the line
    push rdi
    push rsi
    mov rsi, r12    ; offset
    mov rdi, r10    ; num pixels
    call draw_line
    pop rsi
    pop rdi

    pop r12

    inc r9
    mov r11, rcx
    shl r11, 1
    cmp r9, r11
    jl .draw_ball_loop

    pop r12
    pop r11
    pop r9
    pop r8
    pop r10

    xor rax, rax
    ret

; @params:
;       - rdi: xpos
;       - rsi: ypos
;       - rdx: frame buf base addr
;       - rcx: rect height
;       - r10: rect width
; @function:
;       - Draws a rectangle of width and height
;         onto the frame buffer at (x, y) in white
draw_rectangle:
    push r11

    ; Check against the full rect size
    push rdi
    add rdi, r10
    cmp rdi, SCREEN_WIDTH
    jae .bad_width
    pop rdi

    push rsi
    add rsi, rcx
    cmp rsi, USABLE_SCREEN_HEIGHT
    jae .bad_height
    pop rsi

    ; r11 = y_index
    xor r11, r11
.draw_rect_loop:
    ; calculate the start of the line
    xor rax, rax
    mov rax, rsi
    add rax, r11 ; start + y_index
    imul rax, SCREEN_WIDTH ; * screen_width
    add rax, rdi ; + x_offset
    imul rax, BYTES_PP ; rax now contains offset

    mov rdi, r10  ; rect_width
    push rsi
    mov rsi, rax  ; offset
    mov r14, rdx  ; frame buf
    call draw_line
    pop rsi

    inc r11
    cmp r11, rcx
    jl .draw_rect_loop

    pop r11

    xor rax, rax
    ret

; fail cases

.bad_width: ; stack: r11, rdi
    pop rdi
    pop r11

    mov rax, -1
    ret

.bad_height: ; stack: r11, rsi
    pop rsi
    pop r11

    mov rax, -1
    ret


; @params:
;       - rdi: the number of pixels to draw
;       - rsi: the offset to draw at
;       - r14: frame_buf
draw_line:
    push rdi
    push r14
    push rcx
    push rax

    mov rcx, rdi
    add r14, rsi
    mov rdi, r14
    mov eax, WHITE
    rep stosd

    pop rax
    pop rcx
    pop r14
    pop rdi
    ret

; @params:
;       - rdi: frame buf base addr

; @function:
;       - Moves black into every pixel on the screen
clear_screen:
    push rcx

    mov rcx, SCREEN_WIDTH * USABLE_SCREEN_HEIGHT
    mov eax, BLACK
    rep stosd

    mov rax, 0

    pop rcx
    ret
    
