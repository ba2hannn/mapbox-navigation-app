#!/usr/bin/env python3
import os, re, json, sys
root = os.path.abspath(os.path.dirname(os.path.dirname(__file__)))
libdir = os.path.join(root, 'lib')

if not os.path.isdir(libdir):
    print(json.dumps({'error': 'lib directory not found', 'libdir': libdir}))
    sys.exit(1)

dart_files = []
for dirpath, dirs, files in os.walk(libdir):
    for f in files:
        if f.endswith('.dart'):
            dart_files.append(os.path.normpath(os.path.join(dirpath, f)))

a = set(dart_files)

import_re = re.compile(r"['\"]([^'\"]+\.dart)['\"]")
referenced = set()

for path in dart_files:
    try:
        txt = open(path, 'r', encoding='utf-8').read()
    except Exception:
        continue
    for m in import_re.findall(txt):
        imp = m
        if imp.startswith('package:'):
            # skip package imports
            continue
        # resolve relative path
        if imp.startswith('/'):
            candidate = os.path.normpath(os.path.join(root, imp.lstrip('/')))
        else:
            candidate = os.path.normpath(os.path.join(os.path.dirname(path), imp))
        if candidate in a:
            referenced.add(candidate)

heuristic_keep = set()
for p in dart_files:
    if p.endswith('main.dart') or os.path.basename(p) in ('firebase_options.dart',):
        heuristic_keep.add(p)

unref = sorted(list(a - referenced - heuristic_keep))

out = {
    'total_dart_files': len(dart_files),
    'referenced_count': len(referenced) + len(heuristic_keep),
    'unreferenced_count': len(unref),
    'unreferenced_files': unref
}
print(json.dumps(out, indent=2, ensure_ascii=False))
