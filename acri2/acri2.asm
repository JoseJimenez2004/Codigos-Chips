.include "m8535def.inc"

; --- Definiciones de registros ---
.def aux      = R16
.def valor    = R17

; --- Configuración inicial ---
; PORTA -> salida (display)
; PORTB -> entrada con pull-ups internos
ser aux            ; aux = 0xFF
out DDRA, aux      ; PORTA como salida
clr aux
out DDRB, aux      ; PORTB como entrada
out PORTB, aux     ; activar pull-ups internos en PB

; --- Tabla de segmentos para display de 7 segmentos (ánodo común) ---
; Valores para 0..F
; PORTA = segments: PA0=a, PA1=b, ..., PA6=g
.equ SEG_0 = 0x3F
.equ SEG_1 = 0x06
.equ SEG_2 = 0x5B
.equ SEG_3 = 0x4F
.equ SEG_4 = 0x66
.equ SEG_5 = 0x6D
.equ SEG_6 = 0x7D
.equ SEG_7 = 0x07
.equ SEG_8 = 0x7F
.equ SEG_9 = 0x6F
.equ SEG_A = 0x77
.equ SEG_B = 0x7C
.equ SEG_C = 0x39
.equ SEG_D = 0x5E
.equ SEG_E = 0x79
.equ SEG_F = 0x71

; --- Programa principal ---
main:
    in aux, PINB        ; leer switches PB0–PB3
    andi aux, 0x0F      ; tomar solo 4 bits (0..F)
    mov valor, aux      ; guardar en valor

    ; seleccionar el segmento correcto según el valor
    cpi valor, 0
    breq mostrar0
    cpi valor, 1
    breq mostrar1
    cpi valor, 2
    breq mostrar2
    cpi valor, 3
    breq mostrar3
    cpi valor, 4
    breq mostrar4
    cpi valor, 5
    breq mostrar5
    cpi valor, 6
    breq mostrar6
    cpi valor, 7
    breq mostrar7
    cpi valor, 8
    breq mostrar8
    cpi valor, 9
    breq mostrar9
    cpi valor, 10
    breq mostrarA
    cpi valor, 11
    breq mostrarB
    cpi valor, 12
    breq mostrarC
    cpi valor, 13
    breq mostrarD
    cpi valor, 14
    breq mostrarE
    cpi valor, 15
    breq mostrarF

    rjmp main   ; nunca debería llegar aquí

; --- Mostrar dígitos ---
mostrar0:
    ldi aux, SEG_0
    rjmp mostrar
mostrar1:
    ldi aux, SEG_1
    rjmp mostrar
mostrar2:
    ldi aux, SEG_2
    rjmp mostrar
mostrar3:
    ldi aux, SEG_3
    rjmp mostrar
mostrar4:
    ldi aux, SEG_4
    rjmp mostrar
mostrar5:
    ldi aux, SEG_5
    rjmp mostrar
mostrar6:
    ldi aux, SEG_6
    rjmp mostrar
mostrar7:
    ldi aux, SEG_7
    rjmp mostrar
mostrar8:
    ldi aux, SEG_8
    rjmp mostrar
mostrar9:
    ldi aux, SEG_9
    rjmp mostrar
mostrarA:
    ldi aux, SEG_A
    rjmp mostrar
mostrarB:
    ldi aux, SEG_B
    rjmp mostrar
mostrarC:
    ldi aux, SEG_C
    rjmp mostrar
mostrarD:
    ldi aux, SEG_D
    rjmp mostrar
mostrarE:
    ldi aux, SEG_E
    rjmp mostrar
mostrarF:
    ldi aux, SEG_F

mostrar:
    out PORTA, aux
    rjmp main
