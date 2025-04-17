;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file st.asm
;; @brief Módulo del System Timer para control de tiempo
;; @details Implementa funciones para gestionar el tiempo del sistema mediante
;;          el temporizador Timer_A
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            .cdecls C,LIST,"msp430.h"       ; Incluye archivo de cabecera MSP430
            
;-------------------------------------------------------------------------------
            .text                           ; Sección de código
            .retain                         ; Preserva la sección en el enlace
            .retainrefs                     ; Preserva referencias a esta sección

			.bss         SystemTimer, 4     ; Variable SystemTimer de 4 Bytes
			.bss         stPeriodo, 2       ; Variable para guardar el periodo

			.global stIni, stTime, stSec

;-------------------------------------------------------------------------------------------------------------
;; @fn stIni
;; @brief Inicializa el System Timer para generar interrupciones periódicas
;; @details Configura el temporizador TA2 para funcionar con ACLK y generar
;;          interrupciones según el periodo especificado
;; @param R12 - Valor del periodo para el temporizador
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

stIni        mov.w     R12,    &stPeriodo   ; Guarda el periodo en variable global
             mov.w     #TASSEL__ACLK + ID__1 + MC__CONTINUOUS + TACLR,   &TA2CTL    ; Fuente ACLK + Modo Continuous +
                                                                                    ; + Divisor 1 + Reseteo del contador
             mov.w     R12, &TA2CCR0        ; Establece el valor de comparación
             bic.w     #CCIFG, &TA2CCTL0    ; Limpia la bandera de interrupción
             bis.w     #CCIE, &TA2CCTL0     ; Activa la interrupción en el registro
		     nop
		     eint                           ; Activa interrupciones globales
		     nop
		     ret



;-------------------------------------------------------------------------------------------------------------
;; @fn stA2ISR
;; @brief Rutina de servicio de interrupción para Timer2_A0
;; @details Incrementa el contador SystemTimer (32 bits) y ajusta el próximo valor
;;          de comparación. Sale del modo de bajo consumo.
;; @note No es necesario limpiar la bandera de interrupción en modo comparación (CCR0)
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

stA2ISR      add.w  	#1, &SystemTimer         ; Incrementa SystemTimer (parte baja)
			 addc.w 	#0, &SystemTimer+2       ; Si hay acarreo, incrementa parte alta
			 add.w      &stPeriodo, &TA2CCR0     ; Ajusta el siguiente valor de comparación
			 bic.w      #LPM4, 0(SP)             ; Sale de modo de bajo consumo
		     reti


;-------------------------------------------------------------------------------------------------------------
;; @fn stTime
;; @brief Obtiene el tiempo actual del sistema
;; @details Devuelve el valor actual del contador SystemTimer de 32 bits
;;          deshabilitando temporalmente las interrupciones para evitar inconsistencias
;; @param Ninguno
;; @return R12-R13 - Valor de 32 bits del contador de tiempo
;-------------------------------------------------------------------------------------------------------------

stTime  	mov.w 		SR, R14               ; Guarda estado actual de interrupciones
			nop
			dint                              ; Deshabilita interrupciones
			nop
   			mov.w 		&SystemTimer, 	R12   ; Lee parte baja de SystemTimer
   			mov.w 		&SystemTimer+2,	R13   ; Lee parte alta de SystemTimer
   			nop
   			mov.w 		R14, SR               ; Restaura estado previo de interrupciones
   			nop
   			ret

;-------------------------------------------------------------------------------------------------------------
;; @brief Vector de interrupción para Timer2_A0
;; @details Configuración del vector de interrupción para que salte a la rutina
;;          de servicio stA2ISR cuando ocurre una interrupción del temporizador
;-------------------------------------------------------------------------------------------------------------

	        .sect TIMER2_A0_VECTOR          ; Vector de interrupción Timer2_A0
	        .word stA2ISR                   ; Dirección de la rutina de servicio

