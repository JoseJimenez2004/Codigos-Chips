; --- Definiciones ---
.include "m8535def.inc"

.def asc = r17  ; Registro temporal para el valor de ajuste (7, si es A-F)
.def hex = r16  ; Registro para el valor hexadecimal ASCII resultante (ej. '5', 'A')

; --- Inicializaci�n de Punteros de Memoria ---
; El c�digo original opera en RAM, NO en puertos I/O.
clr xh            ; Puntero X (Direcci�n de origen) en 0x00
clr yh            ; Puntero Y (Direcci�n de destino) en 0x00
ldi xl, $60       ; Establece la direcci�n de origen X en $0060
ldi yl, $70       ; Establece la direcci�n de destino Y en $0070

; --- Bucle Principal (Procesa 16 bytes) ---
etql:
    ldi hex, $30  ; Carga el valor base ASCII '0' ($30) en 'hex'
    ld  asc, x+   ; Carga el byte de la RAM ($60) en 'asc' y avanza el puntero X
    
    ; Conversi�n: Suma el valor num�rico al ASCII '0'.
    ; Si el valor es 5, hex = $30 + 5 = $35 (ASCII '5').
    ; Si el valor es A (10), hex = $30 + 10 = $3A (ASCII ':').
    add hex, asc  
    
    cpi hex, $3A  ; Compara el resultado con el ASCII ':' ($3A)
    brsh letra    ; Si es mayor o igual, salta a ajustar para las letras (A-F)

; --- Almacenamiento ---
guar:
    st  y+, hex   ; Almacena el car�cter ASCII resultante en la RAM ($70) y avanza el puntero Y
    
    ; Comprueba si se han procesado 16 bytes (desde $60 hasta $6F)
    cpi xl, $70   ; Compara el byte bajo del puntero X con $70
    brne etql     ; Si no es $70 (a�n no ha terminado), vuelve al inicio del bucle

fin:
    rjmp fin      ; Bucle infinito al finalizar la tarea

; --- Ajuste para Letras (A-F) ---
letra:
    ldi asc, 7    ; Carga el valor de ajuste 7
    ; La suma: hex ($3A..$3F) + 7 = $41..$46 (ASCII 'A'..'F')
    add hex, asc  
    rjmp guar     ; Salta a la parte de almacenamiento (guar)
