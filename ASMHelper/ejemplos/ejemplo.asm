.model small
.stack 100h




.data
mensaje db "DVD",10,13,"$"

col db 35
row db 12

posicion macro x, y      
   mov    ah, 02H                   ;funcion para acomodar el cursor
   mov    bh, 00h
   mov    dh, row                      ;FILA
   mov    dl, col                      ;COLUMNA
   int    10H
endm

.code

mov ax,@DATA
mov ds, ax






ciclo:
call limpia
posicion 12,col

mov ah,09h
lea dx,mensaje 
int 21h

mov ah,010h 
int 16h; %espera la tecla 

cmp AL,"a"
je decrementar_col

cmp AL,"d"
je incrementar_col
   
cmp AL,"w"
je decrementar_row

cmp AL,"s"
je incrementar_row

cmp AL,"q"
je decrementar_dia

cmp AL,"c"
je incrementar_dia

cmp AL,"z"
je decrementar_dia2

cmp AL,"e"
je incrementar_dia3

jmp ciclo

   decrementar_col:
   dec col
   jmp ciclo
   
   incrementar_col:
   inc col
   jmp ciclo
	
   decrementar_row:
   dec row
   jmp ciclo
   
   incrementar_row:
   inc row
   jmp ciclo
   
   decrementar_dia:
   dec row
   dec col
   jmp ciclo
   
   incrementar_dia:
   inc row
   inc col
   jmp ciclo
   decrementar_dia2:
   inc row
   dec col
   jmp ciclo
   
   incrementar_dia3:
   dec row
   inc col
   
jmp ciclo

mov ah, 04ch
int 21h ;Salir 


limpia proc          
   mov ax,0600h
   mov bh,17h
   mov cx,0000h
   mov dx,184fh
   int 10h
   ret
limpia  endp


end