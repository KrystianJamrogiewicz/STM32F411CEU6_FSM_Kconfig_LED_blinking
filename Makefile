# ===================================================================
# MAKEFILE DLA STM32
# ====================================================================


# ====================================================================
# Instalacja potrzebnych pakietów:
# sudo apt update
# sudo apt install build-essential
# sudo apt install gcc-arm-none-eabi binutils-arm-none-eabi libnewlib-arm-none-eabi
# sudo apt install openocd
# ====================================================================


# ====================================================================
# MIKROPROCESOR VS MIKROKONTROLER 
# ====================================================================
#
# 1. Mikroprocesor (MPU) - "Sama głowa np: ARM Cortex-M4"
#    - Sam rdzeń obliczeniowy (np. Intel Core, AMD Ryzen, ARM Cortex).
#    - Potrafi tylko szybko liczyć. Nie ma pamięci RAM, FLASH ani portów na piny.
#    - Wymaga zewnętrznych układów na płycie głównej, żeby w ogóle ruszyć.
#
# 2. Mikrokontroler (MCU) - "Komputer w jednej kostce np: STM32F411CEU6"
#    - Kompletny, autonomiczny komputer zamknięty w jednym małym układzie scalonym.
#    - Ma w środku: rdzeń (mikroprocesor) + pamięć RAM + pamięć FLASH (dysk) 
#      + układy peryferyjne (liczniki, przetworniki analogowo-cyfrowe ADC, 
#		kontrolery SPI, I2C, UART, GPIO itp.).
#
# 3. STM32 BlackPill - "Płytka uruchomieniowa (deweloperska)"
#    - To PŁYTKA, na której wlutowany jest MIKROKONTROLER (STM32F411CEU6).
#    - Mikrokontroler daje rdzeń Cortex-M4, RAM i FLASH, a płytka wyprowadza to 
#      na piny z możliwością podpięcia przewodu, dodaje gniazdo USB-C, diodę LED i przycisk RESET.
#
# ====================================================================


# ====================================================================
# CO ROBIĄ PLIKI .o, .elf i .bin? (PROCES KOMPILACJI)
# ====================================================================
#
# 1. Pliki obiektowe (.o) - "Półprodukty"
#    - Powstają jako pierwsze z każdego pojedynczego pliku źródłowego (.c lub .s).
#    - Zawierają już kod maszynowy (zrozumiały dla procesora), ale nie mają 
#      jeszcze przypisanych konkretnych adresów w pamięci mikrokontrolera.
#    - Kompiluje się je osobno, aby przy zmianie kodu w jednym pliku .c, 
#      kompilator musiał przebudować tylko ten jeden plik .o, a nie cały projekt.
#
# 2. Plik wykonywalny (.elf - Executable and Linkable Format) - "Kompletna mapa"
#    - Powstaje w procesie LINKOWANIA, gdzie linker (ld) bierze wszystkie pliki .o 
#      oraz biblioteki wykorzystane w projekcie i łączy je w jeden plik.
#    - Wykorzystuje skrypt linkera (.ld), aby poukładać funkcje i zmienne pod 
#      konkretne adresy fizyczne w pamięci FLASH i RAM mikrokontrolera.
#    - Oprócz czystego kodu maszynowego, plik .elf zawiera ogromną ilość danych 
#      dodatkowych: nazwy zmiennych, numery linii kodu i tabele symboli. 
#    - Jest to plik NIEZBĘDNY DLA DEBUGERA (np. Cortex-Debug w VS Code) – dzięki 
#      niemu komputer wie, którą linijkę kodu w C aktualnie wykonuje procesor.
#    - Plik .elf jest zbyt "ciężki" i skomplikowany, by wgrać go bezpośrednio 
#      do pamięci mikrokontrolera.
#
# 3. Czysty plik binarny (.bin) - "Czysty kod dla pamięci FLASH"
#    - Powstaje przez "odchudzenieie" pliku .elf za pomocą narzędzia objcopy.
#    - Objcopy bezwzględnie wyrzuca wszystkie informacje debugowe, nazwy zmiennych 
#      i nagłówki formatu ELF. Zostawia SAM CZYSTY KOD MASZYNOWY (bity i bajty).
#    - Plik .bin to dokładnie to, co programator (np. ST-Link) kopiuje bajt po bajcie 
#      i zapisuje bezpośrednio w pamięci trwałej FLASH Twojego STM32.
#
# --------------------------------------------------------------------
# PODSUMOWANIE: .c/.s  ===(kompilator)===>  .o  ===(linker)===>  .elf  ===(objcopy)===>  .bin
# ====================================================================



# ====================================================================
# Deklaracja zmiennych. Zmienne wywołuje się: $(nazwa_zmiennej)
# ====================================================================

TARGET = FSM_Kconfig_LED_blinking
# Nazwa projektu (taką nazwę będą miały pliki wyjściowe).

BUILD_DIR = build
# Nazwa folderu do przechowywania zbudowanych plików wynikowych: .o, .elf, .bin.

CC = arm-none-eabi-gcc
# Kompilator dla procesorów ARM (tłumaczy C na kod maszynowy).

OBJCOPY = arm-none-eabi-objcopy
# Narzędzie do wycinania kodu binarnego z pliku .elf i utworzenia na jego podstawie pliku .bin.

SIZE = arm-none-eabi-size
# Narzędzie do wyświetlenia rozmiaru programu (RAM i FLASH).

# PODZIAŁ PAMIĘCI W MIKROKONTROLERZE:
# 1. Pamięć FLASH (Trwała): Przechowuje skompilowany kod maszynowy (powstały z plików .c, .h oraz .s) oraz stałe niepodlegające zmianom.
# 2. Pamięć RAM (Ulotna): Przechowuje zmienne globalne (sekcje .data i .bss) oraz zmienne lokalne funkcji (Stos / Stack). Znika po odłączeniu zasilania.
# 3. Pamięć EEPROM (Trwała): (* Może być Emulowana czyli wydzielona z FLASH) - Służy do celowego zapisywania konfiguracji (np. kalibracji, haseł, VIN) w trakcie pracy urządzenia.



# ====================================================================
# Dołączenie ścieżek do folderów plików do kompilacji
# Wbudowane funkcje w make (-I, wildcard) same dodają wszystkie odpowiednie pliki.
# ====================================================================

# Dołączenie plików nagłówkowych .h
# Flaga -I (Includes) informuje kompilator gdzie szukać potrzebnych 
# plików nagłówkowych .h np w folderze Core/inc
INCLUDES = -ICore/inc

# Dołączenie plików źródłowych .c
# Funkcja wildcard przeszukuje wskazany folder i zwraca listę ścieżek do 
# każdego znalezionego pliku o zadanym wzorcu np: *.c - wszystkie pliki .c
SRCS_C = $(wildcard Core/src/*.c)

# Dołączenie pliku startowego asemblera .s - wymagany przez mikrokontroler do 
# jego inicjalizacji przed uruchomieniem właściwego kodu .c (przygotowuje procesor 
# i pamięć RAM, wywołuje funkcję SystemInit(), a na końcu przechodzi do właściwej funkcji main() z pliku .c)
SRCS_ASM = Core/startup/startup_stm32f411ceux.s

# Dołączenie skryptu linkera .ld - wymagany przez system budowania do prawidłowego rozmieszczenia programu 
# w pamięci mikrokontrolera (definiuje fizyczne granice pamięci FLASH i RAM, rozdziela sekcje 
# kodu oraz zmiennych pod konkretne adresy, a także wyznacza pozycję startową stosu).
LDSCRIPT = STM32F411CEUX_FLASH.ld

# Stos (Stack) - wydzielony, bardzo szybki obszar pamięci RAM działający w trybie LIFO
# (ostatni wszedł, pierwszy wyszedł), używany automatycznie przez procesor do: 
# 1) przechowywania zmiennych lokalnych funkcji
# 2) pamiętania adresów powrotu z wywołanych funkcji
# 3) zapamiętywania stanu procesora przed obsługą przerwania sprzętowego



# ====================================================================
# Tworzenie plików .o (Object files) - to zapisane w kodzie maszynowym pliki .c. Tworzy się je po to, aby
# przy zmianie jednego pliku .c kompilator przebudował tylko ten jeden zmieniony plik, a nie cały projekt (OSZCZĘDNOŚĆ CZASU).
# ====================================================================

# Zmienna OBJS zawiera tylko ścieżki i nazwy plików .o jakie będą później utworzone.
OBJS = $(addprefix $(BUILD_DIR)/, $(notdir $(SRCS_C:.c=.o))) 
# Do zmiennej OBJS przypisz listę SRCS_C ze zmienionymi rozszerzeniami z .c na .o.
# addprefix - Dodaje do ścieżki pliku folder ze zmiennej BUILD_DIR (będzie np: build/...).
# notdir - Usuwa ze ścieżki pliku foldery (zostawia samo np: main.o).

OBJS += $(addprefix $(BUILD_DIR)/, $(notdir $(SRCS_ASM:.s=.o)))
# Do zmiennej OBJS dodaj SRCS_ASM: .s=.o (plik startowy zmieniony z .s na .o).

# Ponieważ tworzony będzie folder build trzeba powiedzieć narzędziu MAKE aby szukał
# plików .c i .s pod starą ścieżką czyli (np: Core/src i Core/startup).
vpath %.c $(sort $(dir $(SRCS_C)))
vpath %.s $(sort $(dir $(SRCS_ASM)))
# vpath - Definiuje ścieżkę wyszukiwania dla plików o określonym rozszerzeniu np .c, .s.
# dir - Wyciąga ze zmiennej ścieżkę (np: z SRCS_C będzie Core/src).
# sort - Usuwa ewentualne duplikaty ścieżek.



# ====================================================================
# Konfiguracja (Flagi) kompilatora i linkera
# Flagi -m dotyczą mikrokontrolera.

# Dokumentacja np: RM0383 Reference manual dla mikrokontrolera STM32F411. 
# Strona: 34, 1 Documentation conventions.

# Dokumentacja np: PM0214 Programming manual dla mikroprocesora / rdzenia Cortex-M4.
# Strona 15, 1.3.3 Cortex-M4 processor features and benefits summary
# Strona 252, 4.6 Floating point unit (FPU)
# ====================================================================

# Zmienna definiuje dla jakiego sprzętu (mikrokontrolera) kod będzie budowany.
MCU = -mcpu=cortex-m4 -mthumb -mfloat-abi=hard -mfpu=fpv4-sp-d16
# -mcpu = nazwa rdzenia - core / mikroprocesora w mikrokontroleże
# -mthumb - Typ generowanych instrukcji. Jedyny możliwy dla mikroprocesora ARM Cortex-M to mthumb.
# -mfloat-abi=hard - Określa, jak procesor ma radzić sobie z liczbami zmiennoprzecinkowymi
#   hard - dla mocnych układów np Cortex-M4. Wtedy używa bezpośrednio specjalnych rejestrów do obliczeń.
#   soft - dla słabszych procesorów bez rejestrów do obliczeń zmiennoprzecinkowych np Cortex-M3.
#   Wtedy kompilator generuje kod pomocniczy do obliczeń zmiennoprzecinkowych (wolniejsze działanie).
# -mfpu=fpv4-sp-d16 - Jeśli flaga mfloat-abi=hard to wtedy należy wybrać model kalkulatora do obliczeń
#   zmiennoprzecinkowych (fpu - floating point unit).
#   fpv4 -  architektura fpu dla ARM Cortex w wersji 4.
#   sp - (Single Precision) wymagane dla Cortex-M4 - przeprowadza szybkie obliczenia na zmiennych float (32-bit). Jeśli będzie
#       potrzeba obliczania zmiennej double (64-bit) sp będzie to wolniej symulował programowo.
#       Dla mocniejszych mikrokontrolerów np Cortex-M7 można użyć dp (Double Precision - oblicza szybciej 16 jak i 32 bit).
#   d16 - Liczba fizycznych rejestrów typu doubleword do obliczeń zmiennoprzecinkowych. Dla Cortex-M4 jest 16.


# Kompilator tłumaczy język C na - pliki .o (kod maszynowy).
# Zmienna definiuje parametry kompilatora.
CFLAGS = $(MCU) $(INCLUDES) -Wall -O0 -g
# MCU - Przekazuje informacje dla jakiego sprzętu (mikrokontrolera) kod będzie kompilowany.
# INCLUDES - Lista ścieżek w których kompilator będzie szukał plików nagłówkowych .h.
# -Wall - Ostrzegaj o wszystkich (All Warnings) potencjalnych błędach w kodzie.
# -O0 - DUŻE O - w kompilatorze gcc oznacza OPTYMALIZACJE. -O0 - Optymalizacja kodu poziom 0. 
#   Używać -O0 zawsze w początkowym etapie projektu, niezbędne do debugowania linijka po linijce. 
#   (Ale kod będzie wolniejszy i więcej ważył).
#   Flaga -Og - Działa jak O0 ale kod jest szybszy i mniej waży (NOWY STANDARD).
#   Flaga -Os - Optymalizacja rozmiaru i szybkości ZALECANA DO GOTOWEGO KODU w Mikrokontrolerach
#   Flaga -O1 - Podstawowa optymalizacja. 
#   Flaga -O2 - Mocna optymalizacja ZALECANE DO GOTOWEGO KODU na PC. 
#   Flaga -O3 - Nastawiona na szybkość, ale plik może więcej ważyć (NIE ZALECANE W MIKROKONTROLERACH).
# -g - Podgląd nazw zmiennych w VS Code podczas testów / debugowania. 
#   Gdy jest inna flaga niż -O0 lub -Og podgląd zmiennych nie jest potrzebny - można usunąć flagę.


# Linker bierze pliki kodu maszynowego .o, dodaje do nich biblioteki wykorzystane w projekcie np: stdint.h i łączy je w jeden plik wykonywalny .elf.
# Zmienna definiuje parametry linkera.
LDFLAGS = $(MCU) -T$(LDSCRIPT) --specs=nano.specs --specs=nosys.specs -Wl,--gc-sections
# MCU - Przekazuje informacje dla jakiego sprzętu (mikrokontrolera) linker ma dobrać wbudowane biblioteki.
# LDSCRIPT - Flaga -T mówi że w tej zmiennej przekazuje się plik linkera .ld.
#   Plik .ld mówi linkerowi pod jaki adres w pamięci Flash wstawić program a w pamięci RAM zmienne.
# --specs=nano.specs - Flaga nakazuje użycie NewLib-Nano - specjalnej odchudzonej biblioteki dla mikrokontrolerów.
# --specs=nosys.specs - Flaga No System - mówi że Mikrokontroler nie ma systemu operacyjnego 
#   i żeby funkcje nie próbowały się do niego odwoływać.
# -Wl,--gc-sections - OSZCZĘDZA MIEJSCE W PAMIĘCI FLASH. 
#   -Wl, - WYMAGANE - Flaga po przecinku omija kompilator i trafia bezpośrednio do linkera.
#   --gc-sections - Flaga linkera usuwa wszystkie nieużywane funkcje z pliku wyjściowego. Np jeśli
#       dołączona jest biblioteka a korzysta się tylko z jednej jej funkcji to reszta funkcji nie jest wgrywana.



# ====================================================================
# REGUŁY BUDOWANIA PROJEKTU

# cel_do_zbudowania: pliki_od_których_zależy
# [tabulator] komenda_do_wykonania

# Plik Makefile nie jest wykonywany od góry do dołu. Zamiast tego analizuje cały plik i buduje graf 
# zależności w celu wykonania konkretnej reguły.
# Uruchomienie samego polecenia „make” spowoduje uruchomienie tylko pierwszej reguły na górze (np: all)
# Pozostałe konkretne reguły muszą być wywoływane ręcznie za pomocą polecenia „make cel_do_zbudowania".

# Reguły wskazują na inne reguły poprzez zależności wymienione po znaku „:”.
# Na przykład cel „all” wymaga „$(TARGET).bin”, który z kolei wymaga „$(TARGET).elf” itd. 
# To powoduje automatyczną reakcję łańcuchową i wykonywanie reguł "Od dołu do góry".

# Symbole automatyczne
# $ - Wywołanie zmiennej np: $(TARGET)
# $@ - Zostanie podmienione na CEL reguły (nazwa pliku PRZED dwukropkiem).
# $< - Zostanie podmienione na PIERWSZĄ ZALEŻNOŚĆ reguły (nazwa pierwszego pliku PO dwukropku).
# $^ - Zostanie podmienione na WSZYSTKIE ZALEŻNOŚCI reguły (nazwy wszystkich pliku PO dwukropku).
# % - "Wild card - Dzika karta w regułach" - oznacza DOWOLNĄ NAZWĘ (pozwala tworzyć uniwersalny szablon dla wielu plików).
# @ - Postawiona na samym początku polecenia np: @echo - sprawia, że komenda nie wyświetli się w konsoli, wyświetli się tylko jej wynik.
# ====================================================================

# GŁÓWNA REGUŁA - Zapisana jako pierwsza (najwyżej w programie standardowa nazwa to "all") wykonuje się po wpisaniu "make".
# Reguła zależy od pliku .bin w folderze o nazwie ze zmiennej BUILD_DIR, jeśli go nie ma przeskakuje do reguły w której .bin lub folder jest CELEM.
all: $(BUILD_DIR)/$(TARGET).bin
	@$(SIZE) $(BUILD_DIR)/$(TARGET).elf
# Wyświetla rozmiar pliku .elf za pomocą zmiennej SIZE zadeklarowanej na górze programu.

# Jej CELEM jest zbudowanie ostatecznego pliku .bin.
$(BUILD_DIR)/$(TARGET).bin: $(BUILD_DIR)/$(TARGET).elf
	$(OBJCOPY) -O binary $< $@
# -O - DUŻE O (W narzędziu OBJCOPY) - Output target Docelowy format wyjściowy.
# Ustawia plik wyjściowy z komendy w zmiennej OBJCOPY jako binary -binarny.

# Jej CELEM jest zbudowanie pliku .elf na podstawie plików .o ze zmiennej OBJS.
$(BUILD_DIR)/$(TARGET).elf: $(OBJS)
	$(CC) $(CFLAGS) $^ $(LDFLAGS) -o $@
# -o - małe o (ZAWSZE) output - nazwa pliku wyjściowego.

# Reguła wzorcowa (Pattern Rule) kompiluje pliki .c do plików .o
# Jej CELEM jest stworzenie pliku / plików .o
# % to "Wild card - dzika karta" mówi - aby zrobić plik .o weź plik .c o tej samej nazwie.
# | $(BUILD_DIR) - | (Order-only) oznacza w języku Makefile tylko sprawdź czy BUILD_DIR istnieje,
#	nie sprawdzaj daty modyfikacji. Normalnie (bez |) sprawdza też datę modyfikacji.
$(BUILD_DIR)/%.o: %.c | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@
# -c - małe c - Compile Only - Tylko kompiluj. Potrzebne aby komenda w tym miejscu wykonała tylko kompilację,
#   a nie cały proces budowania gotowego programu (budowa następuje później).

# Reguła wzorcowa (Pattern Rule) kompiluje pliki (Asembler) .s do plików .o (kod maszynowy)
$(BUILD_DIR)/%.o: %.s | $(BUILD_DIR)
	$(CC) $(CFLAGS) -c $< -o $@

# Reguła budująca folder build
$(BUILD_DIR):
	mkdir -p $@
# Tworzy folder o nazwie ze zmiennej BUILD_DIR obok pliku Makefile.
# Flaga -p - system nie wyrzuci błędu, jeśli folder już istnieje.


# =========================================================================================
# Reguła czyszcząca - komenda "make clean" usuwa wszystkie wygenerowane pliki / folder o nazwie zmiennej BUILD_DIR.
clean:
	rm -rf $(BUILD_DIR)
#	rm -f $(OBJS) $(TARGET).bin $(TARGET).elf


# =========================================================================================
# Reguła wgrywająca program / flashująca - komenda "make flash" - wgrywa odchudzony plik .elf do pamięci mikrokontrolera przez ST-Link.
# (jeśli plik .elf nie istnieje lub zaszły zmiany - data modyfikacji) automatycznie buduje projekt. 
flash: $(BUILD_DIR)/$(TARGET).elf
	openocd -f interface/stlink.cfg -f target/stm32f4x.cfg -c "program $< verify reset exit"
# openocd (Open On-Chip Debugger) - narzędzie do wgrywania programu na mikrokontroler.
# FLAGI NARZĘDZIA OpenOCD
# Flaga -f (file) wczytuje plik konfiguracyjny.
# interface/stlink.cfg - Plik konfiguracyjny dla programatora (ST-Link).
# target/stm32f4x.cfg - Plik konfiguracyjny dla mikrokontrolera (STM32F4).
# Flaga -c (command) - Komenda do narzędzia OpenOCD. W " " lista zadań do wykonania.
#	program $< - Wgraj plik (podstawiony za $< czyli o nazwie ze zmiennej TARGET .elf) do pamięci flash mikrokontrolera.
#		OpenOCD na bazie pliku .elf wgra tylko niezbędne dane takie jak w pliku .bin. 
#		Dzięki .elf OpenOCD wie pod jaki adres wgrać te dane. Gdyby wgrywać .bin zamiast .elf trzeba by podać adres do wgrania danych.
#	verify - Po wgraniu porównuje plik na mikrokontrolerze z tym na PC, jeśli się różnią zgłasza błąd.
#	reset - Po pomyślnym wgraniu resetuje mikrokontroler (uruchamia program).
#	exit - Zamyka program OpenOCD.



# ===========================================================================================
# Definicja fałszywych (wirtualnych) celów. Polecenia sprawiają, że all, clean itp.
# to nazwy poleceń wewnętrznych, a nie rzeczywistych plików fizycznych na dysku.
.PHONY: all clean flash