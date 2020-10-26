/*
  LiquidCrystal Library - display() and noDisplay()

 Demonstrates the use a 16x2 LCD display.  The LiquidCrystal
 library works with all LCD displays that are compatible with the
 Hitachi HD44780 driver. There are many of them out there, and you
 can usually tell them by the 16-pin interface.

 This sketch prints "Hello World!" to the LCD and uses the
 display() and noDisplay() functions to turn on and off
 the display.

 The circuit:
 * LCD RS pin to digital pin 32
 * LCD Enable pin to digital pin 30
 * LCD D4 pin to digital pin 28
 * LCD D5 pin to digital pin 26
 * LCD D6 pin to digital pin 24
 * LCD D7 pin to digital pin 22
 * LCD R/W pin to ground
 * 10K resistor:
 * ends to +5V and ground
 * wiper to LCD VO pin (pin 3)

 Library originally added 18 Apr 2008
 by David A. Mellis
 library modified 5 Jul 2009
 by Limor Fried (http://www.ladyada.net)
 example added 9 Jul 2009
 by Tom Igoe
 modified 22 Nov 2010
 by Tom Igoe
 modified 7 Nov 2016
 by Arturo Guadalupi

 This example code is in the public domain.

 http://www.arduino.cc/en/Tutorial/LiquidCrystalDisplay

*/

#include <math.h>

// include the library code:
#include <LiquidCrystal.h>

#include <Wire.h>
#define Si7021_i2c_addr 0x40

//SDA Grau D12
//SCL Gelb D13
//#include <SoftWire.h>
//#include <AsyncDelay.h>
//#define i2c_sw_SDA 12
//#define i2c_sw_SCL 13
//SoftWire i2c_sw(i2c_sw_SDA, i2c_sw_SCL);
#define BMP180_i2c_addr 0x77

typedef enum{
  RH,
  Temperature
}e_sensor_info;

typedef struct{
  float RH;
  float RH_old;
  float RH_trend;
  float RH_display;
  float Temp;
  float Temp_old; 
  float Temp_trend;
  float Temp_display;
}s_Sensor_data;
s_Sensor_data Sensor = {0};

//char 1byte
//short 2bytes
//int,long 4bytes
typedef struct{
  int16_t AC1;
  int16_t AC2;
  int16_t AC3;
  uint16_t AC4;
  uint16_t AC5;
  uint16_t AC6;
  int16_t VB1;
  int16_t VB2;
  int16_t MB;
  int16_t MC;
  int16_t MD;
}s_bmp180_cal_param;
s_bmp180_cal_param bmp180_cal_param_default = {408,-72,-14383,32741,32757,23153,6190,4,-32768,-8711,2868};
s_bmp180_cal_param bmp180_cal_param = {0};

uint8_t bmp180_oss = 3;

// initialize the library by associating any needed LCD interface pin
// with the arduino pin number it is connected to
const int rs = 32, en = 30, d4 = 28, d5 = 26, d6 = 24, d7 = 22;
LiquidCrystal lcd(rs, en, d4, d5, d6, d7);

//CRC-Check falls der Sensor einen falschen Wert liefert
uint8_t crcCheck(uint8_t msb, uint8_t lsb, uint8_t check) {
    uint32_t data32 = ((uint32_t) msb << 16) |
            ((uint32_t) lsb << 8) |
            (uint32_t) check;
    uint32_t divisor = 0x988000;
    int i;
    for (i = 0; i < 16; i++) {
        if (data32 & (uint32_t) 1 << (23 - i))
            data32 ^= divisor;
        divisor >>= 1;
    };
    return (uint8_t) data32;
}

uint16_t i2c_read(uint8_t device_address, uint8_t register_address, uint8_t n_Bytes){
  uint16_t ret_val = 0;
  Wire.beginTransmission(device_address);
  Wire.write(register_address);
  Wire.endTransmission();
  uint8_t n_bytes_ready = Wire.requestFrom((uint8_t)device_address,(uint8_t)n_Bytes);
  //Serial.println(n_bytes_ready);
  uint8_t read_buffer[8] = {0};
  uint8_t i = 0;
  while(Wire.available()){
    read_buffer[i] = Wire.read();
    //Serial.println(read_buffer[i]);
    i++;
  }
  ret_val = read_buffer[0]<<8 | read_buffer[1];
  uint8_t check_sum = read_buffer[2];
  uint8_t ret_val_msb = (ret_val>>8)&0xFF;
  uint8_t ret_val_lsb = ret_val&0xFF;
//  Serial.print("Register: 0x");
//  Serial.print(register_address, HEX);
//  Serial.print(", ret_val: ");
//  Serial.print(ret_val);
//  Serial.print(", msb: ");
//  Serial.print(ret_val_msb);
//  Serial.print(", lsb: ");
//  Serial.print(ret_val_lsb);
//  uint8_t check_sum_valid = crcCheck(ret_val_msb,ret_val_lsb,check_sum);
//  Serial.print(", Check_sum: ");
//  Serial.print(check_sum);
//  Serial.print("; ");
//  Serial.println(check_sum_valid);
//  Serial.println();
  return ret_val;
}

float Convert_Sensor_Value(uint16_t Sensor_value, e_sensor_info Sensor_value_info){
  float ret_val = 0;
  float ret_val_help = 0;
  switch(Sensor_value_info){
    case RH:
      //Serial.println("RH");
      ret_val_help = 125*((float)Sensor_value/(float)65536)-6;
      if(ret_val_help > 100)
        ret_val_help = 100; 
      ret_val = ret_val_help;
      break;
    case Temperature:
      //Serial.println("T");
      ret_val = 175.72*((float)Sensor_value/(float)65536)-46.85;
      break;
    default: break;
  }
  return ret_val;
}

int BMP180_ID(void){
  int ret_val = 0;
  ret_val = i2c_read(BMP180_i2c_addr,0xD0, 1);
  ret_val = ret_val >> 8;
  //Serial.print("BMP180_ID: 0x");
  //Serial.println(ret_val,HEX);
  return ret_val;
}

bool BMP180_BootCheck(void){
  if(BMP180_ID() == 0x55)
    return true;
  return false;
}

void bmp180_reset(void){
  Wire.beginTransmission(BMP180_i2c_addr);
  Wire.write(0xE0);
  Wire.write(0xB6);
  Wire.endTransmission();
  while (!BMP180_BootCheck()){
    delay(20);
  }
  //Serial.println("BMP180 reset completed.");
}

void bmp180_get_cal_param(s_bmp180_cal_param* param_out){
  //Serial.println("bmp180_get_cal_param ...");
  s_bmp180_cal_param param_out_default = bmp180_cal_param_default;
  param_out->AC1 = i2c_read(BMP180_i2c_addr, 0xAA, 1) | i2c_read(BMP180_i2c_addr, 0xAB, 1)>>8;
  param_out->AC2 = i2c_read(BMP180_i2c_addr, 0xAC, 1) | i2c_read(BMP180_i2c_addr, 0xAD, 1)>>8;
  param_out->AC3 = i2c_read(BMP180_i2c_addr, 0xAE, 1) | i2c_read(BMP180_i2c_addr, 0xAF, 1)>>8;
  param_out->AC4 = i2c_read(BMP180_i2c_addr, 0xB0, 1) | i2c_read(BMP180_i2c_addr, 0xB1, 1)>>8;
  param_out->AC5 = i2c_read(BMP180_i2c_addr, 0xB2, 1) | i2c_read(BMP180_i2c_addr, 0xB3, 1)>>8;
  param_out->AC6 = i2c_read(BMP180_i2c_addr, 0xB4, 1) | i2c_read(BMP180_i2c_addr, 0xB5, 1)>>8;
  param_out->VB1 = i2c_read(BMP180_i2c_addr, 0xB6, 1) | i2c_read(BMP180_i2c_addr, 0xB7, 1)>>8;
  param_out->VB2 = i2c_read(BMP180_i2c_addr, 0xB8, 1) | i2c_read(BMP180_i2c_addr, 0xB9, 1)>>8;
  param_out->MB = i2c_read(BMP180_i2c_addr, 0xBA, 1) | i2c_read(BMP180_i2c_addr, 0xBB, 1)>>8;
  param_out->MC = i2c_read(BMP180_i2c_addr, 0xBC, 1) | i2c_read(BMP180_i2c_addr, 0xBD, 1)>>8;
  param_out->MD = i2c_read(BMP180_i2c_addr, 0xBE, 1) | i2c_read(BMP180_i2c_addr, 0xBF, 1)>>8; 
}

void print_cal_param(s_bmp180_cal_param* param){
  Serial.println("Calibration Parameters: ");
  Serial.print("AC1: ");
  Serial.println(param->AC1);
  Serial.print("AC2: ");
  Serial.println(param->AC2);
  Serial.print("AC3: ");
  Serial.println(param->AC3);
  Serial.print("AC4: ");
  Serial.println(param->AC4);
  Serial.print("AC5: ");
  Serial.println(param->AC5);
  Serial.print("AC6: ");
  Serial.println(param->AC6);
  Serial.print("B1: ");
  Serial.println(param->VB1);
  Serial.print("B2: ");
  Serial.println(param->VB2);
  Serial.print("MB: ");
  Serial.println(param->MB);
  Serial.print("MC: ");
  Serial.println(param->MC);
  Serial.print("MD: ");
  Serial.println(param->MD);
  Serial.println("------------------------");
}

int32_t bmp180_get_ut(void){
  int32_t UT = 0;
  Wire.beginTransmission(BMP180_i2c_addr);
  Wire.write(0xF4);
  Wire.write(0x2E);
  Wire.endTransmission();
  delay(5);
  
  Wire.beginTransmission(BMP180_i2c_addr);
  Wire.write(0xF6);
  Wire.endTransmission();
  Wire.requestFrom((uint8_t)BMP180_i2c_addr,(uint8_t)1);
  while(Wire.available()){
    UT = Wire.read()<<8;
  }

  Wire.beginTransmission(BMP180_i2c_addr);
  Wire.write(0xF7);
  Wire.endTransmission();
  Wire.requestFrom((uint8_t)BMP180_i2c_addr,(uint8_t)1);
  while(Wire.available()){
    UT += Wire.read();
  }
  //Serial.print("UT: ");
  //Serial.println(UT);
  return UT;
}

int32_t bmp180_get_temperature(int32_t UT, s_bmp180_cal_param* cal_param){
  int32_t X1 = ((UT - (int32_t)cal_param->AC6) * (int32_t)cal_param->AC5) >> 15;
  int32_t X2 = ((int32_t)(cal_param->MC) * pow(2,11)) / (int32_t)(X1 + cal_param->MD);
  int32_t B5 = X1 + X2;
  int32_t T = (B5 + 8) >> 4;
  return T;
}

int32_t bmp180_get_up(uint8_t oss, uint8_t n_samples){
  int32_t UP = 0;
  for(int i = 0; i < n_samples; i++){
    int32_t UP_temp = 0;

    Wire.beginTransmission(BMP180_i2c_addr);
    Wire.write(0xF4);
    Wire.write(0x34 + (oss<<6));
    Wire.endTransmission();
    switch(oss){
      case 0: delay(5); break;
      case 1: delay(8); break;
      case 2: delay(14); break;
      default: delay(26); break;
    }

    Wire.beginTransmission(BMP180_i2c_addr);
    Wire.write(0xF6);
    Wire.endTransmission();
    Wire.requestFrom((uint8_t)BMP180_i2c_addr,(uint8_t)1);
    while(Wire.available()){
      UP_temp |= ((int32_t)Wire.read())<<16;
    }

    Wire.beginTransmission(BMP180_i2c_addr);
    Wire.write(0xF7);
    Wire.endTransmission();
    Wire.requestFrom((uint8_t)BMP180_i2c_addr,(uint8_t)1);
    while(Wire.available()){
      UP_temp |= ((int32_t)Wire.read())<<8;
    }

    Wire.beginTransmission(BMP180_i2c_addr);
    Wire.write(0xF8);
    Wire.endTransmission();
    Wire.requestFrom((uint8_t)BMP180_i2c_addr,(uint8_t)1);
    while(Wire.available()){
      UP_temp |= ((int32_t)Wire.read());
    }
    UP_temp = UP_temp>>(8-oss);

    //Serial.print("UP_temp: ");
    //Serial.println(UP_temp);
    UP += (UP_temp/n_samples)+(i%2);
  }
  //Serial.print("UP: ");
  //Serial.println(UP);
  return UP;
}

int32_t bmp180_calpressure(int32_t UP, int32_t UT, uint8_t oss, s_bmp180_cal_param* cal_param, uint8_t* error_flag){  
  int32_t X1 = ((UT - (int32_t)cal_param->AC6) * (int32_t)cal_param->AC5) >> 15;  
  int32_t X2 = ((int32_t)(cal_param->MC) << 11) / (int32_t)(X1 + cal_param->MD);  
  int32_t B5 = X1 + X2;  
  int32_t B6 = B5 - 4000;
  X1 = ((int32_t)cal_param->VB2 * (B6 * B6)>>12)>>11;
  X2 = (cal_param->AC2 * B6)>>11;
  int32_t X3 = X1 + X2;
  int32_t B3 = (((((int32_t)cal_param->AC1) * 4 + X3) << oss) + 2) >> 2;
  X1 = (cal_param->AC3 * B6) >> 13;
  X2 = ((int32_t)cal_param->VB1 * (B6 * B6 >> 12)) >> 16;
  X3 = (X1 + X2 + 2)>>2;
  int32_t B4 = (cal_param->AC4*(uint32_t)(X3 + 32768))>>15;
  uint32_t B7 = (UP - B3) * (50000 >> oss);
  int32_t p = 0;
  if(B7 < 0x80000000){
    p = (B7*2)/B4;
    *error_flag = 1;
  }
  else{
    p = (B7/B4)*2;
    *error_flag = 0;
  }
  X1 = (p>>8)*(p>>8);
  X1 = (X1 * 3038)>>16;
  X2 = (-7357 * p)>>16;
  p = p + ((X1 + X2 + 3791)>>4);
  return p;
}

float bmp180_get_altitude(int32_t pressure){
  int32_t currentSeaLevelPressureInPa = 101325;
  float altitude = 44330.0 * (1.0 - pow(((float)pressure / (float)currentSeaLevelPressureInPa), 0.1902949571836346));
  return altitude;
}

int get_light_intensity(uint8_t pin){
  int ret_val = 0;
  ret_val = analogRead(pin);
  return ret_val;
}

void setup() {
  Serial.begin(9600);
  Wire.begin();
  
  // set up the LCD's number of columns and rows:
  lcd.begin(16, 2);
  lcd.display();
  while(!BMP180_BootCheck());
  bmp180_reset();
  //Serial.println("BMP180 online");
  bmp180_get_cal_param(&bmp180_cal_param);
  
  
}

void loop() {
  // Turn off the display:
  //lcd.noDisplay();
  //delay(500);
  int32_t UT = bmp180_get_ut();
  int32_t UP = bmp180_get_up(bmp180_oss,2);
  float bmp180_temperature = (float)bmp180_get_temperature(UT,&bmp180_cal_param)/10;
  // Serial.print("bmp180: t: ");
  // Serial.print(bmp180_temperature);

  uint8_t error_flag = 0;
  int32_t p = bmp180_calpressure(UP,UT,bmp180_oss,&bmp180_cal_param,&error_flag);
  // Serial.print(", p: ");
  // Serial.print(p);
  // Serial.print(" (");
  // Serial.print((float)p/100);
  // Serial.print(" hPa)");

  float bmp180_altitude = bmp180_get_altitude(p);
  // Serial.print(", alt: ");
  // Serial.print(bmp180_altitude);
  // Serial.println(" m");

  // Turn on the display:
  Sensor.RH_old = Sensor.RH;
  Sensor.Temp_old = Sensor.Temp;
  uint16_t rh_raw = i2c_read(Si7021_i2c_addr, 0xE5, 3);
  uint16_t temp_raw = i2c_read(Si7021_i2c_addr, 0xE0, 3);
  Sensor.RH = Convert_Sensor_Value(rh_raw,RH);
  Sensor.Temp = Convert_Sensor_Value(temp_raw,Temperature);
  Sensor.RH_trend = Sensor.RH - Sensor.RH_old;
  Sensor.Temp_trend = Sensor.Temp - Sensor.Temp_old;

  if(abs(Sensor.RH - Sensor.RH_old)<0.1){
    Sensor.RH_display = Sensor.RH_old;
  }
  else{
    Sensor.RH_display = Sensor.RH;
    Sensor.RH_old = Sensor.RH;
  }
  
  if(abs(Sensor.Temp - Sensor.Temp_old)<0.1){
    Sensor.Temp_display = Sensor.Temp_old;
  }
  else{
    Sensor.Temp_display = Sensor.Temp;
    Sensor.Temp_old = Sensor.Temp;
  }


  int Light_intensity = get_light_intensity(A0);
  
    
//  Serial.print("RH: ");
//  Serial.print(rh_raw);
//  Serial.print(" = ");
//  Serial.print(RH_value, 4);
//  Serial.print("%");
//  Serial.print("; Temp: ");
//  Serial.print(temp_raw);
//  Serial.print(" = ");
//  Serial.print(temp_value, 4);
//  Serial.println("°C");
//  Serial.println("-------------------------------------");

  // Serial.print("RH");
  // Serial.print(Sensor.RH);
  // Serial.print("\t");
  // Serial.print("RH trend");
  // Serial.print(Sensor.RH_trend);
  // Serial.print("\t");
  // Serial.print("Temp");
  // Serial.print(Sensor.Temp);
  // Serial.print("\t");
  // Serial.print("Temp trend");
  // Serial.println(Sensor.Temp_trend);
  
  Serial.print(Sensor.RH);
  Serial.print("\t");
  Serial.print(Sensor.Temp);
  Serial.print("\t");
  Serial.print(p);
  Serial.print("\t");
  Serial.print(UP);
  Serial.print("\t");
  Serial.print(bmp180_temperature);
  Serial.print("\t");
  Serial.print(Light_intensity);
  Serial.print("\n");

  // Print a message to the LCD.
  lcd.clear();
  lcd.setCursor(0,0);
  lcd.print("RH: ");
  lcd.print(Sensor.RH_display);
  lcd.print("%");
  lcd.setCursor(0, 1);
  lcd.print("T:  ");
  lcd.print(Sensor.Temp_display);
  lcd.print((char)223);
  lcd.print("C");

  delay(1000);
}