; =============================================================================
; boot.asm - Bootloader del Micro OS
; Actividad 1 - INFB6052 - Infraestructura para Ciencia de Datos
; Universidad Tecnológica Metropolitana (UTEM)
; Autor: Ignacio Ramírez
; =============================================================================

BITS 16         ; Indicamos al ensamblador que el código es de 16 bits (modo real x86)
ORG 0x7C00      ; El BIOS siempre carga el sector de arranque en la dirección 0x7C00

; =============================================================================
; LIMPIAR PANTALLA
; Usamos la interrupción BIOS int 0x10 con función 0x06 (scroll up / limpiar región)
; Esto borra todo el contenido visible antes de imprimir nuestros mensajes
; =============================================================================
limpiar_pantalla:
    mov ah, 0x06        ; Función 0x06 de int 0x10: desplazar pantalla hacia arriba
    mov al, 0x00        ; Número de líneas a desplazar = 0 significa limpiar toda la región
    mov bh, 0x07        ; Atributo de relleno: texto gris claro sobre fondo negro (color por defecto)
    mov ch, 0x00        ; Fila superior de la región a limpiar: fila 0
    mov cl, 0x00        ; Columna izquierda de la región: columna 0
    mov dh, 0x18        ; Fila inferior de la región: fila 24 (pantalla de 25 filas, base 0)
    mov dl, 0x4F        ; Columna derecha de la región: columna 79 (pantalla de 80 columnas, base 0)
    int 0x10            ; Llamada a la interrupción BIOS de video

; =============================================================================
; POSICIONAR EL CURSOR AL INICIO (fila 0, columna 0)
; Sin esto, el cursor quedaría en alguna posición indefinida después del scroll
; =============================================================================
    mov ah, 0x02        ; Función 0x02 de int 0x10: establecer posición del cursor
    mov bh, 0x00        ; Página de video: página 0 (la visible por defecto)
    mov dh, 0x00        ; Fila destino: 0 (primera fila)
    mov dl, 0x00        ; Columna destino: 0 (primera columna)
    int 0x10            ; Llamada a la interrupción BIOS

; =============================================================================
; IMPRIMIR PRIMERA LÍNEA: "MicroOS v1.0 - INFB6052"
; Usamos la función 0x0E (teletype output) que imprime un carácter con color
; e imprime carácter por carácter iterando sobre la cadena hasta encontrar 0
; =============================================================================
    mov si, msg1        ; SI apunta al inicio de la primera cadena de texto
    mov bl, 0x0B        ; Color: texto cian claro (0x0B) sobre fondo negro (atributo de color)
    call imprimir       ; Llamamos a la función de impresión

; =============================================================================
; IMPRIMIR SALTO DE LÍNEA entre los dos mensajes
; El carácter 0x0D mueve el cursor al inicio de la línea (Carriage Return)
; El carácter 0x0A baja el cursor una línea (Line Feed)
; Ambos juntos equivalen a un salto de línea estándar
; =============================================================================
    mov ah, 0x0E        ; Función teletype de int 0x10
    mov al, 0x0D        ; Carácter: Carriage Return (volver al inicio de línea)
    int 0x10
    mov al, 0x0A        ; Carácter: Line Feed (bajar una línea)
    int 0x10

; =============================================================================
; IMPRIMIR SEGUNDA LÍNEA: "Boot exitoso! - Ignacio Ramirez"
; Mismo mecanismo que la primera línea, con diferente color para distinguirlas
; =============================================================================
    mov si, msg2        ; SI apunta al inicio de la segunda cadena de texto
    mov bl, 0x0A        ; Color: texto verde claro (0x0A) sobre fondo negro
    call imprimir       ; Llamamos a la función de impresión

; =============================================================================
; HALT LOOP - Detener el procesador
; Una vez impresos los mensajes, el bootloader no tiene más trabajo que hacer.
; cli: deshabilita las interrupciones para que el CPU no sea despertado
; hlt: suspende el procesador hasta la próxima interrupción (que nunca llegará)
; El loop 'fin' atrapa cualquier eventual interrupción no maskeable (NMI)
; =============================================================================
fin:
    cli                 ; Deshabilitar interrupciones (Clear Interrupt Flag)
    hlt                 ; Detener el procesador (Halt)
    jmp fin             ; Bucle de seguridad: si algo despertara al CPU, vuelve al hlt

; =============================================================================
; FUNCIÓN: imprimir
; Imprime una cadena terminada en 0 (null-terminated) usando int 0x10 / 0x0E
; Entrada:
;   SI = dirección de inicio de la cadena
;   BL = atributo de color del texto
; Modifica: AX, AL, SI
; =============================================================================
imprimir:
    mov ah, 0x0E        ; Función 0x0E: teletype output (imprime carácter con avance de cursor)
.bucle:
    lodsb               ; Carga el byte apuntado por SI en AL, luego incrementa SI automáticamente
    cmp al, 0           ; Compara el carácter leído con 0 (fin de cadena)
    je  .fin            ; Si es 0, la cadena terminó: saltar al final de la función
    mov bh, 0x00        ; Página de video: 0 (pantalla activa)
    int 0x10            ; Imprimir el carácter en AL con color en BL
    jmp .bucle          ; Volver a leer el siguiente carácter
.fin:
    ret                 ; Retornar al llamador (pop dirección de retorno del stack)

; =============================================================================
; DATOS: cadenas de texto a imprimir
; Las cadenas terminan con 0 (byte nulo) para que la función sepa dónde parar
; =============================================================================
msg1 db "MicroOS v1.0 - INFB6052", 0      ; Primera línea: identificación del SO y asignatura
msg2 db "Boot exitoso! - Ignacio Ramirez", 0  ; Segunda línea: confirmación y autor

; =============================================================================
; RELLENO Y FIRMA DE ARRANQUE
; El BIOS espera que el sector de arranque ocupe exactamente 512 bytes.
; 'times 510-($-$$) db 0' rellena con ceros desde la posición actual hasta el byte 509.
;   $  = dirección actual en el segmento
;   $$ = dirección de inicio del segmento (0x7C00)
;   $-$$ = número de bytes usados hasta ahora
;   510-($-$$) = bytes restantes para llegar al byte 510 (posición de la firma)
; Los últimos 2 bytes deben ser 0x55 y 0xAA (en ese orden en memoria = 0xAA55 en little-endian)
; El BIOS verifica esta firma para identificar que el sector es arrancable
; =============================================================================
times 510-($-$$) db 0   ; Rellena con ceros hasta el byte 510
dw 0xAA55               ; Firma mágica de sector de arranque (bytes 511-512)
