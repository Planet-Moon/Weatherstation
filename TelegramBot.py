import sys
import os
import configparser
import time
import random
import datetime
import telepot
from telepot.loop import MessageLoop

class WeatherData():
    def __init__(self):
        self.mylogfile = Logfile("../Wetterlog/Wetterlog")
        self.DataString = ""
        self.Second = ""
        self.RH = ""
        self.T = ""
        self.AP = ""
        self.LI = ""
        self.get_Data()

    def get_DataString(self):
        self.DataString = self.mylogfile.get_lastLine()
        self.DataString = self.DataString.split(";")
        return self.DataString

    def get_Data(self, Data=""):
        self.get_DataString()
        self.RH = self.DataString[6]+"%"
        self.T = self.DataString[7]+"°C"
        self.AP = str(float(self.DataString[8])/100)+" hPa"
        self.LI = str(round(float(self.DataString[11])*100/409.6, 2))+"%"
        self.Second = self.DataString[5]+" s"
        if(Data == "RH"):            
            return self.RH

        elif(Data == "T"):
            return self.T

        elif(Data == "AP"):
            return self.AP

        elif(Data == "LI"):
            return self.LI

        elif(Data == "Second"):
            return self.Second
        
        elif(Data == "all"):
            return "Humidity: "+self.RH+"\nTemperature: "+self.T+"\nAtmospheric pressure: "+self.AP+"\nLight intensity: "+self.LI

        return

class Logfile():
    def __init__(self,filepath):
        self.filepath = filepath
        self.date_now = self.get_date()
        self.logfile = self.get_filename()
        self.firstLine = ""
        self.lastLine = ""
        self.get_firstLine()
        self.get_lastLine()

    def get_filename(self):
        self.get_date()
        self.logfile = self.filepath+str(self.date_now.date())+".csv"
        return self.logfile

    def get_date(self):
        self.date_now = datetime.datetime.now()
        return self.date_now

    def get_firstLine(self):
        with open(self.logfile,"r") as file:
            self.firstLine = file.readline()
        return self.firstLine

    def get_lastLine(self):
        with open(self.logfile,"r") as file:
            for last_line in file:
                    pass
            self.lastLine = last_line
        return self.lastLine

def handle(msg):
    chat_id = msg['chat']['id']
    command = msg['text']

    print ('Got command: '+str(command))

    if command == '/roll':
        bot.sendMessage(chat_id, random.randint(1,6))
    elif command == '/time':
        bot.sendMessage(chat_id, str(datetime.datetime.now()))
    elif command == "/whichweatherfile":
        bot.sendMessage(chat_id, str(MyLogfile.logfile))
    elif command == "/lastDataLine":
        bot.sendMessage(chat_id, str(MyLogfile.get_lastLine()))
    elif command == "/humidity":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("RH"))
    elif command == "/temperature":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("T"))
    elif command == "/atmosphericpressure":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("AP"))
    elif command == "/lightintensity":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("LI"))
    elif command == "/weatherdata":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("all"))
    elif command == "/second":
        bot.sendMessage(chat_id, MyWeatherData.get_Data("Second"))


config = configparser.RawConfigParser()
configFilePath = "telegrambot.cfg"
readConfig = config.read(configFilePath)
bot_token = config.get("telegrambot","token")
bot = telepot.Bot(bot_token)
botInfo = bot.getMe()

MessageLoop(bot, handle).run_as_thread()
print('I am listening ...')

MyLogfile = Logfile("../Wetterlog/Wetterlog")
MyWeatherData = WeatherData()

while 1:
    time.sleep(10)