PROCESSOR 10F200
#include <xc.inc>

; --- CONFIGURATION ---
config WDTE = OFF, CP = OFF, MCLRE = OFF

; --- VARIABLES RAM ---
BRIGHTNESS  EQU 0x10    ; Niveau de luminosité actuel (0 à 255)
COUNTER     EQU 0x11    ; Compteur pour la période PWM
DELAY_VAL   EQU 0x12    ; Délai pour la vitesse de l'effet
DIRECTION   EQU 0x13    ; 0 = augmente, 1 = diminue

PSECT code,class=CODE,delta=2,abs
org 0x00

start:
    MOVWF   OSCCAL      ; Calibration d'usine
    MOVLW   0           ; Mode Digital I/O
    OPTION
    MOVLW   0xFE        ; GP0 en sortie
    TRIS    GPIO
    
    CLRF    BRIGHTNESS
    CLRF    DIRECTION

main_loop:
    ; --- GÉNÉRATION PWM (1 cycle complet) ---
    ; On compare COUNTER à BRIGHTNESS pour décider d'allumer ou éteindre
    MOVLW   255
    MOVWF   COUNTER
    
pwm_loop:
    MOVF    BRIGHTNESS, W
    SUBWF   COUNTER, W  ; W = COUNTER - BRIGHTNESS
    
    BTFSC   STATUS, 0   ; Test du Carry bit (C=1 si COUNTER >= BRIGHTNESS)
    BCF     GPIO, 0     ; Éteindre LED
    BTFSS   STATUS, 0   ; Test du Carry bit (C=0 si COUNTER < BRIGHTNESS)
    BSF     GPIO, 0     ; Allumer LED
    
    DECFSZ  COUNTER, f
    GOTO    pwm_loop

    ; --- VITESSE DE L'EFFET ---
    ; On ne change la luminosité que tous les X cycles PWM
    DECFSZ  DELAY_VAL, f
    GOTO    main_loop
    MOVLW   1           ; Ajustez cette valeur pour changer la vitesse
    MOVWF   DELAY_VAL

    ; --- LOGIQUE DE GRADATION (FADE) ---
    BTFSC   DIRECTION, 0
    GOTO    decrease
    
increase:
    INCF    BRIGHTNESS, f
    MOVLW   254
    XORWF   BRIGHTNESS, W
    BTFSC   STATUS, 2   ; Si BRIGHTNESS == 254
    BSF     DIRECTION, 0 ; On change de direction
    GOTO    main_loop

decrease:
    DECF    BRIGHTNESS, f
    MOVLW   1
    XORWF   BRIGHTNESS, W
    BTFSC   STATUS, 2   ; Si BRIGHTNESS == 1
    BCF     DIRECTION, 0 ; On repasse en mode augmentation
    GOTO    main_loop

END start