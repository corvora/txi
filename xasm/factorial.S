; Calculates factorial

mov g01, 8

loop:
    sub g01, 1
    mov g01, rs
    cmp g01, 0
    je halt
    mov g16, g01
    jmp fac
continue_loop:
    jmp loop

fac: ; g16 = input, g13 = temp
mov g13, g16
cmp g13, 0
jne fac_forloop
fac_retone:
    mov g15, g13
    jmp npr
fac_forloop:
    push rs
    sub g13, 1
    mov g13, rs
    cmp g13, 0
    jne fac_mul
    je fac_done
fac_forloop_cont:
    pop rs
    jmp fac_forloop
fac_mul:
    mul g16, rs
    mov g16, rs
    jmp fac_forloop_cont
fac_done:
    mov g15, g16
    jmp npr

npr: ; g15 = input, g14 = counter
cmp g15, 0
je npr_zero
npr_loop:
    cmp g15, 0
    je npr_done
    mod g15, 10
    push rs
    div g15, 10
    mov g15, rs
    add g14, 1
    mov g14, rs
    jmp npr_loop
npr_zero:
    outp 0,48
npr_done:
npr_doneloop:
    cmp g14, 0
    je npr_ok
    pop rs
    add rs, 48
    outp 0,rs
    sub g14, 1
    mov g14, rs
    jmp npr_doneloop
npr_ok:
    jmp done

done:
    outp 0,10
    outp 0,13
    jmp continue_loop

halt:
    hlt