/**
 * @file task.c
 * @brief Implementación de tareas del sistema de reloj digital
 * @details Contiene las implementaciones de las diferentes tareas
 *          que componen el sistema de reloj: LEDs, batería, puntos,
 *          reloj y manejo de teclado para edición de hora.
 */

#include <msp430fr6989.h>
#include <stdio.h>
#include <stdint.h>
#include "task.h"
#include "lcd.h"
#include "cs.h"
#include "lpiu.h"
#include "st.h"
#include "teclado.h"


static Tiempo_t ahora = {0};  // Estructura que representa el "ahora"
static Modos_e modo = VISUAL; // Modos de la aplicacion puede ser VISUAL/EDICION

/**
 * @brief Controla el parpadeo de los LEDs
 * @details Esta tarea activa los LEDs alternadamente cuando el sistema está en modo EDICION
 *          y los mantiene apagados en modo VISUAL
 * @return Ninguno
 */
void tareaLed(void)
{
    static uint32_t ProximaEjec = 0;
    static boolean estadoLed = 0;

    if (stTime() >= ProximaEjec) {
        ProximaEjec += periodoLed;

        // Solo activamos los LEDs en modo EDICION
        if (modo == EDICION) {
            ledSet1(estadoLed);
            estadoLed = !estadoLed;
            ledSet2(estadoLed);
        }
    }
} 

/**
 * @brief Controla la animación del indicador de batería
 * @details Anima los segmentos de la batería mostrando un desplazamiento
 *          bidireccional que cambia de velocidad según la fase de animación
 * @return Ninguno
 */
void tareaBateria(void)
{
    static uint32_t ProximaEjec = 0;
    static boolean desplz_hacia = DERECHA;
    static uint8_t posicion_segmento = 0; // Posicion de cada segmento LCD bateria
    static uint8_t fase_animacion = 0;    // Controla la fase de la animacion
    static uint8_t factor = 1;            // Factor de velocidad de la animacion

    if (stTime() >= ProximaEjec) {
        // Actualizar el factor según la fase de animacion actual
        switch(fase_animacion) {
            case 0: factor = 1; break; // 2Hz
            case 1: factor = 2; break; // 4Hz
            case 2: factor = 4; break; // 8Hz
            case 3: factor = 8; break; // 16Hz
        }

        ProximaEjec += periodoBateria / factor;

        lcdBat(posicion_segmento); // Actualizar la bateria

        // Actualizar la posición según la dirección
        if (desplz_hacia == DERECHA) {
            posicion_segmento++;

            if (posicion_segmento == 7) {
                posicion_segmento = 6;
                desplz_hacia = IZQUIERDA;
                fase_animacion++;
                if (fase_animacion == 1) factor = 2;
                if (fase_animacion == 3) factor = 8;
            }
        }
        else { // Desplazamiento hacia la izquierda
            posicion_segmento--;

            if (posicion_segmento == 0) {
                posicion_segmento = 1;
                desplz_hacia = DERECHA;
                fase_animacion++;
                if (fase_animacion == 2) factor = 4;
                if (fase_animacion > 3) {
                    fase_animacion = 0;
                    factor = 1;
                }
            }
        }
    }
}

/**
 * @brief Controla el parpadeo de los puntos separadores del reloj
 * @details En modo VISUAL, hace parpadear los puntos separadores (:) del reloj.
 *          En modo EDICION, los puntos permanecen apagados.
 * @return Ninguno
 */
void tareaPuntos(void)
{
    static uint32_t ProximaEjec = 0;
    static boolean estadoPuntos = 0;

    if (stTime() >= ProximaEjec) {
        ProximaEjec += periodoPuntos;

        switch(modo) {
            case VISUAL: 
                // En modo VISUAL, los puntos parpadean
                Puntos(estadoPuntos);
                estadoPuntos = !estadoPuntos;
                break;
                
            case EDICION:
                // En modo EDICION, los puntos permanecen apagados
                Puntos(0);
                estadoPuntos = 0;
                break;
        }
    }
}

/**
 * @brief Actualiza la visualización y gestión del tiempo
 * @details Actualiza los contadores de horas, minutos y segundos, y
 *          actualiza la visualización en el LCD cuando está en modo VISUAL
 * @return Ninguno
 */
void tareaReloj(void) 
{
    static uint32_t ProximaEjec = 0;

    if (stTime() >= ProximaEjec) {
        ProximaEjec += periodoReloj;
        
        // Si estamos en modo visualizacion, actualizar la pantalla
        if (modo == VISUAL) {
            lcdLPutc('0' + ahora.horas / 10);
            lcdLPutc('0' + ahora.horas % 10);
            lcdLPutc('0' + ahora.minutos / 10);
            lcdLPutc('0' + ahora.minutos % 10);
            lcdLPutc('0' + ahora.segundos / 10);
            lcdLPutc('0' + ahora.segundos % 10);
        }
        
        // Actualizar los contadores de tiempo independientemente del modo
        ahora.segundos++;
        if (ahora.segundos >= 60) { // Si se sobrepasa el limite resetear y aumentar el siguiente contador
            ahora.segundos = 0;
            ahora.minutos++;

            if (ahora.minutos >= 60) {
                ahora.minutos = 0;
                ahora.horas++;

                if (ahora.horas >= 24) {
                    ahora.horas = 0;
                }
            }
        }

    }
}
   
/**
 * @brief Gestiona la entrada de teclado para visualizar y editar la hora
 * @details Permite cambiar entre modos VISUAL y EDICION.
 *          En modo EDICION permite introducir una nueva hora siguiendo
 *          el formato HH:MM:SS con validación para cada dígito.
 *          Procesa teclas especiales: INTRO (confirmar), ESC (cancelar), DEL (borrar).
 * @return Ninguno
 */
void tareaTeclado(void)
{
    static uint32_t ProximaEjec = 0;
    static int tecla;
    static uint8_t tiempo_buffer[6] = {0};
    static uint8_t digito = 1;  // Controla la posicion del digito se esta editando [1-7)

    if (stTime() >= ProximaEjec) {
        ProximaEjec += periodoTeclado;
        tecla = kbGetc();  // Leer la tecla pulsada

        // Si estamos en modo EDICION y se ha pulsado una tecla numerica valida
        if (modo == EDICION && tecla >= '0') {

            // Representacion visual HH:MM:SS
            // Primer digito. Perimitido 0, 1, 2
            if (digito == 1 && tecla <= '2') {
                lcdLPutc(tecla);
                tiempo_buffer[0] = tecla;
                digito = 2;
            }
            
            // Segundo digito
            else if (digito == 2) {
                // Si el digito anterior inferior a 2 podemos tener 0-9
                if (tiempo_buffer[0] < '2' && tecla <= '9') {
                    lcdLPutc(tecla);
                    tiempo_buffer[1] = tecla;
                    digito = 3;
                }
                // Si el digito anterior es un 2 entonces solo podemos tener 1-3
                else if (tiempo_buffer[0] == '2' && tecla <= '3') {
                    lcdLPutc(tecla);
                    tiempo_buffer[1] = tecla;
                    digito = 3;
                }
            }
            
            // Tercer digito permitidos 0-5
            else if (digito == 3 && tecla <= '5') {
                lcdLPutc(tecla);
                tiempo_buffer[2] = tecla;
                digito = 4;
            }
            
            // Cuarto digito permitidos 0-9
            else if (digito == 4 && tecla <= '9') {
                lcdLPutc(tecla);
                tiempo_buffer[3] = tecla;
                digito = 5;
            }
            
            // Quinto digito permitidos 0-5
            else if (digito == 5 && tecla <= '5') {
                lcdLPutc(tecla);
                tiempo_buffer[4] = tecla;
                digito = 6;
            }
            
            // Sexto digito permitidos 0-9
            else if (digito == 6 && tecla <= '9') {
                lcdLPutc(tecla);
                tiempo_buffer[5] = tecla;
                digito = 7;  // Se han introducido todos los digitos
            }
        }

        // Tecla INTRO: confirmar la hora introducida
        if (tecla == INTRO && digito == 7) {
            modo = VISUAL;
            digito = 1;
            
            // Convertir los valores ASCII a enteros
            ahora.horas = (tiempo_buffer[0] - '0') * 10 + tiempo_buffer[1] - '0';
            ahora.minutos = (tiempo_buffer[2] - '0') * 10 + tiempo_buffer[3] - '0';
            ahora.segundos = (tiempo_buffer[4] - '0') * 10 + tiempo_buffer[5] - '0';
        }
        
        // Tecla EDIT: entrar en modo edición
        if (tecla == EDIT && modo == VISUAL) {
            modo = EDICION;
            digito = 1;
            
            Puntos(0); // Apagar los puntos en modo edicion
            
            // Limpiar la pantalla imprimiendo espacios
            lcdLPutc(' ');
            lcdLPutc(' ');
            lcdLPutc(' ');
            lcdLPutc(' ');
            lcdLPutc(' ');
            lcdLPutc(' ');
        }
        
        // Tecla ESC: salir del modo edición sin guardar cambios
        else if (tecla == ESC) {
            modo = VISUAL;
            digito = 1;
        }
        
        // Tecla DEL: borrar el último digito introducido
        else if (tecla == DEL && modo == EDICION) {
            if (digito > 1 && digito <= 7) {
                digito--;
                lcdRPutc(' ');
            }
        }
    }
}

