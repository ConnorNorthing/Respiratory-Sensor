    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7)
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register)
  CONFIG  LVP = ON
  
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
	   Delay1
	   Delay2
	   Delay3
	   Move_State
	   Inhaling
	   Exhaling
	   temp_Storage
           Higher
	   Lower
	   Range
	   Delay1_1
	   Delay2_1
	   Short1
	   Short2
	   Short3
	   Timer_Start
       endc
       
;========== Reset vector ==========
	org 	00h
	goto 	INIT
	org 	08h
	goto 	ISR
	
INIT	
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
	CLRF	T2CON
	CLRF	TMR2

;==== Move Bank Register back =====
	MOVLB	0x0F
	
;======= PORT Initialisation ======
	;PORTA
	CLRF	PORTA
	CLRF	LATA
	CLRF	TRISA
	CLRF	ANSELA
	
	;PORTC
	CLRF	TRISC
	CLRF	ANSELC
	CLRF	LATC
	CLRF 	PORTC
	
	;PORTD
	CLRF 	PORTD 		
	CLRF 	LATD 
	CLRF	ANSELD 		
	CLRF 	TRISD
	
	;PORTE
	CLRF	PORTE
	CLRF	LATE
	CLRF	ANSELE
	CLRF	TRISE
	
;========== OUTPUT LEDs =============
	BCF	PORTC,1
	BCF	PORTA,4
	BCF	PORTA,5
	BCF	PORTA,6
	BCF	PORTA,7
	BCF	PORTD,0
	BCF	PORTD,1
			
;====== Interrupt On Change =========
	CLRF	INTCON
	BSF	INTCON,RBIE
	
;==== Timer Interrupt Setup =========
	BSF	INTCON,GIE
	BSF	INTCON,PEIE
	BSF	PIE5,TMR4IE
	CLRF	TMR4
	
	;Timer 4 period register and Timer register setup
	SETF	PR4	    ;Places the value of 255 into the period register of
			    ; for timing calculations needed
	MOVLW	b'01001011'
	MOVWF	T4CON
	
;=== PORTB Interrupt on Change ====
	BSF	TRISB,4
	BCF	ANSELB,4
	BSF	IOCB,IOCB4
	
;===== Start Timer 4 for BPM ======
	BSF	T4CON,TMR4ON
	
;==== Move Bank Register back =====
	MOVLB	0x0


;======== Starting State ==========
Starting_State	
	;Clear Flag variables
	MOVLW	0x0
	MOVWF	Move_State
	MOVLW	0x0
	MOVWF	Inhaling
	MOVLW	0x0
	MOVWF	Exhaling
	
	;Set the ADC Threshold
	MOVLW	0x5C
	MOVWF	Range
	
	;Setup timers
	BSF	TRISC,1
	BCF	T2CON,TMR2ON
	BCF	T4CON,TMR4ON
	
	;Clear PWM Capture 
	CLRF	CCPR2L
	
	;Clear the PORTs used within the system
	CLRF	PORTA
	CLRF	PORTB
	CLRF	PORTC
	CLRF	PORTD
	CLRF	PORTE
	
	;Clear Rollover Variables
	CLRF	First
	CLRF	Second
	CLRF	Third
	CLRF	Fourth
	CLRF	Fifth
	CLRF	Sixth
	CLRF	Seventh
	CLRF	Eighth
	CLRF	Rollover
	CLRF	Average

;Main subroutine waits for the capacitive touch start to occurs. This subroutine
; waits for the user to start the system through interacting with the capacitive
; start/stop sensor
Main
	CALL	Capacitive_Touch
	CALL	LED_Delay
	CALL	Capacitive_Touch_Poll_Start
	CALL	ADC_Change_Sensor
	
;Take eight measurements for breathing in order to determine the average breaths
; per minute for the sensing code.
Breathe_Eight
	;Ensure that TMR4 has started counting
	MOVLW	.1
	CPFSEQ	Timer_Start
	CALL	Clear_Timer
	
	;Continue with the usual routine
	CALL	Check_Breathing
	CALL	Poll_IN_OUT_Check
	CALL	Short_Delay
	CALL	Respiratory_Sensor
	MOVLW	.16
	CPFSEQ	Move_State
	GOTO	Breathe_Eight
	
	;Calculate the breathing rate and display the result
	CALL	Compute_Table
	CALL	Display
	
	;Stop the system
	CALL	Capacitive_Touch_Stop
	CALL	LED_Delay
	CALL	Capacitive_Touch_Poll_Stop
	
	;Restart the system and wait for Capacitive Touch
	GOTO	Starting_State
	
;This subroutine is used to ensure that TMR4 is counting to insure that the 
; correct rollover value will be stored in the correct rollover variables. 
; Effectively, the subroutine sets the timer flag and clear the timer and 
; rollover variable
Clear_Timer
	MOVLW	.1
	MOVWF	Timer_Start
	CLRF	TMR4
	CLRF	Rollover
	RETURN

;This subroutine sets up the ADC for the start capacitive touch sensing to 
; allow the sensor to start the sensing. RC1 is used for sample and hold 
; capacitor charging and RB5 is used for the sensor input
Capacitive_Touch
	;Check for polling
	BTFSC	PORTD,2
	RETURN
	
	;Setup ADCON2
	MOVLW	b'00011101'  
	MOVWF	ADCON2
	
	;Setup ADCON1
	MOVLW	b'00000000' 
	MOVWF	ADCON1
	
	;Setup PORTC,2 to charge sample/hold capacitor
	BCF	TRISC,2
	BCF	ANSELC,2
	BSF	PORTC,2
	MOVLW	b'00111001'
	MOVWF	ADCON0	

	;ADCON0 Setup
	BSF	TRISC,5
	BSF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0

	RETURN

Capacitive_Touch_Poll_Start
	BSF 	ADCON0,GO	;Start conversion		
	MOVF	ADRESH,W	;Store Low value of ADRESH
	MOVWF	Lower
	BTFSC 	ADCON0,GO	;Has conversion finished yet		
	BRA 	$-2		;Wait until conversion is finished
Start_Conversion	
	MOVF 	ADRESH,W				
	MOVWF 	Higher		
	MOVF	Lower,W
	CPFSGT	Higher
	BRA	Capacitive_Touch_Poll_Start
	RETURN

;This subroutine sets up the ADC for the stop capacitive touch sensing to 
; allow the sensor to stop the sensing. RC1 is used for sample and hold 
; capacitor charging and RB5 is used for the sensor input
ADC_Change_Sensor
	MOVLB	0xF		    ;Change the bank register to setup timer
	CLRF	PORTC
	CLRF	LATC
	BCF	TRISC,1	
	
	;Start Timer
	BSF	T2CON,TMR2ON	    
	MOVLB	0x0		    ;Change the bank register back
	
	;ADCON2 Setup
	MOVLW	b'00011101'  
	MOVWF	ADCON2
	
	;ADCON0 Setup
	MOVLW	b'00110001'	    ;AN5 Channel is used for the ADC input. 
				    ; The Thermistor is connected to RB0
	MOVWF	ADCON0
	RETURN
	

;In this subroutine, I check to see if the patient has both exhaled and inhaled
; in order to move onto the next state of the code. If the patient has only
; inhlaed (or exhaled), the simply moves back to the Main subroutine and 
; continues polling until both inhalation and exhalation occurs
Check_Breathing
	MOVLW	.1
	CPFSEQ	Inhaling
	RETURN
	MOVLW	.1
	CPFSEQ	Exhaling
	RETURN
;Important to note for code understanding:
;The code measures half breaths. Therefore, the Move_State variable has to 
; increment twice in order to move into the next state.
Change_State   
	INCF	Move_State	
	CLRF	Exhaling
	CLRF	Inhaling
	RETURN

;Check to see if the patient is breathing. If breathing, poll through the ADC 
; and determine whether inhaling or exhaling and make computations dependent on
; the state of the patient
Poll_IN_OUT_Check
	BSF 	ADCON0,GO	;Start conversion		
	BTFSC 	ADCON0,GO	;Has conversion finished yet		
	BRA 	$-2 		;Wait until conversion is finished
	
;Populate the temporary vairable and compare it with the ADC threshold so that
; the code knows whether to move into exhale or inhale
Start_Conversion_Sensing	
	MOVF	ADRESH,W
	MOVWF	temp_Storage
	MOVF	Range,W
	CPFSEQ	temp_Storage
	GOTO	Wait_For_EQ
	GOTO	Poll_IN_OUT_Check
	
;This subroutine determines whether the patient is inhaling or exhaling. What 
; happens is if the temporary variable is lower than the threshold specified for
; the ADC, then the patient is exhaling and if it is greater than the threshold, 
; then the patient is inhaling
Wait_For_EQ
	CPFSGT	temp_Storage
	GOTO	Exhale
	GOTO	Inhale
	
;This subroutine is for when the patient is exhaling. When exhaling, the PWM
; duty cycle must firstly be particularly high to signify the breathing on the
; breathing LED and also to set the exhaling flag bit for further calculation
; for the sensor code
Exhale
	MOVLW	.18
	MOVWF	CCPR2L
	MOVLW	.1
	MOVWF	Exhaling
	RETURN
	
;This subroutine is for when the patient is inhaling. When inhaling, the PWM
; duty cycle must firstly be particularly low to signify the breathing on the
; breathing LED and also to set the inhaling flag bit for further calculation
; for the sensor code
Inhale
	MOVLW	.5
	MOVWF	CCPR2L
	MOVLW	.1
	MOVWF	Inhaling
	RETURN

;This subroutine sets up the ADC for the stop capacitive touch sensing to 
; allow the sensor to stop the sensing. RC1 is used for sample and hold 
; capacitor charging and RB5 is used for the sensor input
Capacitive_Touch_Stop
	;Turn off the PWM when the system is turned off
	BCF	T2CON,TMR2ON
	CLRF	CCPR2L
	
	;ADCON2 Setup
	MOVLW	b'00011101'  
	MOVWF	ADCON2
	
	;ADCON1 Setup
	MOVLW	b'00000000' 
	MOVWF	ADCON1
	
	;Setup PORTC,1 to charge sample/hold cap
	BCF	TRISC,3
	BCF	ANSELC,3
	BSF	PORTC,3
	MOVLW	b'00111001'
	MOVWF	ADCON0	

	;Setup the analog channel for the capacitive touch
	BSF	TRISC,5
	BSF	ANSELC,5
	MOVLW	b'01000101'
	MOVWF	ADCON0
	RETURN

Capacitive_Touch_Poll_Stop	
	BSF 	ADCON0,GO	;Start conversion		
	MOVF	ADRESH,W	;Store Low value of ADRESH
	MOVWF	Lower		
	BTFSC 	ADCON0,GO	;Has conversion finished yet		
	BRA 	$-2		;Wait until conversion is finished
Conversion_Test_STOP	
	MOVF 	ADRESH,W				
	MOVWF 	Higher		
	MOVF	Lower,W
	CPFSLT	Higher
	BRA	Capacitive_Touch_Poll_Start
	RETURN

;This subroutine marks the start of the state machine that will be implemented
; in order to measure and store eight different breathes with the purpose of 
; determining the average breathing rate of the patient, allowing for the 
; correct output to be displayed
Respiratory_Sensor
	MOVLW	0x0
	CPFSEQ	Move_State
	GOTO	Check_First
	RETURN	
	
;================== State 1 =====================
Check_First
	MOVLW	.2
	CPFSEQ	Move_State
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
	MOVLW	.4
	CPFSEQ	Move_State
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
	MOVLW	.6
	CPFSEQ	Move_State
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
	MOVLW	.8
	CPFSEQ	Move_State
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
	MOVLW	.10
	CPFSEQ	Move_State
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
	MOVLW	.12
	CPFSEQ	Move_State
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
	MOVLW	.14
	CPFSEQ	Move_State
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
	MOVLW	.16
	CPFSEQ	Move_State
	RETURN
	GOTO	Eighth_Breath
Eighth_Breath	
	MOVF	Rollover,W
	MOVWF	Eighth
	CLRF	Rollover
	CLRF	TMR4
	RETURN

;In the following two subroutines are used in order to populate the Average 
; variable and then dividing by eight in order to obtain the average over the 
; eight sensed values
Compute_Table
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	First
	RRNCF	First
	RRNCF	First
	MOVF	First,W
	ADDWF	Average,1
	
	;DIV 8 Second Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Second
	RRNCF	Second
	RRNCF	Second
	MOVF	Second,W
	ADDWF	Average,1
	
	;DIV 8 Third Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Third
	RRNCF	Third
	RRNCF	Third
	MOVF	Third,W
	ADDWF	Average,1
	
	;DIV 8 Fourth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Fourth
	RRNCF	Fourth
	RRNCF	Fourth
	MOVF	Fourth,W
	ADDWF	Average,1
	
	;DIV 8 Fifth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Fifth
	RRNCF	Fifth
	RRNCF	Fifth
	MOVF	Fifth,W
	ADDWF	Average,1
	
	;DIV 8 Sixth Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Sixth
	RRNCF	Sixth
	RRNCF	Sixth
	MOVF	Sixth,W
	ADDWF	Average,1
	
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Seventh
	RRNCF	Seventh
	RRNCF	Seventh
	MOVF	Seventh,W
	ADDWF	Average,1
	
	;DIV 8 First Breath, clear first 3 bits and add to Average
	CLRF	WREG
	RRNCF	Eighth
	RRNCF	Eighth
	RRNCF	Eighth
	MOVF	Eighth,W
	ADDWF	Average,1
	
	RETURN
	
;This subroutine checks to see which LED display to go to. What happens is that
; if Average is less than 12, the code branches to the Abnormal_Low subroutine
; and if Average is greater than 12, the code branches to the Low_Normal 
; subroutine
Display
	MOVLW	d'122'	    ;Rollover > 122 => Abnormal_Low 
	CPFSGT	Average
	GOTO	Low_Normal  ;Rollover < 122 => Low_Normal
	GOTO	Abnormal_Low
	
;This subroutine is a relatively low breathing rate but is still classified as
; a normal breathing rate according to the specified values, therefore, only the
; first LED on the PIC board is to be switched on.
Low_Normal
	BSF	PORTA,4
	MOVLW	d'92'	    ;Rollover > 92 => Display and Return
	CPFSGT	Average
	GOTO	High_Normal ;Rollover < 92 => High_Normal 
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
	
;This subroutine is a relatively high breathing rate, but is still classified 
; as a normal breathing rate, therefore, no issues and 2 LED should turn on
High_Normal
	BSF	PORTA,5
	MOVLW	d'73'	    ;Rollover > 73 => Display and Return
	CPFSGT	Average
	GOTO	Exercising  ;Rollover < 73 => Exercising
	BSF	PORTD,0
	BCF	PORTD,1
	RETURN
	
;This subroutine is for when the breathing rate is above average but below
; the exceptionally high threshold of the specified breathing ranges, therefore
; 3 LED should be displayed on the PIC board
Exercising
	BSF	PORTA,6
	MOVLW	d'49'		;Rollover > 49 => Display and Return
	CPFSGT	Average
	GOTO	Abnormal_High	;Rollover < 49 => Abnormal_High
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

;Short delay for general purposes
Short_Delay
	MOVLW   0xF
	MOVWF   Short1
S_Loop
	MOVLW   0xFF
	MOVWF   Short2
S_Loop2
	MOVLW   0xFF
	MOVWF   Short3
S_Loop3
	DECFSZ  Short3
	GOTO    S_Loop3
	DECFSZ  Short2
	GOTO    S_Loop2
	DECFSZ  Short1
	RETURN

;The Interrupt service routine will show firstly that all output LED's are 
; in working order. Secondly, the 
ISR	
;Check to see if the interrupt flag for the interrupt on change has been set
LED_Display
	BTFSC 	INTCON,RBIF
	GOTO	LED_Test
;Check to see if the timer interrupt flag has been set 
Timer_interrupt
	BTFSC 	PIR5,TMR4IF
	GOTO	Timer
	GOTO	Return_From_Interrupt
	
;This subroutine occurs when the test button RB4 is triggered in order to 
; signify that all the LEDs are in working condition for the system.
LED_Test
	MOVF	PORTB
	BSF	PORTA,4
	CALL	LED_Delay
	BSF	PORTA,5
	CALL	LED_Delay
	BSF	PORTA,6
	CALL	LED_Delay
	BSF	PORTA,7
	CALL	LED_Delay
Off 
	BCF	PORTA,4
	CALL	LED_Delay
	BCF	PORTA,5
	CALL	LED_Delay
	BCF	PORTA,6
	CALL	LED_Delay
	BCF	PORTA,7
	BCF	PORTD,0
	BCF	PORTD,1
	BRA	Return_From_Interrupt
	
;This subroutine in the ISR is used to identify how many breathes have been 
; within the measurement period of the breathing sensor
Timer	
	INCF	Rollover
	GOTO	Return_From_Interrupt
	
;Simply used to clear interrupt flags and exit the ISR
Return_From_Interrupt
	BCF 	INTCON,RBIF
	BCF	PIR5,TMR4IF
	RETFIE
	
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



