    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7)
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register)
  CONFIG  LVP = ON
  
;========== Definition of variables ==========
       cblock 0x00
           RESULTHI
	   RESULTLOWER
	   Delay1
	   Delay2
       endc
  
;========== Reset vector ==========
	org 	00h
	goto 	Main
	
;========== Setup ============
Main
	;Initialise Port A
	CLRF 	PORTA 		; Initialize PORTA by clearing output data latches
	CLRF 	LATA 		; Alternate method to clear output data latches
	CLRF	ANSELA 		; Configure I/O
	CLRF 	TRISA		; All digital outputs
	
	;Clear Output LED
	BCF	PORTA,5
	
	MOVLW	b'10101111'
	MOVWF	ADCON2
	MOVLW	b'00000000'
	MOVWF	ADCON1
	
	;Now to setup the port needed to charge the sample and hold capacitor
	BCF	TRISC,2
	BCF	ANSELC,2
	BSF	PORTC,2
	MOVLW	b'00111001'
	MOVWF	ADCON0
	
	;Setting the sensor channel as an input and pointing the ADC to the 
	; sensor channel for conversion
	BSF	TRISB,4
	BSF	ANSELB,4
	MOVLW	b'00101101'
	MOVWF	ADCON0

Poll	;=== Poll for conversion ===
	BSF 	ADCON0,GO		; Start conversion
	MOVF	ADRESH,W
	MOVWF	RESULTLOWER
	BTFSC 	ADCON0,GO 		; Is conversion done?
	BRA 	$-2 			; No, test again
		                        ; Note the $-2: $-1 gives a linker error because the
			                ; address is not word-aligned
					
Display	;=== Read & display result ===
		MOVF 	ADRESH,W 	; Read upper 8 bits only, i.e. in this example we 
	   				; throw away the lower two bits and use in effect 
					; an 8 bit conversion
					; ADRESH stands for AD RESult High
		MOVWF 	RESULTHI	; store in GPR space
		MOVF	RESULTLOWER,W
		CPFSLT	RESULTHI
		BRA	Poll
		BSF	PORTA,5
		CALL	Delay_loop
		CALL	Delay_loop
		
;========== Delay subroutine ==========
Delay_loop			
	MOVLW	0xFF
	MOVWF	Delay2		
Go1					
	MOVLW	0xFF
	MOVWF	Delay1
Go2
	DECFSZ	Delay1,f	
	GOTO	Go2		
	DECFSZ	Delay2,f	
	GOTO	Go1		

	RETURN
		

		end