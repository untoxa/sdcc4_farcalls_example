#!/usr/bin/env python
# -*- coding: utf-8 -*-
# vim: sts=4 sw=4 et
# Description: Far call fixer for SDCC4 for gbz80 object files
# Author: Tony Pavlov (untoxa)
# SPDX-License-Identifier: MIT

import sys
from struct import unpack

banks_by_symbol = {}

def load_symbols(filename):
    with open(filename) as f:
        area = None
        line = f.readline()
        while line:
            decoded_line = [x.strip() for x in line.split()]
            type = decoded_line[0]
            if type == 'A':
                area = decoded_line[1]
            elif type == 'S':
                if area is not None:
                    decoded_area = [x.strip() for x in area.split('_')]
                    if len(decoded_area) >= 2:
                        if decoded_area[1] == 'CODE':
                            bank_no = 0 if len(decoded_area) == 2 else int(decoded_area[2])
                            banks_by_symbol.setdefault(decoded_line[1], [bank_no, 0])
                        elif decoded_area[1] == 'DATA':
                            bank_no = 0 if len(decoded_area) == 2 else int(decoded_area[2])
                            banks_by_symbol.setdefault(decoded_line[1], [bank_no, 1])
            
            line = f.readline()
    return

def fix_far_calls(filename):
    symbols = [[]]
    area_idx = 0
    current_area = 0
    farcall_detected = False
    last_T = last_last_T = None
    patch_ofs = -1
    patch_value = None
    message = ''
    with open(filename) as f:
        prev_line = None
        line = f.readline()
        while line:
            decoded_line = [x.strip() for x in line.split()]
            type = decoded_line[0]
            
            if type == 'A':
                symbols.append([])
                area_idx += 1
            elif type == 'S':
                symbols[area_idx].append(decoded_line[1])
            elif type == 'T':
                last_last_T = last_T
                last_T = int(decoded_line[-1], 16)
                # we have a delayed patch from a previous iteration
                if patch_ofs >= 0:
                    decoded_line[patch_ofs + 1 + 2] = patch_value
                    line = ' '.join(decoded_line) + '\n'
                    sys.stderr.write('{:s} [delayed patch]\n'.format(patch_message))
                    patch_ofs = -1
            elif type == 'R':
                # decode previous line
                prev_decoded_line = [x.strip() for x in prev_line.split()]
                if prev_decoded_line[0] != 'T': 
                    sys.exit('ERROR: PREVIOUS LINE IS NOT A CODE')
                i = 5
                while i < len(decoded_line):
                    mode = int(decoded_line[i], 16)
                    if mode & 0xf0 == 0xf0:
                        sys.exit('ERROR: MODE ENCODING NOT SUPPORTED YET Line:"{:s}"'.format(line))
                    if (mode & 2):
                        # global symbol detected
                        current_area = 0
                        idx = int(decoded_line[i + 3], 16) << 8 | int(decoded_line[i + 2], 16)
                    else:
                        # area/symbol detected
                        current_area = int(decoded_line[i + 2], 16) + 1
                        idx = int(decoded_line[i + 3], 16) 

                    ofs = int(decoded_line[i + 1], 16)
                    
                    if not farcall_detected:
                        if symbols[current_area][idx] == 'banked_call':
                            # we need to check, that it is a call, not "dw #banked_call"
                            # "db 0xCD dw #banked_call" case is not supported, don't do this!
                            farcall_detected = ((int(prev_decoded_line[ofs], 16) if ofs > 2 else last_last_T) in [0xCD, 0xDC, 0xD4, 0xC4, 0xCC])
                    else:
                        bank = banks_by_symbol.get(symbols[current_area][idx])
                        if bank is not None:
                            patch_ofs = ofs + 1 + 2
                            patch_value = '{:02X}'.format(bank[0])
                            patch_message = 'patching call to {:s} into _{:s}_{:d}'.format(symbols[current_area][idx], 'CODE' if bank[1] == 0 else 'DATA', bank[0])
                            if patch_ofs < len(prev_decoded_line):
                                prev_decoded_line[patch_ofs] = patch_value
                                prev_line = ' '.join(prev_decoded_line) + '\n'
                                sys.stderr.write('{:s}\n'.format(patch_message))
                            patch_ofs = patch_ofs - len(prev_decoded_line) 
                        else:
                            sys.stderr.write('WARNING: SYMBOL {:s} NOT FOUND Line:"{:s}"\n'.format(symbols[current_area][idx], line))
                        farcall_detected = False
                    i += 4
            # output previous line (patched or not)
            if prev_line is not None:
                sys.stdout.write(prev_line)
            prev_line = line
            line = f.readline()            
        # output previous line (patched or not)    
        if prev_line is not None:
            sys.stdout.write(prev_line)
    return

if len(sys.argv) <= 1:
    sys.exit(('FAR CALL FIXER v0.2a\n'
              '  USAGE: far_fixer.py <file1.rel> <file2.rel> ...\n'
              '  The last file in the list will be fixed and dumped to stdout'))

filename_to_fix  = sys.argv[-1] # the last one for now

for arg in sys.argv[1:]:
    load_symbols(arg)

fix_far_calls(filename_to_fix)
