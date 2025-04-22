;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file lpiu.asm
;; @brief Módulo de control de dispositivos de entrada/salida de bajo consumo
;; @details Contiene funciones para controlar LEDs
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            .cdecls C,LIST,"msp430.h"       ; Incluye archivo de cabecera MSP430
            
;-------------------------------------------------------------------------------
            .text                           ; Sección de código
            .retain                         ; Preserva la sección en el enlace
            .retainrefs                     ; Preserva referencias a esta sección

            .global ledIni1, ledIni2, ledSet1, ledSet2
            
;-------------------------------------------------------------------------------------------------------------
;; @fn ledIni1
;; @brief Inicializa el LED1 (rojo) del MSP430FR6989
;; @details Configura el pin P1.0 como salida para controlar el LED1
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------
            
ledIni1     bis.b   #BIT0, &P1DIR       ; P1.0 como salida (LED1 rojo)
            bic.b   #BIT0, &P1OUT       ; LED1 apagado
            ret

;-------------------------------------------------------------------------------------------------------------
;; @fn ledIni2
;; @brief Inicializa el LED2 (verde) del MSP430FR6989
;; @details Configura el pin P9.7 como salida para controlar el LED2
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

ledIni2     bis.b   #BIT7, &P9DIR       ; P9.7 como salida (LED2 verde)
            bic.b   #BIT7, &P9OUT       ; LED2 apagado
            ret

;-------------------------------------------------------------------------------------------------------------
;; @fn ledSet1
;; @brief Controla el estado del LED1 (rojo)
;; @details Enciende o apaga el LED1 según el valor del parámetro
;; @param R12 - Estado del LED (0=apagado, 1=encendido)
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

ledSet1     rrc.w    R12                ; Desplaza bit 0 a Carry
            jnc      led1off            ; Si carry=0, apagar LED
            bis.b    #BIT0, &P1OUT      ; Si carry=1, encender LED
            ret
led1off     bic.b    #BIT0, &P1OUT      ; Apagar LED
            ret

;-------------------------------------------------------------------------------------------------------------
;; @fn ledSet2
;; @brief Controla el estado del LED2 (verde)
;; @details Enciende o apaga el LED2 según el valor del parámetro
;; @param R12 - Estado del LED (0=apagado, 1=encendido)
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

ledSet2     rrc.w    R12                ; Desplaza bit 0 a Carry
            jnc      led2off            ; Si carry=0, apagar LED
            bis.b    #BIT7, &P9OUT      ; Si carry=1, encender LED
            ret
led2off     bic.b    #BIT7, &P9OUT      ; Apagar LED
            ret
