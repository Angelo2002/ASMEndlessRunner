.model small
.stack 200h
.data


;CONSTANTS
VIDEO_MEM equ 0A000h



pressEnter db "Presione ENTER para continuar...$"

ultima_c db 0
vel dw 2
last_sec db 0
gametime dw 0
no_hit_count db 0
toptimes dw 4 dup(0)
number_size db 0

obstaclex_matrix dw 320 dup(0)
obstacley_matrix dw 320 dup(0)
obstacle_ammount dw 0
matrix_pointer dw 0
px_travel_since_spawn db 0

screen_w dw 320 
screen_h dw 200  
num_text db 5 dup('0'),10,13, '$'
handle dw ?



update_freq dw 25
x dw 0
y dw 0
w dw 0
h dw 0
centiseconds dw 0

color db 0


;Meteor
meteor_x dw 20
meteor_y dw 20
;Player

player_x dw 0
player_y dw 20
;Images
pos_y dw 0
pos_x dw 0

player_iname db "ship.img",0
img_player db 730 dup(?)
player_w dw ?
player_h dw ?

img_obstacle db 262 dup(?)


obstacle_w dw ?
obstacle_h dw ?



img_address dw ?
filename_address dw ?
w_address dw ?
h_address dw ?

y_address dw ?
x_address dw ?

obstacle_iname db "meteor.img",0
;MACROS

IMPRIMIR MACRO text
   lea dx, text
   mov ah, 09h
   int 21h          
ENDM

UPDATE_TIME MACRO

ENDM

SPAWN_OBSTACLE MACRO yPosition
	cmp obstacle_ammount,320
	jge nospaceavailable
	lea di, obstaclex_matrix
	add di, obstacle_ammount
	mov [di],0
	lea di, obstacley_matrix
	add di, obstacle_ammount
	mov [di],yPosition
	inc obstacle_ammount
	nospaceavailable:
ENDM

DRAW_OBSTACLES MACRO

	LOAD_IMG_VARS obstacle_w,obstacle_h,img_obstacle
	mov x_address, offset obstaclex_matrix
	mov y_address, offset obstacley_matrix
	mov cx,obstacle_ammount
	drawobs_loop:
	text cx,cx
	jz noObstacles
	call draw_img
	add x_address,2
	add y_address,2
	loop drawobs_loop
	noObstacles:
ENDM

;Loads the address of img information into address variables
CALL_LOAD_IMG MACRO imgName, imgW, imgH, img
	lea ax, imgName
	mov filename_address, ax 
			
	lea ax, imgW
	mov w_address, ax
	
	lea ax, imgH
	mov h_address, ax
	
	lea ax, img
	mov img_address, ax
	
	call load_img 
ENDM

LOAD_IMG_VARS MACRO imgW, imgH, img
	mov img_address, offset img
	mov w_address, offset imgW
	mov h_address, offset imgH
ENDM
;macro para dibujar una imagen en x,y posicion
CALL_DRAW_IMG MACRO  xPosition,  yPosition          
	lea ax, xPosition
	mov x_address, ax
	lea ax, yPosition
	mov y_address, ax
	call draw_img
ENDM

posicion macro x, y
    mov ah, 02H
    mov bh, 00h
	mov dl, x
    mov dh, y
    int 10H
endm


;macro para ejecutar draw_rect
DIBUJAR_RECT_DATOS MACRO xm, ym, wm, hm, cm
	mov ax, xm
	mov x, ax
	mov ax, ym
	mov y, ax
	mov ax, wm
	mov w, ax
	mov ax, hm
	mov h, ax
	mov al, cm
	mov color, al
	call draw_rect
ENDM

.code
jmp start



NumberToString proc
	xor cx,cx			;How many numbers have been written
    lea di, num_text      
    cmp ax, 0           ; Check if AX is 0
    je zeroNumber
    mov bx, 10          ; BX = 10 for division        
divideLoop:
    xor dx, dx          ; Clear DX for division
    div bx              ; AX / 10, quotient in AL, remainder in DX
    add dl, '0'         ; ASCII
    push dx ; Remainder
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
	mov ax,di
	sub ax, offset num_text

	cmp al, number_size
	jge setTerminator
    mov byte ptr [di], '_'  ; Add a space for padding
    inc di
    dec bx
    jmp checkPadding

setTerminator:
    mov [di], 10
	mov [di+1],13
	mov [di+2], '$'
    ret
NumberToString endp

waitForEnter proc
    waitingForEnter:
        mov ah, 01h  
        int 16h
        cmp al, 0Dh  ; ENTER key
        je endWait  
        
        mov ah, 00h  ;
        int 16h
	
        jmp waitingForEnter  

    endWait:
    ret
waitForEnter endp


;proc para dibujar cuadrados
draw_rect proc
	;requiere un w, h, x, y, c
	;bx <- contador para medir ancho
	;cuando se alcance el ancho -> se cambia de linea
	;cuando se hayan pintado todos los pixeles se termina
	mov bx, 0
	mov ax, w
	mul h
	mov cx, ax
	ciclo_rect:
		;calcular donde pintar
		;posicion de memoria grafica
		; 320 x 200
		; recorrer el rectangulo por ancho
		; 
		mov ax, y
		mul screen_w
		add ax, x
		add ax, bx
		mov di, ax
		mov al, color
		mov es:[di], al
		inc bx
		cmp bx, w
		jne sig_px_rect
		mov bx, 0
		inc y
		sig_px_rect:
			loop ciclo_rect 
	ret    
endp

;lee un archivo cargado en dx
read_file proc
	;INT 21h / AH= 3Dh - open existing file.
	mov dx,  filename_address
	mov al, 0
	mov ah, 3dh
	int 21h
	jc err
	mov handle, ax
	ret
read_file endp

close_file proc
	;INT 21h / AH= 3Eh - close file. 
	mov bx, handle
	mov ah, 3eh
	int 21h ; close file... 
	ret
close_file endp
;proc para leer imagen
;requiere filename_address, img_address, h_address, w_address
load_img proc   
	;INT 21h / AH= 3Dh - open existing file.
	mov dx, filename_address
	call read_file
	;mov al, 0
	;mov dx,  filename_address
	;mov ah, 3dh
	;int 21h
	;jc err
	;mov handle, ax
	
	;INT 21h / AH= 42h - SEEK - set current file position.
	mov al, 0
	mov bx, handle
	mov cx, 0
	mov dx, 0
	mov ah, 42h
	int 21h ; seek... 
	jc err
	
	
	;INT 21h / AH= 3Fh - read from file. 
	mov bx, handle
	mov dx, w_address
	mov cx, 1
	mov ah, 3fh
	int 21h ; read from file...
	jc err
	

	
	;INT 21h / AH= 3Fh - read from file. 
	mov bx, handle
	mov dx, h_address
	mov cx, 1
	mov ah, 3fh
	int 21h ; read from file... 
	jc err
	
	;calcular tamano de la imagen
	;para saber cuandos bytes leer
	;w x h  = cantidad de bytes
	mov di, w_address
	mov ax, [di] 
	mov di, h_address
	mov bx, [di]
	mul bx
	mov cx, ax 
	

	
	;INT 21h / AH= 3Fh - read from file. 
	mov bx, handle
	mov dx, img_address
	mov ah, 3fh
	int 21h ; read from file... 
	jmptoerr:
	jc err
	
	call close_file
	jnc ok
	err:

		;ERROR!!!
	ok:
ret    
load_img endp

;proc para dibujar imagen
draw_img proc
	;usa los valores de las direcciones de memoria
	;para pintar las imagenes
	;calcular cuantos px hay que pintar
	;bx<-recorrer el ancho
	;verificar el px
	; si el color es 0 lo ignoramos para que deje el fondo
	; si no lo pintamos calculando la posicion de memoria grafica
	mov di, w_address
	mov ax, [di] 
	mov di, h_address
	mov bx, [di]
	mul bx
	mov cx, ax
	mov si, img_address
	mov di, y_address
	mov dx, [di]  ; dx <- posicion y de la imagen (calcular linea)
	mov pos_y, dx
	mov bx, 0
	ciclo_draw_img:
		cmp [si], 0
		je pint_sig_px
		mov ax, pos_y
		mul screen_w
		mov di, x_address
		mov dx, [di]
		add ax, dx
		add ax, bx
		mov di, ax
		mov al, [si]
		mov es:[di], al
		pint_sig_px:
			inc bx
			inc si
			mov di, w_address
			mov ax, [di]
			cmp bx, ax
			jne continuar_loop
			mov bx, 0
			inc pos_y
		continuar_loop:
			loop  ciclo_draw_img
	ret    
endp


start:
mov color, 10

mov ax,@DATA
mov ds, ax

mov ah,00h ; Establece el modo de video
mov al,13h ; Selecciona el modo de video
int 10h    ; Ejecuta la interrupción de video

mov ax, VIDEO_MEM
mov es, ax


CALL_LOAD_IMG player_iname, player_w, player_h, img_player
CALL_LOAD_IMG obstacle_iname, obstacle_w, obstacle_h, img_obstacle


mov meteor_x,294
mov meteor_y,0
mov vel, 1
mov ah, 02Ch
int 21h
mov ultima_c, dl
mov last_sec,dh
update:
mov ah, 02Ch
int 21h
mov ultima_c, dl
esperar:
	int 21h
	cmp dl, ultima_c
	je esperar
mov ultima_c,0

xor di, di      ; Clear DI to start from the beginning of the video segment
mov cx, 32000   ; Number of words (64000 bytes / 2)
mov ah,color
mov al,color 
rep stosw       ; Clear screen using string operation



mov cx,20
mov meteor_y,0
mov img_address, offset img_obstacle
mov w_address, offset obstacle_w
mov h_address, offset obstacle_h
draw_20_meteors:
	push cx
	CALL_DRAW_IMG meteor_x, meteor_y
	add meteor_y,10
	pop cx
	loop draw_20_meteors
	
mov img_address, offset img_player
mov w_address, offset player_w
mov h_address, offset player_h
CALL_DRAW_IMG player_x,player_y
mov ax, vel
cmp meteor_x,ax
sub meteor_x,ax
jge notOver
mov meteor_x, 294
add vel,2
notOver:
;INT 21h / AH=2Ch - get system time;
;return: CH = hour. CL = minute. DH = second. DL = 1/100 seconds.  
mov ah, 02Ch
int 21h
mov ultima_c, dl

;para minimizar el flicker se mantiene la imagen un instante
esperar2:
    int 21h          ; Call DOS interrupt to get time
    cmp dl, ultima_c ; Compare current second with the last recorded second
    je esperar2      ; Jump if equal (no second has passed)

; Time has changed, update ultima_c
mov ultima_c, dl
cmp dh,last_sec
je noChange
inc gametime
inc no_hit_count
mov last_sec, dh
noChange:
posicion 30, 1 
mov ax,gametime
mov number_size,4
call NumberToString
IMPRIMIR num_text


jmp update


; wait for any key....    
mov ah, 10h
int 16h
mov ax, 4c00h ; exit to operating system.
int 21h 
end