;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;; @file lcd.asm
;; @brief Módulo para el control del LCD del MSP430FR6989
;; @details Controla la pantalla LCD de 6 dígitos con representación de 14 segmentos,
;;          puntos separadores y símbolo de batería.
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

            .cdecls C,LIST,"msp430.h"       ; Incluye archivo de cabecera MSP430
            
;-------------------------------------------------------------------------------
            .text                           ; Sección de código
            .retain                         ; Preserva la sección en el enlace
            .retainrefs                     ; Preserva referencias a esta sección

            .global lcdIni, lcda2seg, lcdLPutc, lcdRPutc, lcdClear, lcdBat, Puntos

;-------------------------------------------------------------------------------------------------------------
;; @brief Definición de los registros del LCD
;; @details Mapeo de los registros para controlar los diferentes dígitos, 
;;          puntos y elementos del LCD
;-------------------------------------------------------------------------------------------------------------

; Registros de los 6 dígitos del LCD
DIG1L       .equ    LCDM10          ; Dígito 1 parte baja
DIG1H       .equ    LCDM11          ; Dígito 1 parte alta

DIG2L       .equ    LCDM6           ; Dígito 2 parte baja
DIG2H       .equ    LCDM7           ; Dígito 2 parte alta

DIG3L       .equ    LCDM4           ; Dígito 3 parte baja
DIG3H       .equ    LCDM5           ; Dígito 3 parte alta

DIG4L       .equ    LCDM19          ; Dígito 4 parte baja
DIG4H       .equ    LCDM20          ; Dígito 4 parte alta

DIG5L       .equ    LCDM15          ; Dígito 5 parte baja
DIG5H       .equ    LCDM16          ; Dígito 5 parte alta

DIG6L       .equ    LCDM8           ; Dígito 6 parte baja
DIG6H       .equ    LCDM9           ; Dígito 6 parte alta

; Registros de la batería
BATA        .equ    LCDM14          ; Registros para segmentos pares de batería
BATB        .equ    LCDM18          ; Registros para segmentos impares de batería
MARCOBAT    .equ    BIT4            ; Bit para el marco de la batería

; Registros de los puntos separadores
PUN1        .equ    LCDM20          ; Registro para primer punto
PUN2        .equ    LCDM7           ; Registro para segundo punto


;-------------------------------------------------------------------------------------------------------------
;; @fn lcdIni
;; @brief Inicializa el controlador LCD del MSP430FR6989
;; @details Configura los divisores de frecuencia, voltajes, modos de operación 
;;          y activa los pines necesarios para el LCD
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

lcdIni      bis.w   #LCDDIV__32,  &LCDCCTL0  ; Configura divisor de frecuencia a 32
            bis.w   #LCD4MUX,     &LCDCCTL0  ; Configura el LCD en modo 4-mux
            bis.w   #BIT1,        &LCDCCTL0  ; Modo de bajo consumo

            bis.w   #VLCD_2_60,   &LCDCVCTL  ; Voltaje VLCD a 2.60V
            bis.w   #BIT7,        &LCDCVCTL  ; Tensiones V2-V4 internas
            bis.w   #BIT3,        &LCDCVCTL  ; Bomba de carga activa

            bic.w   #R03EXT,      &LCDCVCTL  ; V5=0
            bis.w   #LCDCPCLKSYNC,&LCDCCPCTL ; Bomba de carga sincronizada

            ; ACTIVACIÓN DE PUERTOS LCD
            bis.w #LCDS4+LCDS6+LCDS7+LCDS8+LCDS9,&LCDCPCTL0             ; Puertos s4-9
            bis.w #LCDS10+LCDS11+LCDS12+LCDS13+LCDS14+LCDS15,&LCDCPCTL0 ; Puertos s10-15
            bis.w #LCDS16+LCDS17+LCDS18+LCDS19+LCDS20+LCDS21,&LCDCPCTL1 ; Puertos s16-21
            bis.w #LCDS27+LCDS28+LCDS29+LCDS30+LCDS31,&LCDCPCTL1        ; Puertos s27-31
            bis.w #LCDS35+LCDS36+LCDS37+LCDS38+LCDS39,&LCDCPCTL2        ; Puertos s35-39
            
            bis.w  #LCDCLRM|LCDCLRBM,  &LCDCMEMCTL  ; Borra pantalla
            bis.w  #LCDON,             &LCDCCTL0    ; Activa el LCD
            ret

;-------------------------------------------------------------------------------------------------------------
;; @fn lcdBat
;; @brief Controla los segmentos del indicador de batería
;; @details Activa un segmento específico de la batería manteniendo siempre encendido el marco
;; @param R12 - Número del segmento a activar (1-6)
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

lcdBat      cmp.b   #1,     R12
            jlo     finbat                  ; Si R12 < 1, termina
            cmp.b   #2,     R12
            jz      bateri2                 ; Si R12 = 2, activa segmento 2
            cmp.b   #3,     R12
            jz      bateri3                 ; Si R12 = 3, activa segmento 3
            cmp.b   #4,     R12
            jz      bateri4                 ; Si R12 = 4, activa segmento 4
            cmp.b   #5,     R12
            jz      bateri5                 ; Si R12 = 5, activa segmento 5
            cmp.b   #6,     R12
            jz      bateri6                 ; Si R12 = 6, activa segmento 6
            cmp.b   #7,     R12
            jhs     finbat                  ; Si R12 >= 7, termina

            ; Caso para segmento 1
            mov.b   #BIT5+MARCOBAT,&BATB    ; Activa segmento 1 y marco
            mov.b   #0+MARCOBAT,&BATA       ; Solo mantiene marco en BATA
            jmp     finbat

bateri2     mov.b   #BIT5+MARCOBAT,&BATA    ; Activa segmento 2 y marco
            mov.b   #0+MARCOBAT,&BATB       ; Solo mantiene marco en BATB
            jmp     finbat

bateri3     mov.b   #BIT6+MARCOBAT,&BATB    ; Activa segmento 3 y marco
            mov.b   #0+MARCOBAT,&BATA
            jmp     finbat

bateri4     mov.b   #BIT6+MARCOBAT,&BATA    ; Activa segmento 4 y marco
            mov.b   #0+MARCOBAT,&BATB
            jmp     finbat

bateri5     mov.b   #BIT7+MARCOBAT,&BATB    ; Activa segmento 5 y marco
            mov.b   #0+MARCOBAT,&BATA
            jmp     finbat

bateri6     mov.b   #BIT7+MARCOBAT,&BATA    ; Activa segmento 6 y marco
            mov.b   #0+MARCOBAT,&BATB
            jmp     finbat

finbat      ret


;-------------------------------------------------------------------------------------------------------------
;; @fn Puntos
;; @brief Controla el estado de los puntos separadores del reloj
;; @details Activa o desactiva los dos puntos que separan horas, minutos y segundos
;; @param R12 - Estado de los puntos (0=apagados, 1=encendidos)
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

Puntos      rrc.w   R12                     ; Desplaza bit 0 al carry
            jc      pntsOn                  ; Si carry=1, enciende puntos
            bic.b   #BIT2, &PUN1            ; Si carry=0, apaga puntos
            bic.b   #BIT2, &PUN2
            jmp     finpunt
pntsOn      bis.b   #BIT2, &PUN1            ; Enciende ambos puntos
            bis.b   #BIT2, &PUN2
finpunt     ret


;-------------------------------------------------------------------------------------------------------------
;; @fn lcda2seg
;; @brief Convierte un carácter ASCII a representación de 14 segmentos
;; @details Convierte caracteres imprimibles (códigos 32-127) a su representación
;;          de 14 segmentos según la configuración del LCD del LaunchPad
;; @param R12 - Código ASCII del carácter a convertir
;; @return R12 - Representación de 14 segmentos (o -1 si fuera de rango)
;-------------------------------------------------------------------------------------------------------------

lcda2seg    cmp.b   #0x80, R12              ; Verifica si R12 > 127
            jc      norango                 ; Si es mayor, fuera de rango
            sub.b   #0x20, R12              ; Resta 32 para ajustar índice
            jnc     norango                 ; Si R12 < 32, fuera de rango
            rla.b   R12                     ; Multiplica por 2 (cada caracter ocupa 2 bytes)
            mov.w   Tab14Seg(R12),R12       ; Obtiene representación de la tabla
            jmp     enrango
norango     mov.w   #-1, R12                ; Carácter fuera de rango
enrango     ret


;-------------------------------------------------------------------------------------------------------------
;; @fn lcdClear
;; @brief Borra el contenido del LCD
;; @details Limpia todos los segmentos de la pantalla LCD
;; @param Ninguno
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

lcdClear    bis.w   #LCDCLRM|LCDCLRBM,&LCDCMEMCTL  ; Borra memoria del LCD
            ret


;-------------------------------------------------------------------------------------------------------------
;; @fn lcdLPutc
;; @brief Desplaza el contenido del LCD a la izquierda y escribe un carácter a la derecha
;; @details Mueve el contenido actual un dígito a la izquierda y escribe el nuevo carácter
;;          en la posición más a la derecha (DIG6)
;; @param R12 - Código ASCII del carácter a escribir
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

lcdLPutc    call    #lcda2seg               ; Convierte ASCII a formato de segmentos
            cmp.w   #-1, R12                ; Verifica si es válido
            jz      finizq                  ; Si no es válido, termina
            clr.w   R13

            ; Desplaza los dígitos hacia la izquierda preservando bits especiales
            mov.b   &DIG2L, &DIG1L          ; DIG2 -> DIG1 (parte baja)
            and.b   #5, &DIG1H              ; Preserva bits especiales
            mov.b   &DIG2H, R13             ; Obtiene parte alta
            bic.b   #5, R13                 ; Limpia bits especiales
            bis.b   R13, &DIG1H             ; Combina con DIG1H

            mov.b   &DIG3L, &DIG2L          ; DIG3 -> DIG2
            and.b   #5, &DIG2H
            mov.b   &DIG3H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG2H

            mov.b   &DIG4L, &DIG3L          ; DIG4 -> DIG3
            and.b   #5, &DIG3H
            mov.b   &DIG4H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG3H

            mov.b   &DIG5L, &DIG4L          ; DIG5 -> DIG4
            and.b   #5, &DIG4H
            mov.b   &DIG5H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG4H

            mov.b   &DIG6L, &DIG5L          ; DIG6 -> DIG5
            and.b   #5, &DIG5H
            mov.b   &DIG6H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG5H

            ; Escribe nuevo carácter en DIG6
            mov.w   R12, R13                ; Prepara representación de segmentos
            and.b   #5, &DIG6H              ; Preserva bits especiales
            mov.b   R13, &DIG6L             ; Escribe parte baja
            swpb    R13                     ; Intercambia bytes
            and.w   #0x00FF, R13            ; Limpia byte alto
            bic.b   #5, R13                 ; Limpia bits especiales
            bis.b   R13, &DIG6H             ; Combina con DIG6H

finizq      ret


;-------------------------------------------------------------------------------------------------------------
;; @fn lcdRPutc
;; @brief Desplaza el contenido del LCD a la derecha y escribe un carácter a la izquierda
;; @details Mueve el contenido actual un dígito a la derecha y escribe el nuevo carácter
;;          en la posición más a la izquierda (DIG1)
;; @param R12 - Código ASCII del carácter a escribir
;; @return Ninguno
;-------------------------------------------------------------------------------------------------------------

lcdRPutc    call    #lcda2seg               ; Convierte ASCII a formato de segmentos
            cmp.b   #-1, R12                ; Verifica si es válido
            jz      findch                  ; Si no es válido, termina
            clr.w   R13

            ; Desplaza los dígitos hacia la derecha preservando bits especiales
            mov.b   &DIG5L, &DIG6L          ; DIG5 -> DIG6
            and.b   #5, &DIG6H              ; Preserva bits especiales
            mov.b   &DIG5H, R13             ; Obtiene parte alta
            bic.b   #5, R13                 ; Limpia bits especiales
            bis.b   R13, &DIG6H             ; Combina con DIG6H

            mov.b   &DIG4L, &DIG5L          ; DIG4 -> DIG5
            and.b   #5, &DIG5H
            mov.b   &DIG4H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG5H

            mov.b   &DIG3L, &DIG4L          ; DIG3 -> DIG4
            and.b   #5, &DIG4H
            mov.b   &DIG3H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG4H

            mov.b   &DIG2L, &DIG3L          ; DIG2 -> DIG3
            and.b   #5, &DIG3H
            mov.b   &DIG2H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG3H

            mov.b   &DIG1L, &DIG2L          ; DIG1 -> DIG2
            and.b   #5, &DIG2H
            mov.b   &DIG1H, R13
            bic.b   #5, R13
            bis.b   R13, &DIG2H

            ; Escribe nuevo carácter en DIG1
            mov.w   R12, R13                ; Prepara representación de segmentos
            and.b   #5, &DIG1H              ; Preserva bits especiales
            mov.b   R13, &DIG1L             ; Escribe parte baja
            swpb    R13                     ; Intercambia bytes
            and.w   #0x00FF, R13            ; Limpia byte alto
            bic.b   #5, R13                 ; Limpia bits especiales
            bis.b   R13, &DIG1H             ; Combina con DIG1H

findch      ret


;-------------------------------------------------------------------------------
;; @brief Tabla de conversión ASCII a 14 segmentos
;; @details Define la representación de 14 segmentos para cada carácter ASCII
;;          desde el espacio (32) hasta el carácter 127
;; @note Cada carácter requiere 2 bytes en formato abcdefgm hjkpq-n-
;-------------------------------------------------------------------------------

            ;       abcdefgm   hjkpq-n-
Tab14Seg    .byte   00000000b, 00000000b    ;Espacio (32)
            .byte   00000000b, 00000000b    ;! (33)
            .byte   00000000b, 00000000b    ;" (34)
            .byte   00000000b, 00000000b    ;# (35)
            .byte   00000000b, 00000000b    ;$ (36)
            .byte   00000000b, 00000000b    ;% (37)
            .byte   00000000b, 00000000b    ;& (38)
            .byte   00000000b, 00000000b    ;' (39)
            .byte   00000000b, 00000000b    ;( (40)
            .byte   00000000b, 00000000b    ;) (41)
            .byte   00000011b, 11111010b    ;* (42)
            .byte   00000011b, 01010000b    ;+ (43)
            .byte   00000000b, 00000000b    ;, (44)
            .byte   00000011b, 00000000b    ;- (45)
            .byte   00000000b, 00000000b    ;. (46)
            .byte   00000000b, 00101000b    ;/ (47)
            ;       abcdefgm   hjkpq-n-
            .byte   11111100b, 00101000b    ;0 (48)
            .byte   01100000b, 00100000b    ;1 (49)
            .byte   11011011b, 00000000b    ;2 (50)
            .byte   11110011b, 00000000b    ;3 (51)
            .byte   01100111b, 00000000b    ;4 (52)
                .byte   10110111b, 00000000b    ;5 (53)
            .byte   10111111b, 00000000b    ;6 (54)
            .byte   10000000b, 00110000b    ;7 (55)
            .byte   11111111b, 00000000b    ;8 (56)
            .byte   11100111b, 00000000b    ;9 (57)
            .byte   00000000b, 00000000b    ;: (58)
            .byte   00000000b, 00000000b    ;; (59)
            .byte   00000000b, 00100010b    ;< (60)
            .byte   00010011b, 00000000b    ;= (61)
            .byte   00000000b, 10001000b    ;> (62)
            .byte   00000000b, 00000000b    ;? (63)
            ;       abcdefgm   hjkpq-n-
            .byte   00000000b, 00000000b    ;@ (64)
            .byte   01100001b, 00101000b    ;A (65)
            .byte   11110001b, 01010000b    ;B (66)
            .byte   10011100b, 00000000b    ;C (67)
            .byte   11110000b, 01010000b    ;D (68)
            .byte   10011110b, 00000000b    ;E (69)
            .byte   10001110b, 00000000b    ;F (70)
            .byte   10111101b, 00000000b    ;G (71)
            .byte   01101111b, 00000000b    ;H (72)
            .byte   10010000b, 01010000b    ;I (73)
            .byte   01111000b, 00000000b    ;J (74)
            .byte   00001110b, 00100010b    ;K (75)
            .byte   00011100b, 00000000b    ;L (76)
            .byte   01101100b, 10100000b    ;M (77)
            .byte   01101100b, 10000010b    ;N (78)
            .byte   11111100b, 00000000b    ;O (79)
            ;       abcdefgm   hjkpq-n-
            .byte   11001111b, 00000000b    ;P (80)
            .byte   11111100b, 00000010b    ;Q (81)
            .byte   11001111b, 00000010b    ;R (82)
            .byte   10110111b, 00000000b    ;S (83)
            .byte   10000000b, 01010000b    ;T (84)
            .byte   01111100b, 00000000b    ;U (85)
            .byte   01100000b, 10000010b    ;V (86)
            .byte   01101100b, 00001010b    ;W (87)
            .byte   00000000b, 10101010b    ;X (88)
            .byte   00000000b, 10110000b    ;Y (89)
            .byte   10010000b, 00101000b    ;Z (90)
            .byte   10011100b, 00000000b    ;[ (91)
            .byte   00000000b, 10000010b    ;\ (92)
            .byte   11110000b, 00000000b    ;] (93)
            .byte   01000000b, 00100000b    ;^ (94)
            .byte   00010000b, 00000000b    ;_ (95)
            ;       abcdefgm   hjkpq-n-
            .byte   00000000b, 10000000b    ;` (96)
            .byte   00011010b, 00010000b    ;a (97)
            .byte   00111111b, 00000000b    ;b (98)
            .byte   00011011b, 00000000b    ;c (99)
            .byte   01111011b, 00000000b    ;d (100)
            .byte   11011111b, 00000000b    ;e (101)
            .byte   10001110b, 00000000b    ;f (102)
            .byte   11110111b, 00000000b    ;g (103)
            .byte   00101111b, 00000000b    ;h (104)
            .byte   00000000b, 00010000b    ;i (105)
            .byte   01110000b, 00000000b    ;j (106)
            .byte   00000000b, 01110010b    ;k (107)
            .byte   00000000b, 01010000b    ;l (108)
            .byte   00101011b, 00010000b    ;m (109)
            .byte   00101011b, 00000000b    ;n (110)
            .byte   00111011b, 00000000b    ;o (111)
            ;       abcdefgm   hjkpq-n-
            .byte   11001111b, 00000000b    ;p (112)
            .byte   11100111b, 00000000b    ;q (113)
            .byte   00000001b, 00010000b    ;r (114)
            .byte   10110111b, 00000000b    ;s (115)
            .byte   00010011b, 01010000b    ;t (116)
            .byte   00111000b, 00000000b    ;u (117)
            .byte   00100000b, 00000010b    ;v (118)
            .byte   00101000b, 00001010b    ;w (119)
            .byte   00000000b, 10101010b    ;x (120)
            .byte   01110001b, 01000000b    ;y (121)
            .byte   00010010b, 00001000b    ;z (122)
            .byte   00000000b, 00000000b    ;{ (123)
            .byte   00000000b, 00000000b    ;| (124)
            .byte   00000000b, 00000000b    ;} (125)
            .byte   00000000b, 00000000b    ;~ (126)
            .byte   00000000b, 00000000b    ;DEL (127)
