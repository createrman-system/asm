# Tetris

A small Tetris project with two builds:

- `tetris.asm` - the original 16-bit DOS assembly version.
- `tetris_win64.c` - a native Windows x64 console version.

## Files

| File | Description |
| --- | --- |
| `tetris.asm` | Original MASM/UASM-style DOS assembly source |
| `tetris.exe` | Built DOS MZ executable |
| `tetris.obj` | DOS object file produced from the assembly source |
| `tetris_win64.c` | Native Windows x64 console implementation |
| `tetris_win64.exe` | Built Windows x64 executable |
| `build_win64.bat` | Rebuild script for the Windows x64 version |

## Windows x64 Version

Run:

```bat
tetris_win64.exe
```

Build:

```bat
build_win64.bat
```

Or build manually with GCC:

```bat
gcc -std=c11 -O2 -Wall -Wextra -static -o tetris_win64.exe tetris_win64.c
```

The Windows version is a native PE x86-64 console application.

## Controls

| Key | Action |
| --- | --- |
| Left Arrow | Move left |
| Right Arrow | Move right |
| Up Arrow | Rotate |
| Down Arrow | Soft drop |
| Space | Hard drop |
| P | Pause |
| R | Restart |
| Q or Esc | Quit |

## DOS Assembly Version

The original assembly source targets 16-bit DOS and uses BIOS/DOS interrupts. It is not a native Windows x64 executable.

Build with UASM:

```bat
uasm -mz -Fo tetris.exe tetris.asm
```

This produces a DOS MZ executable:

```bat
tetris.exe
```

Run it inside a DOS environment or emulator such as DOSBox.

## Notes

The DOS assembly source was adjusted for MASM/UASM-compatible syntax so it can be assembled cleanly with UASM.
