;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file cs.asm
;; @brief Módulo de configuración del sistema de reloj
;; @details Funciones para configuración del reloj de bajo consumo LFXT
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            .cdecls C,LIST,"msp430.h"       ; Incluye archivo de cabecera MSP430
            
;-------------------------------------------------------------------------------
            .text                           ; Sección de código
            .retain                         ; Preserva la sección en el enlace
            .retainrefs                     ; Preserva referencias a esta sección

	    	.global csIniLf                 


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @fn csIniLf
;; @brief Inicializa el reloj de baja frecuencia LFXT
;; @details Configura el oscilador de cristal externo de baja frecuencia (32.768kHz) 
;;          como fuente de reloj para ACLK
;; @param Ninguno
;; @return Ninguno
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

csIniLf     bic.b #BIT4,&PJSEL1             ; Configura pin PJ.4 como función LFXIN
            bis.b #BIT4,&PJSEL0             ; PJSEL0.4=1, PJSEL1.4=0 -> Función LFXIN
            mov.b #CSKEY_H,&CSCTL0_H        ; Desbloquea registro CS con clave de acceso
            bic.w #LFXTOFF,&CSCTL4          ; Activa oscilador LFXT

; Bucle de espera a que el oscilador se estabilice
EsperaLFXT  bic.w #LFXTOFFG,&CSCTL5	    	; Borra bandera de fallo del oscilador LFXT
	    	bic.w #OFIFG, &SFRIFG1          ; Borra bandera de fallo del oscilador global
            bit.w #LFXTOFFG,&CSCTL5         ; Comprueba si la bandera sigue activa
            jnz   EsperaLFXT                ; Si la bandera está activa, sigue esperando

            mov.b #0,&CSCTL0_H              ; Bloquea registros CS para protección
            ret                             ; Retorno al programa principal

