.include "m8535def.inc"

; --- Registros y Definiciones ---
.def cont = r17       ; Contador BCD actual (0x00 - 0x99)
.def temp = r16       ; Temporal
.def unidades = r20   ; Unidades (0-9)
.def decenas = r21    ; Decenas (0-9)
.def d_low = r18      ; Para el loop de retardo
.def d_high = r19     ; Para el loop de retardo
.def target = r22     ; Valor objetivo guardado de INT0
.def auto_mode = r23  ; Flag: 0=manual, 1=conteo automático

; --- Tabla de conversión BCD a 7 segmentos (cátodo común) ---
; Bits: gfedcba (LSB = a, MSB = g)
; Dígitos: 0-9
.cseg
.org 0x100
SEG7_TABLE:
    .db 0x3F, 0x06, 0x5B, 0x4F, 0x66, 0x6D, 0x7D, 0x07, 0x7F, 0x6F  ; 0-9

; --- Inicialización ---
.org 0x0000
    ; Inicializar Stack Pointer
    ldi temp, low(RAMEND)
    out SPL, temp
    ldi temp, high(RAMEND)
    out SPH, temp
    
    ; Configurar PORTA y PORTC como salidas (Displays 7 segmentos)
    ser temp              ; 0xFF
    out DDRA, temp        ; PORTA como salida (Display decenas)
    out DDRC, temp        ; PORTC como salida (Display unidades)
    
    ; Configurar PORTD como entrada con pull-ups activados
    clr temp
    out DDRD, temp        ; PORTD como entrada
    ser temp
    out PORTD, temp       ; Activa pull-ups en PORTD
    
    ; Inicializar variables
    clr cont
    clr target
    clr auto_mode         ; Modo manual

; --- Rutina Principal ---
main_loop:
    ; Separar unidades y decenas del contador BCD
    mov temp, cont
    mov unidades, temp
    andi unidades, 0x0F   ; Extraer nibble bajo (unidades)
    
    swap temp
    mov decenas, temp
    andi decenas, 0x0F    ; Extraer nibble alto (decenas)
    
    ; Convertir BCD a 7 segmentos y mostrar
    rcall display_7seg
    rjmp check_inputs

check_inputs:
    ; Verificar si estamos en modo automático
    tst auto_mode
    brne auto_count       ; Si auto_mode != 0, hacer conteo automático

check_int0:
    ; Verificar INT0 (PD2) - Modo manual
    in temp, PIND         ; Leer PORTD
    sbrc temp, 2          ; Skip if bit 2 is Clear (pressed)
    rjmp check_int1       ; Bit está en 1 (no presionado), revisar INT1
    
    ; INT0 presionado - Incrementar manual
    rcall delay_debounce
    rcall increment_bcd
    
wait_int0_up:
    in temp, PIND
    sbrs temp, 2          ; Skip if bit 2 is Set (released)
    rjmp wait_int0_up
    rcall delay_debounce
    rjmp main_loop

check_int1:
    ; Verificar INT1 (PD3) - Iniciar replay
    in temp, PIND         ; Leer PORTD
    sbrc temp, 3          ; Skip if bit 3 is Clear (pressed)
    rjmp main_loop        ; Bit está en 1 (no presionado), volver al inicio
    
    ; INT1 presionado - Guardar valor y empezar replay
    rcall delay_debounce
    
    ; Guardar el valor actual como objetivo
    mov target, cont
    
    ; Reiniciar contador a 0
    clr cont
    
    ; Activar modo automático
    ldi temp, 1
    mov auto_mode, temp
    
wait_int1_up:
    in temp, PIND
    sbrs temp, 3          ; Skip if bit 3 is Set (released)
    rjmp wait_int1_up
    rcall delay_debounce
    rjmp main_loop

; --- Modo de Conteo Automático ---
auto_count:
    ; Retardo para velocidad de conteo visible (~200ms)
    rcall delay_count
    
    ; Verificar si llegamos al objetivo
    cp cont, target
    breq auto_done        ; Si cont == target, terminar modo auto
    
    ; Incrementar
    rcall increment_bcd
    rjmp main_loop

auto_done:
    ; Llegamos al objetivo, reiniciar y continuar en modo manual
    clr cont
    clr auto_mode         ; Volver a modo manual
    rjmp main_loop

; --- Subrutina: Mostrar en displays de 7 segmentos ---
display_7seg:
    push temp
    push zl
    push zh
    push r0
    
    ; Cargar dirección de la tabla de 7 segmentos
    ldi zh, high(SEG7_TABLE << 1)
    
    ; Mostrar unidades en PORTC
    ldi zl, low(SEG7_TABLE << 1)
    mov temp, unidades
    add zl, temp          ; Offset en la tabla
    lpm temp, z           ; Cargar patrón de 7 segmentos
    out PORTC, temp       ; Mostrar unidades
    
    ; Mostrar decenas en PORTA
    ldi zl, low(SEG7_TABLE << 1)
    mov temp, decenas
    add zl, temp          ; Offset en la tabla
    lpm temp, z           ; Cargar patrón de 7 segmentos
    out PORTA, temp       ; Mostrar decenas
    
    pop r0
    pop zh
    pop zl
    pop temp
    ret

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

; --- Subrutina: Retardo para debounce (~50ms @ 4MHz) ---
delay_debounce:
    push d_high
    push d_low
    
    ldi d_high, 50
deb_outer:
    ldi d_low, 200
deb_inner:
    dec d_low
    brne deb_inner
    dec d_high
    brne deb_outer
    
    pop d_low
    pop d_high
    ret

; --- Subrutina: Retardo para conteo automático (~200ms @ 4MHz) ---
delay_count:
    push d_high
    push d_low
    push temp
    
    ldi temp, 4           ; 4 iteraciones de 50ms = 200ms
count_delay_loop:
    ldi d_high, 50
cnt_outer:
    ldi d_low, 200
cnt_inner:
    dec d_low
    brne cnt_inner
    dec d_high
    brne cnt_outer
    dec temp
    brne count_delay_loop
    
    pop temp
    pop d_low
    pop d_high
    ret
