.model small
.stack 100h
.data

mensaje db "DVD",10,13,"$"
col db 35
row db 12
menuOpciones1 db "1.     Disenar escenario de juego", 10, 13, "$"
menuOpciones2 db "2. Establecer nivel y nombre del jugador", 10, 13, "$"
menuOpciones3 db "3.        Establecer escenario", 10, 13, "$"
menuOpciones4 db "4.           Iniciar juego", 10, 13, "$"
menuOpciones5 db "5.             Acerca de", 10, 13, "$"
menuOpciones6 db "6.               Salir", 10, 13, "$"
pausaTexto db "El juego se encuentra en pausa...", 10, 13, "$"
fileName db "Patrones\Mapa1.txt", 0
fileHandle dw ?
buffer db 26




posicionNave macro x, y
    mov ah, 02H
    mov bh, 00h
    mov dh, row
    mov dl, col
    int 10H
endm

posicion macro x, y
    mov ah, 02H
    mov bh, 00h
    mov dh, x
    mov dl, y
    int 10H
endm

.code
mov ax,@DATA
mov ds, ax

   mov ah,00h ; Establece el modo de video
   mov al,12h ; Selecciona el modo de video
   int 10h    ; Ejecuta la interrupción de video
   mov ax,00  ; Configuración inicial del mouse
   int 33h    ; Inicializa el mouse
   add dx,10
   mov ax,4  
   int 33h    ; Ejecuta la interrupción del mouse
   mov ax,01h ; Establece para mostrar el cursor del mouse
   int 33h    ; Ejecuta la operación del mouse


    posicion 11, 20 ;Coloca el siguiente texto en el centro de la pantalla, fue a puro "ojo"
    mov ah, 09h
    lea dx, menuOpciones1
    int 21h
	posicion 12, 20 ;el primer valor es para el eje de las Y y el segundo para el eje de las X 
    mov ah, 09h
    lea dx, menuOpciones2
    int 21h
	posicion 13, 20
    mov ah, 09h
    lea dx, menuOpciones3
    int 21h
	posicion 14, 20
    mov ah, 09h
    lea dx, menuOpciones4
    int 21h
	posicion 15, 20
    mov ah, 09h
    lea dx, menuOpciones5
    int 21h
	posicion 16, 20
    mov ah, 09h
    lea dx, menuOpciones6
    int 21h
	
menu:
    mov ah, 01h
    int 16h
    jz menu

    mov ah, 00h
    int 16h

    cmp al, '4'
    je juego
	
    cmp al, '6'
    je salir
	
	cmp al, '3'
	je readFile
	
	jne menu ;Si escribe algo diferente aqui lo manda otra vez al menu
	
	
;------------------------------------------------------Opciones del menu----------------------------------------------------
	
;---------------------------------------------------Iniciar Juego Opción 4--------------------------------------------------

juego:
   mov ah,00h ; volvemos a Establecer la parte grafica, esto hace la misma funcion que el metodo limpia que se vio en clases 
   mov al,12h ; y es el mismo que se ejecuta al principio del codigo
   int 10h 
   
    posicionNave 10,10

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

    jmp juego


;------------------------------------------------------Salir Opción 6-------------------------------------------------------
salir:
mov ah, 04ch
int 21h



;-----------------------------------Anexo----------------------------------------------
;Aqui se encuentra "Metodos" que no son propios del menu aunque son requeridos,

waitForP: ;Aqui se espera que la persona vuelva a presionar la p para salir de la pausa
	mov ah, 01h
    int 16h
    jz waitForP
    
    mov ah,010h
    int 16h
    cmp AL, "p"
    jne waitForP
    jmp juego
	
	
	
	
	readFile: ; Abrir el archivo
    
    mov ah, 3Dh ; función para abrir el archivo
    mov al, 0   ; modo de lectura
    lea dx, fileName
    int 21h
    jc fileError ; en caso de que de error va salta a error 

    mov fileHandle, ax ; aqui guardamos la matriz o mapa

    mov ah, 3Fh ; aqui comenzamos a leer 
    mov bx, fileHandle
    lea dx, buffer
    mov cx, 33 ; 25 de la matriz y el resto de elementos como los saltos de linea 
    int 21h
    jc fileError

    
    mov ah, 3Eh ; Cierra el archivo
    mov bx, fileHandle
    int 21h
	jmp processBuffer

    fileError:
    posicion 25, 20 
    mov ah, 09h
    lea dx, menuOpciones1
    int 21h
    ret

processBuffer:
   mov ah,00h
   mov al,12h 
   int 10h 
   
    lea si, buffer 
    mov cx, 25 
    
    mov dh, 10 
    mov dl, 20 

printLoop:
    
    mov ah, 02H
    mov bh, 0
    int 10H

    lodsb

    cmp al, 0Dh
    je nextLine

    mov ah, 0Eh       
    mov bh, 0  
    mov bl, 07h    
    int 10h   
    inc dl

    loop printLoop
    ret

nextLine:
    lodsb
    inc dh  
    mov dl, 20        
    jmp printLoop
    
end