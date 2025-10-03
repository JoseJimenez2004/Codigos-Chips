	.include"m8535def.inc"
	
	ser r16
	out ddra,r16
	out ddrc,r16
	out portb,r16
	out portd,r16

ciclo:
  in r16,pinb
  in r17,pind
  cp r16,r17
  breq igual
  brlo menor
mayor:
  out porta,r16
  out portc,r17
  rjmp ciclo
igual:
  out porta,r16
  out portc,r17
  rjmp ciclo
menor:
  out portc,r17
  out porta,r16
  rjmp ciclo
