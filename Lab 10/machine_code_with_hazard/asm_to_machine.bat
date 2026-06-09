@echo off

set INPUT=program.s
set BASENAME=program
set OBJ=%BASENAME%.o
set DUMP=%BASENAME%_dump.txt
set HEX=%BASENAME%_machine_code.txt
set BIN=%BASENAME%.bin

echo ==============================
echo   RISC-V Assembly Toolchain
echo ==============================

echo Assembling %INPUT% ...

riscv64-unknown-elf-as -march=rv32im %INPUT% -o %OBJ%

if errorlevel 1 (
    echo ERROR: Assembly failed. Check program.s file.
    pause
    exit /b
)

echo Generating full disassembly...
riscv64-unknown-elf-objdump -d -M numeric,no-aliases %OBJ% > %DUMP%

echo Extracting machine code (hex only)...
riscv64-unknown-elf-objdump -d -M numeric,no-aliases %OBJ% | findstr ":" > temp.txt
(for /f "tokens=2" %%A in (temp.txt) do echo %%A) > %HEX%
del temp.txt

echo Generating raw binary...
riscv64-unknown-elf-objcopy -O binary %OBJ% %BIN%

echo ==============================
echo Done Successfully!
echo ==============================
echo Output files generated:
echo  - %DUMP%
echo  - %HEX%
echo  - %BIN%
echo ==============================
pause