.model small
.stack 100h

.data
mensaje db "DVD",10,13,"$"
col db 35
row db 12
randomNum db ?
randomStr db 10 DUP('$')

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

; Initialize seed with system time
mov ah, 00h
int 1Ah
mov bx, dx

ciclo:
    mov ah, 01h
    int 16h
    jz game

    mov ah, 00h
    int 16h

    cmp AL, "P"
    je pause

game:
    ; Generate random number using seed and some operations
    mul bx
    add ax, 1
    and ax, 0FFh
    mov randomNum, al

    ; Convert random number to string (in this example, assume it's a single digit)
    mov ah, 0
    mov al, randomNum
    add al, '0'
    mov randomStr, al

    call limpia
    posicion 12, col

    ; Print the random number
    mov ah, 09h
    lea dx, randomStr
    int 21h

    mov ah, 10h
    int 16h

    ; Check for 'R' key to refresh random number
    cmp AL, "R"
    jne notR

    ; Refresh random seed
    mov ah, 00h
    int 1Ah
    mov bx, dx
	jmp ciclo
