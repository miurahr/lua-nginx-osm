#!/usr/bin/env python
import sys
import re
import string

res = []
for line in sys.stdin:
    m = re.match('(-)?\d+\.\d+,(-)?\d+\.\d+',line)
    if m:
        res.append(m.group().translate(string.maketrans(',', ' ')))

print len(res)
for line in res:
    print line
