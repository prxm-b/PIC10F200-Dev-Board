PROCESSOR 10F200
#include <xc.inc>

config WDTE = OFF, CP = OFF, MCLRE = OFF

; --- VARIABLES ---
MODE        EQU 0x10    ; 0:Off, 1:50%, 2:100%, 3:SOS
BRIGHTNESS  EQU 0x11
PWM_CNT     EQU 0x12
TEMP        EQU 0x13
DELAY_HI    EQU 0x14
DELAY_LO    EQU 0x15

PSECT code,class=CODE,delta=2,abs
org 0x00

start:
    MOVWF   OSCCAL
    MOVLW   0           ; Pas de T0CKI, pas de Pull-ups
    OPTION
    MOVLW   0xFE        ; GP0=Sortie, GP1-3=Entrées
    TRIS    GPIO
    CLRF    MODE

main_loop:
    ; --- 1. GESTION DU BOUTON (GP3) ---
    BTFSS   GPIO, 3     ; Bouton pressé ? (High)
    GOTO    run_mode    ; Non, on continue le mode actuel
    
    ; Anti-rebond (Debounce)
    CALL    delay_20ms
    BTFSS   GPIO, 3     ; Toujours pressé ?
    GOTO    run_mode
    
    ; Incrémenter le mode (0 -> 1 -> 2 -> 3 -> 0)
    INCF    MODE, f
    MOVLW   4
    XORWF   MODE, W
    BTFSC   STATUS, 2   ; Si MODE == 4
    CLRF    MODE        ; Reset à 0
    
wait_release:           ; Attendre que l'utilisateur relâche le bouton
    BTFSC   GPIO, 3
    GOTO    wait_release
    CALL    delay_20ms

run_mode:
    ; --- 2. EXECUTION DES MODES ---
    MOVF    MODE, W
    BTFSC   STATUS, 2   ; Mode 0 ?
    GOTO    mode_off
    
    XORLW   1           ; Mode 1 ?
    BTFSC   STATUS, 2
    GOTO    mode_50
    
    MOVF    MODE, W
    XORLW   2           ; Mode 2 ?
    BTFSC   STATUS, 2
    GOTO    mode_100
    
    GOTO    mode_sos    ; Sinon, Mode 3 (SOS)

; --- DÉFINITION DES MODES ---

mode_off:
    BCF     GPIO, 0
    GOTO    main_loop

mode_50:
    MOVLW   128         ; 50% de 255
    MOVWF   BRIGHTNESS
    CALL    do_pwm_frame
    GOTO    main_loop

mode_100:
    BSF     GPIO, 0     ; 100% (Allumé fixe)
    GOTO    main_loop

mode_sos:
    ; SOS : ... --- ...
    CALL    send_s      ; . . .
    CALL    send_o      ; - - -
    CALL    send_s      ; . . .
    CALL    long_delay  ; Espace entre les messages
    GOTO    main_loop

; --- SOUS-ROUTINES ---

do_pwm_frame:           ; Un petit cycle de PWM pour le 50%
    MOVLW   100
    MOVWF   PWM_CNT
pwm_loop:
    MOVF    BRIGHTNESS, W
    SUBWF   PWM_CNT, W
    BTFSS   STATUS, 0
    BSF     GPIO, 0
    BTFSC   STATUS, 0
    BCF     GPIO, 0
    DECFSZ  PWM_CNT, f
    GOTO    pwm_loop
    RETURN

; --- MORSE OPS ---
send_s:
    CALL    dot : CALL    dot : CALL    dot
    CALL    long_delay : RETURN
send_o:
    CALL    dash : CALL    dash : CALL    dash
    CALL    long_delay : RETURN

dot:
    BSF     GPIO, 0 : CALL    short_delay
    BCF     GPIO, 0 : CALL    short_delay
    RETURN
dash:
    BSF     GPIO, 0 : CALL    long_delay
    BCF     GPIO, 0 : CALL    short_delay
    RETURN

; --- DÉLAIS ---
delay_20ms:             ; Simple délai pour le bouton
    MOVLW   20
    MOVWF   DELAY_HI
d1: MOVLW   255
    MOVWF   DELAY_LO
d2: DECFSZ  DELAY_LO, f
    GOTO    d2
    DECFSZ  DELAY_HI, f
    GOTO    d1
    RETURN

short_delay: MOVLW 1 : GOTO base_delay
long_delay:  MOVLW 3 : GOTO base_delay

base_delay:             ; Délai ajustable pour le Morse
    MOVWF   TEMP
b1: CALL    delay_20ms
    CALL    delay_20ms
    CALL    delay_20ms
    DECFSZ  TEMP, f
    GOTO    b1
    RETURN

END start