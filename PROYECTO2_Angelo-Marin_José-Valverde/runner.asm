.model small
.stack 200h
.data


;CONSTANTS
VIDEO_MEM equ 0A000h
PUSHALL equ push ax bx cx dx
POPALL equ pop dx cx bx ax

UP_LIMIT equ 10
BOT_LIMIT equ 190

player_bot_limit dw 0

pressEntermsg db "Presione ENTER para continuar...$"
errLoading db "Error al cargar los sprites. Saliendo$"
vidasmsg db "Vid:$"
segundosmsg db "Seg:$"
nivmsg db "Niv:$"

ultima_c db 0
vel dw 2
last_sec db 0
gametime dw 0
no_hit_count db 0
toptimes dw 4 dup(0)
number_size db 0
lives db 0

pattern dw 18 dup(1001000000000001b)
metx_matrix dw 320 dup(0)
mety_matrix dw 320 dup(0)
meteor_ammount dw 0
;matrix_pointer dw 0
px_travel_since_spawn dw 20

x_mat_address dw ?
y_mat_address dw ?
entity_amm_address dw ?
despawn_amm dw 0

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

img_meteor db 262 dup(?)


meteor_w dw ?
meteor_h dw ?



img_address dw ?
filename_address dw ?
w_address dw ?
h_address dw ?

y_address dw ?
x_address dw ?

meteor_iname db "meteor.img",0
;MACROS

CLEAR_SCREEN MACRO
xor di, di      ; Clear DI to start from the beginning of the video segment
mov cx, 32000   ; Number of words (64000 bytes / 2)
mov ah,color
mov al,color 
rep stosw       ; Clear screen using string operation
ENDM


IMPRIMIR MACRO text
   lea dx, text
   mov ah, 09h
   int 21h          
ENDM

UPDATE_TIME MACRO
	add cx,1
ENDM

CALL_SPAWN_ENTITY MACRO yPosition,EXMatrix,EYMatrix,ECounter
	mov entity_amm_address, offset ECounter
	mov x_mat_address, offset EXMatrix
	mov y_mat_address, offset EYMatrix
	mov ax, yPosition
	mov pos_y, ax
	call spawn_ent
ENDM



CALL_DESPAWN MACRO EXMatrix,EYMatrix,ECounter
	mov x_mat_address, offset EXMatrix
	mov y_mat_address, offset EYMatrix
	mov entity_amm_address, offset ECounter
	call despawnEntities
ENDM

DRAW_METEORS MACRO
	LOAD_IMG_VARS meteor_w,meteor_h,img_meteor
	mov x_address, offset metx_matrix
	mov y_address, offset mety_matrix
	mov cx,meteor_ammount
	test cx,cx
	jz noObstacles
	drawobs_loop:
	push cx
	call draw_img
	add x_address,2
	add y_address,2
	pop cx
	loop drawobs_loop
	noObstacles:
ENDM

MOVE_ENTITIES MACRO
	mov despawn_amm,0
	lea di,metx_matrix
	mov cx,meteor_ammount
	test cx,cx
	jz endOfMeteors
	moveMet_loop:
	mov ax,[di]
	cmp ax,0 ;Ya llego al final
	je incDespawn
	sub ax,vel
	cmp ax,0
	jge moveMeteor
	mov ax,0
	moveMeteor:
	mov [di],ax
	jmp dontIncDespawn
	incDespawn:
	inc despawn_amm
	dontIncDespawn:
	add di,2
	loop moveMet_loop
	cmp despawn_amm,0
	je endOfMeteors
	CALL_DESPAWN metx_matrix,mety_matrix,meteor_ammount
	endOfMeteors:
ENDM


SPAWN_ENT_PREP MACRO yPosition,EXMatrix,EYMatrix,ECounter
	mov entity_amm_address, offset ECounter
	mov x_mat_address, offset EXMatrix
	mov y_mat_address, offset EYMatrix
	mov ax, yPosition
	mov pos_y, ax
ENDM

SPAWN_NEWCOL MACRO
	cmp px_travel_since_spawn,20
	jl spawnNotReady
	sub px_travel_since_spawn,20
	lea si, pattern
	
	SPAWN_ENT_PREP 20, metx_matrix, mety_matrix, meteor_ammount
	mov bx,20
	mov cx,18
	spawnMeteorLoop:
		push cx
		push bx
		mov pos_y,bx
		ROL word ptr [si],1
		jnc dontSpawnMet
		call spawn_ent
		dontSpawnMet:
		pop bx
		add bx,20
		inc si
		inc si
		pop cx
		loop spawnMeteorLoop
	spawnNotReady:
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
CALL_DRAW_RECT MACRO xm, ym, wm, hm, cm
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
mov ax,@DATA
mov ds, ax

jmp start

spawn_ent proc
	mov di, entity_amm_address
	mov ax, [di]
	inc [di]
	shl ax,1
	mov di, x_mat_address
	add di,ax
	mov bx,320
	sub bx, px_travel_since_spawn ;calcular posicion donde debería aparecer el meteoro
	mov [di],bx
	mov di, y_mat_address
	add di, ax

	mov bx, pos_y
	mov [di],bx
	ret
spawn_ent endp

despawnEntities proc
	mov di, entity_amm_address
	mov cx,[di]
	sub cx, despawn_amm
	mov [di], cx
	mov di, x_mat_address
	mov si,di
	add si,despawn_amm
	add si,despawn_amm
	test cx,cx
	jz despawnCompleted
	push cx
	shiftXMat:
	mov dx,[si]
	mov [di],dx
	add si,2
	add di,2
	loop shiftXMat
	pop cx
	
	mov di, y_mat_address
	mov si,di
	add si,despawn_amm
	add si,despawn_amm
	shiftYMat:
	mov dx,[si]
	mov [di],dx
	add si,2
	add di,2
	loop shiftYMat
	despawnCompleted:
ret
despawnEntities endp


NumberToString proc
	push cx
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
	pop cx
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

pauseP proc
PauseLoop:
	;Limpiar buffer
	mov ah, 0ch
	mov al, 0
	int 21h
	;obtener tecla
	mov ah, 01h
	int 16h
	jz PauseLoop
	cmp al,'P'
	je exitPause
	cmp al,'p'
	je exitPause
	jmp PauseLoop
	exitPause:
	ret
pauseP endp

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
open_file proc
	;INT 21h / AH= 3Dh - open existing file.
	mov dx,  filename_address
	mov al, 0
	mov ah, 3dh
	int 21h
	jc err
	mov handle, ax
	ret
open_file endp

close_file proc
	mov bx, handle
	mov ah, 3eh
	int 21h 
	ret
close_file endp

;requiere filename_address, img_address, h_address, w_address
load_img proc   
	;INT 21h / AH= 3Dh - open existing file.
	mov dx, filename_address
	call open_file
	jc err
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
	int 21h 
	jc err
	
	
	mov bx, handle
	mov dx, h_address
	mov cx, 1
	mov ah, 3fh
	int 21h 
	jc err
	
	;calcular tamaño de la imagen
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
		IMPRIMIR errLoading
		jmp exit
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
	mov bx, 0 ; <-recorrido en X
	ciclo_draw_img:
		;ignorar color 0
		cmp [si], 0
		je pint_sig_px
		;verificar limite de pantalla
		mov ax,bx
		mov di,x_address
		add ax,[di]
		cmp ax,screen_w
		jge pint_sig_px
		
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
			cmp bx, [di]
			jne continuar_loop
			mov bx, 0
			inc pos_y
		continuar_loop:
			loop  ciclo_draw_img
	ret    
endp

game proc

	mov ax, BOT_LIMIT
	sub ax, player_h
	mov player_bot_limit,ax
	mov meteor_ammount,0
	mov px_travel_since_spawn,20
	


	
	mov vel, 2
	mov ah, 02Ch
	int 21h
	mov ultima_c, dl
	mov last_sec,dh
	update:
		
	;Limpia el buffer de entrada (teclado)
	mov ah, 0ch
	mov al, 0
	int 21h
	
	mov ah, 02Ch
	int 21h
	mov ultima_c, dl
	esperar:
		int 21h
		cmp dl, ultima_c
		je esperar
	mov ultima_c,0



	mov color,0
	CLEAR_SCREEN
	
	LOAD_IMG_VARS player_w,player_h, img_player
	CALL_DRAW_IMG player_x,player_y
	;REEMP CON MACRO
	cmp px_travel_since_spawn,20
	jl spawnNotReady
	sub px_travel_since_spawn,20
	lea si, pattern
	
	;SPAWN_ENT_PREP 20, metx_matrix, mety_matrix, meteor_ammount

	mov cx,18
	mov meteor_y,10
	spawnMeteorLoop:
		push cx
	
		ROL word ptr [si],1
		
		jnc dontSpawnMet
	
		;call spawn_ent
		CALL_SPAWN_ENTITY meteor_y,metx_matrix,mety_matrix,meteor_ammount
	
		dontSpawnMet:
		add meteor_y,10
		inc si
		inc si
		pop cx
		loop spawnMeteorLoop
	spawnNotReady:
	;FIN MACRO
	DRAW_METEORS
	

	MOVE_ENTITIES
	
	mov ax,vel
	add px_travel_since_spawn, ax
	
	
	;INT 21h / AH=2Ch - get system time;
	;return: CH = hour. CL = minute. DH = second. DL = 1/100 seconds.  
	mov ah, 02Ch
	int 21h
	mov ultima_c, dl
	
	;para minimizar el flicker se mantiene la imagen un instante
	esperar2:
		
		mov ah,02Ch
		int 21h          
		cmp dl, ultima_c 
		je esperar2      ; Jump if equal (no centisecond has passed)

	; Time has changed, update ultima_c
	mov ultima_c, dl
	cmp dh,last_sec
	je noChange ;seconds, not centiseconds*
	
	inc gametime
	inc no_hit_count
	mov last_sec, dh
	
	noChange:
	posicion 0, 0 
	mov ax,gametime
	mov number_size,4
	call NumberToString
	IMPRIMIR segundosmsg
	IMPRIMIR num_text

	
	; se lee el bufer del teclado para mover la nave
	mov ah, 01h
	int 16h
	jz updateAux
	cmp al, 's'
	je  movShipDown 
	cmp al, 'S'
	je  movShipDown
	cmp al, 'w'
	je  movShipUp
	cmp al, 'W'
	je  movShipUp
	cmp al, 'P'
	je  callPause
	cmp al, 'p'
	je  callPause
	updateAux:
    jmp update
	
	callPause:
		call pauseP
		jmp update
	movShipDown:
	
           ;primero borrar la imagen anterior
            CALL_DRAW_RECT player_x, player_y, player_w, player_h, 0
            mov ax, player_y
            add ax, 15
            cmp ax, player_bot_limit
            jle dibujarShipDown
            
            mov ax, player_bot_limit
            dibujarShipDown:
                mov player_y, ax
                mov player_x, 0
                LOAD_IMG_VARS player_w, player_h, img_player
                CALL_DRAW_IMG player_x, player_y 
        jmp update
        
        movShipUp:
           ;primero borrar la imagen anterior
		   mov meteor_y, 50
			CALL_SPAWN_ENTITY meteor_y,metx_matrix,mety_matrix,meteor_ammount
            CALL_DRAW_RECT player_x, player_y, player_w, player_h, 0
            mov ax, player_y
            sub ax,15
            cmp ax, UP_LIMIT
            jge dibujarShipUp        
            
            mov ax, UP_LIMIT
           
            dibujarShipUp:
				mov player_y, ax
                mov player_x, 0
                LOAD_IMG_VARS player_w, player_h, img_player
                CALL_DRAW_IMG player_x, player_y 
			jmp update
			
ret
game endp

start:

	mov color, 10
	
	mov ah,00h ; Establece el modo de video
	mov al,13h ; Selecciona el modo de video
	int 10h    ; Ejecuta la interrupción de video
	
	mov ax, VIDEO_MEM
	mov es, ax
	
	CALL_LOAD_IMG player_iname, player_w, player_h, img_player
	CALL_LOAD_IMG meteor_iname, meteor_w, meteor_h, img_meteor
	;implementar menu
	call game

	exit:
	; wait for any key....    
	mov ah, 10h
	int 16h
	;exit to operating system.
	mov ax, 4c00h 
	int 21h 
end