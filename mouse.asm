mouseX dw 0        ; Mouse X coordinate
mouseY dw 0        ; Mouse Y coordinate

InitMouse proc
    mov ax, 0
    int 33h
	mov ax, 1
    int 33h
ret

InitMouse endp

GetMousePos proc
    mov ax, 3
    int 33h
    mov [mouseX], cx
    mov [mouseY], dx
    ret
GetMousePos endp



DisplayMouseCoordinates proc

    push ax
    push bx
    push cx
    push dx

	posicion 0,0
    mov ax, [mouseX]
    call NumberToString
	mov dx, offset buffer
    mov ah, 09h
    int 21h  ; Print the string
	mov ax, [mouseY]

    call NumberToString

	mov dx, offset buffer  ; DS:DX points to our string
    mov ah, 09h
    int 21h  ; Print the string

    pop dx
    pop cx
    pop bx
    pop ax

    ret
DisplayMouseCoordinates endp

;NUMEROS
NumberToString proc
    lea di, buffer      ; Load the address of the buffer
    cmp ax, 0           ; Check if AX is 0
    je zeroNumber
    mov bx, 10          ; BX = 10 for division
	mov cx,0
divideLoop:
    xor dx, dx          ; Clear DX for division
    div bx              ; AX / 10, quotient in AL, remainder in DX
    add dl, '0'         ; Convert the remainder to ASCII
    push dx ; Push remainder on stack
	inc cx
    test ax, ax        ; Check if quotient is zero
    jnz divideLoop

reverseDigits:
    pop dx              ; Pop a digit from stack
    mov [di], dl        ; Store the digit
    inc di              ; Move to next position in buffer
    loop reverseDigits
	jmp checkPadding
zeroNumber:
mov [di],'0'
inc di
checkPadding:
    ; Add padding spaces if necessary
    mov bx, 3           ; Total desired length
    sub bx, cx          ; Calculate padding needed
    jz  setTerminator   ; Jump if no padding needed
paddingLoop:
    mov byte ptr [di], ' '  ; Add a space for padding
    inc di
    dec bx
    jnz paddingLoop

setTerminator:
    mov [di], 10
	mov [di+1],13
	mov [di+2], '$'
    ret
NumberToString endp



call InitMouse
MouseLoop:
	call GetMousePos
	call DisplayMouseCoordinates
	jmp MouseLoop
