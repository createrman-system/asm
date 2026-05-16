default rel

global main

extern GetAsyncKeyState
extern Sleep
extern printf
extern puts
extern rand
extern srand
extern system
extern time

WIDTH equ 40
HEIGHT equ 15
MAXLEN equ WIDTH * HEIGHT

DIR_UP equ 0
DIR_DOWN equ 1
DIR_LEFT equ 2
DIR_RIGHT equ 3

VK_A equ 41h
VK_D equ 44h
VK_Q equ 51h
VK_S equ 53h
VK_W equ 57h

section .data
    cmd_cls db "cls",0
    fmt_header db "Windows x64 Snake - WASD move, Q quit",10,"Score: %d",10,0
    fmt_gameover db 10,"Game over! Score: %d",10,0
    fmt_quit db 10,"Thanks for playing! Score: %d",10,0

    snake_len dd 3
    direction dd DIR_RIGHT
    fruit_x db 28
    fruit_y db 8
    score dd 0
    game_over dd 0
    quit_game dd 0

    snake_x db 20,19,18
            times (MAXLEN - 3) db 0
    snake_y db 8,8,8
            times (MAXLEN - 3) db 0

section .bss
    linebuf resb WIDTH + 3
    next_x resb 1
    next_y resb 1

section .text

main:
    sub rsp,40

    xor ecx,ecx
    call time
    mov ecx,eax
    call srand
    call place_fruit

.loop:
    call draw_screen
    call handle_input

    cmp dword [quit_game],1
    je .quit

    call step_game
    cmp dword [game_over],1
    je .gameover

    mov ecx,90
    call Sleep
    jmp .loop

.gameover:
    call draw_screen
    lea rcx,[fmt_gameover]
    mov edx,[score]
    call printf
    xor eax,eax
    add rsp,40
    ret

.quit:
    lea rcx,[fmt_quit]
    mov edx,[score]
    call printf
    xor eax,eax
    add rsp,40
    ret

handle_input:
    sub rsp,40

    mov ecx,VK_Q
    call GetAsyncKeyState
    test ax,8000h
    jz .check_w
    mov dword [quit_game],1
    jmp .done

.check_w:
    mov ecx,VK_W
    call GetAsyncKeyState
    test ax,8000h
    jz .check_s
    cmp dword [direction],DIR_DOWN
    je .done
    mov dword [direction],DIR_UP
    jmp .done

.check_s:
    mov ecx,VK_S
    call GetAsyncKeyState
    test ax,8000h
    jz .check_a
    cmp dword [direction],DIR_UP
    je .done
    mov dword [direction],DIR_DOWN
    jmp .done

.check_a:
    mov ecx,VK_A
    call GetAsyncKeyState
    test ax,8000h
    jz .check_d
    cmp dword [direction],DIR_RIGHT
    je .done
    mov dword [direction],DIR_LEFT
    jmp .done

.check_d:
    mov ecx,VK_D
    call GetAsyncKeyState
    test ax,8000h
    jz .done
    cmp dword [direction],DIR_LEFT
    je .done
    mov dword [direction],DIR_RIGHT

.done:
    add rsp,40
    ret

step_game:
    push rbx
    push r12
    sub rsp,40

    mov al,[snake_x]
    mov [next_x],al
    mov al,[snake_y]
    mov [next_y],al

    mov eax,[direction]
    cmp eax,DIR_UP
    jne .not_up
    dec byte [next_y]
    jmp .moved
.not_up:
    cmp eax,DIR_DOWN
    jne .not_down
    inc byte [next_y]
    jmp .moved
.not_down:
    cmp eax,DIR_LEFT
    jne .go_right
    dec byte [next_x]
    jmp .moved
.go_right:
    inc byte [next_x]

.moved:
    mov al,[next_x]
    cmp al,1
    jb .dead
    cmp al,WIDTH
    ja .dead

    mov al,[next_y]
    cmp al,1
    jb .dead
    cmp al,HEIGHT
    ja .dead

    xor r12d,r12d
    mov ebx,[snake_len]
.self_loop:
    cmp r12d,ebx
    jge .self_ok

    lea r8,[snake_x]
    mov al,[r8+r12]
    cmp al,[next_x]
    jne .self_next
    lea r8,[snake_y]
    mov al,[r8+r12]
    cmp al,[next_y]
    je .dead

.self_next:
    inc r12d
    jmp .self_loop

.self_ok:
    mov al,[next_x]
    cmp al,[fruit_x]
    jne .no_eat
    mov al,[next_y]
    cmp al,[fruit_y]
    jne .no_eat

    inc dword [score]
    inc dword [snake_len]
    call shift_body
    call place_fruit
    jmp .done

.no_eat:
    call shift_body
    jmp .done

.dead:
    mov dword [game_over],1

.done:
    add rsp,40
    pop r12
    pop rbx
    ret

shift_body:
    mov ecx,[snake_len]
    dec ecx

.loop:
    cmp ecx,0
    jle .head
    mov edx,ecx
    dec edx

    lea r8,[snake_x]
    mov al,[r8+rdx]
    mov [r8+rcx],al

    lea r8,[snake_y]
    mov al,[r8+rdx]
    mov [r8+rcx],al

    dec ecx
    jmp .loop

.head:
    mov al,[next_x]
    mov [snake_x],al
    mov al,[next_y]
    mov [snake_y],al
    ret

place_fruit:
    push rbx
    push r12
    sub rsp,40

.retry:
    call rand
    xor edx,edx
    mov ebx,WIDTH
    div ebx
    inc dl
    mov [fruit_x],dl

    call rand
    xor edx,edx
    mov ebx,HEIGHT
    div ebx
    inc dl
    mov [fruit_y],dl

    xor r12d,r12d
    mov ebx,[snake_len]
.check_loop:
    cmp r12d,ebx
    jge .done

    lea r8,[snake_x]
    mov al,[r8+r12]
    cmp al,[fruit_x]
    jne .next
    lea r8,[snake_y]
    mov al,[r8+r12]
    cmp al,[fruit_y]
    je .retry

.next:
    inc r12d
    jmp .check_loop

.done:
    add rsp,40
    pop r12
    pop rbx
    ret

draw_screen:
    push r12
    push r13
    push r14
    sub rsp,32

    lea rcx,[cmd_cls]
    call system

    lea rcx,[fmt_header]
    mov edx,[score]
    call printf

    xor r12d,r12d
.row_loop:
    cmp r12d,HEIGHT + 2
    jge .done

    xor r13d,r13d
.col_loop:
    cmp r13d,WIDTH + 2
    jge .print_row

    mov al,' '
    cmp r12d,0
    je .border
    cmp r12d,HEIGHT + 1
    je .border
    cmp r13d,0
    je .border
    cmp r13d,WIDTH + 1
    je .border

    mov al,'X'
    mov bl,[fruit_x]
    cmp r13b,bl
    jne .check_snake
    mov bl,[fruit_y]
    cmp r12b,bl
    je .store

.check_snake:
    xor r14d,r14d
.snake_loop:
    cmp r14d,[snake_len]
    jge .empty

    lea r8,[snake_x]
    mov bl,[r8+r14]
    cmp r13b,bl
    jne .snake_next
    lea r8,[snake_y]
    mov bl,[r8+r14]
    cmp r12b,bl
    jne .snake_next

    mov al,'*'
    cmp r14d,0
    jne .store
    mov al,'@'
    jmp .store

.snake_next:
    inc r14d
    jmp .snake_loop

.empty:
    mov al,' '
    jmp .store

.border:
    mov al,'#'

.store:
    lea r8,[linebuf]
    mov [r8+r13],al
    inc r13d
    jmp .col_loop

.print_row:
    lea r8,[linebuf]
    mov byte [r8+r13],0
    lea rcx,[linebuf]
    call puts
    inc r12d
    jmp .row_loop

.done:
    add rsp,32
    pop r14
    pop r13
    pop r12
    ret
