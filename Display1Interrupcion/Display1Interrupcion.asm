.include "m8535def.inc"

; --- Registros y Definiciones ---
.def cont = r17       ; Contador BCD (0x00 - 0x99)
.def temp = r16       ; Temporal
.def unidades = r20   ; Unidades (0-9)
.def decenas = r21    ; Decenas (0-9)
.def d_low = r18      ; Para el loop de retardo
.def d_high = r19     ; Para el loop de retardo

; --- Inicialización ---
.org 0x0000
    ; Inicializar Stack Pointer
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp
    
    ; Configurar PORTA y PORTC como salidas (Displays BCD)
    ser temp              ; 0xFF
    out DDRA, temp        ; PORTA como salida (Display decenas)
    out DDRC, temp        ; PORTC como salida (Display unidades)
    
    ; Configurar PORTD como entrada con pull-ups activados
    clr temp
    out DDRD, temp        ; PORTD como entrada
    ser temp
    out PORTD, temp       ; Activa pull-ups en PORTD
    
    ; Inicializar contador a 0
    clr cont

; --- Rutina Principal ---
main_loop:
    ; Separar unidades y decenas del contador BCD
    mov temp, cont
    mov unidades, temp
    andi unidades, 0x0F   ; Extraer nibble bajo (unidades)
    
    swap temp
    mov decenas, temp
    andi decenas, 0x0F    ; Extraer nibble alto (decenas)
    
    ; Enviar valores BCD directamente a los displays
    out PORTC, unidades   ; Display unidades recibe 0-9
    out PORTA, decenas    ; Display decenas recibe 0-9

    ; DIAGNÓSTICO: Leer y mostrar estado de PIND en los bits altos de PORTC
    ; (Comentar después de verificar)
    ;in temp, PIND
    ;out PORTC, temp

check_int0:
    ; Verificar INT0 (PD2)
    in temp, PIND         ; Leer PORTD
    sbrc temp, 2          ; Skip if bit 2 is Clear (pressed)
    rjmp check_int1       ; Bit está en 1 (no presionado), revisar INT1
    
    ; INT0 presionado
    rcall delay_debounce
    rcall increment_bcd
    
wait_int0_up:
    in temp, PIND
    sbrs temp, 2          ; Skip if bit 2 is Set (released)
    rjmp wait_int0_up
    rcall delay_debounce
    rjmp main_loop

check_int1:
    ; Verificar INT1 (PD3)
    in temp, PIND         ; Leer PORTD
    sbrc temp, 3          ; Skip if bit 3 is Clear (pressed)
    rjmp main_loop        ; Bit está en 1 (no presionado), volver al inicio
    
    ; INT1 presionado
    rcall delay_debounce
    rcall decrement_bcd
    
wait_int1_up:
    in temp, PIND
    sbrs temp, 3          ; Skip if bit 3 is Set (released)
    rjmp wait_int1_up
    rcall delay_debounce
    rjmp main_loop

; --- Subrutina: Incrementar en BCD ---
increment_bcd:
    push temp
    push unidades
    push decenas
    
    ; Separar unidades y decenas
    mov temp, cont
    mov unidades, temp
    andi unidades, 0x0F   ; Extraer unidades
    
    swap temp
    mov decenas, temp
    andi decenas, 0x0F    ; Extraer decenas
    
    ; Incrementar unidades
    inc unidades
    cpi unidades, 10      ; ¿Llegó a 10?
    brne rebuild_bcd      ; Si no, reconstruir
    
    ; Unidades = 10, resetear y carry a decenas
    clr unidades
    inc decenas
    cpi decenas, 10       ; ¿Decenas llegó a 10?
    brne rebuild_bcd      ; Si no, reconstruir
    
    ; Llegó a 100, resetear todo
    clr decenas
    clr unidades

rebuild_bcd:
    ; Reconstruir el número BCD
    mov temp, decenas
    swap temp             ; Mover decenas a nibble alto
    or temp, unidades     ; Combinar con unidades
    mov cont, temp        ; Guardar en contador
    
    pop decenas
    pop unidades
    pop temp
    ret

; --- Subrutina: Decrementar en BCD ---
decrement_bcd:
    push temp
    push unidades
    push decenas
    
    ; Separar unidades y decenas
    mov temp, cont
    mov unidades, temp
    andi unidades, 0x0F   ; Extraer unidades
    
    swap temp
    mov decenas, temp
    andi decenas, 0x0F    ; Extraer decenas
    
    ; Verificar si unidades es 0
    cpi unidades, 0       ; ¿Unidades = 0?
    brne dec_units        ; Si no es 0, solo decrementar unidades
    
    ; Unidades = 0, poner en 9 y decrementar decenas
    ldi unidades, 9
    
    ; Verificar si decenas también es 0
    cpi decenas, 0        ; ¿Decenas = 0?
    brne dec_tens         ; Si no es 0, decrementar decenas
    
    ; Todo es 0, poner en 99
    ldi decenas, 9
    rjmp rebuild_bcd_dec

dec_tens:
    ; Decrementar decenas
    dec decenas
    rjmp rebuild_bcd_dec

dec_units:
    ; Solo decrementar unidades
    dec unidades

rebuild_bcd_dec:
    ; Reconstruir el número BCD
    mov temp, decenas
    swap temp             ; Mover decenas a nibble alto
    or temp, unidades     ; Combinar con unidades
    mov cont, temp        ; Guardar en contador
    
    pop decenas
    pop unidades
    pop temp
    ret

; --- Subrutina: Retardo (~50ms @ 4MHz) ---
delay_debounce:
    push d_high
    push d_low
    
    ldi d_high, 50
delay_loop_outer:
    ldi d_low, 200
delay_loop_inner:
    dec d_low
    brne delay_loop_inner
    dec d_high
    brne delay_loop_outer
    
    pop d_low
    pop d_high
    ret
