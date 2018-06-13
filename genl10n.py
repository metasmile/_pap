#!/usr/bin/python
# -*- coding: utf-8 -*-

import sys
import os, time, datetime, re, argparse, textwrap, subprocess
from datetime import date, timedelta
from time import mktime
from os.path import expanduser
import shutil
from distutils.dir_util import copy_tree
import json
import glob
import codecs
import fnmatch

dest_app_path = './pap/'
dest_l10n_base_path ='./pap/Resources/Localizations/Base.lproj/Localizable.strings'
split_key = '.localized'

complied_patterns_by_priority = [
    re.compile(r'((\"\b.*\b\")' + split_key + ')', re.I|re.U|re.MULTILINE|re.X)
    , re.compile(r'((\".*\")' + split_key + ')', re.I|re.U|re.MULTILINE|re.X)
]

# for excluing format literal -> \(value)
qs = re.compile(r'\\\((.+)\)', re.I|re.U)

swift_files = []

for root, dirnames, filenames in os.walk(dest_app_path):
    for filename in fnmatch.filter(filenames, '*.swift'):
        swift_files.append(os.path.join(root, filename))

gened_strs = {}
for code_file in swift_files:
    rcur = codecs.open(code_file, "r", "utf-8")
    wlines = []
    for line in rcur.readlines():
        for line_sp in line.split(split_key):

            for p in complied_patterns_by_priority:
                loc_strs = p.search(line_sp + split_key)

                if loc_strs:
                    str = loc_strs.group()

                    # unwrap overlapped quote "
                    str = '"'+str.split('"')[-2]+'"'

                    if qs.search(str):
                        # for excluding literal format e.g. -> %d \(pluralizedString)
                        continue

                    if not str in gened_strs:
                        gened_strs[str] = []

                    if not code_file in gened_strs[str]:
                        gened_strs[str].append(code_file)


rcur = codecs.open(dest_l10n_base_path, "r", "utf-8")
rlines = rcur.readlines()
rcur.close()

wlines = []
for line in rlines:
    wlines.append(line)

keys_in_l10n_file = map(lambda line: line.split("=")[0], rlines)
keys_in_gened_strs = [k for k, v in gened_strs.items()]

for new_key in list(set(keys_in_gened_strs) - set(keys_in_l10n_file)):
    new_line = u'{0} = {0};'.format(new_key)
    print("Added line: " + new_line.encode('utf8'))

    from_files = ", ".join(map(lambda s: os.path.basename(s), gened_strs[new_key]))
    wlines.append('\n')
    wlines.append("/* Generated from: {}*/".format(from_files))
    wlines.append('\n')
    wlines.append(new_line)

print(len(keys_in_gened_strs))

wcur = codecs.open(dest_l10n_base_path, "w", "utf-8")
wcur.writelines(wlines)
wcur.close()
