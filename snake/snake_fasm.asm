format MZ
entry code_segment:start
stack 100h

left = 0
top = 2
row = 15
col = 40
right = left + col
bottom = top + row

segment data_segment
    msg db "Welcome to the snake game!!",0
    instructions db 0Ah,0Dh,"Use a, s, d and w to control your snake",0Ah,0Dh,"Use q anytime to quit",0Dh,0Ah,"Press any key to continue$"
    quitmsg db "Thanks for playing! hope you enjoyed",0
    gameovermsg db "OOPS!! your snake died! :P ",0
    scoremsg db "Score: ",0
    head db '^',10,10
    body db '*',10,11,45 dup (0)
    segmentcount db 1
    fruitactive db 1
    fruitx db 8
    fruity db 8
    gameover db 0
    quit db 0
    delaytime db 5

segment code_segment
start:
    mov ax,data_segment
    mov ds,ax

    mov ax,0b800h
    mov es,ax

    mov ax,0003h
    int 10h

    mov bx,msg
    mov dx,00
    call writestringat

    mov dx,instructions
    mov ah,09h
    int 21h

    mov ah,07h
    int 21h
    mov ax,0003h
    int 10h
    call printbox

mainloop:
    call delay
    mov bx,msg
    mov dx,00
    call writestringat
    call shiftsnake
    cmp byte [gameover],1
    je gameover_mainloop

    call keyboardfunctions
    cmp byte [quit],1
    je quitpressed_mainloop
    call fruitgeneration
    call draw

    jmp mainloop

gameover_mainloop:
    mov ax,0003h
    int 10h
    mov byte [delaytime],100
    mov dx,0000h
    mov bx,gameovermsg
    call writestringat
    call delay
    jmp quit_mainloop

quitpressed_mainloop:
    mov ax,0003h
    int 10h
    mov byte [delaytime],100
    mov dx,0000h
    mov bx,quitmsg
    call writestringat
    call delay
    jmp quit_mainloop

quit_mainloop:
    mov ax,0003h
    int 10h
    mov ax,4c00h
    int 21h

delay:
    mov ah,00
    int 1Ah
    mov bx,dx

jmp_delay:
    int 1Ah
    sub dx,bx

    cmp dl,[delaytime]
    jl jmp_delay
    ret

fruitgeneration:
    mov ch,[fruity]
    mov cl,[fruitx]
regenerate:
    cmp byte [fruitactive],1
    je ret_fruitactive
    mov ah,00
    int 1Ah

    push dx
    mov ax,dx
    xor dx,dx
    xor bh,bh
    mov bl,row
    dec bl
    div bx
    mov [fruity],dl
    inc byte [fruity]

    pop ax
    mov bl,col
    dec dl
    xor bh,bh
    xor dx,dx
    div bx
    mov [fruitx],dl
    inc byte [fruitx]

    cmp [fruitx],cl
    jne nevermind
    cmp [fruity],ch
    jne nevermind
    jmp regenerate
nevermind:
    mov al,[fruitx]
    ror al,1
    jc regenerate

    add byte [fruity],top
    add byte [fruitx],left

    mov dh,[fruity]
    mov dl,[fruitx]
    call readcharat
    cmp bl,'*'
    je regenerate
    cmp bl,'^'
    je regenerate
    cmp bl,'<'
    je regenerate
    cmp bl,'>'
    je regenerate
    cmp bl,'v'
    je regenerate

ret_fruitactive:
    ret

dispdigit:
    add dl,'0'
    mov ah,02h
    int 21h
    ret

dispnum:
    test ax,ax
    jz retz
    xor dx,dx

    mov bx,10
    div bx

    push dx
    call dispnum
    pop dx
    call dispdigit
    ret
retz:
    mov ah,02
    ret

setcursorpos:
    mov ah,02h
    push bx
    mov bh,0
    int 10h
    pop bx
    ret

draw:
    mov bx,scoremsg
    mov dx,0109h
    call writestringat

    add dx,7
    call setcursorpos
    mov al,[segmentcount]
    dec al
    xor ah,ah
    call dispnum

    mov si,head
draw_loop:
    mov bl,[si]
    test bl,bl
    jz out_draw
    mov dx,[si+1]
    call writecharat
    add si,3
    jmp draw_loop

out_draw:
    mov bl,'X'
    mov dh,[fruity]
    mov dl,[fruitx]
    call writecharat
    mov byte [fruitactive],1

    ret

readchar:
    mov ah,01h
    int 16h
    jnz keybdpressed
    xor dl,dl
    ret
keybdpressed:
    mov ah,00h
    int 16h
    mov dl,al
    ret

keyboardfunctions:
    call readchar
    cmp dl,0
    je next_14

    cmp dl,'w'
    jne next_11
    cmp byte [head],'v'
    je next_14
    mov byte [head],'^'
    ret
next_11:
    cmp dl,'s'
    jne next_12
    cmp byte [head],'^'
    je next_14
    mov byte [head],'v'
    ret
next_12:
    cmp dl,'a'
    jne next_13
    cmp byte [head],'>'
    je next_14
    mov byte [head],'<'
    ret
next_13:
    cmp dl,'d'
    jne next_14
    cmp byte [head],'<'
    je next_14
    mov byte [head],'>'
next_14:
    cmp dl,'q'
    je quit_keyboardfunctions
    ret
quit_keyboardfunctions:
    inc byte [quit]
    ret

shiftsnake:
    mov bx,head

    xor ax,ax
    mov al,[bx]
    push ax
    inc bx
    mov ax,[bx]
    inc bx
    inc bx
    xor cx,cx
l:
    mov si,[bx]
    test si,[bx]
    jz outside
    inc cx
    inc bx
    mov dx,[bx]
    mov [bx],ax
    mov ax,dx
    inc bx
    inc bx
    jmp l

outside:
    pop ax

    push dx

    mov bx,head
    inc bx
    mov dx,[bx]

    cmp al,'<'
    jne next_1
    dec dl
    dec dl
    jmp done_checking_the_head
next_1:
    cmp al,'>'
    jne next_2
    inc dl
    inc dl
    jmp done_checking_the_head

next_2:
    cmp al,'^'
    jne next_3
    dec dh

    jmp done_checking_the_head

next_3:
    inc dh

done_checking_the_head:
    mov [bx],dx
    call readcharat

    cmp bl,'X'
    je i_ate_fruit

    mov cx,dx
    pop dx
    cmp bl,'*'
    je game_over
    mov bl,0
    call writecharat
    mov dx,cx

    cmp dh,top
    je game_over
    cmp dh,bottom
    je game_over
    cmp dl,left
    je game_over
    cmp dl,right
    je game_over

    ret
game_over:
    inc byte [gameover]
    ret
i_ate_fruit:
    mov al,[segmentcount]
    xor ah,ah

    mov bx,body
    mov cx,3
    mul cx

    pop dx
    add bx,ax
    mov byte [bx],'*'
    mov [bx+1],dx
    inc byte [segmentcount]
    mov dh,[fruity]
    mov dl,[fruitx]
    mov bl,0
    call writecharat
    mov byte [fruitactive],0
    ret

printbox:
    mov dh,top
    mov dl,left
    mov cx,col
    mov bl,'*'
l1:
    call writecharat
    inc dl
    loop l1

    mov cx,row
l2:
    call writecharat
    inc dh
    loop l2

    mov cx,col
l3:
    call writecharat
    dec dl
    loop l3

    mov cx,row
l4:
    call writecharat
    dec dh
    loop l4

    ret

writecharat:
    push dx
    mov ax,dx
    and ax,0FF00h
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1

    push bx
    mov bh,160
    mul bh
    pop bx
    and dx,0FFh
    shl dx,1
    add ax,dx
    mov di,ax
    mov [es:di],bl
    pop dx
    ret

readcharat:
    push dx
    mov ax,dx
    and ax,0FF00h
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    push bx
    mov bh,160
    mul bh
    pop bx
    and dx,0FFh
    shl dx,1
    add ax,dx
    mov di,ax
    mov bl,[es:di]
    pop dx
    ret

writestringat:
    push dx
    mov ax,dx
    and ax,0FF00h
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1
    shr ax,1

    push bx
    mov bh,160
    mul bh

    pop bx
    and dx,0FFh
    shl dx,1
    add ax,dx
    mov di,ax
loop_writestringat:
    mov al,[bx]
    test al,al
    jz exit_writestringat
    mov [es:di],al
    inc di
    inc di
    inc bx
    jmp loop_writestringat

exit_writestringat:
    pop dx
    ret
