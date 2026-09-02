# Z80 Calculator

This is a simple Z80 based calculator.  I have been doing various electronics projects
designed by other people and wanted to try making my own.  I figured a calculator
using the Z80 microprocessor would be a good choice as I had several of them on
hand and could reference other projects if needed.

## Features

The Z80 Caclulator has:

* 8K of RAM
* 8K of ROM
* 2 8-bit inputs (DIP switches)
* 6 push buttons
* Program select switch (software controlled)
* 4 seven segment displays (16-bit output)
* Expansion header for additional RAM or devices
* Blinkenlights!
* 555 timer for variable clock rate (useful for debugging)

Pretty basic, but this was more a learning exercise than anything.  Of the 8K ROM,
only a couple hundred bytes are used.  Combined with the program select switch,
it should be possible to load it up with three other programs.

The answers are displayed in hexadecimal so all operations on two eight bit numbers
would fit on the display.  The following operations are supported:

* Addition
* Subtraction
* Multiplication
* Division
* Greatest common denominator
* Square root

Only integer operations are supported, so division and square root are truncated.

## Programming

The Z80 Calculator has the following memory map:

* ROM: 0x0000 - 0x1FFF
* RAM: 0x2000 - 0x3FFF
* Unused: 0x4000 - 0xFFFF

I/O addresses are the following:

* 7SEG 1: 0x00
* 7SEG 2: 0x01
* 7SEG 3: 0x02
* 7SEG 4: 0x03
* Buttons + Program Select: 0x04
* DIP Switch X: 0x05
* DIP Switch 7: 0x06

The buttons and program select switch are mapped to the following bits of the byte
that you read back from their I/O address:

* SW1: Bits 0 and 1
* SW7: Bit 2
* SW6: Bit 3
* SW5: Bit 4
* SW4: Bit 5
* SW3: Bit 6
* SW2: Bit 7

All inputs are wired up to go high when enabled.  The seven segement displays are
also wired up to go high when a one is written to them.  Only one seven segment
display can be on at any time, and they won't stay on while other calculations
are occuring.  You can see an example of how this works in the provided source code.
There are also predefined values for the addresses and seven segment display values.

The idea with the program select switch was that on boot up, the code would check
what it was set to and jump to a different part of ROM.  However, it could be used
in other ways if multiple programs are not desired.

## BOM

Most of the parts can be had from Mouser except for the Z80 CPU.  Those are easy
enough to find on eBay.  Unicorn Electronics is also a good source for these parts
and is often cheaper than eBay or Mouser.  It might be possible to substitute 74HC
parts for the 74HCT, but I reccomend the latter.  74LS should be fine for any chip
that isn't driving an LED.  To use the 555 timer, you'll need a CMOS Z80.

For getting the PCB, I reccommend JLCPCB.  You can upload the included gerber files
to the site and just use their defaults, though change the color if you want.  Use the
cheapest shipping option (not DHL, FedEx, or UPS).

Component type     | Reference  | Description                                 | Quantity | Notes
------------------ | ---------- | ------------------------------------------- | -------- | --------------------------
PCB                |            | PCB                                         | 1        | JLCPCB, PCBWay
Capacitor          | C1,C16     | 1uF, electrolytic, 2mm lead spacing         | 2        | Could replace with ceramic
Capacitor          | C2,C15     | 10uF, electrolytic, 2mm lead spacing        | 2        | Could replace with ceramic
Capacitor          | C3,C4,C5,C6,C7,C8,C9,C10,C11,C12,C13,C14,C17 | 0.1uF, ceramic, 5mm lead spacing        | 13       |
LED                | D1,D2,D3,D4,D5,D6,D7,D8,D9,D10,D11,D12,D13,D14,D15,D16,D17,D18,D19,D20,D21,D22,D23,D24,D25,D26,D27  | 3mm lead spacing        | 27       | Consider mixing up the colors
Connector          | J1         | Barrel jack, 2.1mm                          | 1        |
Connector          | J2         | 2x20 shrouded pin header                    | 1        | Optional, used for expansion header
Connector          | JP1        | 1x3 pin header                              | 1        |
Resistor           | R1,R3,R4   | 2K ohm                                      | 3        |
Resistor           | R2         | 1K ohm                                      | 1        |
Resistor           | R5         | 22K ohm                                     | 1        |
Resistor Network   | RN1,RN4,RN5,RN9 | 10k ohm, 9 pin bussed                  | 4        |
Resistor Network   | RN2,RN3    | 470 ohm, 8 pin isolated                     | 2        | Could use normal resistors and bend leads
Resistor Network   | RN6,RN7,RN8| 2k ohm, 9 pin bussed                        | 3        |
Potentiometer      | RV1        | 50k ohm                                     | 1        |
Switch             | SW1        | DIP Switch 2x                               | 1        |
Switch             | SW2,SW3,SW4,SW5,SW6,SW7,SW8 | 6mm pushbutton             | 7        |
Switch             | SW9,SW10   | DIP Switch 8x                               | 2        |
IC                 | U1         | NE555P                                      | 1        | Other manufacturers are fine
IC                 | U2,U4,U11,U14,U15,U16,U17 | 74HCT245                     | 7        |
IC                 | U3         | Z80, CMOS, 4MHz                             | 1        |
IC                 | U5,U9      | 74HCT138                                    | 2        |
IC                 | U6         | 28C64 EEPROM                                | 1        | Can use 27C64
IC                 | U7,U10,U12,U13 | Seven segment, common cathode           | 4        | 
IC                 | U8         | 6264 RAM                                    | 1        | 
Oscillator         | Y1         | 4 MHz                                       | 1        | Could use a slower one or a faster one if the CPU supports higher speeds

## Misc

I wrote up a little post to my [blog](https://branmitc.blogspot.com/2026/09/homebrew-z80-computer.html) about designing and building this computer, if you
are interested.