; --- Definiciones ---
.include "m8535def.inc"

.def asc = r17  ; Registro temporal para el valor de ajuste (7, si es A-F)
.def hex = r16  ; Registro para el valor hexadecimal ASCII resultante

; --- Configuración de Puertos ---
; Configurar Puerto B como entrada
ldi r18, $FF
out PORTB, r18
; Configurar Puerto A como salida  
ldi r18, $FF    ; Cargar 0xFF para configurar Puerto A como salida
out DDRA, r18   ; DDRA = 0xFF (todos los pines como salida)

; --- Bucle Principal ---
main:
    ldi hex, $30  ; Carga el valor base ASCII '0' ($30) en 'hex'
    
    ; LEER DESDE PUERTO B
    in asc, PINB  ; Lee el valor del Puerto B y lo guarda en 'asc'
    
    ; Conversión: Suma el valor numérico al ASCII '0'.
    add hex, asc  
    
    cpi hex, $3A  ; Compara el resultado con el ASCII ':' ($3A)
    brsh letra    ; Si es mayor o igual, salta a ajustar para las letras (A-F)

; --- Salida al Puerto A ---
salida:
    ; ENVIAR AL PUERTO A
    out PORTA, hex ; Envía el valor ASCII convertido al Puerto A
    rjmp main     ; Vuelve al inicio para procesar continuamente

; --- Ajuste para Letras (A-F) ---
letra:
    ldi asc, 7    ; Carga el valor de ajuste 7
    add hex, asc  ; Ajusta para obtener 'A'-'F'
    rjmp salida   ; Salta a la salida
