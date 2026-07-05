# CNC PIC32 — Documentaci n del Proyecto

## Descripci n General

Controladora CNC basada en **PIC32MX795F512L** (TQFP-100) con driver de motores paso a paso **A4988** (Pololu breakout). Incluye conectividad USB, Zigbee (MRF24J40), display OLED y programaci n/debug por FT232.

## Arquitectura del Sistema

```
                +------------------+
                |   FT232BM (U2)   |--- USB (UART debug/programming)
                +--------+---------+
                         | UART
    +--------------------+--------------------+
    |              PIC32MX795 (U1)            |
    |  +---------+  +--------+  +----------+  |
    |  | USB OTG |  | I2C    |  | SPI4     |  |
    |  +----+----+  +---+----+  +-----+----+  |
    +-------+----------+------------+---------+
            |          |            |
       USB Mini-B    OLED       MRF24J40MA
       (J5/J18)    ST7789       Zigbee (U4)
                      |
                A4988 x5 (A1-A5)
              (Stepper motor drivers)
```

## Esquem ticos (jer rquicos)

| Archivo | Descripci n |
|---------|-------------|
| `cnc_pic32.kicad_sch` | Hoja ra z (jerarqu a principal) |
| `mcu.kicad_sch` | Microcontrolador PIC32MX795F512L |
| `power.kicad_sch` | Alimentaci n (3.3V, 5V, 12V) |
| `ft232.kicad_sch` | FT232BM (USB-UART, programaci n/debug) |
| `usb_conector_Ft232.kicad_sch` | Conector USB para FT232 |
| `Usb_pic32.kicad_sch` | USB OTG del PIC32 |
| `pololu.kicad_sch` | Drivers A4988 (x5) |
| `oled.kicad_sch` | Display OLED I2C |
| `zigbee.kicad_sch` | M dulo MRF24J40MA |
| `idc.kicad_sch` | Conector ICD (programaci n) |
| `oscilador.kicad_sch` | Osciladores |
| `osc_ft232.kicad_sch` | Oscilador del FT232 |
| `tp_ft232.kicad_sch` | Test points FT232 |
| `power_ft232.kicad_sch` | Alimentaci n del FT232 |

## BOM (Bill of Materials)

**Total: 109 componentes**

| Categor a | Cantidad |
|-----------|----------|
| Resistencias (0805/0603) | 48 |
| Capacitores (0805) | 30 |
| Conectores (pin header 2.54mm, USB) | 12 |
| Stepper drivers (Pololu A4988) | 5 |
| ICs (PIC32, FT232, MRF24J40) | 3 |
| Reguladores LM1117-3.3V | 2 |
| Jumpers (solder) | 2 |
| Diodos | 2 |
| Inductores (1206) | 2 |
| MOSFET (2N7002) | 1 |
| Cristal (6MHz) | 1 |
| Switch t ctil | 1 |

## Clases de Red (Net Classes)

| Clase | Track Width | Clearance | Nets |
|-------|-------------|-----------|------|
| Default | 0.508 mm | 0.382 mm | Todas las se ales |
| Power_12V | 3 mm | 0.5 mm | +12V |
| Power_5V | 1 mm | 0.3 mm | +5V |
| Power_3V3 | 0.762 mm | 0.2 mm | +3.3V, +3V3 |

## Microcontrolador — Pines Disponibles

De 100 pines del PIC32MX795F512L:
- **73** pines conectados (I/O funcionales)
- **26** pines de alimentaci n (+3.3V / GND)
- **1** pin libre: **RB4 (pin 21)** — nico disponible para futuras expansiones

## Interfaces Utilizadas

| Interfaz | Pines | Dispositivo |
|----------|-------|-------------|
| USB OTG | D+/D-, VBUS | USB Mini-B (J18) |
| USB-UART | TX/RX | FT232BM (J5) |
| I2C | SDA/SCL (RD0/RD1) | OLED + sensores |
| SPI4 | CS/MOSI/MISO/SCK | MRF24J40MA Zigbee |
| ICSP | PGD/PGC (RB0/RB1/RB6/RB7) | Programaci n |
| JTAG | TMS/TCK/TDI/TDO | Debug |
| UART | TX/RX | FT232, RP2040 |
| STEP/DIR/ENABLE | 5x3 = 15 pines | A4988 x5 |

## Voltajes de Alimentaci n

| Voltaje | Fuente | Uso |
|---------|--------|-----|
| +12V | Fuente externa | Motores paso a paso (A4988 VMOT) |
| +5V | USB o regulador | FT232, RP2040, pull-ups USB |
| +3.3V | LM1117-3.3 (U3, U5) | PIC32, MRF24J40, OLED, l gica |
| VUSB3V3 | Interno PIC32 | USB OTG transceiver |

## Herramientas

- **KiCad** 10.0 (formato s-expression 2026)
- **PIC32MX795F512L** — MIPS32 MC4K core, 80MHz
- **MPLAB X / XC32** — Desarrollo de firmware

## Archivos del Proyecto

| Archivo | Descripci n |
|---------|-------------|
| `cnc_pic32.kicad_pcb` | PCB (ruteo y layout) |
| `cnc_pic32.kicad_sch` | Esquem tico ra z |
| `cnc_pic32.kicad_pro` | Configuraci n del proyecto |
| `cnc_pic32.net` | Netlist exportado |
| `*.kicad_sch` | Sub-hojas del esquema jer rquico |
| `fp-info-cache` | Cache de footprints |
| `cnc_pic32-backups/` | Copias de seguridad |
