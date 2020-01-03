# BIKELOCKLIGHT
This is a really simple small project to light up so I can see my motorcycle lock, using AVR assembly and an ATTINY13A

When i park my motorcycle down the side of my house in the winter, it is pitch black and I cannot see the lock. 
Rather than purchase a small battery powered lamp that I can turn on and off, I thought the best solution would be to make an AVR powered unit on which I can press a button, and it lights up a light for a set period of time.

I am mainly doing it so I can learn AVR assembly concepts and apply them on this project. I currently have used:
- Push button input with pullup
- Output signal, which will drive the base of a trasistor for a 12v line off an old bike battery
- 8 bit timer
- Sleep mode - Full power down
- Clock prescaler - divided by 64
- Timer prescaler - divided by 1024. This and the clock prescaler creates a 1 second delay with 15 timer overflows
- Set delay lengths using the scaled clock / timer
- INT0 interrupt to wake from power down sleep mode
- Nested interrupts (INT0 interrupt runs a subroutine that uses a timer overflow interrupt)
- ISP programming using USBASP (If I can find it)

The whole project will comprise of an old 12v bike battery, which provides power to the AVR via a power regulator. The AVR in turn, wakes up when the user presses a button, and switches the 12v power on to the light circuit via a transistor for 30 seconds, before going back into sleep mode. 
The AVR will be housed in a weatherproof box, and the light will be made from two 12v LED indicator bulbs I bought, that were too dim for use on my car.
