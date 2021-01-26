#!/bin/env python3

import argparse
import sys, os

parser = argparse.ArgumentParser()
parser.add_argument('--file', help='file name', required=True)
parser.add_argument('--string_infile', help='ip address inside the file', required=True)
parser.add_argument('--string_tochange', help='ip address to change', required=True)
args = parser.parse_args()

file_name = args.file
string_tochange = args.string_tochange
string_infile = args.string_infile

print('File name: ', file_name)
print('IP address to change: ', string_tochange)

with open(file_name, 'r+') as file:
    content = file.read()
    file.seek(0)
    content = content.replace(string_infile, string_tochange)
    file.write(content)
