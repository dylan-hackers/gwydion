#!/bin/sh
rm -f TAGS
find common d2c/compiler d2c/runtime -name *.dylan | xargs -n1 etags -a -l none -r "/define \(\(sealed\|open\|abstract\|concrete\|primary\|free\|inline\|movable\|flushable\|functional\|\/\*\s*exported\s*\*\/\) \)*\(method\|generic\|function\|class\|variable\|constant\|macro\) \([-A-Za-z0-9!&*<>|^$%@_?=]+\)/" -r "/[ \t]*\(\(virtual\|constant\|sealed\|instance\|class\|each-subclass\|\/\*\s*exported\s*\*\/\) \)*slot \([-A-Za-z0-9!&*<>|^$%@_?=]+\)/" -


#!/bin/sh
rm -f TAGS
find common d2c/compiler d2c/runtime -name *.dylan | xargs -n1 etags -a -l none -r "/define \(\(sealed\|open\|abstract\|concrete\|primary\|free\|inline\|movable\|flushable\|functional\|\/\*\s*exported\s*\*\/\) \)*\(method\|generic\|function\|class\|variable\|constant\) \([-A-Za-z0-9!&*<>|^$%@_?=]+\)/" -r "/[ \t]*\(\(virtual\|constant\|sealed\|instance\|class\|each-subclass\|\/\*\s*exported\s*\*\/\) \)*slot \([-A-Za-z0-9!&*<>|^$%@_?=]+\)/" -


