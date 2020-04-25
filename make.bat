@echo off
@set PROJ=sdcc4farcalls
@set GBDK=..\..\gbdk
@set GBDKLIB=%GBDK%\lib\small\asxxxx
@set OBJ=build

@set CFLAGS=-mgbz80 --no-std-crt0 -Dnonbanked= -I %GBDK%\include -I %GBDK%\include\asm -I src\include -c
@rem set CFLAGS=%CFLAGS% -DUSE_SFR_FOR_REG

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

sdasgb %ASMFLAGS% %OBJ%\MBC1_RAM_INIT.rel MBC1_RAM_INIT.s
sdasgb %ASMFLAGS% %OBJ%\__sdcc_call_hl.rel __sdcc_call_hl.s
@set LFILES=%LFILES% %OBJ%\MBC1_RAM_INIT.rel %OBJ%\__sdcc_call_hl.rel

@echo COMPILING WITH SDCC4...

sdcc %CFLAGS% sdcc4bank1code.c -bo1 -o %OBJ%\sdcc4bank1code.rel
sdcc %CFLAGS% sdcc4bank2code.c -bo2 -o %OBJ%\sdcc4bank2code.rel
@set LFILES=%LFILES% %OBJ%\sdcc4bank1code.rel %OBJ%\sdcc4bank2code.rel 

sdcc %CFLAGS% %PROJ%.c -o %OBJ%\%PROJ%.rel

@echo PATCHING...
@python far_fixer.py %LFILES% %OBJ%\%PROJ%.rel > %OBJ%\%PROJ%.fixed.rel

@echo LINKING WITH GBDK...
%GBDK%\bin\link-gbz80 %LFLAGS% %PROJ%.gb %LFILES% %OBJ%\%PROJ%.fixed.rel 

@echo DONE!
