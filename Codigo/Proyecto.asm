.model small
.stack 100h
.data

mensaje db "DVD",10,13,"$"
col db 35
row db 12
menuOpciones db "1. Disenar escenario de juego", 10, 13, "2. Establecer nivel y nombre del jugador", 10, 13, "3. Establecer escenario", 10, 13, "4. Iniciar juego", 10, 13, "5. Acerca de", 10, 13, "6. Salir", 10, 13, "$"
posicion macro x, y
    mov ah, 02H
    mov bh, 00h
    mov dh, row
    mov dl, col
    int 10H
	
endm

.code
mov ax,@DATA
mov ds, ax
menu:
    call limpia
    posicion 10, 10
    
	mov ah, 09h
    lea dx, menuOpciones
    int 21h

    mov ah, 01h
    int 16h
    jz menu

    mov ah, 00h
    int 16h

    cmp al, '1'
    je ciclo
    cmp al, '6'
    je salir
ciclo:

    posicion 10, 10
    call limpia
    posicion 10,10

    mov ah,09h
    lea dx,mensaje
    int 21h

    mov ah,010h
    int 16h

    cmp AL,"w"
    jne notA
    dec row
    notA:
	
    cmp AL, "p"
    je waitForP
	
    cmp AL,"s"
    jne notB
    inc row
    notB:

    cmp AH,48h
    jne notC
    dec row
    notC:

    cmp AH,50h
    jne notD
    inc row
    notD:

    jmp ciclo

waitForP:
    mov ah, 01h
    int 16h
    jz waitForP
    
    mov ah,010h
    int 16h
    cmp AL, "p"
    jne waitForP
    jmp ciclo

salir:
mov ah, 04ch
int 21h

limpia proc
    mov ax,0600h
    mov bh,17h
    mov cx,0000h
    mov dx,184fh
    int 10h
    ret
limpia endp

end