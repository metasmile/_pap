#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os, fnmatch, re, codecs

#INFO: always normally check commented time and number '\s[0-9]{1,}\s{0,}\/\/[0-9]{1,}' (e.g. 30//60*40, 30//200 ...)

src_path = './pap/'
swift_files = []
qs = re.compile(r'\s[0-9]{1,}\s{0,}\/\/[0-9]{1,}', re.I|re.U)

for root, dirnames, filenames in os.walk(src_path):
    for filename in fnmatch.filter(filenames, '*.swift'):
        swift_files.append(os.path.join(root, filename))

error_lines = []
for code_file in swift_files:
    rcur = codecs.open(code_file, "r", "utf-8")
    wlines = []
    for i, line in enumerate(rcur.readlines()):
        if qs.search(line):
            error_lines.append((code_file, line))

if error_lines:
    msg = "Validation Error: Commented numbers found:\n"
    for l in error_lines:
        msg += "at {}\n{}".format(l[0], l[1])
    raise BaseException(msg)
    sys.exit(1)
