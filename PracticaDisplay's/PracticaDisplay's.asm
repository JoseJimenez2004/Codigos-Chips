 .include "m8535def.inc"

.equ Gi = $40
.equ H  = $76
.equ O  = $3F
.equ L  = $38
.equ A  = $77

.macro ldb
	ldi r16, @1
	mov @0, r16
.endm

.def col  = r17
.def dato = r18

; Inicialización del Stack Pointer
ldi dato, low(RAMEND)
out SPL, dato
ldi dato, high(RAMEND)
out SPH, dato

; Configuración de puertos
ser dato
out DDRB, dato
out DDRC, dato

; Carga de caracteres en registros
ldb r0, A
ldb r1, L
ldb r2, O
ldb r3, H
ldb r4, A
ldb r5, Gi

clr ZH

dos:
	clr ZL
	ldi col, 4
uno:
	com col
	out PORTC, col
	com col
	ld dato, Z+
	out PORTB, dato
	rcall delay
	out PORTB, ZH
	lsl col
	cpi col, $00
	brne uno
	rjmp dos

; Rutina de retardo
delay:
	ldi R19, $1F
WGLOOP0:
	ldi R20, $2A
WGLOOP1:
	dec R20
	brne WGLOOP1
	dec R19
	brne WGLOOP0
	nop
	ret
