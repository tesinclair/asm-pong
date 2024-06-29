%define WHITE 0xFFFFFFFF
%define BLACK 0xFF000000

%define SCREEN_HEIGHT 2160
%define SCREEN_WIDTH 3200
%define USABLE_HEIGHT 2160 - 165

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

    mov [x_pos], rdi
    mov [y_pos], rsi
    mov [frame_buf], rdx
    mov [radius], rcx

    ; offset y = r9
    mov r9, [radius] + [y_pos]
.draw_ball_loop:
    ; calculate offset x = r8
    ; equation: x = sqrt(r^2 - (r9 - y_pos)^2) + x_pos
    mov r8, [radius] * [radius]
    mov r11, r9 - [y_pos]
    imul r11, r11
    sub r8, r11 ; r^2 - (r9 - y_pos)^2
    push rdi
    mov rdi, r8
    call sqrt
    pop rdi
    mov r8, rax
    add r8, [x_pos]

    ; calculate start offset [offset]
    ; x and y are (r8, r9)
    mov [offset], r9 * WIDTH + r8

    ; num pixels to draw = (radius - offset.x) * 2
    mov r10, [radius] - r8
    shl r10

    ; draw the line
    mov rsi, [offset]
    mov rdi, r10
    call draw_line

    inc rcx
    cmp rcx, [radius] * 2
    jl .draw_ball_loop

    pop r11
    pop r9
    pop r8
    pop r10
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
    mov [x_pos], rdi
    mov [y_pos], rsi
    mov [frame_buf], rdx
    mov [rect_height], rcx
    mov [rect_width], r10

    ; Check against the full rect size
    add rdi, [rect_width]
    cmp rdi, WIDTH
    jae exit_failure

    add rsi, [rect_height]
    cmp rsi, USABLE_HEIGHT
    jae exit_failure

    ; offset = y_pos * WIDTH + x_pos
    mov rcx, 0 ; y_index
.draw_rect_loop:

    ; calculate the start of the line
    mov [offset], [y_pos] * WIDTH + [x_pos]

    mov rdi, [rect_width]
    mov rsi, [offset]
    call draw_line

    inc rcx
    cmp rcx, [rect_height]
    jl .draw_rect_loop

    ret

; @params:
;       - rdi: the number of pixels to draw
;       - rsi: the offset to draw at
;       - assumes frame_buf
draw_line:
    mov rcx, rdi
    mov rdi, [frame_buf + rsi]
    mov eax, WHITE
    rep stosd

    ret

; @params:
;       - rdi: frame buf base addr

; @function:
;       - Moves black into every pixel on the screen
clear_screen:
    push rcx

    mov rcx, WIDTH * USABLE_HEIGHT
    mov eax, BLACK
    rep stosd

    mov rax, 0

    pop rcx
    ret
    
    
; @params:
;       - rdi: frame buf base addr
;       - rsi: offset

; @function:
;       - Draws a white pixel to the current offset
;       in the frame buf
draw_pixel:
    push rcx

    mov rcx, rdi
    add rcx, rsi
    mov eax, WHITE
    mov [rcx], eax

    mov rax, 0

    pop rcx

    ret

section .bss
    offset resq 1

    frame_buf resq 1
    rect_width resq 1
    rect_height resq 1
    x_pos resq 1
    y_pos resq 1
    radius resq 1
