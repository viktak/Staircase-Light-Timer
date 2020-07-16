;******************************************************************************
;                                                                             *
;    Filename:      main.asm                                                  *
;    Date:          27/08/2010                                                *
;    File Version:  1                                                         *
;                                                                             *
;    Author:        Viktor Takacs                                             *
;    Company:       VikTak.com                                                *
;                                                                             *
;                                                                             *
;******************************************************************************

	LIST	p=16F628		
	include "P16F628a.inc"		
	__config (_CP_OFF & _DATA_CP_OFF & _PWRTE_ON & _WDT_OFF & _INTRC_OSC_CLKOUT & _LVP_OFF & _BODEN_OFF & _MCLRE_OFF)

; Registers we will be using
	INT_VAR     UDATA_SHR      
	#define R_DEL1			0x20	; Delay register
	#define R_DEL2			0x21	; Delay register
	#define R_WDATA_TMP1	0x22
	#define R_WDATA_TMP2	0x23
	#define R_SEND_W_TMP	0x24
	#define	R_WTMP			0x27	; W storage
	#define	R_STMP			0x28	; STATUS storage
	#define	R_STMP1			0x2E	; Send temp register
	#define R_PSEC			0x2F


;	data line
STORE		Equ 		1		;RA1
CLOCK		Equ 		2		;RA2
DATA_OUT	Equ 		0		;RA0

;	output
LED			Equ			1		;RB1

;	input lines
UP			Equ			3		;RA3
DOWN		Equ			4		;RA4
TEST		Equ			0		;RB0

;	other variables
VALUE		RES			1		; Current value
OLDVALUE	RES			1		; Previous value
MYPATTERN	RES			1		; Bit pattern
PCounter	RES			1		; Pattern Counter
TEMP		RES 		1		; a temporary register
t1			RES			1		; a temporary register
t2			RES			1		; a temporary register

Value_High	RES			1
Value_Low	RES			1

	org	0
	goto	init

; Blank interrupt routine - simply saves and restores status & W
; Add code to do something useful...	
	org 4
	movwf	R_WTMP		; Save W & STATUS
	swapf	STATUS, W
	movwf	R_STMP
	bcf		STATUS, RP0

int_cleanup:
	movlw	b'11111000'	; Clear interrupt bits
	andwf	INTCON, F
	swapf	R_STMP, W	; Restore W & STATUS
	movwf	STATUS
	swapf	R_WTMP, F
	swapf	R_WTMP, W
	retfie


; Init sets all I/O lines as outputs and selects PORTA as
; I/O lines by turning the comparators off.
init
	clrf	PORTB
	clrf	PORTA
	movlw	0x07
	movwf	CMCON		; Comparators off - PORTA on
	bsf		STATUS, RP0	; Select bank 1
	movlw	b'00000001'	; Set PORTB
	movwf	TRISB
	movlw	b'00011000'	; Set PORTA
	movwf	TRISA

	bcf		STATUS, RP0	; Select bank 0

	clrf	VALUE
	
	call	SelfTest

	call	_eeRead
	andlw	0x0f

	movwf	VALUE
	movwf	OLDVALUE

loop

Check_UP
	btfsc	PORTA,	UP
		goto	Check_Down

	movlw	0x0f
	subwf	VALUE, 0
	btfss	STATUS,	Z			;	if it hasn't reached max
		incf	VALUE,	1		;	increment it


Check_Down
	btfsc	PORTA,	DOWN
		goto	Check_Action

	movlw	0x0F
	andwf	VALUE,	0
	btfss	STATUS,	Z
		decf	VALUE,	1

Check_Action
	btfss	PORTB,	TEST
		call	DoAction

	incf	VALUE,	0			;	pass VALUE as parameter in W
	goto	EndKeys

EndKeys
	call	DisplayValue

	movlw	d'150'
	call	delay

	movfw	VALUE				;	check if VALUE has changed
	xorwf	OLDVALUE,	0
	btfsc	STATUS,	Z
		goto	loop
	movfw	VALUE
	movwf	OLDVALUE
	
	call	_eeWrite			;	save VALUE to EEPROM in case of power break

	goto loop

;	Takes value in W and displays it on 2 bytes 
;	represented by LEDs in VU meter style
DisplayValue

	movwf	TEMP				;	store value to display

	movlw	0x08				;	check value
	subwf	TEMP,	0

	btfsc	STATUS,	C			;	if VALUE < 9
		goto	d1
	clrf	Value_High			;	no upper LEDs to set
	movfw	TEMP
	movwf	Value_Low


	goto	DisplayValue_1
	

d1								;	if VALUE > 8
	movlw	0x08
	subwf	TEMP,	0
	movwf	Value_High

	movlw	0x08
	movwf	Value_Low

	goto	DisplayValue_1

DisplayValue_1

	movfw	Value_Low
	call	GetPattern
	movwf	MYPATTERN
	call	SendData


	movfw	Value_High
	movwf	MYPATTERN
	call	GetPattern
	call	SendData

	call	RefreshDisplay

	return


; ---------------------
;	Parameter: VALUE

DoAction
	movfw	VALUE
	movwf	t1						;	set number of iterations to VALUE
	incf	t1,	1
	bsf		PORTB,	LED				;	switch ON relay and LED

ActionLoop
	movlw	d'15'					;	this will give approc 10 sec
	movwf	t2

flashes
	movfw	t1
	call	DisplayValue

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay


	decf	t1,	0
	call	DisplayValue

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay

	btfss	PORTB,	TEST			;	if button is pressed, restart countdown
		goto	DoAction

	movlw	d'50'
	call	delay


	decfsz	t2,	1
		goto	flashes

	decf	t1,	1
	btfss	STATUS,	Z
		goto	ActionLoop
	bcf		PORTB,	LED				;	switch OFF relay and LED
	return


; ----------------------

GetPattern
	addwf	PCL,	1
	dt	b'00000000',	b'00000001', b'00000011', b'00000111', b'00001111', b'00011111', b'00111111', b'01111111', b'11111111'
	
; ----------------------

SendData
	movwf	MYPATTERN				; Store the pattern to be displayed in @MYPATTERN
	movlw	8						; Set up bit counter
	movwf	TEMP

SendBit
	rrf	MYPATTERN, 1				; Rotate bits to the right
	btfsc	STATUS, 0				; The Carry flag holds the bit to send
	goto	SendOne
	goto	SendZero
		
SendBit_Resume

	decfsz	TEMP, 1
	goto SendBit					; If there are more bits, continue
	return

SendOne
	bsf		PORTA, DATA_OUT
	bsf		PORTA, CLOCK					; Clock-out (send) bit
	bcf		PORTA, CLOCK
	goto	SendBit_Resume

SendZero
	bcf		PORTA, DATA_OUT
	bsf		PORTA, CLOCK					; Clock-out (send) bit
	bcf		PORTA, CLOCK
	goto	SendBit_Resume


RefreshDisplay
	bsf		PORTA, STORE					; Display data
	bcf		PORTA, STORE					; Display data
	return

; ---------------------

; Calls the delay_1ms routine the number of times specified by
; the W register.
delay
	movwf	R_DEL2
delay_loop
	call	delay_1ms
	decfsz	R_DEL2, F
		goto	delay_loop
	return
	
; When called gives a delay of about 1000 cycles, or 1ms at 4Mhz
; before the next instruction is executed.
delay_1ms
	movlw	d'248'
	movwf	R_DEL1
delay_1ms_loop
	nop
	decfsz	R_DEL1, F
		goto	delay_1ms_loop
	return


; *********************************
; EEPROM write
; call with W reg containg # to save
_eeWrite        
	bsf				STATUS,	RP0		;bank 1
	bsf				EECON1,WREN		; initiate EEPROM write sequence
	movwf           EEDATA			; save W into EEDATA
	clrf			EEADR			; set EEPROM address 0
	bcf				PIR1,EEIF		; clear EE Interrupt flag
	movlw           0x55
	movwf           EECON2
	movlw           0xAA
	movwf           EECON2
	bsf             EECON1,WR
	bcf				STATUS,		RP0	;bank 0
	return							; return
              
; *********************************
; EEPROM read
; returns with saved # in W reg

_eeRead         
	bsf				STATUS,	RP0		;bank 1
	clrf			EEADR			; set EEPROM address 0
	bsf             EECON1,	RD		; initiate EEPROM read
	movf            EEDATA,W		; load EEPROM data into W
	bcf				STATUS,	RP0		;bank 0
	return          				; return   



; **********************************
; Test lights at startup
; **********************************

SelfTest

TestLED
	clrf	t1

TestLED_1
	movfw	t1
	call	DisplayValue

	movlw	d'20'
	call	delay

	incf	t1
	movlw	0x11
	subwf	t1, 0
	btfss	STATUS,	Z
		goto TestLED_1


TestLED_2
	
	movfw	t1
	call	DisplayValue

	movlw	d'20'
	call	delay

	decfsz	t1
		goto	TestLED_2

TestLights
	bsf		PORTB,	LED				;	switch ON relay and LED
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	movlw	d'250'
	call	delay
	bcf		PORTB,	LED				;	switch OFF relay and LED

return

; **********************************

	
end