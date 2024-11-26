import numpy as np
import sys, getopt
import math
from struct import *
np.random.seed(123)
# data_format="INTEGER" # INTEGER, FLOATING_POINT

def float_to_hex(f):
  return hex(unpack('<I', pack('<f', f))[0])


def convert_header_to_dat(address, row_size, col_size):
  address = 0x00000000
  file_str = "// Row size: {}, Column size: {}\n".format(row_size, col_size)
  file_str += " @{:08X} ".format(0) + "{:04X}".format(row_size)+ "{:04X} \n".format(col_size)
  return file_str


def convert_matrix_to_dat(matrix, address, row_size, col_size, file_str, data_format):
  for i,row in enumerate(matrix):
    print(f"i = {i}, row = {row}")
    for j,elements in enumerate(row):
      print(f"j = {j}, col = {elements}")
      print(f"address = {(address+(i*col_size)+j)}")
      file_str+="// {:.7f} \n".format(elements)
      if data_format == "INTEGER":
        file_str+=" @{:08X} ".format(address+(i*col_size)+j) + "{:08X}".format(elements) + "\n"    
      elif data_format == "FLOATING_POINT":
        file_str+=" @{:08X} ".format(address+(i*col_size)+j) + float_to_hex(elements).replace('0x','') + "\n"    

  return file_str



def main(argv):
  try:
    opts, args = getopt.getopt(argv,"o:i:d:r:c:x:y:t:",["iDir=","oDir="])
  except getopt.GetoptError as err:
    print(err)  # will print something like "option -a not recognized"
    usage()
    sys.exit(2)

  testFileName=''
  for opt, arg in opts:
    if "-r" in opt:
      input_row_size = int(arg)
    elif "-c" in opt:
      input_col_size = int(arg)
    elif "-t" in opt:
      print(f"testFileName received = {arg}")
      testFileName = arg	
    elif "-x" in opt:
      weight_row_size = int(arg)
    elif "-y" in opt:
      weight_col_size = int(arg)
    elif "-d" in opt:
      data_format = str(arg)
      print(f"data_format = {data_format}")
      
  if data_format=="INTEGER":
    input_matrix = np.random.randint(1, 10,size=[input_row_size,input_col_size])    
  elif data_format=="FLOATING_POINT":
    input_matrix = np.single(np.random.uniform(1,-1,size=[input_row_size,input_col_size]))
  
  if data_format=="INTEGER":
    weight_q_matrix = np.random.randint(1, 10,size=[weight_row_size,weight_col_size])
    weight_k_matrix = np.random.randint(1, 10,size=[weight_row_size,weight_col_size])
    weight_v_matrix = np.random.randint(1, 10,size=[weight_row_size,weight_col_size])
  elif data_format == "FLOATING_POINT":
    weight_q_matrix = np.single(np.random.uniform(1,-1,size=[weight_row_size,weight_col_size])) 
    weight_k_matrix = np.single(np.random.uniform(1,-1,size=[weight_row_size,weight_col_size])) 
    weight_v_matrix = np.single(np.random.uniform(1,-1,size=[weight_row_size,weight_col_size])) 
  
  weight_q_matrix_transpose = np.array(weight_q_matrix).T.tolist()
  weight_k_matrix_transpose = np.array(weight_k_matrix).T.tolist()
  weight_v_matrix_transpose = np.array(weight_v_matrix).T.tolist()
  
  query_matrix = np.matmul(input_matrix, weight_q_matrix)
  key_matrix = np.matmul(input_matrix, weight_k_matrix)
  value_matrix = np.matmul(input_matrix, weight_v_matrix)
  
  score_matrix = np.matmul(query_matrix, key_matrix.transpose())
  print(f"score_matrix = {score_matrix}")

  # scaled_score_matrix = np.divide(score_matrix, 8)
  # print(f"scaled_score_matrix = {scaled_score_matrix}")

  attn_matrix = np.matmul(score_matrix, value_matrix)
  print(f"attn_matrix = {attn_matrix}")

  # ----------------- Input matrix generation -------------------- #
  input_address = 0x00000000
  input_str = "// Row size: {}, Column size: {}\n".format(input_row_size, input_col_size)
  input_str += " @{:08X} ".format(0) + "{:08X}".format(input_row_size)+ "{:08X} \n".format(input_col_size)
  
  input_str = convert_header_to_dat(
    address = input_address,
    row_size=input_row_size,
    col_size=input_col_size
    )
  print(f"Input matrix generation")
  input_str = convert_matrix_to_dat(
    matrix=input_matrix, 
    address=input_address+1, 
    row_size=input_row_size, 
    col_size=input_col_size, 
    file_str=input_str,
    data_format=data_format
    )

  with open(f"{testFileName}_input.dat","w") as F:
    F.write(input_str)
  
  # ----------------- Weight matrix generation -------------------- #
  print(f"Weight matrix generation")
  weight_address = 0x00000000
  weight_str = convert_header_to_dat(
    address =weight_address,
    row_size=weight_row_size,
    col_size=weight_col_size
    )
  weight_str = convert_matrix_to_dat(
    matrix=weight_q_matrix_transpose, # Weight transpose is matrix is stored in memory to ease the controller
    address=weight_address+1, 
    row_size=weight_col_size, # Row and column size is flipped in Weight transpose matrix 
    col_size=weight_row_size, # Row and column size is flipped in Weight transpose matrix
    file_str=weight_str,
    data_format=data_format
    )
  
  weight_address = weight_address + (weight_col_size*weight_row_size)
  weight_str = convert_matrix_to_dat(
    matrix=weight_k_matrix_transpose, # Weight transpose is matrix is stored in memory to ease the controller
    address=weight_address+1, 
    row_size=weight_col_size, # Row and column size is flipped in Weight transpose matrix 
    col_size=weight_row_size, # Row and column size is flipped in Weight transpose matrix
    file_str=weight_str,
    data_format=data_format
    )

  weight_address = weight_address + (weight_col_size*weight_row_size)
  weight_str = convert_matrix_to_dat(
    matrix=weight_v_matrix_transpose, # Weight transpose is matrix is stored in memory to ease the controller
    address=weight_address+1, 
    row_size=weight_col_size, # Row and column size is flipped in Weight transpose matrix 
    col_size=weight_row_size, # Row and column size is flipped in Weight transpose matrix
    file_str=weight_str,
    data_format=data_format
    )

  with open(f"{testFileName}_weight.dat","w") as F:
    F.write(weight_str)

  # ----------------- Result matrix generation -------------------- #
  result_str = ""
  result_address = 0x00000000
  print(f"Query matrix data generation")
  result_str = convert_matrix_to_dat(
    matrix=query_matrix, 
    address=result_address, 
    row_size=input_row_size, 
    col_size=weight_col_size,  
    file_str=result_str,
    data_format=data_format
    )
  result_address = result_address + (input_row_size * weight_col_size)
  print(f"Key matrix data generation")
  result_str = convert_matrix_to_dat(
    matrix=key_matrix, 
    address=result_address, 
    row_size=input_row_size, 
    col_size=weight_col_size,  
    file_str=result_str,
    data_format=data_format
    )
  result_address = result_address + (input_row_size * weight_col_size)
  print(f"Value matrix data generation")
  result_str = convert_matrix_to_dat(
    matrix=value_matrix, 
    address=result_address, 
    row_size=input_row_size, 
    col_size=weight_col_size,  
    file_str=result_str,
    data_format=data_format
    )
  result_address = result_address + (input_row_size * weight_col_size)
  print(f"Score matrix data generation")
  result_str = convert_matrix_to_dat(
    matrix=score_matrix, 
    address=result_address, 
    row_size=input_row_size, 
    col_size=input_row_size,  
    file_str=result_str,
    data_format=data_format
    )
  result_address = result_address + (input_row_size * input_row_size)
  print(f"Attn matrix data generation")
  result_str = convert_matrix_to_dat(
    matrix=attn_matrix, 
    address=result_address, 
    row_size=input_row_size, 
    col_size=weight_col_size,  
    file_str=result_str,
    data_format=data_format
    )

  with open(f"{testFileName}_result.dat","w") as F:
    F.write(result_str)

if __name__ == "__main__":
     print(sys.argv[1:])
     main(sys.argv[1:])
