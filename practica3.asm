;Programa: Ejercicio 21/10/2020
;Propósito: Dibujar píxeles pseudoaleatorios en una fila y columna determinada, y cambiar el color teniendo en cuenta el timer
;Autores: Guillermo Díaz, David Fuentes, Raúl Benito, Francisco García-Morales
;Fecha: 25/10/2020

;OBSERVACIÓN 1: No sabíamos a qué se refería el enunciado con lo de fila 1 y fila 2, así que hemos usado el
;display gráfico como una matriz

;OBSERVACIÓN 2: Actualmente el trato de excepciones provoca un bucle infinito en el que al salir se vuelve a
;ejecutar la sentencia que provocó la excepción. No sabemos cómo evitarlo

JMP boot	; Primera sentencia siempre es boot
JMP nop		; No hay NOP en este micro y JMP svc tiene que ser la tercera instrucción
JMP svc		; Tercera sentencia siempre es la llamada al sistema
JMP exc		; Cuarta sentencia siempre es excepción de usuario
    
    
num_excep:
	DB 0x00 		; Para imprimir el código de error
    
boot:
	MOV SP, 0x1FF	; Inicializamos la SP, escogemos esta posición (justo antes de que empiece la zona de usuario)
    				; para evitar que la pila sobreescriba instrucciones
	MOV A, 1		; Iniciamos IRQMASK
	OUT 0			; IRQMASK
    MOV A, 0xF		; Definimos el valor del timer a 15 (F en hexadecimal)
    OUT 3			; TMRPRELOAD
	MOV A, 0x02DF	; Definimos el final de la zona no protegida (es decir, de usuario)
	OUT 8			; MEMPTEND
	MOV A, 0x0209	; Definimos el inicio de la zona no protegida
	OUT 7			; MEMPTSTART
	PUSH 0x0010		; PUSH del SR
	PUSH 0x2DF		; Posición de inicio de la pila de usuario (al final de la zona no protegida)
	PUSH task		; Posición de inicio de ejecución de usuario
	SRET			; Pasamos a modo usuario
	HLT				
    
;"""INTERRUPCIONES""" (lo usamos como NOP)
nop:				; Como no hay nop, hemos hecho esto vacío, ya que no vamos a usar interrupciones
    RET
    
;EXCEPCIONES
exc:
	POP A						; Recibe el código de excepción
    ADD A, 0x30					; Para convertirlo en ascii
    MOV B, num_excep			; Apunta B a la etiqueta del código de excepción
    MOVB [B], AL				; Guardia el código de excepción
	CALL .exception				; Imprime el error por el display de texto
    SRET						; Vuelve al modo usuario (actualmente provoca un bucle infinito)
    
.exception:
    MOV C, error1				; C apunta al primer trozo del mensaje de error
    MOV D, 0x02E0				; D apunta al primer espacio de memoria del display de texto
    CALL .print					; Imprimimos
    MOV C, num_excep			; C apunta al número de error que corresponda en ese momento
    MOVB BL, [C]				; Imprimimos (no podemos usar .print porque no tiene byte 0 para parar)
    MOVB [D], BL
    INC D
    MOV C, error2				; Hacemos que C apunte al tercer trozo del mensaje de error
    CALL .print					; Imprimimos
	RET

.print:
	MOVB BH, 0x00				; Se guarda 0 en BH para comparar al final del bucle
	MOVB BL, [C]				; Guardamos el caracter actual de C en BL
    MOVB [D], BL				; Imprimimos BL
    INC C						; Incrementamos C (siguiente caracter)
    INC D						; Incrementamos D (display)
    CMPB BH, [C]				; Si es 0 es que ha terminado de imprimir (corta el bucle)
    JNZ .print					; Si no ha terminado repite el bucle
    RET
    
; LLAMADAS AL SISTEMA
svc:				; Llamada al sistema
	PUSH A
    PUSH B
    PUSH C
    PUSH D
    
	CMP B, 0				; Caso de llamada 0 (excepción)
    JZ llamada_excepcion
	CMP B, 1				; Caso de llamada 1 (rellenar num_columna)
    JZ columna
	CMP B, 2				; Caso de llamada 2 (rellenar num_fila)
    JZ fila
	CMP B, 3				; Caso de llamada 3 (rellenar num_color)
    JZ color
	CMP B, 4				; Caso de llamada 4 (pintar el pixel)
    JZ print_pixel_svc
	JMP fin					; Si no es ninguno de los casos anteriores termina la llamada al sistema
llamada_excepcion:
	CALL .exception			; Llama a .exception
	JMP fin
columna:
	IN 4					; Set A al valor del TMRCOUNTER
   	MOV B, num_columna		; B apunta al tag que almacena el número de columna
    MOV [B], A				; Se guarda A en la etiqueta
    JMP fin
fila:
	IN 4					; Set A al valor del TMRCOUNTER
    ADD A, 0x30				; Suma 30 para ponerlo en una fila real del display gráfico
   	MOV B, num_fila			; B apunta a la etiqueta de la fila
    MOV [B], A				; Se guarda A en la etiqueta
    JMP fin
color:
	IN 4					; Set A al valor del TMRCOUNTER
   	MOV B, num_color	    ; B apunta a la etiqueta del color
    MOV [B], A				; Se guarda A en la etiqueta
    JMP fin
print_pixel_svc:
	MOV D, pos_pixel	    ; Hacemos que D apunte a la etiqueta de dirección del pixel
    MOV D, [D]			    ; Apuntamos D a la dirección (contenido de la etiqueta)
    MOV C, num_color	    ; Hacemos que C apunte a la etiqueta del color
    MOV C, [C]			    ; Guardamos ese valor en C
    MOVB [D], CL		    ; Imprimimos el color (usamos CL para que se escriba en la casilla correcta y no en la siguiente)
    JMP fin
fin:
	POP D					; Pop del stack y salida
    POP C
    POP B
    POP A
	SRET					; Vuelta al modo usuario
    
;MODO USUARIO
task:
	MOV B, 1				; LLamada a supervisor para rellenar la columna
	SVC
	MOV B, 2				; LLamada a supervisor para rellenar la fila
	SVC
	MOV B, 3				; LLamada a supervisor para rellenar el color
	SVC
    CALL .print_pixel		; Llamamos a imprimir pixel
    
.print_pixel:
	MOV A, num_fila			; A apunta al número de la fila en la que se hace print
    MOV A, [A]				; Para que A sea el valor de la fila y no la etiqueta
    MOV D, 0x10				; Guardamos 16 (10 en hexadecimal) para multiplicar por A
    MUL D					; Multiplicamos A por 16 para ponerle un 0 a la derecha
    
    ;DIV 0x00				; DESCOMENTAR PARA PROVAR LA DIVISIÓN POR 0 (EXCEPCIONES)
    
    ;MOV C, 0x010			; DESCOMENTAR PARA PROVAR EL ACCESO ILEGAL A MEMORIA PROTEGIDA (EXCEPCIONES)
    ;MOV [C], 0xAA
    
    IN 4					; DESCOMENTAR PARA PROBAR EL USO ILEGAL DE INSTRUCCIONES (EXCEPCIONES)
    
    MOV B, num_columna		; B apunta al número de la columna en la que se va a hacer print
    MOV B, [B]
    ADD A, B				; Pone el número de columna en A para completar la dirección
    
    MOV C, pos_pixel		; C apunta a la etiqueta de dirección
    MOV [C], A				; Guardamos el valor de A en la etiqueta
    
    MOV B, 4				; LLamada al sistema para terminar de imprimir
    SVC
    JMP task				; Vuelve a iniciar todo el proceso de usuario
    
ORG 0x200					; Para que escriba estas etiquetas en la zona no protegida (de usuario)
error1:	
	DB "Error "             ; Definimos el primer trozo del mensaje de excepción
	DB 0
error2:
	DB ". Sistema parado"  	; Definimos el segundo trozo del mensaje a concatenar
	DB 0
num_columna: 
	DW 0x0000				; Definimos el número de columna, con DW para leer con el registro completo
num_fila:
	DW 0x0000				; Definimos el número de fila, con DW para leer con el registro completo
num_color:
	DW 0x0000				; Definimos el número de color, con DW porque con DB no cabría
pos_pixel:
	DW 0x0000				; Definimos el número con la dirección del display gráfico para imprimir el pixel,
    						;con DW para leer con el registro completo