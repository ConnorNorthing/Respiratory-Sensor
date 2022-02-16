;################################################################################################################################################################################################
;========== PIC USED ==========
    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
  ; CONFIG1H
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block)
  CONFIG  PLLCFG = OFF          ; 4X PLL Enable (Oscillator used directly)
  CONFIG  PRICLKEN = ON         ; Primary clock enable bit (Primary clock is always enabled)
  CONFIG  FCMEN = OFF           ; Fail-Safe Clock Monitor Enable bit (Fail-Safe Clock Monitor disabled)
  CONFIG  IESO = OFF            ; Internal/External Oscillator Switchover bit (Oscillator Switchover mode disabled)

; CONFIG2L
  CONFIG  PWRTEN = OFF          ; Power-up Timer Enable bit (Power up timer disabled)
  CONFIG  BOREN = SBORDIS       ; Brown-out Reset Enable bits (Brown-out Reset enabled in hardware only (SBOREN is disabled))
  CONFIG  BORV = 190            ; Brown Out Reset Voltage bits (VBOR set to 1.90 V nominal)

; CONFIG2H
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bits (Watch dog timer is always disabled. SWDTEN has no effect.)
  CONFIG  WDTPS = 32768         ; Watchdog Timer Postscale Select bits (1:32768)

; CONFIG3H
  CONFIG  CCP2MX = PORTC1       ; CCP2 MUX bit (CCP2 input/output is multiplexed with RC1)
  CONFIG  PBADEN = ON           ; PORTB A/D Enable bit (PORTB<5:0> pins are configured as analog input channels on Reset)
  CONFIG  CCP3MX = PORTB5       ; P3A/CCP3 Mux bit (P3A/CCP3 input/output is multiplexed with RB5)
  CONFIG  HFOFST = ON           ; HFINTOSC Fast Start-up (HFINTOSC output and ready status are not delayed by the oscillator stable status)
  CONFIG  T3CMX = PORTC0        ; Timer3 Clock input mux bit (T3CKI is on RC0)
  CONFIG  P2BMX = PORTD2        ; ECCP2 B output mux bit (P2B is on RD2)
  CONFIG  MCLRE = EXTMCLR       ; MCLR Pin Enable bit (MCLR pin enabled, RE3 input pin disabled)

; CONFIG4L
  CONFIG  STVREN = ON           ; Stack Full/Underflow Reset Enable bit (Stack full/underflow will cause Reset)
  CONFIG  LVP = ON              ; Single-Supply ICSP Enable bit (Single-Supply ICSP enabled if MCLRE is also 1)
  CONFIG  XINST = OFF           ; Extended Instruction Set Enable bit (Instruction set extension and Indexed Addressing mode disabled (Legacy mode))

; CONFIG5L
  CONFIG  CP0 = OFF             ; Code Protection Block 0 (Block 0 (000800-001FFFh) not code-protected)
  CONFIG  CP1 = OFF             ; Code Protection Block 1 (Block 1 (002000-003FFFh) not code-protected)
  CONFIG  CP2 = OFF             ; Code Protection Block 2 (Block 2 (004000-005FFFh) not code-protected)
  CONFIG  CP3 = OFF             ; Code Protection Block 3 (Block 3 (006000-007FFFh) not code-protected)

; CONFIG5H
  CONFIG  CPB = OFF             ; Boot Block Code Protection bit (Boot block (000000-0007FFh) not code-protected)
  CONFIG  CPD = OFF             ; Data EEPROM Code Protection bit (Data EEPROM not code-protected)

; CONFIG6L
  CONFIG  WRT0 = OFF            ; Write Protection Block 0 (Block 0 (000800-001FFFh) not write-protected)
  CONFIG  WRT1 = OFF            ; Write Protection Block 1 (Block 1 (002000-003FFFh) not write-protected)
  CONFIG  WRT2 = OFF            ; Write Protection Block 2 (Block 2 (004000-005FFFh) not write-protected)
  CONFIG  WRT3 = OFF            ; Write Protection Block 3 (Block 3 (006000-007FFFh) not write-protected)

; CONFIG6H
  CONFIG  WRTC = OFF            ; Configuration Register Write Protection bit (Configuration registers (300000-3000FFh) not write-protected)
  CONFIG  WRTB = OFF            ; Boot Block Write Protection bit (Boot Block (000000-0007FFh) not write-protected)
  CONFIG  WRTD = OFF            ; Data EEPROM Write Protection bit (Data EEPROM not write-protected)

; CONFIG7L
  CONFIG  EBTR0 = OFF           ; Table Read Protection Block 0 (Block 0 (000800-001FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR1 = OFF           ; Table Read Protection Block 1 (Block 1 (002000-003FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR2 = OFF           ; Table Read Protection Block 2 (Block 2 (004000-005FFFh) not protected from table reads executed in other blocks)
  CONFIG  EBTR3 = OFF           ; Table Read Protection Block 3 (Block 3 (006000-007FFFh) not protected from table reads executed in other blocks)

; CONFIG7H
  CONFIG  EBTRB = OFF           ; Boot Block Table Read Protection bit (Boot Block (000000-0007FFh) not protected from table reads executed in other blocks)
;========== Definition of variables ==========
       cblock 0x00
	   Rollover
	   First
	   Second
	   Third
	   Fourth
	   Fifth
	   Sixth
	   Seventh
	   Eighth
	   Average
	   StateVariable
	   FLAG
	   Threshold
	   Breaths_in
	   Breaths_out
	   Current
           RESULTHI
	   RESULTLOWER
	   No_of_blinks
	   Delay1_1
	   Delay2_1
	   Delay1_2
	   Delay2_2
	   Delay3_2
	   Count
	   
       endc
;========== Reset vector ==========
	org 	00h
	goto 	Setup
	org 	08h
	goto 	ISR
	
;========== Setup ============
Setup	
	; Clock Speed 4MHZ
	BSF	OSCCON,IRCF0
	BCF	OSCCON,IRCF1
	BSF	OSCCON,IRCF2
	;CCP CONFIG FOR CCP2
	MOVLW	b'00001100'
	MOVWF	CCP2CON
	;PWM SETUP FOR LED
	MOVLW	.20
	MOVWF	PR2
	;TIMER FOR PWM
	CLRF	T2CON
	CLRF	TMR2
;========== PORTS ============
	; Initialize Port A
	MOVLB	0xF
	CLRF 	PORTA 		;Digital Outputs
	CLRF 	LATA 		
	CLRF	ANSELA 		
	CLRF 	TRISA
	; Set up Port B pin B.4 for interrupt on change
	;BSF 	TRISB,0x04	
	;BSF 	IOCB,IOCB4	;IOC input
	;CLRF 	ANSELB
	
	; Initialize Port C
	CLRF	TRISC
	CLRF	ANSELC
	CLRF	LATC
	CLRF 	PORTC
	
	; Initialize Port D
	CLRF 	PORTD 		
	CLRF 	LATD 		;Digital Outputs
	CLRF	ANSELD 		
	CLRF 	TRISD
	
	BSF	T4CON,TMR4ON
	
	MOVLB	0x0
			
;========== INTERRUPTS ============
	CLRF 	INTCON		; clear all interrupt bits
	BSF 	INTCON,RBIE 	; enable RB change interrupt
	
;========== TIMER ============	
	BSF	INTCON,PEIE		; Peripheral interrupt enable
	BSF	INTCON,GIE		; global interrupt enable
	BSF	PIE5,TMR4IE		; timer4 interrupt enable
	CLRF	TMR4			; Clear the timer of the few counts that accumulated since the previous roll-over.
	SETF	PR4			;set period reg for tmr4 255
	movlw	b'01001011'		; 16pre,10post
	movwf	T4CON

;#################################################################################################################################################################################################
;========== INITIAL STATE ============
INITIAL_STATE
	MOVLB	0x00	
	MOVLW	0x5A
	MOVWF	Threshold
	CLRF	StateVariable
	CLRF	Breaths_in
	CLRF	Breaths_out
	CLRF	Rollover
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC
	BSF	TRISC,1
	CLRF	PORTD
	BCF	T2CON,TMR2ON
	CLRF	CCPR2L
	CLRF	TMR4
	CLRF	First
	CLRF	Second
	CLRF	Third
	CLRF	Fourth
	CLRF	Fifth
	CLRF	Sixth
	CLRF	Seventh
	CLRF	Eighth
	CLRF	Average
	CLRF	Rollover
	CLRF	FLAG
;#################################################################################################################################################################################################
;========== MAIN LOOP ============
MAIN
	CALL	CAP_TOUCH_ON_CHANNEL
	CALL	CAP_TOUCH_Poll_START
	CALL	BREATHING_SENSOR_Channel
	;CALL	TIMER_ON
LOOP	
	MOVLW	0x1
	CPFSEQ	FLAG
	CALL	CLEAR_TIMER
	CALL	BREATHING_TEST
	CALL	BREATHING_POLLING
	CALL	STATE_TABLE
	MOVLW	0x10
	CPFSEQ	StateVariable
	GOTO	LOOP
	BSF	PORTD,4
	CALL	CALC_LOOKUP_TABLE
	CALL	Delay_loop_2
	BCF	PORTD,4
	CALL	OUTPUT
	CALL	CAP_TOUCH_OFF_CHANNEL
	CALL	CAP_TOUCH_Poll_STOP
	GOTO	INITIAL_STATE

CLEAR_TIMER
	MOVLW	0x1
	MOVWF	FLAG
	CLRF	TMR4
	CLRF	Rollover
	RETURN
	
;##############################################################################################################################################################################################
;========== NORMAL SUBROUTINES ============
CAP_TOUCH_ON_CHANNEL
	;Setup ADCON1 and ADCON2 FOR CAPACITIVE TOUCH
	MOVLW	b'10101111'  
	MOVWF	ADCON2
	MOVLW	b'00000000' 
	MOVWF	ADCON1
	
	;Now to setup the port needed to charge the sample and hold capacitor FOR CAPACITIVE TOUCH
	BCF	TRISC,2
	BCF	ANSELC,2
	BSF	PORTC,2
	MOVLW	b'00111001'
	MOVWF	ADCON0	

	BSF	TRISC,5
	BSF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0
	RETURN
;==============================================================================================================================================================================================
CAP_TOUCH_Poll_START
	BTFSC	PORTD,6
	RETURN
	BSF	PORTD,5
	;START CONVERSION
	BSF 	ADCON0,GO		
	MOVF	ADRESH,W
	MOVWF	RESULTLOWER
	BTFSC 	ADCON0,GO 		
	BRA 	$-2 
Conversion_Test_START	
	MOVF 	ADRESH,W				
	MOVWF 	RESULTHI		
	MOVF	RESULTLOWER,W
	CPFSGT	RESULTHI
	BRA	CAP_TOUCH_Poll_START
INI_START	
	BTFSC	PORTD,6
	GOTO	Clear_LED_START
	GOTO	Set_LED_START
Clear_LED_START	
	BCF	PORTD,6
	Call	Delay_loop_1
	BRA	CAP_TOUCH_Poll_START
Set_LED_START	
	BSF	PORTD,6
	Call	Delay_loop_1
	BRA	CAP_TOUCH_Poll_START
;==============================================================================================================================================================================================
BREATHING_SENSOR_Channel
	;SWITCHED CHANNEL AND PUTS ON PWM FOR LED
	MOVLB	0xF
	CLRF	PORTC
	CLRF	LATC
	BCF	TRISC,1		
	BSF	T2CON,TMR2ON
	MOVLB	0x0
	MOVLW	b'00101111'  
	MOVWF	ADCON2
	MOVLW	b'00010101'
	MOVWF	ADCON0
	RETURN
;==============================================================================================================================================================================================
TIMER_ON
	MOVLB	0xF
	BSF	T4CON,TMR4ON		; Start the counter for first breath
	MOVLB	0x0
	RETURN
;==============================================================================================================================================================================================
BREATHING_TEST
	MOVLW	0x1
	CPFSEQ	Breaths_in
	RETURN
	MOVLW	0x1
	CPFSEQ	Breaths_out
	RETURN
INCREMENT   
	INCF	StateVariable
	CLRF	Breaths_out
	CLRF	Breaths_in
	RETURN
;==============================================================================================================================================================================================
BREATHING_POLLING
	BSF 	ADCON0,GO		
	BTFSC 	ADCON0,GO 		
	BRA 	$-2 							
Testing	
	MOVF	ADRESH,W
	MOVWF	Current
	MOVF	Threshold,W
	CPFSEQ	Current
	GOTO	NOT_equal
	GOTO	BREATHING_POLLING
NOT_equal
	CPFSGT	Current
	GOTO	BREATH_Out
	GOTO	BREATH_In
BREATH_Out
	;Configure CCP3CON for PWM
	;DC1B<2:1> = 10 for 0.5
	;CCP1M<3:0> = 11XX for PWM
	MOVLW	.18
	MOVWF	CCPR2L
	MOVLW	0x1
	MOVWF	Breaths_out
	RETURN
BREATH_In
	;MOVFF	Current,Before
	;Configure CCP3CON for PWM
	;DC1B<2:1> = 00 for 1.5
	;CCP1M<3:0> = 11XX for PWM
	MOVLW	.5
	MOVWF	CCPR2L
	MOVLW	0x1
	MOVWF	Breaths_in
	RETURN
;==============================================================================================================================================================================================
CAP_TOUCH_OFF_CHANNEL
	;DISABLE PWM
	BCF	T2CON,TMR2ON
	CLRF	CCPR2L
	
	MOVLW	b'10101111'  
	MOVWF	ADCON2
	MOVLW	b'00000000' 
	MOVWF	ADCON1
	
	;Now to setup the port needed to charge the sample and hold capacitor FOR CAPACITIVE TOUCH
	BCF	TRISC,2
	BCF	ANSELC,2
	BSF	PORTC,2
	MOVLW	b'00111001'
	MOVWF	ADCON0	

	BSF	TRISC,5
	BSF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0
	RETURN
;==============================================================================================================================================================================================
CAP_TOUCH_Poll_STOP	
	BTFSS	PORTD,6
	RETURN
	BSF	PORTD,5
	;START CONVERSION
	BSF 	ADCON0,GO		
	MOVF	ADRESH,W
	MOVWF	RESULTLOWER
	BTFSC 	ADCON0,GO 		
	BRA 	$-2 
Conversion_Test_STOP	
	MOVF 	ADRESH,W				
	MOVWF 	RESULTHI		
	MOVF	RESULTLOWER,W
	CPFSGT	RESULTHI
	BRA	CAP_TOUCH_Poll_START
INI_STOP	
	BTFSC	PORTD,6
	GOTO	Clear_LED_STOP
	GOTO	Set_LED_STOP
Clear_LED_STOP	
	BCF	PORTD,6
	Call	Delay_loop_1
	BRA	CAP_TOUCH_Poll_START
Set_LED_STOP	
	BSF	PORTD,6
	Call	Delay_loop_1
	BRA	CAP_TOUCH_Poll_STOP

;==============================================================================================================================================================================================
STATE_TABLE
	MOVLW	0x0
	CPFSEQ	StateVariable
	GOTO	Check_First
	RETURN	
	
;================== State 1 =====================
Check_First
	MOVLW	0x2
	CPFSEQ	StateVariable
	GOTO	Check_Second
	GOTO	First_Breath
First_Breath	
	MOVF	Rollover,W
	MOVWF	First
	CLRF	Rollover
	CLRF	TMR4
	RETURN

;================== State 2 =====================
Check_Second
	MOVLW	0x4
	CPFSEQ	StateVariable
	GOTO	Check_Third
	GOTO	Second_Breath
Second_Breath	
	MOVF	Rollover,W
	MOVWF	Second
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 3 =====================
Check_Third
	MOVLW	0x6
	CPFSEQ	StateVariable
	GOTO	Check_Fourth
	GOTO	Third_Breath
Third_Breath	
	MOVF	Rollover,W
	MOVWF	Third
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 4 =====================
Check_Fourth
	MOVLW	0x8
	CPFSEQ	StateVariable
	GOTO	Check_Fifth
	GOTO	Fourth_Breath
Fourth_Breath	
	MOVF	Rollover,W
	MOVWF	Fourth
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 5 =====================
Check_Fifth
	MOVLW	0xA
	CPFSEQ	StateVariable
	GOTO	Check_Sixth
	GOTO	Fifth_Breath
Fifth_Breath	
	MOVF	Rollover,W
	MOVWF	Fifth
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 6 =====================
Check_Sixth
	MOVLW	0xC
	CPFSEQ	StateVariable
	GOTO	Check_Seventh
	GOTO	Sixth_Breath
Sixth_Breath	
	MOVF	Rollover,W
	MOVWF	Sixth
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 7 =====================
Check_Seventh	
	MOVLW	0xE
	CPFSEQ	StateVariable
	GOTO	Check_Eighth
	GOTO	Seventh_Breath
Seventh_Breath	
	MOVF	Rollover,W
	MOVWF	Seventh
	CLRF	Rollover
	CLRF	TMR4
	RETURN
	
;================== State 8 =====================
Check_Eighth
	MOVLW	0x10
	CPFSEQ	StateVariable
	RETURN
	GOTO	Eighth_Breath
Eighth_Breath	
	MOVF	Rollover,W
	MOVWF	Eighth
	CLRF	Rollover
	CLRF	TMR4
	RETURN
;==============================================================================================================================================================================================
OUTPUT
	MOVLW	d'122'	    ;Rollover > 122 => Abnormal_Low 
	CPFSGT	Average
	GOTO	Low_Normal  ;Rollover < 122 => Low_Normal
	GOTO	Abnormal_Low
Low_Normal
	BSF	PORTA,4
	MOVLW	d'92'	    ;Rollover > 92 => Display and Return
	CPFSGT	Average
	GOTO	High_Normal ;Rollover < 92 => High_Normal 
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
High_Normal
	BSF	PORTA,5
	MOVLW	d'73'	    ;Rollover > 73 => Display and Return
	CPFSGT	Average
	GOTO	Exercising  ;Rollover < 73 => Exercising
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
Exercising
	BSF	PORTA,6
	MOVLW	d'49'		;Rollover > 49 => Display and Return
	CPFSGT	Average
	GOTO	Abnormal_High	;Rollover < 49 => Abnormal_High
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
Abnormal_Low
	BCF	PORTA,4
	BCF	PORTA,5
	BCF	PORTA,6
	BCF	PORTA,7
	BSF	PORTD,1
	BCF	PORTD,0
	RETURN
Abnormal_High
	BSF	PORTA,7
	BSF	PORTD,1
	BCF	PORTD,0
	RETURN
;==============================================================================================================================================================================================
CALC_LOOKUP_TABLE
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	First
	RRCF	First
	RRCF	First
	MOVF	First,W
	ADDWF	Average
	
	;DIV 8 Second Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Second
	RRCF	Second
	RRCF	Second
	MOVF	Second,W
	ADDLW	Average
	
	;DIV 8 Third Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Third
	RRCF	Third
	RRCF	Third
	MOVF	Third,W
	ADDLW	Average
	
	;DIV 8 Fourth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Fourth
	RRCF	Fourth
	RRCF	Fourth
	MOVF	Fourth,W
	ADDLW	Average
	
	;DIV 8 Fifth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Fifth
	RRCF	Fifth
	RRCF	Fifth
	MOVF	Fifth,W
	ADDLW	Average
	
	;DIV 8 Sixth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Sixth
	RRCF	Sixth
	RRCF	Sixth
	MOVF	Sixth,W
	ADDLW	Average
	
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Seventh
	RRCF	Seventh
	RRCF	Seventh
	MOVF	Seventh,W
	ADDLW	Average
	
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRCF	Eighth
	RRCF	Eighth
	RRCF	Eighth
	MOVF	Eighth,W
	ADDLW	Average
	
	RETURN
;##############################################################################################################################################################################################
;========== Delay subroutine 1 - Large Delay ==========
Delay_loop_1			
	MOVLW	0xBB
	MOVWF	Delay2_1		
Go1_1					
	MOVLW	0xAA
	MOVWF	Delay1_1
Go2_1
	DECFSZ	Delay1_1,f	
	GOTO	Go2_1		
	DECFSZ	Delay2_1,f	
	GOTO	Go1_1
	Return
;========== Delay subroutine 2 - SMALL Delay ==========
Delay_loop_2
    MOVLW   0xF
    MOVWF   Delay1_2
Go1_2
    MOVLW   0xFF
    MOVWF   Delay2_2
Go2_2
    MOVLW   0xFF
    MOVWF   Delay3_2
Go3_2
    DECFSZ  Delay3_2
    GOTO	Go3_2
    DECFSZ  Delay2_2
    GOTO	Go2_2
    DECFSZ  Delay1_2
	RETURN
;##############################################################################################################################################################################################
;==========ISR===================
ISR
	BTFSC	PIR5,TMR4IF
	GOTO	ISR_Timer4
	RETFIE
	
ISR_Timer4
	INCF	Rollover
	BCF	PIR5,TMR4IF
	RETFIE
	end






