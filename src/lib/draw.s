%define WHITE 0xFFFFFFFF
%define BLACK 0xFF000000

%define SCREEN_HEIGHT 2160
%define SCREEN_WIDTH 3200
%define USABLE_SCREEN_HEIGHT 1995
%define BYTES_PP 4

%define PLAYER_SCORE_X 1000
%define AI_SCORE_X 2200
%define SCORE_Y 200
%define FONT_SIZE 20
%define NUM_HEIGHT 100
%define NUM_LENGTH 40

; math
extern sqrt

global draw_ball
global draw_rectangle
global clear_screen

; @params:
;       - rdi: xpos
;       - rsi: ypos
;       - rdx: frame buf base addr ;; Used implicitely for draw_line
;       - rcx: radius
; @function:
;       - Draws a ball of radius onto the frame buffer
;         at pos (x, y)
draw_ball:

    ; check circle falls in positive quadrant
    cmp rdi, rcx
    jl .bad_circle
    cmp rsi, rcx
    jl .bad_circle

    push r10
    push r8
    push r9
    push r11
    push r12

    ; offset y = radius + y_pos
    mov r9, rcx ; offset_y = radius
    add r9, rsi ; + y_pos
.draw_ball_loop:
    ; calculate normal co-ords (x-rdi)^2 = rcx^2 - (r9 - rsi)^2
    mov r8, rcx 
    imul r8, r8 ; rcx^2

    mov r11, r9
    sub r11, rsi ; r11 = r9 - rsi
    imul r11, r11 ; (r9 - rsi)^2

    sub r8, r11 ; r8 = rcx^2 - (r9 - rsi)^2

    ; x = sqrt(r8) + rdi
    push rdi
    mov rdi, r8
    call sqrt 
    mov r8, rax ; sqrt(r8)
    imul r8, -1 ; we need the negative root
    pop rdi

    add r8, rdi ; x as co-ord

    ; calculate start offset [r12]
    ; x and y are (r8, r9)
    ; (r9 * SCREEN_WIDTH) + r8
    mov r12, r9
    imul r12, SCREEN_WIDTH
    add r12, r8
    imul r12, BYTES_PP

    ; num pixels to draw = (center.x - x_pos) * 2
    mov r10, rdi
    sub r10, r8 ; center.x - x_pos
    shl r10, 1 ; * 2 

    ; draw the line
    push rdi
    push rsi
    mov rsi, r12 ; offset  
    mov rdi, r10 ; num pixels
    call draw_line
    pop rsi
    pop rdi

    dec r9
    push r8
    mov r8, rsi
    sub r8, rcx
    cmp r9, r8 ; if curr_y = y_pos - radius, we are done
    pop r8 
    jge .draw_ball_loop

    pop r12
    pop r11
    pop r9
    pop r8
    pop r10

    xor rax, rax
    ret

.bad_circle:
    ; no stack corruption
    mov rax, -1
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

    push rdi
    mov rdi, r10  ; rect_width
    push rsi
    mov rsi, rax  ; offset
    mov r14, rdx  ; frame buf
    call draw_line
    pop rsi
    pop rdi

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
    
