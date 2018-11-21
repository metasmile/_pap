#!/usr/bin/env python
# -*- coding: utf-8 -*-

import sys
import os, fnmatch, re, codecs

#INFO: always normally check commented time and number '\s[0-9]{1,}\s{0,}\/\/[0-9]{1,}' (e.g. 30//60*40, 30//200 ...)

src_path = './youl10n/batch'
l10n_files = []
qs = re.compile(r'\s[0-9]{1,}\s{0,}\/\/[0-9]{1,}', re.I|re.U)

for root, dirnames, filenames in os.walk(src_path):
    for filename in fnmatch.filter(filenames, '*.txt'):
        l10n_files.append(os.path.join(root, filename))

error_lines = []
line_kv = {}
for code_file in l10n_files:
    lang_key_code = os.path.basename(code_file).split("_")[0]
    line_kv[lang_key_code] = {}
    rcur = codecs.open(code_file, "r", "utf-8")
    p_line = ""
    for i, line in enumerate(rcur.readlines()):
        if line[0] == "=":
            _k = p_line.replace("\n", "").strip()
            _v = line.replace("=", "").strip()
            line_kv[lang_key_code][_k] = _v
        p_line = line
        if qs.search(line):
            error_lines.append((code_file, line))

if error_lines:
    msg = "Validation Error: Commented numbers found:\n"
    for l in error_lines:
        msg += "at {}\n{}".format(l[0], l[1])
    raise BaseException(msg)
    sys.exit(1)


res_line_kv = {}
res_path = './batch/Resources/Localizations/'
result_msgs = []

for root, dirnames, filenames in os.walk(res_path):
    if res_path == root:
        continue

    lcode = os.path.basename(root).split(".")[0]

    if lcode in line_kv:
        matched_key_cnt = 0
        modified_key_cnt = 0

        line_kv_of_code = line_kv[lcode]

        rcur = codecs.open(os.path.join(root, "Localizable.strings"), "r", "utf-8")

        res_lines = []
        for i, line in enumerate(rcur.readlines()):

            new_line = None

            line_spl = line.replace("\"","").replace(";","").strip().split("=")
            if len(line_spl) == 2:
                _k = line_spl[0].strip()
                _v = line_spl[1].strip()

                for k in line_kv_of_code:
                    if _k == k.strip():
                        matched_key_cnt += 1
                        v = line_kv_of_code[k]

                        if v != _v:
                            new_line = u'"{0}" = "{1}";\n'.format(k,v)

            if new_line is not None:
                modified_key_cnt +=1
                print "[i] Corrected line value - ", _v ,"->>",new_line.split("=")[1].replace("\"","")
                res_lines.append(new_line)
            else:
                res_lines.append(line)

        wcur = codecs.open(os.path.join(root, "Localizable.strings"), "w", "utf-8")
        wcur.writelines(res_lines)
        wcur.close()

        mm = ' '.join(map(str,(lcode, "- Matched:",matched_key_cnt, "Modified:",modified_key_cnt)))
        result_msgs.append(mm)


print "Results:"
for r in result_msgs:
    print(r)
