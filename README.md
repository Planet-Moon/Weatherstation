
# Weatherstation
Software used to read data from 4 sensors (temperature, humidity, light intensity, atmospheric pressure) by an arduino mega 2560 and transmit this data over serial interface to store it as CSV in a Raspberry Pi 3 Model B.

Sensors: temperature + humidity: si7021 (interface: I2C); light intensity: photodiode (interface: ADC); atmospheric pressure: BMP180 (interface: I2C)

## Telegram Bot
This Telegram bot reads the last entry of the logfile created by **ReadSerial_Wetterstation.py** and send the data over telegram.
Available commands:
 - **roll**: reports a random number between 1 and 6
 - **time**: reports current time
 - **humidity**: reports current humidity
 - **temperature**: reports current temperature
 - **atmosphericpressure**: reports current atmospheric pressure
 - **lightintensity**: reports current light intensity
 - **weatherdata**: reports all current sensor data


