#!/bin/bash -ve
#./bootstrap
#./configure --with-tclkitrun=/usr/local/share/tclkits/tclkit-linux-x86
make PLATFORM=LinuxX86 bintgz
make PLATFORM=Win32 TCLXMLLIB=../Tclxml2.6Win32 EXEEXT=.exe TCLKITRUN=/usr/local/share/tclkits/tclkit-win32.exe binzip
make dist
