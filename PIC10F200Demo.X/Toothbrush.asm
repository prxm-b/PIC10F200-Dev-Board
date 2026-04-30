PROCESSOR 10F200
#include <xc.inc>

; --- CONFIGURATION ---
config WDTE = OFF, CP = OFF, MCLRE = OFF

; --- VARIABLES RAM ---
PSECT udata,class=RAM,space=1,abs
org 0x10
SEC_COUNT:   DS 1
SEC_TICK:    DS 1
INNER_LOOP:  DS 1
TEMP:        DS 1

; --- CODE ---
PSECT code,class=CODE,delta=2,abs
org 0x00

start:
    MOVWF   OSCCAL
    MOVLW   0       
    OPTION
    MOVLW   0xFE    ; GP0 out, GP3 in
    TRIS    GPIO
    BCF     GPIO, 0 

wait_press:
    ; 1. ATTENTE DE L'APPUI (GP3 passe à 1)
    BTFSS   GPIO, 3 
    GOTO    wait_press
    
    ; 2. SÉCURITÉ : ATTENTE DU RELÂCHEMENT
    ; On ne démarre que quand tu lâches le bouton
    CALL    debounce
wait_release_start:
    BTFSC   GPIO, 3 
    GOTO    wait_release_start
    CALL    debounce
    
    ; --- INITIALISATION DU TIMER ---
    MOVLW   120     ; 2 minutes
    MOVWF   SEC_COUNT
    BSF     GPIO, 0 ; Allumage LED

timer_loop:
    MOVLW   10      
    MOVWF   SEC_TICK

second_block:
    ; 3. TEST DU RÉ-APPUI POUR ÉTEINDRE
    BTFSC   GPIO, 3
    GOTO    force_stop
    
    CALL    delay_100ms
    
    DECFSZ  SEC_TICK, f
    GOTO    second_block

    ; --- TEST DU GLITCH (60 SEC) ---
    MOVLW   60
    XORWF   SEC_COUNT, W
    BTFSS   STATUS, 2 
    GOTO    check_end
    
    BCF     GPIO, 0
    CALL    delay_100ms
    BSF     GPIO, 0
    CALL    delay_100ms
    BCF     GPIO, 0
    CALL    delay_100ms
    BSF     GPIO, 0

check_end:
    DECFSZ  SEC_COUNT, f
    GOTO    timer_loop

force_stop:
    BCF     GPIO, 0
    CALL    debounce
    
    ; Attendre que le bouton soit relâché avant de pouvoir relancer
wait_final_release:
    BTFSC   GPIO, 3
    GOTO    wait_final_release
    CALL    debounce
    GOTO    wait_press

; --- SOUS-ROUTINES ---

delay_100ms:
    MOVLW   200
    MOVWF   INNER_LOOP
d100_1:
    MOVLW   165
    MOVWF   TEMP
d100_2:
    DECFSZ  TEMP, f
    GOTO    d100_2
    DECFSZ  INNER_LOOP, f
    GOTO    d100_1
    RETLW   0

debounce:
    MOVLW   255
    MOVWF   TEMP
db_1:
    DECFSZ  TEMP, f
    GOTO    db_1
    RETLW   0

END start