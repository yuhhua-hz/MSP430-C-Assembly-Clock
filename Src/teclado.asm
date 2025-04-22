;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file teclado.asm
;; @brief Módulo de gestión del teclado matricial para el MSP430FR6989
;; @details Implementa funciones para inicializar puertos, escanear y leer entradas 
;;          de un teclado matricial 4x4 conectado a puertos GPIO
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;-------------------------------------------------------------------------------
            .cdecls C,LIST,"msp430.h"       ; Incluye archivo de cabecera MSP430
            
;-------------------------------------------------------------------------------
            .text                           ; Sección de código
            .retain                         ; Preserva la sección en el enlace
            .retainrefs                     ; Preserva referencias a esta sección

            .global     kbIni, kbScan, kbGetc
            .bss        Tecla, 1           ; Variable para almacenar última tecla pulsada

;-------------------------------------------------------------------------------------------------------------
;; @brief Definiciones de constantes temporales
;; @details Parámetros para el control del tiempo anti-rebote
;-------------------------------------------------------------------------------------------------------------
frecACLK    .equ 32768               ; Frecuencia del reloj ACLK en Hz
frecEsp     .equ 100                 ; Frecuencia deseada para anti-rebote (100Hz = 10ms)
espera      .equ frecACLK/frecEsp    ; Cálculo de ciclos para el temporizador
                                     

;-------------------------------------------------------------------------------------------------------------
;; @brief Tabla de códigos ASCII para teclas del teclado matricial 4x4
;; @details Mapeo entre índices de teclas físicas y códigos ASCII o caracteres de control
;-------------------------------------------------------------------------------------------------------------
TabTeclas   .byte "1" ; tecla 0 - Número 1
            .byte "2" ; tecla 1 - Número 2
            .byte "3" ; tecla 2 - Número 3
            .byte  8  ; tecla 3 - DEL (Backspace)
            .byte "4" ; tecla 4 - Número 4
            .byte "5" ; tecla 5 - Número 5
            .byte "6" ; tecla 6 - Número 6
            .byte  8  ; tecla 7 - DEL (Backspace)
            .byte "7" ; tecla 8 - Número 7
            .byte "8" ; tecla 9 - Número 8
            .byte "9" ; tecla 10 - Número 9
            .byte  10 ; tecla 11 - INTRO (Line Feed)
            .byte  27 ; tecla 12 - ESC (Escape)
            .byte "0" ; tecla 13 - Número 0
            .byte  32 ; tecla 14 - EDIT (Espacio)
            .byte  10 ; tecla 15 - INTRO (Line Feed)


;-------------------------------------------------------------------------------------------------------------
;; @fn kbIni
;; @brief Inicializa los puertos GPIO para el teclado matricial 4x4
;; @details Configura las columnas como salidas y las filas como entradas con pull-up
;;          y habilita las interrupciones en flanco de bajada para las filas
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------
kbIni
           ;COLUMNAS (salida)
            bis.b  #BIT0, &P2DIR    ; Configura Columna 0: P2.0 como salida
            bic.b  #BIT0, &P2OUT    ; Establece valor inicial 0

            bis.b  #BIT3, &P9DIR    ; Configura Columna 1: P9.3 como salida
            bic.b  #BIT3, &P9OUT    ; Establece valor inicial 0

            bis.b  #BIT3, &P4DIR    ; Configura Columna 2: P4.3 como salida
            bic.b  #BIT3, &P4OUT    ; Establece valor inicial 0

            bis.b  #BIT2, &P9DIR    ; Configura Columna 3: P9.2 como salida
            bic.b  #BIT2, &P9OUT    ; Establece valor inicial 0

           ;FILAS (entrada)
            bic.b  #BIT2, &P3DIR    ; Configura Fila 0: P3.2 como entrada
            bis.b  #BIT2, &P3REN    ; Activa resistencia interna
            bis.b  #BIT2, &P3OUT    ; Configura resistencia como pull-up
            bis.b  #BIT2, &P3IES    ; Configura interrupción en flanco de bajada
            bic.b  #BIT2, &P3IFG    ; Limpia bandera de interrupción

            bic.b  #BIT7, &P4DIR    ; Configura Fila 1: P4.7 como entrada
            bis.b  #BIT7, &P4REN    ; Activa resistencia interna
            bis.b  #BIT7, &P4OUT    ; Configura resistencia como pull-up
            bis.b  #BIT7, &P4IES    ; Configura interrupción en flanco de bajada
            bic.b  #BIT7, &P4IFG    ; Limpia bandera de interrupción

            bic.b  #BIT4, &P2DIR    ; Configura Fila 2: P2.4 como entrada
            bis.b  #BIT4, &P2REN    ; Activa resistencia interna
            bis.b  #BIT4, &P2OUT    ; Configura resistencia como pull-up
            bis.b  #BIT4, &P2IES    ; Configura interrupción en flanco de bajada
            bic.b  #BIT4, &P2IFG    ; Limpia bandera de interrupción

            bic.b  #BIT5, &P2DIR    ; Configura Fila 3: P2.5 como entrada
            bis.b  #BIT5, &P2REN    ; Activa resistencia interna
            bis.b  #BIT5, &P2OUT    ; Configura resistencia como pull-up
            bis.b  #BIT5, &P2IES    ; Configura interrupción en flanco de bajada
            bic.b  #BIT5, &P2IFG    ; Limpia bandera de interrupción

            bis.b  #BIT2, &P3IE     ; Habilita interrupciones en los puertos de filas
            bis.b  #BIT7, &P4IE
            bis.b  #BIT4, &P2IE
            bis.b  #BIT5, &P2IE

            ret


;-------------------------------------------------------------------------------------------------------------
;; @fn kbScan
;; @brief Realiza un barrido del teclado matricial para detectar teclas pulsadas
;; @details Activa secuencialmente cada columna y verifica el estado de las filas
;;          para detectar pulsaciones. Retorna NULL si no hay tecla pulsada o si
;;          hay múltiples pulsaciones simultáneas.
;; @param Ninguno
;; @return R12 - Código ASCII de la tecla pulsada o NULL si ninguna/múltiples teclas
;-------------------------------------------------------------------------------------------------------------
kbScan      push.w R13              ; Guarda R13 en pila (contador de teclas)
            clr.w  R13              ; Inicializa contador de teclas a 0
            clr.w  R12              ; Inicializa índice de tecla a 0

            ;Desactivar COLUMNAS (todas como entrada)
            bic.b  #BIT0, &P2DIR    ; Configura columnas temporalmente como entradas
            bic.b  #BIT3, &P9DIR    ; para preparar el escaneo secuencial
            bic.b  #BIT3, &P4DIR
            bic.b  #BIT2, &P9DIR

            ; COLUMNA 0
            bis.b  #BIT0, &P2DIR    ; Activa Columna 0 como salida para el escaneo

tecla0      bit.b  #BIT2, &P3IN     ; Verifica pulsación de tecla 0 (número 1)
            jnz    tecla4           ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #0, R12          ; Guarda índice para la tabla

tecla4      bit.b  #BIT7, &P4IN     ; Verifica pulsación de tecla 4 (número 4)
            jnz    tecla8           ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #4, R12          ; Guarda índice para la tabla

tecla8      bit.b  #BIT4, &P2IN     ; Verifica pulsación de tecla 8 (número 7)
            jnz    tecla12          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #8, R12          ; Guarda índice para la tabla

tecla12     bit.b  #BIT5, &P2IN     ; Verifica pulsación de tecla 12 (ESC)
            jnz    finc0            ; Si no está pulsada, finaliza columna 0
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #12, R12         ; Guarda índice para la tabla

finc0       bic.b  #BIT0, &P2DIR    ; Desactiva Columna 0 (como entrada)

            ; COLUMNA 1
            bis.b  #BIT3, &P9DIR    ; Activa Columna 1 como salida para el escaneo

tecla1      bit.b  #BIT2, &P3IN     ; Verifica pulsación de tecla 1 (número 2)
            jnz    tecla5           ; Si no está pulsada, verifica siguiente tecla
            mov.w  #1, R12          ; Guarda índice para la tabla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas

tecla5      bit.b  #BIT7, &P4IN     ; Verifica pulsación de tecla 5 (número 5)
            jnz    tecla9           ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #5, R12          ; Guarda índice para la tabla

tecla9      bit.b  #BIT4, &P2IN     ; Verifica pulsación de tecla 9 (número 8)
            jnz    tecla13          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #9, R12          ; Guarda índice para la tabla

tecla13     bit.b  #BIT5, &P2IN     ; Verifica pulsación de tecla 13 (número 0)
            jnz    finc1            ; Si no está pulsada, finaliza columna 1
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #13, R12         ; Guarda índice para la tabla

finc1       bic.b  #BIT3, &P9DIR    ; Desactiva Columna 1 (como entrada)

            ; COLUMNA 2
            bis.b  #BIT3, &P4DIR    ; Activa Columna 2 como salida para el escaneo

tecla2      bit.b  #BIT2, &P3IN     ; Verifica pulsación de tecla 2 (número 3)
            jnz    tecla6           ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #2, R12          ; Guarda índice para la tabla

tecla6      bit.b  #BIT7, &P4IN     ; Verifica pulsación de tecla 6 (número 6)
            jnz    tecla10          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #6, R12          ; Guarda índice para la tabla

tecla10     bit.b  #BIT4, &P2IN     ; Verifica pulsación de tecla 10 (número 9)
            jnz    tecla14          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #10, R12         ; Guarda índice para la tabla

tecla14     bit.b  #BIT5, &P2IN     ; Verifica pulsación de tecla 14 (EDIT)
            jnz    finc2            ; Si no está pulsada, finaliza columna 2
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #14, R12         ; Guarda índice para la tabla

finc2       bic.b  #BIT3, &P4DIR    ; Desactiva Columna 2 (como entrada)

            ; COLUMNA 3
            bis.b  #BIT2, &P9DIR    ; Activa Columna 3 como salida para el escaneo

tecla3      bit.b  #BIT2, &P3IN     ; Verifica pulsación de tecla 3 (DEL)
            jnz    tecla7           ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #3, R12          ; Guarda índice para la tabla

tecla7      bit.b  #BIT7, &P4IN     ; Verifica pulsación de tecla 7 (DEL)
            jnz    tecla11          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #7, R12          ; Guarda índice para la tabla

tecla11     bit.b  #BIT4, &P2IN     ; Verifica pulsación de tecla 11 (INTRO)
            jnz    tecla15          ; Si no está pulsada, verifica siguiente tecla
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #11, R12         ; Guarda índice para la tabla

tecla15     bit.b  #BIT5, &P2IN     ; Verifica pulsación de tecla 15 (INTRO)
            jnz    finc3            ; Si no está pulsada, finaliza columna 3
            add.w  #1, R13          ; Incrementa contador de teclas pulsadas
            mov.w  #15, R12         ; Guarda índice para la tabla

finc3       bic.b  #BIT2, &P9DIR    ; Desactiva Columna 3 (como entrada)

            ; Determina valor a devolver y restaura estado de columnas
            mov.b  TabTeclas(R12), R12  ; Convierte índice a código ASCII
            cmp.w  #2, R13          ; Verifica si hay más de una tecla pulsada
            jc     ebarreo          ; Si hay múltiples teclas, devuelve NULL
            tst.w  R13              ; Verifica si no hay teclas pulsadas
            jnz    finbarreo        ; Si hay exactamente una tecla, continúa
ebarreo     clr.w  R12              ; Devuelve NULL (múltiples o ninguna tecla)
finbarreo   bis.b  #BIT0, &P2DIR    ; Restaura configuración normal de columnas
            bic.b  #BIT0, &P2OUT    ; como salidas con valor 0
            bis.b  #BIT3, &P9DIR    
            bic.b  #BIT3, &P9OUT    
            bis.b  #BIT3, &P4DIR    
            bic.b  #BIT3, &P4OUT    
            bis.b  #BIT2, &P9DIR    
            bic.b  #BIT2, &P9OUT    
            pop.w  R13              ; Restaura R13
            ret


;-------------------------------------------------------------------------------------------------------------
;; @fn kbGetc
;; @brief Obtiene el código de la última tecla pulsada y limpia el buffer
;; @details Lee y retorna el valor almacenado en la variable Tecla,
;;          luego borra dicho valor para futuras lecturas
;; @param Ninguno
;; @return R12 - Código ASCII de la última tecla pulsada o NULL si no hay tecla
;-------------------------------------------------------------------------------------------------------------
kbGetc    mov.b &Tecla, R12        ; Obtiene el código ASCII de la tecla almacenada
          clr.b &Tecla             ; Limpia el buffer para próximas lecturas
          ret

;-------------------------------------------------------------------------------------------------------------
;; @fn kbISR
;; @brief Rutina de servicio para la interrupción de pulsación de tecla
;; @details Desactiva temporalmente las interrupciones de puertos y configura
;;          el temporizador para comprobar la tecla una vez pasado el rebote
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------
kbISR
          bic.b  #BIT2, &P3IE         ; Desactiva interrupciones de puertos durante
          bic.b  #BIT7, &P4IE         ; el proceso de detección para evitar
          bic.b  #BIT4, &P2IE         ; lecturas erróneas por rebotes
          bic.b  #BIT5, &P2IE
          bic.b  #BIT2, &P3IFG        ; Limpia flags de interrupción
          bic.b  #BIT7, &P4IFG
          bic.b  #BIT4, &P2IFG
          bic.b  #BIT5, &P2IFG

          mov.w  &TA2R,   &TA2CCR1    ; Captura tiempo actual
          add.w  #espera, &TA2CCR1    ; Programa interrupción tras periodo anti-rebote
          bic.w  #CCIFG,  &TA2CCTL1   ; Limpia flag de interrupción del timer
          bis.w  #CCIE,   &TA2CCTL1   ; Activa interrupción del timer

          reti

;-------------------------------------------------------------------------------------------------------------
;; @fn kbRebote
;; @brief Rutina para procesar la tecla tras periodo anti-rebote
;; @details Ejecutada por la interrupción del timer, escanea el teclado 
;;          y almacena la tecla detectada en el buffer
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------
kbRebote  push.w R12
          call   #kbScan              ; Escanea el teclado para identificar la tecla
          mov.b  R12, &Tecla          ; Guarda código ASCII en el buffer
          bic.w  #CCIE,   &TA2CCTL1   ; Desactiva interrupción del timer
          bic.w  #CCIFG,  &TA2CCTL1   ; Limpia flag del timer

          bic.b  #BIT2, &P3IFG        ; Limpia flags de interrupción de puertos
          bic.b  #BIT7, &P4IFG
          bic.b  #BIT4, &P2IFG
          bic.b  #BIT5, &P2IFG

          bis.b  #BIT2, &P3IE         ; Reactiva interrupciones de puertos para
          bis.b  #BIT7, &P4IE         ; detectar nuevas pulsaciones
          bis.b  #BIT4, &P2IE
          bis.b  #BIT5, &P2IE

          pop.w  R12
          reti

;-------------------------------------------------------------------------------------------------------------
;; @brief Vectores de interrupción para el manejo del teclado
;; @details Asigna las rutinas de servicio a los vectores correspondientes
;-------------------------------------------------------------------------------------------------------------
          .intvec     TIMER2_A1_VECTOR, kbRebote  ; Timer2_A1 -> Rutina anti-rebote
          .intvec     PORT2_VECTOR,     kbISR     ; Puerto 2 -> Rutina de detección
          .intvec     PORT3_VECTOR,     kbISR     ; Puerto 3 -> Rutina de detección
          .intvec     PORT4_VECTOR,     kbISR     ; Puerto 4 -> Rutina de detección
