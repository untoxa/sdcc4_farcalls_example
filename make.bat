@echo off
@set PROJ=sdcc4farcalls
@set GBDK=..\..\gbdk
@set GBDKLIB=%GBDK%\lib\small\asxxxx
@set OBJ=build\
@set SRC=src\

@set CFLAGS=-mgbz80 --no-std-crt0 -I %GBDK%\include -I %GBDK%\include\asm -I src\include -c
@rem @set CFLAGS=%CFLAGS% --profile

@set LFLAGS=-n -- -z -m -j -yt2 -yo4 -ya4 -k%GBDKLIB%\gbz80\ -lgbz80.lib -k%GBDKLIB%\gb\ -lgb.lib 
@set LFILES=%GBDKLIB%\gb\crt0.o

@set ASMFLAGS=-plosgff -I"libc"

@echo Cleanup...

@if exist %OBJ% @rd /s/q %OBJ%
@if exist %PROJ%.gb @del %PROJ%.gb
@if exist %PROJ%.sym @del %PROJ%.sym
@if exist %PROJ%.map @del %PROJ%.map

@if not exist %OBJ% mkdir %OBJ%

@echo ASSEMBLING THE STUB...

sdasgb %ASMFLAGS% %OBJ%MBC1_RAM_INIT.rel %SRC%MBC1_RAM_INIT.s
sdasgb %ASMFLAGS% %OBJ%__sdcc_call_hl.rel %SRC%__sdcc_call_hl.s
@set LFILES=%LFILES% %OBJ%MBC1_RAM_INIT.rel %OBJ%__sdcc_call_hl.rel

@echo COMPILING WITH SDCC4...

sdcc %CFLAGS% %SRC%sdcc4bank1code.c -bo1 -o %OBJ%sdcc4bank1code.rel
sdcc %CFLAGS% %SRC%sdcc4bank2code.c -bo2 -o %OBJ%sdcc4bank2code.rel

@echo FIX: %OBJ%sdcc4bank2code.rel
python far_fixer.py %LFILES% %OBJ%sdcc4bank2code.rel > %OBJ%sdcc4bank2code.fixed.rel

@set LFILES=%LFILES% %OBJ%sdcc4bank1code.rel %OBJ%sdcc4bank2code.fixed.rel 

sdcc %CFLAGS% %SRC%%PROJ%.c -o %OBJ%%PROJ%.rel

@echo FIX: %OBJ%%PROJ%.rel
python far_fixer.py %LFILES% %OBJ%%PROJ%.rel > %OBJ%%PROJ%.fixed.rel

@echo LINKING WITH GBDK...
%GBDK%\bin\link-gbz80 %LFLAGS% %PROJ%.gb %LFILES% %OBJ%%PROJ%.fixed.rel 

@echo DONE!
