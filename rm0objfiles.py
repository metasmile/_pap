#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os, fnmatch

dest_app_path = './DerivedData/Build'
ofiles = []
for root, dirnames, filenames in os.walk(dest_app_path):
    for filename in fnmatch.filter(filenames, '*.o'):
        ofiles.append(os.path.join(root, filename))

for code_file in ofiles:
    if os.stat(code_file).st_size == 0L:
        os.remove(code_file)
