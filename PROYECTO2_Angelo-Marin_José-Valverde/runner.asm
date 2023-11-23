.model small
.stack 200h
.data


;CONSTANTS
VIDEO_MEM equ 0A000h
PUSHALL equ push ax bx cx dx
POPALL equ pop dx cx bx ax

HITBOX_PAD equ 3
UP_LIMIT equ 10
BOT_LIMIT equ 190

ARROW_DOWN equ 50h
ARROW_UP equ 48h

COOLDOWN_TIME equ 15



IFRAME_TIME equ 10
iframe db 0

flag db 0
player_bot_limit dw 0

patternFileName db "patron.txt", 20 dup(0) ;espacio extra
wordBuffer dw ?
byteBuffer db 0
bitCounter db 0
wordCounter db 0

SPACEVAR db " $"

mensajeSolicitarMapa db "Cual mapa desea cargar?  (1) (2) (3) (4) (5)", 10, 13, "$"
menuOpciones1 db "1. Establecer nivel y nombre del jugador", 10, 13, "$"
menuOpciones2 db "2.        Establecer escenario", 10, 13, "$"
menuOpciones3 db "3.           Iniciar juego", 10, 13, "$"
menuOpciones4 db "4.             Acerca de", 10, 13, "$"
menuOpciones5 db "5.               Salir", 10, 13, "$"
pausaTexto db "El juego se encuentra en pausa...", 10, 13, "$"

selecionarNivelText db "Ingrese en que nivel (en caso de ser un solo digito pon el 0 primero):" , 10, 13, "$"
prompt db "Ingrese el nombre del archivo:" , 10, 13, "$"
pressEntermsg db "Presione ENTER para continuar...$"
errLoading db "Error al cargar los sprites. Saliendo$"
livesmsg db "Vid:$"
segundosmsg db "Seg:$"
nivmsg db "Niv:$"
about db "Proyecto de: Angelo Marin y Jose Valverde.",10,13,"Este juego se basa en una nave la cual debe esquivar meteoritos que apareceran",10,13,"durante toda la partida, la dificultad ira subiendo durante la partida segun el tiempo jugado.",10,13,"El objetivo el juego es durar la mayor cantidad de tiempo sin perder las 3 vidas",10,13,"$""
pressPmsg db "Presione P para continuar...$"

ultima_c db 0
vel dw 2
level dw 1
last_sec db 0
gametime dw 0
no_hit_count db 0
buff_cooldown db 0
toptimes dw 4 dup(0)
number_size db 0
lives db 0
rnumber db ?
seed dw ?

pattern dw 3 dup(1100000000000001b), 3 dup(0000111111111100b),3 dup(0), 9 dup(0FFFFh)
metx_matrix dw 320 dup(0)
mety_matrix dw 320 dup(0)
meteor_ammount dw 0

greenx_matrix dw 320 dup(0)
greeny_matrix dw 320 dup(0)
green_ammount dw 0

redx_matrix dw 320 dup(0)
redy_matrix dw 320 dup(0)
red_ammount dw 0

bluex_matrix dw 320 dup(0)
bluey_matrix dw 320 dup(0)
blue_ammount dw 0


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
player_name db "JUGADOR", 5 dup('$')
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
buff_w dw ?
buff_h dw ?


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

CALL_CHECK_COLLISION MACRO EXMatrix,EYMatrix,ECounter
	mov x_mat_address, offset EXMatrix
	mov y_mat_address, offset EYMatrix
	mov entity_amm_address, offset ECounter
	call check_collision
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

CALL_DRAW_BUFF MACRO EXMatrix,EYMatrix,ECounter,entColor
	mov x_mat_address, offset EXMatrix
	mov y_mat_address, offset EYMatrix
	mov entity_amm_address,offset ECounter
	mov color, entColor
	call draw_buff
ENDM


MOVE_ENTITIES MACRO
	mov entity_amm_address, offset meteor_ammount
	mov x_mat_address, offset metx_matrix
	call move_entity_type
	cmp despawn_amm,0
	je endOfMeteors
	mov y_mat_address, offset mety_matrix
	call despawnEntities
	endOfMeteors:
	

    mov entity_amm_address, offset green_ammount
    mov x_mat_address, offset greenx_matrix
    call move_entity_type
    cmp despawn_amm, 0
    je endOfGreen
	mov y_mat_address, offset greeny_matrix
    call despawnEntities
    endOfGreen:


    mov entity_amm_address, offset red_ammount
    mov x_mat_address, offset redx_matrix
    call move_entity_type
    cmp despawn_amm, 0
    je endOfRed
	mov y_mat_address, offset redy_matrix
    call despawnEntities
    endOfRed:

 
    mov entity_amm_address, offset blue_ammount
    mov x_mat_address, offset bluex_matrix

    call move_entity_type
    cmp despawn_amm, 0
    je endOfBlue
	mov y_mat_address, offset bluey_matrix
    call despawnEntities
    endOfBlue:
	
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
	jge spawn
	jmp endSpawn
	spawn:
	sub px_travel_since_spawn,20 ;
	;Si los meteoritos empiezan a distanciarse demasiado, la distancia se acumula y causa problemas
	;Aquí se corrige eso
	cmp px_travel_since_spawn,25 
	jle noCorrection
	mov px_travel_since_spawn,25
	noCorrection:
	lea si, pattern
	
	;SPAWN_ENT_PREP 20, metx_matrix, mety_matrix, meteor_ammount

	cmp buff_cooldown,0
	je minCooldown
	dec buff_cooldown
	minCooldown:
	mov cx,18
	mov meteor_y,10
	spawnMeteorLoop:
		test cx,cx
		jnz doSpawn
		jmp endSpawn
		doSpawn:
		push cx
	
		ROR word ptr [si],1
	
		jnc dontSpawnMet
		
		CALL_SPAWN_ENTITY meteor_y,metx_matrix,mety_matrix,meteor_ammount
		jmp continueSpawn
		dontSpawnMet:
			cmp buff_cooldown,0
			jne continueSpawn
			
			call generate_random_number
			
			
			
			
			cmp rnumber,0
			je spawnGreen
			
			cmp rnumber,1
			je spawnRed
			
			cmp rnumber,2
			je spawnBlue
			jne continueSpawn
			
			spawnGreen:
			CALL_SPAWN_ENTITY meteor_y, greenx_matrix, greeny_matrix, green_ammount
			jmp resetBuff

			spawnRed:
			CALL_SPAWN_ENTITY meteor_y, redx_matrix, redy_matrix, red_ammount
			jmp resetBuff
		
			spawnBlue:
			CALL_SPAWN_ENTITY meteor_y, bluex_matrix, bluey_matrix, blue_ammount
			
			;jmp continueSpawn
		
		resetBuff:
		mov buff_cooldown,COOLDOWN_TIME
	
		continueSpawn:
		add meteor_y,10
		inc si
		inc si
		pop cx
		dec cx
		jmp spawnMeteorLoop
	endSpawn:
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



generate_random_number proc
    mov ax, seed   ; Load seed into AX

    ; temp1 = seed xor (seed shr 1)
    mov bx, ax       ; Copy seed to BX for right shift
    shr bx, 1        ; BX = seed shr 1
    xor ax, bx       ; AX = seed xor (seed shr 1), now AX is temp1

    ; temp2 = temp1 xor (temp1 shl 1)
    mov bx, ax       ; Copy temp1 (now in AX) to BX for left shift
    shl bx, 1        ; BX = temp1 shl 1
    xor ax, bx       ; AX = temp1 xor (temp1 shl 1), now AX is temp2

    ; seed = temp2 xor (temp2 shr 2)
    mov bx, ax       ; Copy temp2 (now in AX) to BX for right shift
    shr bx, 2        ; BX = temp2 shr 2
    xor ax, bx       ; AX = temp2 xor (temp2 shr 2)
    mov seed, ax   ; Update the seed with the new value
	xor dx,dx
	mov bx, 9
	div bx
	mov rnumber,dl
ret
endp generate_random_number
draw_buff proc

	mov di,entity_amm_address
	mov cx,[di]
	test cx,cx
	jz noEntities
	
	mov di,x_mat_address
	mov si,y_mat_address
	
	drawB_loop:
	push cx
	
	mov dx,[di]
	mov pos_x, dx
	mov dx,[si]
	add dx, HITBOX_PAD ;para representar correctamente la imagen con resp. a la colisión
	mov pos_y, dx
	push si di
	CALL_DRAW_RECT pos_x, pos_y, buff_w, buff_h, color
	pop di si
	add si,2
	add di,2

	pop cx
	loop drawB_loop
	noEntities:
	ret
draw_buff endp


move_entity_type proc
	mov despawn_amm,0
	mov di,entity_amm_address
	mov cx,[di]
	mov di,x_mat_address
	test cx,cx
	jz noEntToMove
	moveEnt_loop:
	mov ax,[di]
	cmp ax,0 ;Meteoro ya llego al final
	je incDespawn
	sub ax,vel
	cmp ax,0
	jge moveEnt
	mov ax,0
	moveEnt:
	mov [di],ax
	jmp dontIncDespawn
	incDespawn:
	inc despawn_amm
	dontIncDespawn:
	add di,2
	loop moveEnt_loop
	noEntToMove:
	ret
endp


check_collision proc
	mov despawn_amm,0
	mov flag,0
	mov si, x_mat_address
	mov cx, 0
	mov di, entity_amm_address
	mov bx,[di]
	mov di, y_mat_address
	checkColLoop:
	cmp cx,bx
	jge finishedCol

	mov ax,player_w
	cmp ax,[si]
	jl finishedCol
	
	;CX debe terminar de revisar cuantos de los obstaculos en el rango X del jugador 
	;Para poder eliminar a toda la columna en caso de colisión.
	cmp flag,1
	je incCounters 
	
	mov y_address, di
	
	call check_single_collision
	
	incCounters:
	inc si
	inc si
	inc di
	inc di
	inc cx
	jmp checkColLoop
	finishedCol:
	cmp flag,1
	jne dontDespawn
	mov despawn_amm,cx
	call despawnEntities
	dontDespawn:
	ret
check_collision endp

check_single_collision proc
	 ;obstaculo = ax
	 ;Area del jugador: BX(arriba) a DX(abajo)
	 push di ax bx dx
	 mov di, y_address
	 mov ax,[di]
	 mov bx, player_y
	 mov dx, bx
	 add dx, player_h
	 
	 ;el hitbox del personaje es más pequeño de lo que aparenta la imagen
	 add bx, HITBOX_PAD 
	 sub dx, HITBOX_PAD
	 
	 cmp ax,bx
	 jl secondway
     cmp ax,dx
	 jle colition
	 
	 secondway:
	 add ax,meteor_h
	 cmp ax,bx
	 jl no_colition
	 cmp ax,dx
	 jg no_colition
	 colition:
	 mov flag, 1
	 
	 no_colition:
	 pop dx bx ax di
	 ret
check_single_collision endp



spawn_ent proc
	mov di, entity_amm_address
	mov ax, [di]
	inc [di]
	shl ax,1
	mov di, x_mat_address
	add di,ax
	mov bx,300
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

read_file PROC
	mov filename_address, offset patternFileName
	
	call open_file
	lea di, pattern
    mov bitCounter,0
	mov wordCounter,0
	
	mov al, 0
	mov bx, handle
	mov cx, 0
	mov dx, 0
	mov ah, 42h
	int 21h 
	jc errorRead
	lea si, byteBuffer
    next_char:
        mov ah, 3Fh      
        mov cx, 1        ; Read one character
		mov bx, handle
        lea dx, [si]   
        int 21h
		jc errorRead
        cmp ax, 0        ; Check if EOF
        je notEnough     ; Jump to notEnough if EOF
		mov bl, [si]
        cmp bl, '1'
        je bit_is_one
        cmp bl, '0'
        je bit_is_zero
        cmp bl, 13 ; End-of-line 
        je next_word
		
		jmp next_char
		notEnough:
			jmp exit
		errorRead:
			IMPRIMIR errLoading
			jmp exit
			
    bit_is_one:
		mov wordBuffer,1 
		mov cl, bitCounter
		SHL word ptr wordBuffer, cl ;mueve el bit 1 a donde corresponde
		mov ax, wordBuffer
		OR [di],ax ;lo añade al patrón con un or
        jmp next_bit

    bit_is_zero:
		mov wordBuffer,1 
		mov cl, bitCounter
		SHL word ptr wordBuffer, cl ;mueve el bit 1 a donde corresponde
		mov ax, wordBuffer
		NOT ax ;invertir, ahora el bit 0 está donde corresponde
		AND [di],ax ;"quitar" bit del patron (poner en 0)
        jmp next_bit

    next_word:
        inc wordCounter           ; Move to the next word
		inc di
		inc di
        mov bitCounter,0         ; Reset bit counter
        jmp next_char   ; Read next character

    next_bit:
        inc bitCounter           
        cmp bitCounter, 16       ; Cantidad máxima de bits (word = 16 bits)
        jl next_charAux
        inc wordCounter           ; Siguiente fila
        mov bitCounter,0      ; Reset 
        cmp wordCounter, 18       ; Máximo de filas
        jge closeF
		next_charAux: 
		jmp next_char ;los jmp pueden saltar más que uno condicional (jl)
	closeF:
    call close_file
    ret


	
read_file ENDP



askFileName proc
	
	;mostrar en pantalla
	mov ah,00h 
	mov al,12h 
	int 10h 
	posicion 1, 1 
	mov ah, 09h
	lea dx, prompt
	int 21h
	mov si, filename_address
	waitForInput:
		mov ah, 01h
		int 16h
		jz waitForInput
		mov ah, 00h
		int 16h
		
		cmp al, 0Dh ; ENTER key
		je inputRetrieved
		
		cmp al, 08h
		je backspace
		
        mov byte ptr [si], al ;añade caracter
		mov byte ptr [si+1],'$'
        inc si 
		jmp askFileNameScreen
		
		backspace:
			cmp si, filename_address
			je waitForInput

			dec si
			mov byte ptr [si],'$'
		
		askFileNameScreen:
		
		;mostrar en pantalla
		mov ah,00h 
		mov al,12h 
		int 10h 
		posicion 1, 1 
		mov ah, 09h
		lea dx, prompt
		int 21h
		mov dx, filename_address
		int 21h
		

        jmp waitForInput

	inputRetrieved:
    ret
askFileName endp


game proc

	mov ah,00h ; Establece el modo de video
	mov al,13h ; Selecciona el modo de video
	int 10h    ; Ejecuta la interrupción de video
	
	mov ax, BOT_LIMIT
	sub ax, player_h
	mov player_bot_limit,ax
	
	mov ax,meteor_h
	sub ax, HITBOX_PAD
	sub ax, HITBOX_PAD
	mov buff_h,ax
	mov ax, meteor_w
	shr ax,1
	mov buff_w,ax
	
	mov meteor_ammount,0
	mov px_travel_since_spawn,20
	mov lives, 3
	mov ax, level
	shl ax,1
	mov vel,ax
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
	
	;SE UTILIZAN MACROS CUANDO SEA POSIBLE PARA EVITAR LLAMADAS INNECESARIAS A PROCEDIMIENTOS
	;QUE PODRÍAN RALENTIZAR AÚN MÁS EL CICLO DE ACTUALIZACIÓN
	;Y PARA MANTENER UN CÓDIGO LEGIBLE
	CLEAR_SCREEN

	LOAD_IMG_VARS player_w,player_h, img_player
	CALL_DRAW_IMG player_x,player_y
	SPAWN_NEWCOL
	DRAW_METEORS
	CALL_DRAW_BUFF greenx_matrix, greeny_matrix, green_ammount, 10
	CALL_DRAW_BUFF redx_matrix, redy_matrix, red_ammount, 12
	CALL_DRAW_BUFF bluex_matrix, bluey_matrix, blue_ammount, 9
	
	posicion 0, 0 
	
	IMPRIMIR livesmsg
	xor ax,ax
	mov al,lives
	mov number_size,1
	call NumberToString
	IMPRIMIR num_text
	
	posicion 6,0
	
	mov ax,gametime
	mov number_size,4
	call NumberToString
	IMPRIMIR segundosmsg
	IMPRIMIR num_text
	
	posicion 15,0
	mov ax,level
	mov number_size,2
	call NumberToString
	IMPRIMIR nivmsg
	IMPRIMIR num_text
	
	posicion 25,0
	
	IMPRIMIR player_name

	
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
	
	mov last_sec, dh
	inc gametime
	inc no_hit_count
	cmp no_hit_count,20
	jl noChange
	cmp level,20
	jge noChange
	inc level
	add vel,2
	mov no_hit_count,0
	noChange:
	cmp iframe,0
	jg decIframe
	CALL_CHECK_COLLISION metx_matrix,mety_matrix,meteor_ammount
	cmp flag,1
	jne noMetCol
	dec lives
	mov iframe,IFRAME_TIME
	cmp lives,0
	
	jg noMetCol
	call pauseP
	decIframe:
	dec iframe
	noMetCol:
	

	
	CALL_CHECK_COLLISION greenx_matrix,greeny_matrix,green_ammount
	cmp flag,1
	jne noGreenCol

	noGreenCol:
	
	CALL_CHECK_COLLISION redx_matrix,redy_matrix,red_ammount
	cmp flag,1
	jne noRedCol
	
	noRedCol:
	CALL_CHECK_COLLISION bluex_matrix,bluey_matrix,blue_ammount
	cmp flag,1
	jne noBlueCol
	;codigo de colision
	noBlueCol:
	
	MOVE_ENTITIES
	mov ax,vel
	add px_travel_since_spawn, ax
	

	
	; se lee el bufer del teclado para mover la nave
	mov ah, 01h
	int 16h
	jz updateAux

    cmp ah,ARROW_DOWN
    je  movShipDown
	cmp ah,ARROW_UP
    je movShipUp 
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
            add ax, 7
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
			
            CALL_DRAW_RECT player_x, player_y, player_w, player_h, 0
            mov ax, player_y
            sub ax,7
            cmp ax, UP_LIMIT
            jge dibujarShipUp        
            
            mov ax, UP_LIMIT
           
            dibujarShipUp:
				push ax
				pop ax
				mov player_y, ax
                mov player_x, 0
                LOAD_IMG_VARS player_w, player_h, img_player
                CALL_DRAW_IMG player_x, player_y 
			jmp update
			
ret
game endp

testing PROC
	;BORRAR ESTO ANTES DE ENTREGA
	call generate_random_number
	xor ax,ax
	mov al, rnumber
	mov number_size,2
	call NumberToString
	IMPRIMIR num_text
	call pauseP
	IMPRIMIR about
	IMPRIMIR pressPmsg
	call pauseP
	mov filename_address, offset patternFileName
	call askFileName
	call read_file
	mov level,10
	call game
	ret
testing endp

start:
	mov ah,02Ch
	int 21h
	mov seed, dx
	mov color, 10
	
	mov ah,00h ; Establece el modo de video
	mov al,12h ; Selecciona el modo de video
	int 10h    ; Ejecuta la interrupción de video
	
	mov ax, VIDEO_MEM
	mov es, ax
	
	CALL_LOAD_IMG player_iname, player_w, player_h, img_player
	CALL_LOAD_IMG meteor_iname, meteor_w, meteor_h, img_meteor
menu:
	mov ah,00h
	mov al,12h
	int 10h   
	posicion 18, 12
	IMPRIMIR menuOpciones1
	posicion 18, 13
    IMPRIMIR menuOpciones2
    posicion 18, 14
    IMPRIMIR menuOpciones3
	posicion 18, 15
    IMPRIMIR menuOpciones4
	posicion 18, 16
    IMPRIMIR menuOpciones5
	
	waitForOption:
    mov ah, 01h
    int 16h
    jz waitForOption

    mov ah, 00h
    int 16h
	
    cmp al, '1'
	je CargarNivel
	
	cmp al, '2'
	je cargarTexto
	
	cmp al, '3'
	je startGame
	
	
    cmp al, '4'
	je showAbout
	
    cmp al, '5'
    je exit
	jne waitForOption
	
	cargarTexto: 
	mov filename_address, offset patternFileName
	call askFileName
	call read_file
	jmp menu
	
	startGame:
	call game
	jmp menu
	
	CargarNivel:
	posicion 0, 18
	IMPRIMIR selecionarNivelText
    mov ah, 01h
    int 16h
    jz CargarNivel
    mov ah, 00h
    int 16h
    sub al, '0'  ;carga el nivel
    mov ah, al 
    mov al, 10
    mul ah
    mov bl, al 
    mov ah, 00h
    int 16h
    sub al, '0' 
    add bl, al
    mov [level], bx
	jmp start
	
	showAbout:
	posicion 0,3
	IMPRIMIR about
	jmp waitForOption



	exit:  
		mov ah,00h
		mov al,0h
		int 10h
		mov ah, 10h
		int 16h
		mov ax, 4c00h 
		int 21h
end