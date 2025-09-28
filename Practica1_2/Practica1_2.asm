.include "m8535def.inc"

; -----------------------------------
; Definiciones y Constantes
; -----------------------------------
.def val_in_out = r16   ; r16 se usa para la entrada, el cálculo y la salida
.def temp_val = r17     ; Registro temporal para guardar el offset
.equ ASCII_ZERO     = $30  ; Offset para ASCII de '0' a '9'
.equ ASCII_A_OFFSET = $37  ; Offset para ASCII de 'A' a 'F' ($41 - $0A)

; -----------------------------------
; Inicialización de Puertos
; -----------------------------------
	ser r17               ; r17 = $FF
	out ddra,r17          ; PORTA como salida
	out ddrb,r17          ; PORTB como salida

; -----------------------------------
; Bucle Principal
; -----------------------------------
ciclo:
	; 1. Leer la entrada (Solo PINB)
	in val_in_out,pinb
	
	; 2. Aísla el nibble bajo (0x0 a 0xF)
	andi val_in_out, $0F 

	; 3. Comprobación de Rango (0x0 a 0x9)
	; Compara el valor en r16 con 10 (0x0A)
	cpi val_in_out, $0A
	brlo digito ; Si es menor que $0A (0-9), salta a 'digito'

	; -----------------------------------
	; Caso: Letra ($A a $F) -> Salida en PORTB
	; -----------------------------------
letra:
	; r16 ya contiene el valor (0xA-0xF)
	ldi temp_val, ASCII_A_OFFSET ; Carga $37
	add val_in_out, temp_val     ; Suma $37: Convierte a ASCII A-F (ej: $0A + $37 = $41 'A')
	out porta, val_in_out        ; Envía el resultado al PORTA
	
	; pa borrar los valores o no se modifique
	;clr r16
	out porta, r16 
	rjmp ciclo

	; Caso: Dígito ($0 a $9) -> Salida en PORTA

digito:
	; r16 ya contiene el valor (0x0-0x9)
	ldi temp_val, ASCII_ZERO ; Carga $30
	add val_in_out, temp_val ; Suma $30: Convierte a ASCII 0-9 
	out porta, val_in_out    ; Envía el resultado al PORTA
	
	; Asegura que PORTA esté limpio o no se modifique, pero para que se deba poner cada iteracion, se lo kite xd
	;clr r16
	out porta, r16 
	rjmp ciclo
