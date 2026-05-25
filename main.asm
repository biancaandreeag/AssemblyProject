    DOSSEG
    .MODEL SMALL
    .STACK 32
    .DATA
encoded     DB  80 DUP(0)
temp        DB  '0x', 160 DUP(0)
fileHandler DW  ?
filename    DB  'in/in.txt', 0          ; Trebuie sa existe acest fisier 'in/in.txt'!
outfile     DB  'out/out.txt', 0        ; Trebuie sa existe acest director 'out'!
message     DB  80 DUP(0)
msglen      DW  ?
padding     DW  0
iterations  DW  0 
x           DW  ?
x0          DW  ?
a           DW  0
b           DW  0

surname     DB 'Ioana '
firstname   DB 'Dragos'

seconds     DB  0
hseconds    DB  0 

alfabet     DB 'Bqmgp86CPe9DfNz7R1wjHIMZKGcYXiFtSU2ovJOhW4ly5EkrqsnAxubTV03a=L/d'
paddingCh   DB '+'

    .CODE
START:
    MOV     AX, @DATA
    MOV     DS, AX

    CALL    FILE_INPUT                  ; NU MODIFICATI!
    
    CALL    CREATEAB                    ;calcularea lui a si b

    CALL    SEED                        ; TODO - Trebuie implementata

    CALL    ENCRYPT                     ; TODO - Trebuie implementata
    
    CALL    ENCODE                      ; TODO - Trebuie implementata
    
                                        ; Mai jos se regaseste partea de
                                        ; afisare pe baza valorilor care se
                                        ; afla in variabilele x0, a, b, respectiv
                                        ; in sirurile message si encoded.
                                        ; NU MODIFICATI!
    MOV     AH, 3CH                     ; BIOS Int - Open file
    MOV     CX, 0
    MOV     AL, 1                       ; AL - Access mode ( Write - 1 )
    MOV     DX, OFFSET outfile          ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    CALL    WRITE                       ; NU MODIFICATI!

    MOV     AH, 4CH                     ; Bios Int - Terminate with return code
    MOV     AL, 0                       ; AL - Return code
    INT     21H
FILE_INPUT:
    MOV     AH, 3DH                     ; BIOS Int - Open file
    MOV     AL, 0                       ; AL - Access mode ( Read - 0 )
    MOV     DX, OFFSET fileName         ; DX - Filename
    INT     21H
    MOV     [fileHandler], AX           ; Return: AX - file handler or error code

    MOV     AH, 3FH                     ; BIOD Int - Read from file or device
    MOV     BX, [fileHandler]           ; BX - File handler
    MOV     CX, 80                      ; CX - Number of bytes to read
    MOV     DX, OFFSET message          ; DX - Data buffer
    INT     21H
    MOV     [msglen], AX                ; Return: AX - number of read bytes

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H

    RET
CREATEAB:
    MOV AX,0
    MOV BX,0 
    MOV DX,0
    MOV SI, OFFSET firstname   

  LOOP_A:
    MOV BL, [SI]
    CMP BL, 0
    JE SET_A
    ADC AX,BX
    INC SI
    JNE LOOP_A
  SET_A:
    MOV DX,0
    MOV BX,255
    DIV BX
    MOV [a],DX
    MOV AX,0
    MOV BX,0
    MOV SI, OFFSET surname
  LOOP_B:
    MOV BL, [SI]
    CMP BL, 20H
    JE SET_B
    ADC AX,BX
    INC SI
    JNE LOOP_B
  SET_B:
    MOV DX,0
    MOV BX,255
    DIV BX
    MOV [b],DX   
    
    RET
SEED:
    MOV     AH, 2CH                     
    INT     21H
    ;x0=(60*(60*CH+CL)+DH)*100+DL) mod 255
    MOV seconds, DH
    MOV hseconds, DL
    MOV AX,60
    MUL CH
    MOV BX,AX
    MOV AX,1
    MUL CL
    ADC AX,BX
    MOV BX,60
    MUL BX
    MOV BX,AX
    MOV AX,1
    MUL seconds
    ADC AX,BX
    MOV BX,100
    MUL BX
    MOV BX,AX
    MOV AX,1
    MUL hseconds
    ADC AX,BX
    MOV BX,255
    DIV BX
    MOV [X0],DX
    MOV [X],DX

    RET                            
ENCRYPT:
    MOV  CX, [msglen]
    MOV  SI, OFFSET message
    MOV  AX, 0
    MOV  BX, 0
  LOOP_ENCRYPT:
    MOV AX, [SI]
    MOV BX, X
    XOR AX,BX
    MOV [SI], AL
    INC SI 
    DEC CX
    CMP CX, 0
    JNE CALCX    

    RET
CALCX:
    CALL RAND
    JMP LOOP_ENCRYPT

    RET
RAND:
    MOV AX, [X]
    MUL a
    ADC AX,b
    MOV DX,0
    MOV BX,255
    DIV BX
    MOV [X],DX                                       

    RET
ENCODE:
    MOV SI, offset message
    MOV CX,[msglen]
    MOV AX, 0
    MOV DX, 0
  LOOP_ENCODE:
    MOV AX, [SI]
    MOV BX, 0
    AND AL, 252 ; nu ma lasa sa folosesc valoarea hexa
    SHR AL, 2
    MOV BL, AL    
    CALL ADDCH

    MOV AX, [SI]
    AND AL, 3
    SHL AL, 4
    OR BL, AL
    INC SI
    DEC CX
    CMP CX, 0
    JE  CASE1
    MOV AX, [SI]
    AND AX, 240 
    SHR AL, 4
    OR BL, AL
    CALL ADDCH

    MOV AX, [SI]
    AND AL, 15
    SHL AL, 2
    OR BL, AL
    INC SI
    DEC CX
    CMP CX, 0
    JE CASE2
    MOV AX, [SI]
    AND AX, 192
    SHR AL, 6
    OR BL, AL
    CALL ADDCH
    
    MOV AX, [SI]
    AND AL, 63
    OR BL, AL
    CALL ADDCH
    INC SI
    DEC CX
    
    CMP CX, 0
    JNE LOOP_ENCODE
    
    RET

CASE1: MOV CX, 2
       MOV padding, CX
       CALL ADDCH
       CALL ADDPadding

       RET
CASE2: MOV CX, 1
       MOV padding, CX
       CALL ADDCH
       CALL ADDPadding

       RET

ADDCH: PUSH(SI)
       MOV SI, offset alfabet
       ADD SI, BX
       MOV DX, [SI]
       CALL CHARAC
       MOV DX,0
       MOV BX,0
       POP(SI)

       RET
CHARAC:PUSH(SI)
       MOV BX, 0
       MOV BX, iterations
       MOV SI,offset encoded
       ADD SI, BX
       MOV [SI], DL
       INC iterations
       POP (SI) 
       
       RET
  
AddPadding:MOV SI, offset encoded
            MOV BX, 0
            MOV BX, iterations
            ADD SI, BX
            MOV DL, paddingCh
            MOV [SI], DL
            DEC padding
            INC iterations
            MOV CX, padding
            CMP CX, 0
            JNE AddPadding

            RET       
WRITE_HEX:
    MOV     DI, OFFSET temp + 2
    XOR     DX, DX
DUMP:
    MOV     DL, [SI]
    PUSH    CX
    MOV     CL, 4

    ROR     DX, CL
    
    CMP     DL, 0ah
    JB      print_digit1

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     next_digit

print_digit1:  
    OR      DL, 30h
    MOV     byte ptr [DI] ,DL
next_digit:
    INC     DI
    MOV     CL, 12
    SHR     DX, CL
    CMP     DL, 0ah
    JB      print_digit2

    ADD     DL, 37h
    MOV     byte ptr [DI], DL
    JMP     AGAIN

print_digit2:    
    OR      DL, 30h
    MOV     byte ptr [DI], DL
AGAIN:
    INC     DI
    INC     SI
    POP     CX
    LOOP    dump
    
    MOV     byte ptr [DI], 10
    RET
WRITE:
    MOV     SI, OFFSET x0
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21h

    MOV     SI, OFFSET a
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET b
    MOV     CX, 1
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET x
    MOV     CX, 1
    CALL    WRITE_HEX    
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, 5
    INT     21H

    MOV     SI, OFFSET message
    MOV     CX, [msglen]
    CALL    WRITE_HEX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET temp
    MOV     CX, [msglen]
    ADD     CX, [msglen]
    ADD     CX, 3
    INT     21h

    MOV     AX, [iterations]
    MOV     BX, 4
    MUL     BX
    MOV     CX, AX
    MOV     AH, 40h
    MOV     BX, [fileHandler]
    MOV     DX, OFFSET encoded
    INT     21H

    MOV     AH, 3EH                     ; BIOS Int - Close file
    MOV     BX, [fileHandler]           ; BX - File handler
    INT     21H
    RET
    END START