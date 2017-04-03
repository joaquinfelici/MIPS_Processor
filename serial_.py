import math
import serial

def print_registers(bytes_recieved):
	bytes_array = bytearray(bytes_recieved)
	reg_array = []
	bytes_counter = 0
	reg_counter = 0

	while(bytes_counter < len(bytes_array)):
		reg = bytes_array[bytes_counter+3] + (bytes_array[bytes_counter+2] * pow(2,8)) + (bytes_array[bytes_counter+1] * pow(2,16)) + (bytes_array[bytes_counter+0] * pow(2,24))
		reg_array.append(reg)
		bytes_counter += 4
		reg_counter += 1
	
	gpr = reg_array[17:49]	# Positions of registers whitin the pack of recieved bytes
	mem = reg_array[49:81]  # Positions of memory whitin the pack of recieved bytes

	print "\nSpecial registers:\n "
	print "   PC  =  %s"%(reg_array[0])

	print "\nIntermediate latches: "
	print " \n   DE_Instruction =  %s"%('{:032b}'.format(reg_array[1]))
	print "   DE_PCPlus4 =  %s"%(reg_array[2])
	print " \n   EX_OperandA =  %s"%(reg_array[3])
	print "   EX_OperandB =  %s"%(reg_array[4])
	print "   EX_Immediate =  %s"%(reg_array[5])
	print "   EX_RegWriteTypeR =  %s"%(reg_array[6])
	print "   EX_RegWriteTypeI=  %s"%(reg_array[7])
	print "   EX_PCPlus4 =  %s"%(reg_array[8])
	print " \n   ME_ALUResult =  %s"%(reg_array[9])
	print "   ME_DataStore =  %s"%(reg_array[10])
	print "   ME_RegWrite =  %s"%(reg_array[11])
	print "   ME_PCPlus4 =  %s"%(reg_array[12])
	print " \n   WB_ALUResult =  %s"%(reg_array[13])
	print "   WB_DataLoad =  %s"%(reg_array[14])
	print "   WB_RegWrite =  %s"%(reg_array[15])
	print "   WB_PCPlus4 =  %s"%(reg_array[16])

	print "\nGeneral purpose registers:\n "
	for i in range(0,32,4):
		print "   REG[%2d] = %2s    REG[%2d] = %2s    REG[%2d] = %2s    REG[%2d] = %2s  "%(i,gpr[i], i+1,gpr[i+1], i+2,gpr[i+2], i+3,gpr[i+3])

	print "\nData memory:\n "
	for i in range(0,32,4):
		print "   MEM[%2d] = %2s    MEM[%2d] = %2s    MEM[%2d] = %2s    MEM[%2d] = %2s  "%(i,mem[i], i+1,mem[i+1], i+2,mem[i+2], i+3,mem[i+3])

	print ""

def main():
	# port number may change!
	ser = serial.Serial(port = 'COM4', baudrate = 19200, stopbits = serial.STOPBITS_ONE, bytesize = serial.EIGHTBITS, timeout = 2)

	print "\nOptions: \n 'c' for continuous mode \n 's' for stepping mode \n 'q' to quit \n"
	input = 1
	
	while input != 'q':
		input = raw_input(">> ")
		if input is 'q':
			print "Exiting..."
			break
		if input is 'c' or input is 's':
			byte_to_send = input.encode("utf-8")
			ser.write(byte_to_send)
			bytes_recieved = ser.read(512)
			print_registers(bytes_recieved)
		else:
			print "Invalid opion! \n"

	ser.close()

if __name__=='__main__':
	main()