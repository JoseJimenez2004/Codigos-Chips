.include"m8535def.inc"
.def aux = r16
rjmp inicio
tabla:
	;.db $3f,6,$5b,$4f,$66,$6d,$7d,$27,$7f,$6f,$77,$7c,$39,$5e,$79,71
	.db 1,2,4,8,16,32,64,128,256,512,1024,2048,5096,1192,2384,5768
inicio:
	ser aux
	out ddra,aux
	out portb,aux
nvo:
	ldi zh,high(tabla<<1)
	ldi zl,low(tabla<<1)
	in aux,pinb
	add zl,aux
	lpm aux,z
	out porta,aux
	rjmp nvo
