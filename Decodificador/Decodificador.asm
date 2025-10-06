.include "m8535def.inc"
.def aux = r16
.def temp = r17

; --- Tabla de Códigos de Segmento (0-F para Ánodo Común) ---
TABLE:
; 0    1    2    3    4    5    6    7    8    9    A    B    C    D    E    F
.db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F, 0x77, 0x7C, 0x39, 0x5E, 0x79, 0x71

; --- Inicialización de Puertos ---
	ser aux                 ; aux = 0xFF

	; Configurar Port A como SALIDA (Display)
	out DDRA, aux           ; DDRA = FF
	; PORTA se inicializa en FF, lo cual apaga un display de ánodo común.

	; Configurar Port B como ENTRADA con Pull-ups (para el selector)
	clr aux                 ; aux = 0x00
	out DDRB, aux           ; DDRB = 00 (Entrada)
	ser aux                 ; aux = 0xFF
	out PORTB, aux          ; PORTB = FF (Activa Pull-ups)

; --- Bucle Principal (Decodificación) ---
nvo:
	; 1. Establecer el puntero Z a la base de la tabla (solo se necesita una vez)
	ldi zh, HIGH(TABLE * 2) ; Carga byte alto de la dirección de la tabla
	ldi zl, LOW(TABLE * 2)  ; Carga byte bajo de la dirección de la tabla

	; 2. Leer la entrada de 4 bits desde PORTB
	in temp, PINB           ; Lee el estado de los pines de PORTB en temp
	andi temp, 0x0F         ; Aislar el índice (0 a 15)

	; 3. Sumar el índice al puntero ZL
	add zl, temp            ; zl = zl + indice
	
	; Lógica de acarreo (necesaria para la tabla)
	brne no_inc_zh          
	inc zh                  
no_inc_zh:
	
	; 4. Cargar el dato del display de la tabla a aux
	lpm aux, z              

	; 5. Muestra el resultado en el Puerto A
	out PORTA, aux          ; Envía el código de segmento al PORTA

	rjmp nvo                ; Repite el ciclo
