# Micro OS Boot - Actividad 1 INFB6052

Bootloader minimalista en ensamblador x86 que arranca en QEMU, imprime un mensaje en pantalla y detiene el procesador. Desarrollado como actividad académica de la asignatura **Infraestructura para Ciencia de Datos** de la UTEM.

---

## Contexto académico

| Campo | Detalle |
|---|---|
| Universidad | Universidad Tecnológica Metropolitana (UTEM) |
| Carrera | Ingeniería Civil en Ciencia de Datos |
| Asignatura | Infraestructura para Ciencia de Datos (INFB6052) |
| Semestre | Primer Semestre 2026 |
| Profesor | Dr. Ing. Michael Miranda Sandoval |
| Integrante | Ignacio Ramírez ([@altairBASIC](https://github.com/altairBASIC)) |

---

## Descripción

Este proyecto implementa un sector de arranque (boot sector) de 512 bytes escrito en ensamblador NASM. Al ejecutarse en QEMU, el bootloader:

1. Limpia la pantalla usando la interrupción BIOS `int 0x10`
2. Imprime `MicroOS v1.0 - INFB6052` en color cian
3. Imprime `Boot exitoso! - Ignacio Ramirez` en color verde
4. Detiene el procesador con `cli + hlt`

---

## Requisitos

### Ubuntu / Debian
```bash
sudo apt update && sudo apt install -y nasm qemu-system-x86 make
```

### macOS (Homebrew)
```bash
brew install nasm qemu make
```

### Windows (con Chocolatey)
```powershell
choco install nasm qemu make
```

---

## Uso rápido

```bash
# 1. Clonar el repositorio
git clone https://github.com/altairBASIC/micro-os-boot.git
cd micro-os-boot

# 2. Compilar el bootloader
make build

# 3. Ejecutar en QEMU
make run
```

---

## Estructura del repositorio

```
micro-os-boot/
├── src/
│   └── boot.asm        # Código fuente del bootloader (ensamblador NASM, 16 bits)
├── build/
│   ├── boot.bin        # Binario compilado: imagen de disco de 512 bytes (no versionado)
│   └── .gitkeep        # Mantiene el directorio en Git
├── docs/
│   ├── informe.md      # Informe técnico de la actividad
│   └── capturas/       # Capturas de pantalla de QEMU
├── Makefile            # Automatización: build, run, clean, verify
├── README.md           # Este archivo
└── .gitignore
```

---

## Comandos disponibles

| Comando | Descripción |
|---|---|
| `make build` | Ensambla `src/boot.asm` → `build/boot.bin` |
| `make run` | Ejecuta el binario en QEMU |
| `make all` | Compila y ejecuta en un solo paso |
| `make clean` | Elimina el binario compilado |
| `make verify` | Muestra tamaño y firma 0xAA55 del binario |

---

## Explicación técnica

### ¿Qué es un boot sector?

Cuando se enciende un computador, el firmware BIOS/UEFI ejecuta el **POST** (Power-On Self Test) y luego busca un dispositivo de arranque. Lee el **primer sector** (512 bytes) del disco y lo carga en la dirección de memoria `0x7C00`. Si los últimos 2 bytes del sector son `0x55 0xAA`, el BIOS reconoce ese sector como **arranque válido** y transfiere el control al código cargado.

### ¿Por qué exactamente 512 bytes?

El tamaño del sector de arranque es un estándar heredado del hardware de discos desde los años 80 (IBM PC/AT). El sector físico de un disco magnético mide 512 bytes. El BIOS solo lee ese primer sector, por lo que el bootloader debe caber completamente en ese espacio.

### ¿Qué es la firma `0xAA55`?

Es una **firma mágica** de 2 bytes ubicada en las posiciones 511 y 512 del sector (offsets 0x1FE y 0x1FF). El BIOS verifica estos bytes antes de ejecutar el código; si no coinciden, el sector es ignorado. El valor `0xAA55` en little-endian se almacena como `0x55` seguido de `0xAA` en memoria.

---

## Referencias

- [QEMU Documentation](https://www.qemu.org/docs/master/)
- [NASM Manual](https://www.nasm.us/doc/)
- [OSDev Wiki - Boot Sequence](https://wiki.osdev.org/Boot_Sequence)
- [OSDev Wiki - Real Mode](https://wiki.osdev.org/Real_Mode)
- [GitHub Docs](https://docs.github.com)
