#!/usr/bin/env python

import fileinput
for line in fileinput.input():
    split = line.split()
    if '=>' in split:
        split.remove('=>')
    name = split[-2]
    if name != 'linux-vdso.so.1':
        print(name)
