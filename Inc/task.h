#ifndef TASK_H_
#define TASK_H_

#include <stdint.h>

typedef enum 
{
    VISUAL = 0, // Modo visualizacion (0)
    EDICION = 1 // Modo edicion (1)
} Modos_e;

typedef struct
{
    uint8_t horas;
    uint8_t minutos;
    uint8_t segundos;

} Tiempo_t;

typedef uint8_t boolean;

#define DEL   8                 // Macros de los teclados en ASCII
#define INTRO 10
#define ESC   27
#define EDIT  32

// Frecuencias de las diferentes tareas
#define frecReloj       1       // Frecuencia de la aplicacion reloj (1Hz)
#define frecPuntosLCD   2       // Frecuencia de los puntos de la pantalla LCD (2Hz)
#define frecBateria     2       // Frecuencia inicial de la bateria (2Hz)
#define frecLed         5       // Frecuencia de los LEDs (5Hz)
#define frecTeclado     10      // Frecuencia del teclado (10Hz)
#define frecSTimer      16      // Frecuencia del System Timer (16Hz)
#define TACLK           32768   // Frecuencia del ACLK (32768Hz)

// Periodos derivados de las frecuencias
#define periodoLed      frecSTimer / frecLed
#define periodoBateria  frecSTimer / frecBateria
#define periodoPuntos   frecSTimer / frecPuntosLCD
#define periodoReloj    frecSTimer / frecReloj
#define periodoTeclado  frecSTimer / frecTeclado
#define periodo         (TACLK / frecSTimer) - 1

#define DERECHA         0
#define IZQUIERDA       1

// Declaraciones de funciones
void tareaLed(void);      // Tarea que gestiona los leds
void tareaBateria(void);  // Tarea que gestiona la bateria
void tareaReloj(void);    // Tarea que gestiona el reloj
void tareaPuntos(void);   // Tarea que gestiona los puntos del reloj
void tareaTeclado(void);  // Tarea que gestiona el teclado

#endif /* TASK_H_ */
