%define WIDTH 3200
%define HEIGHT 2160 - 165
%define RECT_HEIGHT 300
%define RECT_WIDTH 100
%define BALL_RADIUS 30

%define LEFT_WALL 0
%define RIGHT_WALL 1

global collide

extern random
; @params:
;       - rdi: rect_1 y pos
;       - rsi: rect_2 y pos
;       - rdx: ball center x pos
;       - r10: ball center y pos
;       - r8: theta buffer, in degrees [r/w]
; @returns:
;       - rax: the wall the ball collides with
; @function:
;       - updates theta based on any collisions
collide:
.test_ball_rect_1_collision:
.test_ball_rect_2_collision:
.test_ball_top_collision:
.test_ball_bottom_collision:
.test_ball_right_wall_collision:
.test_ball_left_wall_collision:
    
.no_collision_ret:
    xor rax, rax
    ret 

.collision_ret:
    mov [r8], rax
    xor rax, rax
    ret

; returns angle between 1 and 179
.get_angle_left:
    push rdi
    push rsi
    
    mov rdi, 1
    mov rsi, 179
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 181 and 359
.get_angle_right:
    push rdi
    push rsi
    
    mov rdi, 181
    mov rsi, 359
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 91 and 269
.get_angle_top:
    push rdi
    push rsi
    
    mov rdi, 91
    mov rsi, 269
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret

; returns angle between 271 and 360 because its easier than 270-360, 0-90
.get_angle_bottom:
    push rdi
    push rsi
    
    mov rdi, 271
    mov rsi, 360
    call random

    pop rsi
    pop rdi
    
    test rax, rax
    js .ret_failure

    jmp .collision_ret



.ret_failure:
    mov rax, -1
    ret

