#!/bin/bash
# Convertes gds to geo
#   Firtst input: .i2i file
#   Second input: .gds or a file with .gds list (separated by space or \n)

if [ -z "$1" ] || [ -z "$2" ]
then
  echo "Too few arguments."
  echo "Example: $0 file.i2i file.gds" 
  exit 0
fi

file1=$1
file2=$2

if [ ${file1: -4} == ".i2i" ]; then
  gdslist=$2
  templatefile=$1
elif [ ${file2: -4} == ".i2i" ]; then
  gdslist=$1
  templatefile=$2
else
  echo "Wrong input file"
  echo "Example: $0 file.i2i file.gds" 
  exit 0
fi

if [ ${gdslist: -4} == ".gds" ]; then
  gdsfiles[0]=${gdslist}
else
  gdsfiles=`cat ${gdslist}`
fi

for file in ${gdsfiles}
do
  gdsfile=`echo ${file}|sed 's/[[:space:]]*$//'`
  echo "converting file ${file}"
  echo "converting file ${templatefile}"
  ie3dos -m 201 -g ${templatefile} ${file}
done
