.include "m8535def.inc" ; Incluye las definiciones de registros para el ATmega8535

; Definición de alias para los registros
.def aux        = r16 ; Registro auxiliar de propósito general
.def unidades  = r17 ; Almacena el dígito de las unidades (0-9)
.def decenas   = r18 ; Almacena el dígito de las decenas (0-9)
.def stopUni   = r19 ; Almacena el dígito de las unidades para la condición de parada
.def stopDec   = r20 ; Almacena el dígito de las decenas para la condición de parada
.def entrada   = r21 ; Almacena la lectura del Puerto B (PINB)
.def temp      = r22 ; Registro temporal para manipulaciones de datos

; --- Inicialización del Stack Pointer (Pila) ---
ldi aux, low(RAMEND) ; Carga la parte baja de la última dirección de RAM
out SPL, aux         ; Mueve a SPL (Stack Pointer Low)
ldi aux, high(RAMEND) ; Carga la parte alta de la última dirección de RAM
out SPH, aux         ; Mueve a SPH (Stack Pointer High)

; --- Configuración de puertos ---
ser aux             ; Pone '1's en aux (0xFF)
out DDRA, aux       ; Puerto A -> salida (conectado a las decenas del display)
out DDRC, aux       ; Puerto C -> salida (conectado a las unidades del display)
clr aux             ; Pone '0's en aux (0x00)
out DDRB, aux       ; Puerto B -> entrada (para leer el valor de parada)
ser aux             ; Pone '1's en aux (0xFF)
out PORTB, aux      ; Activa las resistencias pull-up internas en el Puerto B (PINB)

Inicio:
    clr unidades      ; Inicializa el contador de unidades a 0
    clr decenas       ; Inicializa el contador de decenas a 0

LeerStop:
    ; Lee y configura el valor de parada (Stop Value) desde el Puerto B
    in entrada, PINB  ; Lee el estado actual del Puerto B (entradas) en 'entrada'

    ; Obtiene el valor de parada para las UNIDADES (bits 3:0 de PINB)
    mov temp, entrada 
    andi temp, 0x0F   ; Aplica máscara para quedarse solo con los 4 bits menos significativos
    mov stopUni, temp ; Guarda el valor de las unidades de parada

    ; Obtiene el valor de parada para las DECENAS (bits 7:4 de PINB)
    mov temp, entrada
    swap temp         ; Intercambia los 4 bits superiores e inferiores (desplaza los bits 7:4 a 3:0)
    andi temp, 0x0F   ; Aplica máscara para quedarse solo con los 4 bits menos significativos (que antes eran los superiores)
    mov stopDec, temp ; Guarda el valor de las decenas de parada

Contar:
    ; Muestra el contador en los displays

    mov aux, decenas  ; Carga el valor de decenas
    rcall MostrarA    ; Llama a la subrutina para mostrarlo en PORTA (decenas)

    mov aux, unidades ; Carga el valor de unidades
    rcall MostrarC    ; Llama a la subrutina para mostrarlo en PORTC (unidades)

    rcall Delay_250ms ; Espera un cuarto de segundo

    ; Compara el contador actual con el valor de parada
    cp decenas, stopDec  ; Compara decenas con el valor de parada de las decenas
    brne Incrementar     ; Si son diferentes, salta a incrementar (sigue contando)
    cp unidades, stopUni  ; Si las decenas son iguales, compara unidades con el valor de parada de las unidades
    brne Incrementar     ; Si son diferentes, salta a incrementar (sigue contando)
    rjmp LeerStop        ; Si ambos son iguales, el contador ha llegado al valor de parada, vuelve a leer un nuevo valor.

Incrementar:
    ; Lógica de incremento del contador BCD (Contador de 00 a 99)
    inc unidades         ; Incrementa las unidades
    cpi unidades, 10     ; Compara si unidades es igual a 10
    brlo Contar          ; Si es menor que 10, vuelve a Contar (no hay acarreo)

    ; Hay acarreo: unidades = 10
    clr unidades         ; Reinicia las unidades a 0
    inc decenas          ; Incrementa las decenas
    cpi decenas, 10      ; Compara si decenas es igual a 10
    brlo Contar          ; Si es menor que 10, vuelve a Contar

    ; Desbordamiento: decenas = 10
    clr decenas          ; Reinicia las decenas a 0 (el contador pasa de 99 a 00)
    rjmp Contar          ; Vuelve a Contar

; --- Subrutinas de Display ---

; Mostrar en PORTA (Decenas)
MostrarA:
    ; Valida que el valor en 'aux' (decenas) sea menor a 10
    cpi aux, 10         ; Compara aux con 10
    brlo MA_OK         ; Si es menor, salta la línea siguiente
    clr aux            ; Si es 10 o más, lo pone a 0 (para no salirse de la tabla si hay un error)
MA_OK:
    ; Carga la dirección base de la tabla en el registro Z
    ldi ZH, high(tabla<<1) ; Carga la parte alta de la dirección de la tabla (multiplica por 2 porque las direcciones son de palabra)
    ldi ZL, low(tabla<<1)  ; Carga la parte baja
    add ZL, aux            ; Suma el valor a mostrar ('aux') a la parte baja del puntero Z (Z apunta a tabla + aux)
    lpm aux, Z             ; Carga el valor del segmento desde la memoria de programa (tabla) a 'aux'
    out PORTA, aux         ; Muestra el código del segmento en PORTA
    ret                    ; Regresa de la subrutina

; Mostrar en PORTC (Unidades)
MostrarC:
    ; Es idéntica a MostrarA, pero muestra el valor en PORTC
    cpi aux, 10
    brlo MC_OK
    clr aux
MC_OK:
    ldi ZH, high(tabla<<1)
    ldi ZL, low(tabla<<1)
    add ZL, aux
    lpm aux, Z
    out PORTC, aux         ; Muestra el código del segmento en PORTC
    ret

; --- Subrutina de Retardo (Delay) ---

; Delay de 250ms exactos para un cristal de 4MHz
Delay_250ms:
    ; Bucle anidado de tres niveles (r23, r24, r25) para generar el tiempo
    ldi r23, 5         ; Contador exterior
D1:
    ldi r24, 100       ; Contador intermedio
L0:
    ldi r25, 150       ; Contador interior
L1:
    dec r25           ; Decrementa
    brne L1           ; Si no es cero, repite L1
    dec r24           ; Decrementa
    brne L0           ; Si no es cero, repite L0
    dec r23           ; Decrementa
    brne D1           ; Si no es cero, repite D1
    ret                ; Regresa de la subrutina

; --- Tabla de Segmentos ---

; Tabla de valores para display 7 segmentos (cátodo común)
.cseg              ; Inicia un nuevo segmento de código
.org 0x0100        ; Ubica la tabla en la dirección 0x0100 de la memoria Flash
tabla:
    ; Valores hexadecimales (código binario) para encender los segmentos (a,b,c,d,e,f,g)
    .db $3F, $06, $5B, $4F, $66, $6D, $7D, $07, $7F, $6F
    ; Corresponden a los dígitos: 0,   1,   2,   3,   4,   5,   6,   7,   8,   9
