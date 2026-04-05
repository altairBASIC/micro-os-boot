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
; IMPRIMIR PRIMERA LÍNEA: "MicroOS v1.0 - INFB6052" en color CIAN
; Usamos la función 0x09 (write char with attribute) que SÍ aplica colores,
; combinada con 0x02 (set cursor) para avanzar manualmente el cursor.
; La función 0x0E (teletype) no siempre respeta BL en todos los BIOS/emuladores.
; =============================================================================
    mov si, msg1        ; SI apunta al inicio de la primera cadena de texto
    mov bl, 0x0B        ; Color: texto cian claro (0x0B) sobre fondo negro
    call imprimir       ; Llamamos a la función de impresión

; =============================================================================
; IMPRIMIR SALTO DE LÍNEA entre los dos mensajes
; Movemos el cursor a la fila 1, columna 0
; =============================================================================
    mov ah, 0x02        ; Función set cursor position
    mov bh, 0x00        ; Página de video 0
    mov dh, 0x01        ; Fila 1 (segunda fila)
    mov dl, 0x00        ; Columna 0
    int 0x10

; =============================================================================
; IMPRIMIR SEGUNDA LÍNEA: "Boot exitoso! - Ignacio Ramirez" en color VERDE
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
; Imprime una cadena terminada en 0 (null-terminated) usando int 0x10 / 0x09
; La función 0x09 escribe un carácter con atributo de color en la posición
; actual del cursor, pero NO avanza el cursor automáticamente. Por eso,
; después de cada carácter, usamos 0x02 para mover el cursor manualmente.
;
; Entrada:
;   SI = dirección de inicio de la cadena
;   BL = atributo de color del texto (bits 3-0 = color texto, bits 7-4 = color fondo)
; Modifica: AX, CX, SI, DL
; =============================================================================
imprimir:
    mov dl, 0x00        ; Inicializar columna del cursor en 0
.bucle:
    lodsb               ; Carga el byte apuntado por SI en AL, luego incrementa SI
    cmp al, 0           ; Compara el carácter leído con 0 (fin de cadena)
    je  .fin            ; Si es 0, la cadena terminó: saltar al final

    ; --- Escribir carácter con color usando función 0x09 ---
    mov ah, 0x09        ; Función 0x09: escribir carácter con atributo de color
    mov bh, 0x00        ; Página de video: 0 (pantalla activa)
    mov cx, 1           ; Número de veces a repetir el carácter: 1
    int 0x10            ; Imprimir el carácter en AL con color en BL

    ; --- Avanzar el cursor una posición a la derecha ---
    inc dl              ; Incrementar columna
    mov ah, 0x02        ; Función 0x02: establecer posición del cursor
    mov bh, 0x00        ; Página de video: 0
    ; DH ya contiene la fila correcta (preservada del último set cursor)
    int 0x10            ; Mover el cursor

    jmp .bucle          ; Volver a leer el siguiente carácter
.fin:
    ret                 ; Retornar al llamador

; =============================================================================
; DATOS: cadenas de texto a imprimir
; Las cadenas terminan con 0 (byte nulo) para que la función sepa dónde parar
; =============================================================================
msg1 db "MicroOS v1.0 - INFB6052", 0                                          ; Primera línea: identificación del SO y asignatura
msg2 db "Boot exitoso! // I.Ramirez, C.Vergara, F.Provoste", 0                   ; Segunda línea: confirmación y autores

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
