; Calculates 800 digits of pi
; 31415926535897932384626433832795028841971693993751058209749445923078164062862089986280348253421170679821480865132823066470938446095505822317253594081284811174502841027019385211055596446229489549303819644288109756659334461284756482337867831652712019091456485669234603486104543266482133936072602491412737245870066063155881748815209209628292540917153643678925903600113305305488204665213841469519415116094330572703657595919530921861173819326117931051185480744623799627495673518857527248912279381830119491298336733624406566430860213949463952247371907021798609437027705392171762931767523846748184676694051320005681271452635608277857713427577896091736371787214684409012249534301465495853710507922796892589235420199561121290219608640344181598136297747713099605187072113499999983729780499510597317328160963185
; adjust for 8-bit words
pi:
mov ad, mem_alloc ; malloc base
mov g01, 0 ; i
mov g02, 0 ; k
mov g03, 0 ; b
mov g04, 0 ; d
mov g05, 0 ; c
wloop:
wloop_for:
wloop_forloop:
    push rs
    add g01, 1
    mov g01, rs
    pop rs
    push ap
    mov ap, g01
    write 2000
    pop ap
    cmp g01, 2800
    js wloop_for
wloop_endloop:

kloop:
mov g02, 2800
kloop_for:
    cmp g02, 0
    jg kloop_forloop
    jmp kloop_endloop
kloop_forloop:
    mov g04, 0
    mov g01, g02
    push rs
    sub g02, 14
    mov g02, rs
    pop rs

dloop:
    push rs
    push ap
    mov ap, g01
    read
    mul rs, 10000
    add rs, g04
    mov g04, rs

    mul 2, g01
    sub rs, 1
    mov g03, rs
    mod g04, g03
    write rs
    div g04, g03
    mov g04, rs
    sub g01, 1
    mov g01, rs
    pop ap
    pop rs
    cmp g01, 0
    je dloop_end
    push rs
    mul g04, g01
    mov g04, rs
    pop rs
    jmp dloop
dloop_end:
    div g04, 10000
    add rs, g05
    mov g15, rs
    jmp npr
continue_loop:
    mod g04, 10000
    mov g05, rs
    jmp kloop_for

kloop_endloop:
    hlt

npr: ; g15 = input, g14 = counter, g13 = 4-digit maker
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
    outp 0,48
    outp 0,48
    outp 0,48
    jmp npr_ok
npr_done:
    cmp g14, 4
    js npr_zf
    jmp npr_doneloop
npr_zf:
    sub 4, g14
    mov g13, rs
npr_zfill:
    cmp g13, 0
    je npr_doneloop
    outp 0,48
    sub g13, 1
    mov g13, rs
    jmp npr_zfill
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
    outp 0, 10
    outp 0, 13
    jmp done

done:
    jmp continue_loop

end:
    outp 0,10
    outp 0,13
    hlt

mem_alloc: