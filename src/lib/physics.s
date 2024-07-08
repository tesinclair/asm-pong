global move_ball
global move_ai

; libmath
extern sin
extern cos

%define MOVESPEED 4
%define SCREEN_WIDTH 3200
%define SCREEN_HEIGHT 2160
%define USABLE_HEIGHT 2160 - 165

; @params:
;       - rdi: x_pos buffer [read/write]
;       - rsi: y_pos buffer [read/write]
;       - rdx: theta (current angle) [read]
; @function:
;       - updates the x and y pos based on the 
;         ball movement speed and angle
move_ball:
    ; y = mvt_speed * sin(90 - theta)
    ; x = mvt_speed * cos(90 - theta)

    push rbx ; y
    push r10 ; x


    xor rax, rax
    ret

; @params:
;       - rdi: y_pos buffer [read/write]
;       - rsi: ball_y_pos [read]
; @function:
;       - moves ai by its movement speed
;         in the direction of ball
move_ai:
    push rbx
    mov rbx, [rdi]
    cmp rbx, rsi
    jl .move_ai_up ; if y_pos < ball_y_pos
    jg .move_ai_down ; if y_pos < ball_y_pos
    
.move_ai_return:
    pop rbx
    xor rax, rax
    ret

.move_ai_up:
    sub rbx, MOVE_SPEED
    test rbx, rbx
    js .move_ai_return ; exit if at roof

    mov [rdi], rbx
    jmp .move_ai_return

.move_ai_down:
    add rbx, MOVE_SPEED
    cmp rbx, USABLE_HEIGHT
    jg .move_ai_return ; exit if at bottom

    mov [rdi], rbx
    jmp .move_ai_return
    
