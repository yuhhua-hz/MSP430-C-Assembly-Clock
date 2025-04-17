/**
 * @file main.c
 * @brief Programa principal del sistema de reloj digital
 * @details Inicializa los periféricos necesarios y ejecuta el bucle principal
 *          que gestiona las diferentes tareas del sistema de reloj.
 */

#include <msp430fr6989.h>
#include "task.h"
#include "lcd.h"
#include "cs.h"
#include "lpiu.h"
#include "st.h"
#include "teclado.h"

int main(void)
{
	WDTCTL = WDTPW | WDTHOLD;   // Parar el watchdog
	PM5CTL0 &= ~LOCKLPM5;       // Desbloquear los puertos

	// Inicializar reloj, System Timer, LCD, teclado y LEDs
	csIniLf();
    stIni(periodo);
    lcdIni();
    kbIni();
    ledIni1();
    ledIni2();

	while(1) {
		tareaReloj();    /**< Actualiza y muestra la hora */
		tareaTeclado();  /**< Gestiona la entrada del teclado */
		tareaBateria();  /**< Actualiza la animación de la batería */
		tareaPuntos();   /**< Controla el parpadeo de los puntos separadores */
		tareaLed();      /**< Gestiona el estado de los LEDs */
		LPM3;            /**< Modo de bajo consumo hasta próxima interrupción */
	}

}

