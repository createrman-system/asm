# Snake Assembly Game

A simple Snake game written in assembly.

The original version in `snake.asm` is a 16-bit DOS/emu8086 program. The current runnable version is `snake_win64.asm`, a native Windows x64 console port built with NASM and GCC.

## Features

- Classic Snake gameplay
- `W`, `A`, `S`, `D` movement
- `Q` to quit
- Score display
- Native Windows x64 executable build

## Requirements

- Windows x64
- NASM
- GCC for Windows, such as MSYS2 UCRT64 GCC
- PowerShell

The project was tested with:

- `nasm.exe`
- `gcc.exe`

## Build

Run the build script from the project folder:

```powershell
.\build.ps1
```

This builds:

```text
snake64.exe
```

## Run

```powershell
.\snake64.exe
```

## Controls

```text
W - Move up
A - Move left
S - Move down
D - Move right
Q - Quit
```

## Files

```text
snake_win64.asm  Native Windows x64 NASM source
snake.asm        Original 16-bit DOS/emu8086 source
snake_fasm.asm   FASM-compatible DOS build source
build.ps1        Build script for the Windows x64 version
```

## Notes

The old DOS version uses BIOS interrupts and direct video-memory writes, which do not work in native Windows x64 user mode. The Windows x64 version uses WinAPI keyboard polling and console output instead.
