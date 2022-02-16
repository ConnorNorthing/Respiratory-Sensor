    list        p=PIC18f45K22
    #include    "p18f45K22.inc"
    
;========== Configuration bits ==========
  CONFIG  FOSC = INTIO67        ; Oscillator Selection bits (Internal oscillator block, port function on RA6 and RA7)
  CONFIG  WDTEN = OFF           ; Watchdog Timer Enable bit (WDT is controlled by SWDTEN bit of the WDTCON register)
  CONFIG  LVP = ON
  
    cblock  0x00
	High_Volt
	Low_Volt
	Threshold
	Range
	Current
	In_Flag
	Out_Flag
	temp_Storage
	High
	Low
	Count
    endc
    
    org	    0h
    GOTO    INIT
    
INIT
    CLRF    Low_Volt
    CLRF    High_Volt
    CLRF    Threshold
    CLRF    Range
    CLRF    WREG
    CLRF    Current
    CLRF    In_Flag
    CLRF    Out_Flag
    
Main
    MOVLW   0x02
    MOVWF   Count
    CALL    Calibration
    DECFSZ  Count
    GOTO    Main
    CALL    Threshold_Calculation
    GOTO    Stop
Stop
    GOTO    Stop
    
Calibration
    MOVLW   0x99
    MOVWF   Current
    
    ;Setup the ADC to accept input values
    MOVLB   0xF		    ;Change the bank register to setup timer
    CLRF    PORTC
    CLRF    LATC
    BCF	    TRISC,1	
    MOVLB   0x00
	
    ;ADCON2 Setup
    MOVLW   b'00011101'  
    MOVWF   ADCON2
	
    ;ADCON0 Setup
    MOVLW   b'00110001'	    ;AN5 Channel is used for the ADC input. 
			    ; The Thermistor is connected to RB0
    MOVWF   ADCON0
    
Poll_IN_OUT_Check
    BSF	    ADCON0,GO	;Start conversion
    BTFSC   ADCON0,GO	;Has conversion finished yet		
    BRA	    $-2 	;Wait until conversion is finished
Start_Conversion_Sensing	
    MOVF    ADRESH,W
    MOVWF   temp_Storage
    MOVF    Current,W
    CPFSLT  temp_Storage
    GOTO    Exhale_Calibration
    GOTO    Inhale_Calibration
    
Inhale_Calibration
    MOVF    Current,W
    CPFSLT  temp_Storage
    GOTO    Exhale_Calibration
    MOVF    temp_Storage,W
    MOVWF   Low_Volt
    MOVWF   Current
    RETURN

Exhale_Calibration
    MOVF    Current,W
    CPFSGT  temp_Storage
    GOTO    Inhale_Calibration
    MOVWF   High_Volt
    MOVWF   Current
    RETURN
    
Threshold_Calculation
    RRNCF   Low_Volt
    MOVF    Low_Volt,W
    ADDWF   Threshold,1
    
    RRNCF   High_Volt
    MOVF    High_Volt,W
    ADDWF   Threshold,1
    
    MOVF    Threshold,W
    MOVWF   Range
    
    RETURN
    
    end
    