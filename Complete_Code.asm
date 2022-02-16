    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7)
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register)
  CONFIG  LVP = ON
  
;====== Definition of variables =========
	cblock 0x00
	   Delay1
	   Delay2
	   Delay3
	   First
	   Second
	   Third
	   Fourth
	   Fifth
	   Sixth
	   Seventh
	   Eighth
	   Average
	   temp_Storage
	   Move_State
	   Inhaling
	   Exhaling
	   sys_reset
	   Higher
	   Lower
	endc
	
divide	    set 0x3
Threshold   set 0x7E
Eight_Times set 0x08
  
;========== Reset vector ==========
	org 	00h
	GOTO 	INIT
	org	08h
	GOTO	ISR

INIT
	MOVLB	0x0F
;========== Oscillator ============
	;4 MHz internal oscillator is selected
	BSF	OSCCON,IRCF0
	BCF	OSCCON,IRCF1
	BSF	OSCCON,IRCF2
	
;======= CCP Configuration ========
	MOVLW	b'00001111'
	MOVWF	CCP2CON
	
;======= PWM Configuration ========
	MOVLW	.20
	MOVWF	PR2
	
;======= Timer Configuration ======
	CLRF	T4CON
	CLRF	TMR4
	
;======= PORT Initialisation ======
	;PORTA
	CLRF	PORTA
	CLRF	LATA
	CLRF	TRISA
	CLRF	ANSELA
	
	;PORTB
	CLRF	PORTB
	CLRF	LATB
	CLRF	TRISB
	CLRF	ANSELB
	
	;PORTC
	CLRF	PORTC
	CLRF	LATC
	CLRF	TRISC
	CLRF	ANSELC
	
	;PORTD
	CLRF	PORTD
	CLRF	LATD
	CLRF	TRISD
	CLRF	ANSELD
	
;========== OUTPUT LEDs =============
	BCF	PORTC,2
	BCF	PORTA,4
	BCF	PORTA,5
	BCF	PORTA,6
	BCF	PORTA,7
	BCF	PORTD,0
	BCF	PORTD,1
	
;=========== Interrupts ===========
	CLRF	INTCON
	BSF	INTCON,GIE
	BSF	INTCON,PEIE
	BSF	INTCON,RBIE
	
;=== PORTB External Interrupt =====
	BSF	TRISB,4
	BCF	ANSELB,4
	BSF	IOCB,IOCB4

;========= Clear Variable =========	
	CLRF	First
	CLRF	Second
	CLRF	Third
	CLRF	Fourth
	CLRF	Fifth
	CLRF	Sixth
	CLRF	Seventh
	CLRF	Eighth
	CLRF	Average
	CLRF	temp_Storage
	CLRF	Move_State
	CLRF	Inhaling
	CLRF	Exhaling
	CLRF	sys_reset
	CLRF	Higher
	CLRF	Lower
	
	MOVLB	0x00
	

;Main subroutine waits for the capacitive touch start to occurs. This subroutine
; waits for the user to start the system through interacting with the capacitive
; start/stop sensor
Main
	CALL	Capacitive_Touch
	CALL	Capacitive_Touch_Poll_Start
	CALL	ADC_Change_Sensor

;Take eight measurements for breathing in order to determine the average breaths
; per minute for the sensing code.
Breathe_Eight
	CALL	Check_Breathing
	CALL	Poll_IN_OUT_Check
	;CALL	Respiratory_Sensor
	MOVLW	.16
	CPFSEQ	Move_State
	BRA	Breathe_Eight
	CALL	Capacitive_Touch_Stop
	CALL	Capacitive_Touch_Poll_Stop

;When the system has completed sensing, or when the capacitive touch has been 
; touched again, the program should immediately jump to the STOP subroutine 
; until the system is reset.
STOP
	GOTO	STOP	

;This subroutine sets up the ADC for the start capacitive touch sensing to 
; allow the sensor to start the sensing. RC1 is used for sample and hold 
; capacitor charging and RB5 is used for the sensor input
Capacitive_Touch
	;SETUP ADCON2
	MOVLW	b'00100100'
	MOVWF	ADCON2
	
	;SETUP ADCON1
	MOVLW	b'00000000'
	MOVWF	ADCON1
	
	;SETUP PORTC,3 to charge sample/hold cap
	BCF	TRISC,3
	BCF	ANSELC,3
	BSF	PORTC,3
	MOVLW	b'00111101'
	MOVWF	ADCON0
	
	;ADCON0 SETUP
	BSF	TRISC,5
	BSF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0
	
	RETURN

Capacitive_Touch_Poll_Start
	BSF	ADCON0,GO		;Start conversion
	MOVF	ADRESH,W		;Store Low value of ADRESH
	MOVWF	Lower
	BTFSC	ADCON0,GO		;Has conversion finished yet
	BRA	$-2			;Wait until conversion is finished
Start_Conversion
	MOVF	ADRESH,W
	MOVWF	Higher
	MOVF	Lower,W
	CPFSGT	Higher
	BRA	Capacitive_Touch_Poll_Start
	RETURN

;This subroutine sets up the ADC for the stop capacitive touch sensing to 
; allow the sensor to stop the sensing. RC1 is used for sample and hold 
; capacitor charging and RB5 is used for the sensor input
Capacitive_Touch_Stop
	;SETUP PORTC,1 to charge sample/hold cap
	BCF	TRISC,1
	BCF	ANSELC,1
	BSF	PORTC,1
	MOVLW	b'00111001'
	MOVWF	ADCON0
	
	;ADCON0 SETUP
	BSF	TRISC,5
	BCF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0
	
	;SETUP ADCON1
	MOVLW	b'00000000'
	MOVWF	ADCON1
	
	;SETUP ADCON2
	MOVLW	b'10100100'
	MOVWF	ADCON2
	
	BCF	T2CON,TMR2ON
	CLRF	CCPR2L
	
	RETURN

Capacitive_Touch_Poll_Stop
	BSF	ADCON0,GO		;Start conversion
	MOVFF	ADRESH,Lower		;Store Low value of ADRESH
	BTFSC	ADCON0,GO		;Has conversion finished yet
	BRA	$-2			;Wait until conversion is finished
Stop_Conversion
	MOVFF	ADRESH,Higher
	MOVF	Lower,W
	CPFSGT	Higher
	BRA	Capacitive_Touch_Poll_Stop
	RETURN
	

;This subroutine sets up the ADC to use the thermistor and swap over from the 
; capactive touch sensor. Additionally, PORTC is initialised again to ensure 
; that no residual signals or noise from the capacitive touch is carried over
; to the thermistor readings
ADC_Change_Sensor
	BSF	PORTD,1
	MOVLB	0x0F
	CLRF	PORTC
	CLRF	LATC
	BCF	TRISC,1
	BSF	T4CON,TMR4ON
	MOVLB	0x00
	MOVLW	b'00101111'
	MOVWF	ADCON2
	MOVLW	b'00000001'
	MOVWF	ADCON0
	RETURN

;Check to see if the patient is breathing. If breathing, poll through the ADC 
; and determine whether inhaling or exhaling and make computations dependent on
; the state of the patient
Poll_IN_OUT_Check
	BSF	ADCON0,GO		;Start conversion
	BTFSC	ADCON0,GO		;Has conversion finished yet
	BRA	$-2			;Wait until conversion is finished
	
;Populate the temporary vairable and compare it with the ADC threshold so that
; the code knows whether to move into exhale or inhale
Start_Conversion_Sensing
	MOVF	ADRESH,W
	MOVWF	temp_Storage
	MOVF	Threshold,W
	CPFSLT	temp_Storage
	GOTO	Wait_For_EQ
	GOTO	Poll_IN_OUT_Check
		
;In this subroutine, I check to see if the patient has both exhaled and inhaled
; in order to move onto the next state of the code. If the patient has only
; inhlaed (or exhaled), the simply moves back to the Main subroutine and 
; continues polling until both inhalation and exhalation occurs
Check_Breathing
	MOVLW	.1
	CPFSEQ	Inhaling
	RETURN
	CLRF	WREG
	MOVLW	.1
	CPFSEQ	Exhaling
	RETURN
	
;This subroutine increments the state variable after the patient has exhaled and 
; inhaled to symbolise a full breath being taken, meeting the criteria to move
; into the next state of the code
Change_State
	INCF	Move_State
	CLRF	Inhaling
	CLRF	Exhaling
	RETURN
	
;This subroutine determines whether the patient is inhaling or exhaling. What 
; happens is if the temporary variable is lower than the threshold specified for
; the ADC, then the patient is exhaling and if it is greater than the threshold, 
; then the patient is inhaling
Wait_For_EQ
	CPFSLT	temp_Storage
	GOTO	Inhale
	GOTO	Exhale
	
;This subroutine is for when the patient is inhaling. When inhaling, the PWM
; duty cycle must firstly be particularly low to signify the breathing on the
; breathing LED and also to set the inhaling flag bit for further calculation
; for the sensor code
Inhale
	MOVLW	.4
	MOVWF	CCPR2L
	MOVLW	.1
	MOVWF	Inhaling
	RETURN

;This subroutine is for when the patient is exhaling. When exhaling, the PWM
; duty cycle must firstly be particularly high to signify the breathing on the
; breathing LED and also to set the exhaling flag bit for further calculation
; for the sensor code
Exhale
	MOVLW	.19
	MOVWF	CCPR2L
	MOVLW	.1
	MOVWF	Exhaling
	RETURN
	
Respiratory_Sensor
	
	

	
	
;In the following two subroutines are used in order to populate the Average 
; variable and then dividing by eight in order to obtain the average over the 
; eight sensed values
Compute
	MOVLW	First
	ADDLW	Average
	MOVLW	Second
	ADDLW	Average
	MOVLW	Third
	ADDLW	Average
	MOVLW	Fourth
	ADDLW	Average
	MOVLW	Fifth
	ADDLW	Average
	MOVLW	Sixth
	ADDLW	Average
	MOVLW	Seventh
	ADDLW	Average
	MOVLW	Eighth
	ADDLW	Average
Divide_by_eight
	RRNCF	Average
	DECFSZ	divide,f
	GOTO	Divide_by_eight
	GOTO	Display
	

;This subroutine checks to see which LED display to go to. What happens is that
; if Average is less than 12, the code branches to the Abnormal_Low subroutine
; and if Average is greater than 12, the code branches to the Low_Normal 
; subroutine
Display
	MOVLW	d'12'
	CPFSLT	Average
	GOTO	Low_Normal
	GOTO	Abnormal_Low
	
;This subroutine is a relatively low breathing rate but is still classified as
; a normal breathing rate according to the specified values, therefore, only the
; first LED on the PIC board is to be switched on.
Low_Normal
	BSF	PORTA,4
	MOVLW	d'16'
	CPFSLT	Average
	GOTO	High_Normal
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
	
;This subroutine is a relatively high breathing rate, but is still classified 
; as a normal breathing rate, therefore, no issues and 2 LED should turn on
High_Normal
	BSF	PORTA,5
	MOVLW	d'20'
	CPFSLT	Average
	GOTO	Exercising
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
	
;This subroutine is for when the breathing rate is above average but below
; the exceptionally high threshold of the specified breathing ranges, therefore
; 3 LED should be displayed on the PIC board
Exercising
	BSF	PORTA,6
	MOVLW	d'30'
	CPFSLT	Average
	GOTO	Abnormal_High
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
	
	
;This is for when the breathing rate is exceptionally low, therefore, all LED's
; on the PIC board should be switched off.
Abnormal_Low
	BCF	PORTA,4
	BCF	PORTA,5
	BCF	PORTA,6
	BCF	PORTA,7
	BSF	PORTD,1
	BCF	PORTD,0
	RETURN
	
;This is for when the breathing rate is exceptionally high, therefore, all 4 
; LED's on the PIC board should turn on.
Abnormal_High
	BSF	PORTA,7
	BSF	PORTD,1
	BCF	PORTD,0
	RETURN
	
;All interrupts are to be dealt with within this subroutine
ISR
LED_Display
	BTFSC	INTCON,RBIF
	GOTO	LED_Test
Timer_Interrupt
	BTFSC	INTCON,RBIF
	GOTO	Timer
	GOTO	Return_From_Interrupt

;This subroutine occurs when the test button RB4 is triggered in order to 
; signify that all the LEDs are in working condition for the system.
LED_Test
	MOVF	PORTB
	BSF	PORTD,1
	CALL	LED_Delay
	BSF	PORTD,0
	CALL	LED_Delay
	BSF	PORTA,4
	CALL	LED_Delay
	BSF	PORTA,5
	CALL	LED_Delay
	BSF	PORTA,6
	CALL	LED_Delay
	BSF	PORTA,7
	CALL	LED_Delay
	BSF	PORTC,2
	CALL	LED_Delay
Off 
	BCF	PORTD,1
	CALL	LED_Delay
	BCF	PORTD,0
	CALL	LED_Delay
	BCF	PORTA,4
	CALL	LED_Delay
	BCF	PORTA,5
	CALL	LED_Delay
	BCF	PORTA,6
	CALL	LED_Delay
	BCF	PORTA,7
	CALL	LED_Delay
	BCF	PORTC,2
	BRA	Return_From_Interrupt
	
Return_From_Interrupt
	BCF	INTCON,RBIF
	RETFIE
	
Timer

;One second delay to show that all LED's that will be used are functioning 
; correctly within the respiratory system.
LED_Delay
	MOVLW	d'10'
	MOVWF	Delay1
Loop
	MOVLW	d'20'
	MOVLW	Delay2
Loop2
	MOVLW	d'39'
	MOVWF	Delay3
Loop3
	NOP
	NOP
	DECF	Delay3
	BNZ	Loop3
	DECF	Delay2
	BNZ	Loop2
	DECF	Delay1
	BNZ	Loop
	RETURN
	
	end
	

	
	
	