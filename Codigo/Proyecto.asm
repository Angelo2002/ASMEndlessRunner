.model small
.stack 100h

.data
mensaje db "DVD",10,13,"$"
col db 35
row db 12

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

ciclo:
    mov ah, 01h
    int 16h
    jz noPause

    mov ah, 00h
    int 16h

    cmp AL, "P"
    je waitForP

noPause:
    call limpia
    posicion 12,col

    mov ah,09h
    lea dx,mensaje
    int 21h

    mov ah,010h
    int 16h

    cmp AL,"w"
    jne notA
    dec row
    notA:

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
    
    mov ah, 00h
    int 16h
    cmp AL, "P"
    jne waitForP
    jmp ciclo

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