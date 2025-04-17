# MSP430FR6989 Digital Clock System ⏰

## Overview 📝

This project implements a digital clock system using the MSP430FR6989 microcontroller. It combines both C and Assembly language programming to create an efficient, low-power digital timekeeper with interactive features. The clock displays time in HH:MM:SS format on the integrated LCD screen of the MSP430FR6989 development board, and includes visual indicators like battery animation and status LEDs.

The system operates in two main modes:
- **Visual Mode**: Displays the current time with blinking separator dots
- **Edit Mode**: Allows time adjustment using keyboard input with LED indicators for feedback

The architecture uses a task-based approach where different functions handle specific aspects of the system (clock management, LED control, battery animation, etc.) running on a cooperative multitasking framework.

## Project Goals 🎯 

- Demonstrate hybrid programming using both C and Assembly language
- Create a functional digital clock with user interface capabilities
- Implement low-power operation techniques for extended battery life
- Develop a modular, task-based system architecture
- Practice embedded systems programming on MSP430 microcontrollers
- Utilize the MSP430FR6989's integrated peripherals (LCD, timers, etc.)
- Apply good programming practices with clear documentation

## Features ✨ 

- **Digital Time Display**: Shows time in HH:MM:SS format on the LCD screen
- **Dual Operation Modes**:
  - Visual Mode: Regular time display with blinking separators
  - Edit Mode: Time adjustment with LED indicators
- **Interactive Input**: Keyboard interface for time setting and mode switching
- **Battery Animation**: Dynamic battery level indicator with multi-speed animation
- **Visual Indicators**:
  - Blinking separator dots for seconds tracking
  - Alternating LEDs for edit mode indication
- **Low Power Operation**: Uses MSP430's LPM3 mode for efficient power consumption
- **Task-Based Architecture**: Modular design with separate tasks for different functionalities
- **Mixed Language Implementation**: Strategic use of both C and Assembly language

## Technologies Used 🔧

### Hardware 🔧
- **MSP430FR6989** microcontroller
- **BOOST-IR** Infrared (IR) BoosterPack Plug-in Module
- Dual LED indicators (red and green)
- Low-power design with LPM3 mode

### Software & Development Tools 🛠️
- **Code Composer Studio** (CCS) IDE
- **C Language** for high-level control logic
- **Assembly Language** for low-level hardware control

### Programming Techniques ⏱️
- Interrupt-based timer system
- Task-based architecture

### Communication Protocols 📡
- Internal communication with the LCD controller
- GPIO-based LED control
- Timer-based system synchronization
- Keyboard interface scanning

## System Architecture 🔄

The system is organized into separate tasks that handle different aspects of the clock:

- **tareaReloj()**: Updates and displays the time
- **tareaTeclado()**: Processes keyboard input for time setting
- **tareaBateria()**: Manages the battery animation display
- **tareaPuntos()**: Controls the blinking of separator dots
- **tareaLed()**: Manages LED indicators (active in edit mode)

All tasks operate on a cooperative scheduling model based on timer interrupts, with the system entering low-power mode (LPM3) between task executions.

## Project Structure 📂

- **Inc/**: Header files
  - `cs.h`: Clock system interface
  - `lcd.h`: LCD display control functions
  - `lpiu.h`: LED and peripheral interface utilities
  - `st.h`: System timer functions
  - `task.h`: Task management and clock functionality
  - `teclado.h`: Keyboard interface

- **Src/**: Source files
  - `cs.asm`: Assembly implementation of clock system configuration
  - `lcd.asm`: Assembly implementation for LCD display control
  - `lpiu.asm`: Assembly implementation of LED and peripheral utilities
  - `main.c`: Program initialization and main execution loop
  - `st.asm`: Assembly implementation of system timer
  - `task.c`: C implementation of the system tasks (clock, keyboard, etc.)
  - `teclado.asm`: Assembly implementation of keyboard interface

## License 📄

This project is provided as an educational resource.
