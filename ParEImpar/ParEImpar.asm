; Incluye las definiciones del microcontrolador ATmega8535
	.include"m8535def.inc"

	; Define un alias para el registro temporal r16
	.def aux= r16

	; Define las direcciones de memoria de inicio
	.equ m1 = $60	; Direcci�n de inicio para la lectura de datos
	.equ m2	= $67	; Direcci�n de inicio para datos pares
	.equ m3	= $6e	; Direcci�n de inicio para datos impares

	; Inicializa la parte alta de los punteros de memoria
	clr zh
	clr yh
	clr xh

	; Carga la parte baja de los punteros con las direcciones de inicio
	ldi zl,m1
	ldi yl,m2
	ldi xl,m3

aqui:
	; Carga un byte y avanza el puntero Z
	ld aux,z+

	; Rota el bit menos significativo al bit de acarreo para verificar paridad
	ror aux

	; Salta si el bit de acarreo est� en 0 (n�mero par)
	brcc par

	; Si el n�mero es impar:
	st x+,aux	; Almacena el valor en la direcci�n apuntada por X y avanza X
	inc xl		; Incrementa la parte baja de X (error l�gico, avanza X dos veces)
	rjmp alla

impar:
	; Si el n�mero es impar:
	rol aux		; Rota el bit de acarreo hacia la izquierda (no se usa en el c�digo)
	st x,aux	; Almacena el valor en la direcci�n apuntada por X
	rjmp alla

par:
	; Si el n�mero es par:
	rol aux		; Rota el bit de acarreo hacia la izquierda
	st y+,aux	; Almacena el valor en la direcci�n apuntada por Y y avanza Y

alla:
	; Compara el puntero Z para el final del bucle
	cpi zl,$67
	breq fin

	; Contin�a el bucle
	rjmp aqui

fin:
	; Bucle infinito para detener la ejecuci�n del programa
	rjmp fin
