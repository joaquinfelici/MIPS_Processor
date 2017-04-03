# Reads an assembly file called "instrucciones.txt" and
# generates a bin file named "instructions.bin".

TIPO_R = 0
TIPO_I = 1
TIPO_J = 2
TIPO_END = 9

SUBTIPO_1 = 3
SUBTIPO_2 = 4
SUBTIPO_3 = 5
SUBTIPO_4 = 6
SUBTIPO_5 = 7
SUBTIPO_6 = 8

lista_instrucciones = {
 
	"HALT":  ["111111", TIPO_END, SUBTIPO_1],
	# Tipo R
	"SLL":  ["000000", TIPO_R, SUBTIPO_1],
	"SRL":  ["000010", TIPO_R, SUBTIPO_1],
	"SRA":  ["000011", TIPO_R, SUBTIPO_1],
	"SRLV": ["000110", TIPO_R, SUBTIPO_2],
	"SRAV": ["000111", TIPO_R, SUBTIPO_2],
	"ADD":  ["100001", TIPO_R, SUBTIPO_3],
	"SLLV": ["000100", TIPO_R, SUBTIPO_2],
	"SUB":  ["100011", TIPO_R, SUBTIPO_3],
	"AND":  ["100100", TIPO_R, SUBTIPO_3],
	"OR":   ["100101", TIPO_R, SUBTIPO_3],
	"XOR":  ["100110", TIPO_R, SUBTIPO_3],
	"NOR":  ["100111", TIPO_R, SUBTIPO_3],
	"SLT":  ["101010", TIPO_R, SUBTIPO_3],

	# Tipo I
	"LB":   ["100000", TIPO_I, SUBTIPO_1],
	"LH":   ["100001", TIPO_I, SUBTIPO_1],
	"LW":   ["100011", TIPO_I, SUBTIPO_1],
	"LWU":  ["100111", TIPO_I, SUBTIPO_1],
	"LBU":  ["100100", TIPO_I, SUBTIPO_1],
	"LHU":  ["100101", TIPO_I, SUBTIPO_1],
	"SB":   ["101000", TIPO_I, SUBTIPO_1],
	"SH":   ["101001", TIPO_I, SUBTIPO_1],
	"SW":   ["101011", TIPO_I, SUBTIPO_1],
	"ADDI": ["001000", TIPO_I, SUBTIPO_2],
	"ANDI": ["001100", TIPO_I, SUBTIPO_2],
	"ORI":  ["001101", TIPO_I, SUBTIPO_3],
	"XORI": ["001110", TIPO_I, SUBTIPO_2],
	"LUI":  ["001111", TIPO_I, SUBTIPO_4],
	"SLTI": ["001010", TIPO_I, SUBTIPO_3],
	"BEQ":  ["000100", TIPO_I, SUBTIPO_5],
	"BNE":  ["000101", TIPO_I, SUBTIPO_5],
	"J":    ["000010", TIPO_I, SUBTIPO_6],
	"JAL":  ["000011", TIPO_I, SUBTIPO_6],

	# Tipo J
	"JR":   ["001000", TIPO_J, SUBTIPO_1],
	"JALR": ["001001", TIPO_J, SUBTIPO_2],
}

def quitar_comentarios(linea):
	linea = linea.split(";")
	txt_instruccion = linea[0]
	return txt_instruccion

def separar_operandos(linea):
	linea = linea.replace(",", " ")
	data = linea.split()
	instruccion = data[0]
	operandos = data[1:]
	return instruccion, operandos

def dec_bin(numero, digitos=5):
	if numero >= 0:
		binario = "{0:b}".format(numero)
		longitud_actual = len(binario)
		if longitud_actual < digitos:
			binario = (digitos - longitud_actual) * "0" + binario
	else:
		max_value = (2**digitos)
		new_numero = max_value + numero #el numero es negativo entonces se le resta
		binario = "{0:b}".format(new_numero)
		longitud_actual = len(binario)
		if longitud_actual < digitos:
			binario = (digitos - longitud_actual) * "1" + binario

	return binario

def parse_end(instruccion):
	instruccion_binaria = "1" * 6 + "0" *26
	return instruccion_binaria


def parse_r(instruccion, operandos):
	subtipo = lista_instrucciones[instruccion][2]
	codigo_operacion = lista_instrucciones[instruccion][0]

	instruccion_binaria = "0" * 6

	#print operandos
	for operando in operandos:
		index =  operandos.index(operando)
		if "R" in operando:
			operandos[index] = operandos[index].replace('R','')
		if "#" in operando:
			operandos[index] = operandos[index].replace('#','')
	#print operandos

	if subtipo == SUBTIPO_1:
		instruccion_binaria += "0" * 5
		instruccion_binaria += dec_bin(int(operandos[1]))
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += dec_bin(int(operandos[2]))
	elif subtipo == SUBTIPO_2:
		instruccion_binaria += dec_bin(int(operandos[2]))
		instruccion_binaria += dec_bin(int(operandos[1]))
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += "0" * 5
	elif subtipo == SUBTIPO_3:
		instruccion_binaria += dec_bin(int(operandos[1]))
		instruccion_binaria += dec_bin(int(operandos[2]))
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += "0" * 5

	instruccion_binaria += codigo_operacion

	return instruccion_binaria


def parse_i(instruccion, operandos):
	subtipo = lista_instrucciones[instruccion][2]
	codigo_operacion = lista_instrucciones[instruccion][0]

	instruccion_binaria = codigo_operacion

	for operando in operandos:
		index =  operandos.index(operando)
		if "R" in operando:
			operandos[index] = operandos[index].replace('R','')
		if "#" in operando:
			operandos[index] = operandos[index].replace('#','')

	if subtipo == SUBTIPO_1:
		operandos[1] = operandos[1].replace("(", " ")
		operandos[1] = operandos[1].replace(")", "")
		operandos.append(operandos[1].split()[1]) 
		operandos[1] = operandos[1][0] 

		instruccion_binaria += dec_bin(int(operandos[2]))
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += dec_bin(int(operandos[1]), digitos=16)
	elif subtipo == SUBTIPO_2 or subtipo == SUBTIPO_3:
		instruccion_binaria += dec_bin(int(operandos[1]))
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += dec_bin(int(operandos[2]), digitos=16)
	elif subtipo == SUBTIPO_4:
		instruccion_binaria += "0" * 5
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += dec_bin(int(operandos[1]), digitos=16)
	elif subtipo == SUBTIPO_5:
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += dec_bin(int(operandos[1]))
		instruccion_binaria += dec_bin(int(operandos[2]), digitos=16)
	elif subtipo == SUBTIPO_6:
		instruccion_binaria += dec_bin(int(operandos[0]), digitos=26)

	return instruccion_binaria


def parse_j(instruccion, operandos):
	subtipo = lista_instrucciones[instruccion][2]
	codigo_operacion = lista_instrucciones[instruccion][0]

	instruccion_binaria = "0" * 6

	for operando in operandos:
		index =  operandos.index(operando)
		if "R" in operando:
			operandos[index] = operandos[index].replace('R','')
		if "#" in operando:
			operandos[index] = operandos[index].replace('#','')

	if subtipo == SUBTIPO_1:
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += "0" * 15
	elif subtipo == SUBTIPO_2:
		instruccion_binaria += dec_bin(int(operandos[0]))
		instruccion_binaria += "0" * 5

		if len(operandos) > 1:
			instruccion_binaria += dec_bin(int(operandos[1]))
		else:
			instruccion_binaria += "1" * 5

		instruccion_binaria += "0" * 5

	instruccion_binaria += codigo_operacion

	return instruccion_binaria

def parsear_instrucciones():
	txt_file = open("instrucciones.txt", 'r')
	txt_instrucciones = txt_file.readlines()
	
	comandos_binario = []

	for linea in txt_instrucciones:
		linea = linea.strip()
		linea = quitar_comentarios(linea)
		if len(linea) > 3:
			instruccion, operandos = separar_operandos(linea) 			
			instruccion_binaria = {
			  TIPO_END: lambda x: parse_end(x),
			  TIPO_I: lambda x: parse_i(x, operandos),
			  TIPO_J: lambda x: parse_j(x, operandos),
			  TIPO_R: lambda x: parse_r(x, operandos)
			}[lista_instrucciones[instruccion][1]](instruccion)
			
			comandos_binario.append(instruccion_binaria)
				
	return comandos_binario


def main():
	comandos = parsear_instrucciones()
	print "\nBin file successfully generated! \n "	
	for comando in comandos:
		print comando
	salida = open("instructions.bin", "w")
	for comando in comandos:	
		salida.write(comando[0:8])
		salida.write(comando[8:16])
		salida.write(comando[16:24])
		salida.write(comando[24:32])
		salida.write('\n')
	salida.close()

if __name__=='__main__':
	main()