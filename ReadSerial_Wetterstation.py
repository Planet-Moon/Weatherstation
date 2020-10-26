#ReadSerial.py
import serial
import time
import platform
import datetime
import struct
import os
import sys
import errno

debug = 0
write_file_flag = 1
dummyOutput_flag = 0
output_path = ""

op_sys = platform.system()
print("op_sys: "+str(op_sys))
if(op_sys == "Linux"):
    port = "/dev/ttyACM0"
elif(op_sys == "Windows"):
    port = "COM3"

def bytes_to_int(input_bytes):
    result = 0
    for b in input_bytes:
        result = result * 256 + int(b)
    return result

def ensure_dir(file_path):
    directory = os.path.dirname(file_path)
    if not os.path.exists(directory):
        try:
            os.makedirs(directory)
        except OSError as e:
            if e.errno != errno.EEXIST:
                raise

def check_arguments(sys_argv):
    global debug, write_file_flag, dummyOutput_flag, output_path
    used_arguments = [0,0,0,0,0,0]
    for arg in sys_argv:
        if(arg == "-new"):
            os.remove(logfile)
            print("creating new file...")
            time.sleep(2)
            used_arguments[0] = 1
          
        if(arg == "-debug"):
            debug = 1
            used_arguments[1] = 1

        if(arg == "-nofile"):
            used_arguments[2] = 1
            write_file_flag = 0
            print("not writing to output file")

        if(arg == "-example"):
            used_arguments[3] = 1
            dummyOutput_flag = 1
            print("creating example output file...")

        if(arg.find("-dir=")==0):
            output_path = arg[arg.find("-dir=")+len("-dir="):] # get all chars in argument after "-dir="
            used_arguments[4] = 1
            print("changed directory of output file to: \""+output_path+"\"")
            if(output_path[-1]!="/"):
                output_path += "/"  # check if last char is a "/", if not append one
            ensure_dir(output_path) # check of output_path is a directory, if not create it

        if((arg == "-help") or (arg == "-h")):
            used_arguments[5] = 1

    if((used_arguments[0] == 0) or (used_arguments[5] == 1)):
        print("append argument \"-new\" to create new csv-file, appending existing csv-file")        
    if((used_arguments[1] == 0) or (used_arguments[5] == 1)):
        print("append argument \"-debug\" to output debug information")
    if((used_arguments[2] == 0) or (used_arguments[5] == 1)):
        print("append argument \"-nofile\" to not write data to output file")
    if((used_arguments[3] == 0) or (used_arguments[5] == 1)):
        print("append argument \"-example\" to create example output file")
    if((used_arguments[4] == 0) or (used_arguments[5] == 1)):
        print("append argument \"-dir=dirname\" to change directory of output file")
    if(used_arguments[5] == 1):
        exit()

check_arguments(sys.argv)

try:
    if(not dummyOutput_flag): 
        ser = serial.Serial(port, baudrate = 9600 )
    else:
        print("Skipped opening serial port")
except:
    print("Error opening Serial Port")
    exit()

print("starting")
if(not dummyOutput_flag):
    ser.readline()
while True:
    date_now = datetime.datetime.now()
    if(not dummyOutput_flag):
        rcv = ser.readline()
        date_string = str(date_now.strftime("%Y")) + ";" + str(date_now.strftime("%m")) + ";" + str(date_now.strftime("%d")) + ";" + str(date_now.strftime("%H")) + ";" + str(date_now.strftime("%M")) + ";" + str(date_now.strftime("%S"))
        data_string = rcv.decode()
        data_string = data_string.replace("\t",";")
        data_string = data_string.replace("\n",";")
        output_string = date_string+";"+data_string+"\n"
    

    example_string = ""
    if(dummyOutput_flag):
        example_string = "example"

    logfile = output_path+"Wetterlog"+str(date_now.date())+"_"+example_string+".csv"
    write_mode = "w" #overwrite existing
    append_mode = "a" #append existing

    if(not os.path.exists(logfile)):
        file = open(logfile,write_mode)
        file.write("Year;Month;Day;Hour;Minute;Second;Relative Humidity;Temperature;Atmospheric Pressure;UP;bmp_temperature;Lightintensity\n")
        file.close()

    if(not dummyOutput_flag):
        i = 0
        for pos in output_string:
            #print("pos: "+pos)
            if(pos == ";"):
                i = i + 1
        if((i == 12) and (write_file_flag == 1)):
            file = open(logfile,append_mode)
            file.write(output_string)
            file.close()

    if(debug == 1):
        print("data_string: "+output_string)
        print("number of fields: "+str(i))
    
    if(dummyOutput_flag):
        print("Created example output file: "+logfile)
        exit()