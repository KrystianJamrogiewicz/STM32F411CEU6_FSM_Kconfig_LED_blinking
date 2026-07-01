# STM32F411CEU6_FSM_Kconfig_LED_blinking

Projekt edukacyjny pokazujący proces budowania i wgrywania oprogramowania na przykładzie mikrokontrolera STM32F411CEU6 (z rdzeniem ARM Cortex-M4) na płytce uruchomieniowej STM32 BlackPill.

---

## 🛠️ Wymagane narzędzia w systemie Linux

Komendy i pakiety potrzebne do programowania mikrokontrolerów z architekturą ARM.

### 1. Odświeżenie list pakietów
```bash
sudo apt update
```
Odświeża listę dostępnych programów w systemowym menedżerze pakietów apt (Advanced Package Tool).

### 2. Narzędzia podstawowe (Make i GCC dla PC)
```bash
sudo apt install build-essential
```
Instaluje system zarządzania kompilacją make oraz standardowy kompilator gcc dla programów w języku C uruchamianych na PC.

### 3. Zestaw narzędzi dla układów ARM (Toolchain)
```bash
sudo apt install gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi
```
Pakiet pobiera:
* **gcc-arm-none-eabi** – Kompilator języka C dedykowany dla rdzeni ARM.
* **binutils-arm-none-eabi** – Narzędzia pomocnicze do edycji plików binarnych (takie jak objcopy czy size).
* **libnewlib-arm-none-eabi** – Odchudzone biblioteki standardowe języka C zoptymalizowane pod kątem mikrokontrolerów.

### 4. Narzędzie do wgrywania programu (OpenOCD)
```bash
sudo apt install openocd
```
Pobiera oprogramowanie OpenOCD służące jako most między komputerem a programatorem (np. ST-Link) do wgrywania kodu na mikrokontroler oraz debugowania. 
> **Uwaga:** Do wygodnego debugowania w środowisku VS Code potrzebny będzie dodatek Cortex-Debug.

---

## 🚀 Ręczna kompilacja i wgrywanie kodu

Komendy do skompilowania i wgrania kodu C na mikrokontroler (tak robi to pod spodem plik Makefile).

### 1. Kompilacja plików źródłowych (.c i .s) do "półproduktów" (.o)
```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c main.c -o main.o
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -c startup_stm32f411ceux.s -o startup.o
```
* **Flaga -o (output)** – Stosowana przed podaniem nazwy pliku wyjściowego.
* **Flaga -c (compile only)** – Stosowana po to, aby kompilator zatrzymał się na etapie plików obiektowych i nie próbował od razu stworzyć pliku wykonywalnego `.elf`. Jest to niezbędne, aby nie musieć kompilować wszystkich plików na raz, gdy zmianie uległ tylko jeden z nich. Wersja bez flagi -c w punkcie 2.1.

**Efekt:** W folderze projektu powinny pojawić się pliki `main.o` oraz `startup.o`.

### 2. Linkowanie – łączenie plików .o w jeden plik wykonywalny (.elf)
```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -T STM32F411CEUX_FLASH.ld main.o startup.o --specs=nano.specs --specs=nosys.specs -o program.elf
```
* **-mcpu** – Model rdzenia mikrokontrolera.
* **-mthumb** – Typ generowanych instrukcji. Jedyny możliwy zestaw instrukcji dla rodziny ARM Cortex-M to skompresowany tryb Thumb.
* **-T** – Flaga informująca, że kolejny argument to plik skryptu pamięci (skrypt linkera `.ld`).
* **--specs=nano.specs** – Nakazuje użycie NewLib-Nano (specjalnej, odchudzonej biblioteki C dla mikrokontrolerów).
* **--specs=nosys.specs** – Flaga "No System", która informuje kompilator, że mikrokontroler nie ma systemu operacyjnego.

### 2.1 Kompilacja i linkowanie w jednej komendzie (bez użycia flagi -c)
Szybsza metoda, która kompiluje kod źródłowy i wykonuje linkowanie za jednym zamachem (tworzy od razu plik `.elf`):
```bash
arm-none-eabi-gcc -mcpu=cortex-m4 -mthumb -T STM32F411CEUX_FLASH.ld main.c startup_stm32f411ceux.s --specs=nano.specs --specs=nosys.specs -o program.elf
```
> **Uwaga:** W projektach składających się z wielu plików `.c` zmiana nawet jednej linijki wymusi kompilację wszystkich plików od zera, co znacznie wydłuża czas w dużych projektach. Dlatego w standardowej pracy używa się metody dwuetapowej (z flagą -c).

### Opcjonalnie: Wyciągnięcie czystego kodu (.bin) z pliku (.elf)
Jeśli programator (lub bootloader) wymaga surowego pliku `.bin`, można go wygenerować:
```bash
arm-none-eabi-objcopy -O binary program.elf program.bin
```
* **Flaga -O (duże O)** – W narzędziu OBJCOPY oznacza Output target, czyli docelowy format wyjściowy (w tym przypadku binary).

### 3. Wgrywanie programu na mikrokontroler (Flashing)
```bash
openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -c "program program.elf verify reset exit"
```
* **Flaga -f (file)** – Wczytuje pliki konfiguracyjne:
  * **interface/stlink.cfg** – Konfiguracja dla programatora (np. ST-Link).
  * **target/stm32f4x.cfg** – Konfiguracja dla rodziny mikrokontrolerów (STM32F4).
* **Flaga -c (command)** – Przekazuje bezpośrednią komendę do narzędzia OpenOCD. W cudzysłowach podajemy listę zadań do wykonania w odpowiedniej kolejności:
  * **program program.elf** – Wyciąga czysty kod z pliku "program.elf" i wgrywa go do pamięci Flash mikrokontrolera.
  * **verify** – Po wgraniu porównuje kod zapisany w pamięci mikrokontrolera z plikiem na dysku komputera. Jeśli wystąpi błąd transmisji, proces zostaje przerwany.
  * **reset** – Zleca sprzętowy reset mikrokontrolera (natychmiast uruchamia wgrany program).
  * **exit** – Zamyka program OpenOCD i odblokowuje terminal.


