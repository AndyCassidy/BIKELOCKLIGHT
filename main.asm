;
; attiny13A-Bikelock.asm
;
; ATTINY13A board via ISP
.nolist
.include "tn13adef.inc" ; Define device ATtiny13A
.list
;
; **********************************
;        H A R D W A R E
; **********************************
;
; Device: ATtiny13A, Package: 8-pin-PDIP_SOIC
;				
;						   		      _________
;								   1 /         |8
;	(PCINT5/RESET/ADC0/dW) PB5   o--|RESET  VCC|--o  VCC
;	(PCINT3/CLKI/ADC3) PB3       o--|PB3    PB2|--o  PB2 (SCK/ADC1/T0/PCINT2)
;	(PCINT4/ADC2) PB4			 x--|PB4    PB1|--x  PB1 (MISO/AIN1/OC0B/INT0/PCINT1)
;						   GND   o--|GND    PB0|--o  PB0 (MOSI/AIN0/OC0A/PCINT0)
;								  4 |__________|5 
; Push button input attached to PORTB, PIN1
; LED +ve side attached to PORTB, PIN4
; ISP programming connections on MOSI,MISO,SCK,VCC,GND AND RESET
; **********************************
;           REGISTERS
; **********************************
.def rmp = R16 ; Define multipurpose register
.def rSreg = R17 ; Save/Restore status port

; **********************************
;           S R A M
; **********************************
.dseg
.org SRAM_START

; **********************************
;         C O D E  S E G M E N T
; **********************************
.cseg
.org 0x000

; **********************************
; R E S E T  &  I N T - V E C T O R S
; **********************************
	rjmp Main		;RESET
	rjmp lightoninterr	;INT0 External interrupt
	reti			;PCINT0
	rjmp overflow	;TIM0 Overflow
	reti			;EE_RDY
	reti			;ANA_COMP
	reti			;TIM0_COMPA
	reti			;TIM0_COMPB
	reti			;WDT
	reti			;ADC	


; **********************************
;  I N T - S E R V I C E   R O U T .
; **********************************
overflow:
		dec r19
reti
;-----------------------------------
lightoninterr:
		sbi DDRB,(1<<DDB1)	;Disable the push button
		IN rSreg,SREG		;Save the SREG

		rcall lighton		;Light on subroutine

		OUT SREG,rSreg		;Restore the SREG
		Cbi DDRB,(1<<DDB1)	;Enable the push button again
reti

; **********************************
; ------- CALLED SUBROUTINES ------- 
; **********************************
lighton:
	push rmp
	Sbi PORTB,PORTB4		;LED on
	rcall delay10sec		;8 Second delay
	rcall delay10sec		;8 Second delay
	rcall delay10sec		;8 Second delay
	cbi PORTB,PORTB4		;LED off
	pop rmp
	ret
;--------------
delay10sec:
	push rmp			;save the rmp register	
	push r19
	ldi r19,150			;initialise r19 for a 10 second timer delay
;	ldi r19,15			;1 second delay for debugging
	ldi rmp,(1<<CS02)|(0<<CS01)|(0<<CS00)	;Start the timer, no prescaler
	sei					;Enable interrupts (for the 16 bit timer overflow)
	OUT TCCR0B,rmp		;start the timer
back:	cpi r19,0
	brne back
	cli					;Disable interrupts
	ldi rmp,(0<<CS02)|(0<<CS01)|(0<<CS00)	;Stop the timer, no prescaler
	OUT TCCR0B,rmp		;stop the timer
	pop r19
	pop rmp				;restore the rmp register
	ret
;--------------
lightonshort:
	push rmp
	ldi rmp,0x04			;Counter for number of flashes
top:	Sbi PORTB,PORTB4	;LED on
	rcall delayshort		;Delay
	cbi PORTB,PORTB4		;LED off
	rcall delayshort		;Delay
	dec rmp
	brne top				;Loop for flashes
	pop rmp
	ret
;--------------
delayshort:
	push rmp			;save the rmp register	
	push r19
	ldi r19,3			;initialise r19
	ldi rmp,(1<<CS02)|(0<<CS01)|(0<<CS00)	;Start the timer, no prescaler
	OUT TCCR0B,rmp		;start the timer
backshort:	cpi r19,0
	brne backshort
	ldi rmp,(0<<CS02)|(0<<CS01)|(0<<CS00)	;Stop the timer, no prescaler
	OUT TCCR0B,rmp		;stop the timer
	pop r19
	pop rmp				;restore the rmp register
	ret

; **********************************
;  M A I N   P R O G R A M   I N I T
; **********************************

Main:
;-------------STACK POINTER SETUP----------
.ifdef SPH				; if SPH is defined
  ldi rmp,High(RAMEND)
  out SPH,rmp			; Init MSB stack pointer
  .endif
	ldi rmp,Low(RAMEND)
	out SPL,rmp			; Init LSB stack pointer
;-------------CLOCK PRESCALER SETUP----------
;	cli
;	ldi rmp,0b10000000	; Load 1 to CLKPCE (prescaler change enable)
;	ldi r18,0b00000110	; Load 1 to CLKPS2 and CLKPS1 FOR CLOCK/64 SPEED
;	out CLKPR,rmp		
;	OUT CLKPR,r18		
nop
;-------------SETUP - INPUT / OUTPUT SIGNALS----------
	sbi DDRB,DDB4		; LED OUTPUT ON PA4
	SBI DDRB,DDB1		; Push button input on PB1
	sbi PORTB,PORTB1	; Pullup enable on pB1 button
	CBI PORTB,PORTB4	; LED OFF

;-------------TIMER OVERFLOW ENABLE----------
	ldi rmp,(1<<TOIE0)	;set up the timer overflow enable
	out TIMSK0,rmp	

;-------------ENABLE INTERRUPTS----------

	ldi rmp,1<<ISC01	; INT0 interrupt - falling edge
	out MCUCR,rmp		; MCU CONTROL REGISTER
	ldi rmp,1<<INT0		; Enable INT0
	out GIMSK,rmp		; Interrupt mask register
	sei					; Enable global interrupts

;-------------SLEEP MODE ENABLE----------
	ldi rmp,(1<<SM1)|(1<<SE)  ; power down sleep mode | sleep enable 
	out MCUCR,rmp		; MCU CONTROL REGISTER

;-------------Initialisation after setup is complete----------
	rcall lightonshort

; **********************************
;    P R O G R A M   L O O P
; **********************************
Loop:
	sleep
	NOP
rjmp loop 
