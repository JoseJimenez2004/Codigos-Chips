	.include"m8535def.inc"
	.def aux = R16
	
	ser aux
	out DDRA, aux
	out PORTB, aux
NVO:
	ldi zh, high(tabla<<1)
	ldi zl, low(tabla<<1)
	in aux, PINB
	add zl, aux
	lpm aux, z
	out PORTA, aux

	rjmp NVO

tabla:
	.db $3f, $06, $5b, $4f, $66, $6d, $7d, $27, $7f, $6f, $77, $7c, $29, $5e, $79, $71
