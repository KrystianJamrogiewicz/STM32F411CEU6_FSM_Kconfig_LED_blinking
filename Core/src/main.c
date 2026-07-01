// ====================================================================
// main.c - Makefile Kconfig - blinking LED test
// ====================================================================



// System library <> (no need to download to the project 
// - it is located in the compiler files)

#include <stdint.h> /* Standard data types in C (except float and double) can 
have different sizes depending on the processor, which is why we use data types 
from the stdint library, for example (uint8_t, int64_t, etc.) */

// Local library "" (the .h file must be in the same folder 
// as the current file, or you must provide the path)

// #include "config.h" // Getting Kconfig settings from the config.h file




// ====================================================================
// PC13 - LED
// ====================================================================



/* -------------------------------------------------------------------------
In the #define section, we don't configure parameters yet. 
Here, we only create a register "map," telling the compiler where the parameters 
to configure are located. The exact configuration (writing values ​​into these registers) 
is performed only within the initialization function in the main.c file or a separate library (e.g., systick_init()).
*/

// ====================================================================
// RCC - Reset and clock control Registers (Memory Mapping)
// Document Reference: RM0383 Reference Manual
// ====================================================================
// - RCC controls the distribution of clock signals to all peripherals.
// - To save power, ALL peripherals (like GPIO, UART, SPI) have their 
//   clocks disabled by default after reset.
// - Writing to RCC registers is ALWAYS the very first step in any 
//   hardware initialization, before configuring the peripheral itself.

// Base address for the Reset and Clock Control (RCC) module.
// Found in the: "Register boundary addresses" in Memory map in RM0383 Reference manual.
#define RCC_BASE 0x40023800

// Always check the "Register boundary addresses" in Memory map in RM0383 Reference manual.
// to see which bus controls the peripheral.
// --------------------------------------------------------------------
// RCC AHB1 Peripheral Clock Enable Register (RCC_AHB1ENR)
// Used to enable the clock for peripherals connected to the AHB1 bus.
// - AHB1: Advanced High-performance Bus 1 (Main high-speed system bus)
// - EN: Enable
// - R: Register
//
// Found in the: "RCC AHB1 peripheral clock enable register (RCC_AHB1ENR)"" in RM0383 Reference manual.
// section to find the address offset (0x30).
#define RCC_AHB1ENR (*(volatile uint32_t *)(RCC_BASE + 0x30))
/*
  Macro breakdown from the inside out:
  1. (RCC_BASE + 0x30)
     - Calculates the exact raw hexadecimal address of the register.
     
  2. (volatile uint32_t *)
     - Type Casting: Converts the raw address into a pointer to a 32-bit register.
     - "volatile": Tells the compiler that this hardware memory can change 
       outside the CPU control, preventing dangerous code optimization.
       
  3. The first '*' at the very beginning "(*(..."
     - Dereference operator: Opens the door to this memory address. It allows 
       us to read and write data directly, treating the macro like a standard variable.
*/




// ====================================================================
// GPIO - General-Purpose Input/Output (Memory Mapping)
// Document Reference: STM32F411xC/E Reference Manual (RM0383)
// ====================================================================
// - GPIO provides direct software control over the physical pins of the MCU.
// - A single port contains up to 16 pins (Pin 0 to Pin 15).
// - Each port has a dedicated set of registers to control direction, speed, 
//   electrical type, and state.
// - * These #define macros only create a map of the registers. The 
//   actual hardware configuration happens when writing values to them in e.g. main.

// Registers are defined once for each GPIO port, e.g. GPIOA, GPIOB, GPIOC, etc.

// Base address for General Purpose Input/Output Port C (GPIOC).
// Found in the: "Register boundary addresses" in Memory map in RM0383 Reference manual.
#define GPIOC_BASE 0x40020800


// GPIO Port C Mode Register - configures pins as input, output, etc.
// Address offset: 0x00 Found in the "GPIO port mode register (GPIOx_MODER)" in RM0383 Reference manual.
#define GPIOC_MODER (*(volatile uint32_t *)(GPIOC_BASE + 0x00))
// 00: Input mode
// 01: General purpose output mode
// 10: Alternate function mode
// 11: Analog mode
// LED PC13 as output are bits 27 = 0 and 26 = 1


// GPIO Port C Output Data Register - used to set pins HIGH (1) or LOW (0)
// Address offset: 0x14 Found in the "GPIO port output data register (GPIOx_ODR" in RM0383 Reference manual.
#define GPIOC_ODR (*(volatile uint32_t *)(GPIOC_BASE + 0x14))
// Used to set the physical state of Port C pins when configured as outputs.
// Each pin uses exactly 1 bit:
// - 1: Sets the pin HIGH (3.3V)
// - 0: Sets the pin LOW (0V)


// GPIO Port C Output Type Register
// Address offset: 0x04 Found in the "GPIO port output type register (GPIOx_OTYPER)" in RM0383 Reference manual.
#define GPIOC_OTYPER (*(volatile uint32_t *)(GPIOC_BASE + 0x04))
// - 1 bit per pin:
// 0 = Push-Pull (Default, used for LEDs), 
// 1 = Open-Drain


// GPIO Port C Output Speed Register (Offset: 0x08)
// Address offset: 0x08 Found in the "GPIO port output speed register (GPIOx_OSPEEDR)" in RM0383 Reference manual.
#define GPIOC_OSPEEDR (*(volatile uint32_t *)(GPIOC_BASE + 0x08))
// - 2 bits per pin:
// 00 = Low Speed (Default, for blinking LEDs)
// 01: Medium speed
// 10: Fast speed
// 11: High speed


// GPIO Port C Pull-up/Pull-down Register (Offset: 0x0C)
// - Used heavily for Inputs (like Buttons) to prevent floating states.
// Address offset: 0x0C Found in the "GPIO port pull-up/pull-down register (GPIOx_PUPDR)" in RM0383 Reference manual.
#define GPIOC_PUPDR (*(volatile uint32_t *)(GPIOC_BASE + 0x0C))
// - 2 bits per pin: 
// 00 = No Pull-up/Pull-down (Default, used for LEDs)
// 01: Pull-up
// 10: Pull-down
// 11: Reserved




// ====================================================================
// SysTick timer (STK)
// Document Reference: Cortex-M4 Programming Manual (PM0214)
// ====================================================================
// - SysTick is a 24-bit hardware countdown timer built directly into 
//   the ARM Cortex-M4 core.
// - Its main purpose is to measure precise intervals of time.
// - In simple bare-metal projects, it is used to create accurate 
//   delay functions, like delay_ms(500).
// - In professional projects, it serves as the "heartbeat" of Operating 
//   Systems (like FreeRTOS) to trigger context switching every 1 millisecond.

// Base address for the System Tick Timer (SysTick) hardware block.
// Address found in the "SysTick timer (STK)" in PM0214 Programming manual.
#define STK_BASE 0xE000E010
// STK_BASE is chosen as the absolute address of the first register (STK_CTRL)

// SysTick Control and Status Register (Offset: 0x00)
#define STK_CTRL (*(volatile uint32_t *)(STK_BASE + 0x00))
// Bit 0 (ENABLE): Starts (1) or stops (0) the counter.
// Bit 1 (TICKINT): Enables/disables SysTick interrupt when counter reaches 0.
// Bit 2 (CLKSOURCE): Selects the clock source (Core clock or external).
// Bit 16 (COUNTFLAG): Returns 1 if the timer has counted down to 0.


// SysTick Reload Value Register (Offset: 0x04)
#define STK_LOAD (*(volatile uint32_t *)(STK_BASE + 0x04))
// Holds the start value for the countdown (24-bit resolution: max 16,777,215).
// When the timer reaches 0, it automatically reloads this value.


// SysTick Current Value Register (Offset: 0x08)
#define STK_VAL (*(volatile uint32_t *)(STK_BASE + 0x08))
// Contains the actual real-time value of the countdown.
// Writing any value to this register clears it to 0 and resets COUNTFLAG.




// ---------------------------------------------------------------
// Initialization / settings - MANDATORY
// ---------------------------------------------------------------

// Global variable to count elapsed milliseconds.
// Since it changes inside an interrupt handler, volatile forces the CPU 
// to read its value directly from RAM every time, instead of using a temporary register.
volatile uint32_t msTicks = 0;

// The name SysTick_Handler is hard-coded in the startup_stm32f411ceux.s file. 
// When the hardware counter reaches zero, the processor drops everything it was doing 
// in the main loop for a moment, jumps here, increments msTicks by 1, and goes back to work.
void SysTick_Handler(void) {
    msTicks++;
}




// The name SystemInit is hard-coded in the startup_stm32f411ceux.s file. 
// Hardware initialization function. 
// It prepares the SysTick timer to tick exactly every 1 millisecond.
// Is performed exactly once at the very beginning (immediately after connecting
// the power supply or pressing the RESET button).
void SystemInit(void) {

    // If the CPU clock is 16 MHz (16,000,000 Hz), then 1 millisecond 
    // takes exactly 16,000 clock cycles.
    STK_LOAD = 16000 - 1; // Subtract 1 because the counter also counts state 0 
    // (triggers an interrupt when it goes from 0 to reload).

    // Writing any value to the STK_VAL register clears it to zero and clears 
    // bit 16 (COUNTFLAG) in the STK_CTRL register.
    STK_VAL  = 0;

    // Configure and start the timer:
    STK_CTRL = 0x07; 
    // 0x07 in binary is 0000 0111:
    // - Bit 0 = 1: ENABLE (Starts the counter)
    // - Bit 1 = 1: TICKINT (Enables the interrupt to trigger SysTick_Handler)
    // - Bit 2 = 1: CLKSOURCE (Selects the main processor clock - 16 MHz)
   
    // - Bit 16 (COUNTY FLAG) is a flag indicating that the counter is counting 
    // down to zero. We don't use it because we've enabled interrupts (TICKINT = 1)!
    // TICKINT = 1: When the timer reaches zero, the hardware automatically calls the 
    // SysTick_Handler function. There is no need to manually check bit 16 because 
    // the processor itself notifies you when the timer expires.
    // TICKINT = 0 (No interrupts): Then you would have to constantly check bit 16 
    // in the while loop: if (STK_CTRL & (1 << 16)). This is a blocking approach and wastes CPU power.
}


// Initialization stub required by the GNU GCC compiler link-time libraries.
// - Called only ONCE during the startup sequence before main().
// - In a standard bare-metal C project, it is left completely empty.
// - Removing this function will cause a linker error: "undefined reference to _init".
// void _init(void) {}




// ---------------------------------------------------------------
// Proper code
// ---------------------------------------------------------------

// MILLISECOND DELAY FUNCTION (CPU-locking)
void delay_ms(uint32_t ms) {
    uint32_t startTicks = msTicks;
    while ((msTicks - startTicks) < ms) {
        // Waits in an empty loop until the msTicks counter increases by 
        // the requested number of milliseconds.
    }
}


int main(void) {
    // Enable the clock for Port C (GPIOC).
    RCC_AHB1ENR |= (1 << 2); // SET bit 2

    // Set pin PC13 as output.
    GPIOC_MODER &= ~(1 << 27); // RESET bit 27
    GPIOC_MODER |=  (1 << 26);

    while (1) {

            GPIOC_ODR ^= (1 << 13); // TOGGLE bit 13
            delay_ms(1000); 

    }   

    return 0;
}