; AI-Generated, not for production.
org:
jmp init
hlt

init:
push g13
mov g13, mem@init
jmp strings@malloc
mem@init:
    pop g13
welcome@init:
    outp 0, 88
    outp 0, 68
    outp 0, 79
    outp 0, 83
    outp 0, 32
    outp 0, 118
    outp 0, 49
    outp 0, 46
    outp 0, 48
    outp 0, 13
    outp 0, 10
    mov g02, 0 ; tick counter

shell: ; g01 = pointer, g02 = ticks
init@shell:
    outp 0, 10
    outp 0, 13
    mov g01, 0
prompt@shell:
    outp 0, 47
    outp 0, 62
    outp 0, 32
input@shell:
    add g02, 1
    mov g02, rs
    inp 0
    cmp rs, 8
    je bksp#input@shell
    cmp rs, 13
    je nl#input@shell
    jmp print@shell
print@shell:
    outp 0, rs
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g01
    write rs
    push rs
    add g01, 1
    mov g01, rs
    pop rs
    mov ap, g01
    write 0
    pop ap
    pop ad
    jmp input@shell
bksp#input@shell:
    outp 0, 8
    outp 0, 32
    outp 0, 8
    cmp g01, 0
    je bksp_null#input@shell
    jg bksp_notnull#input@shell
bksp_null#input@shell:
    outp 0, 13
    jmp prompt@shell
bksp_notnull#input@shell:
    push rs
    push ap
    push ad
    mov ad, base@malloc
    mov ap, g01
    write 0
    sub g01, 1
    mov g01, rs
    mov ap, g01
    write 0
    pop ad
    pop ap
    pop rs
    jmp input@shell
nl#input@shell:
    outp 0, 10
    outp 0, 13

; COMMAND PARSER
nl_check#input@shell:
    ; Check against "mem"
    mov g09, 0
    mov g10, 0
    
check_mem#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, mem#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne mem_not_both_null#input@shell
    cmp g06, 0
    je match_mem#input@shell
    jmp check_halt#input@shell
    
mem_not_both_null#input@shell:
    cmp g06, 0
    je check_halt#input@shell
    cmp g05, g06
    jne check_halt#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_mem#input@shell
    
check_halt#input@shell:
    ; Check against "halt"
    mov g09, 0
    mov g10, 0
    
check_halt_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, halt#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne halt_not_both_null#input@shell
    cmp g06, 0
    je match_halt#input@shell
    jmp check_info#input@shell
    
halt_not_both_null#input@shell:
    cmp g06, 0
    je check_info#input@shell
    cmp g05, g06
    jne check_info#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_halt_loop#input@shell

check_info#input@shell:
    ; Check against "info"
    mov g09, 0
    mov g10, 0
    
check_info_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, info#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne info_not_both_null#input@shell
    cmp g06, 0
    je match_info#input@shell
    jmp check_uptime#input@shell
    
info_not_both_null#input@shell:
    cmp g06, 0
    je check_uptime#input@shell
    cmp g05, g06
    jne check_uptime#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_info_loop#input@shell

check_uptime#input@shell:
    ; Check against "uptime"
    mov g09, 0
    mov g10, 0
    
check_uptime_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, uptime#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne uptime_not_both_null#input@shell
    cmp g06, 0
    je match_uptime#input@shell
    jmp check_poke#input@shell
    
uptime_not_both_null#input@shell:
    cmp g06, 0
    je check_poke#input@shell
    cmp g05, g06
    jne check_poke#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_uptime_loop#input@shell

check_poke#input@shell:
    ; Check against "poke"
    mov g09, 0
    mov g10, 0
    
check_poke_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, poke#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne poke_check_space#input@shell
    cmp g06, 0
    je match_poke#input@shell
    jmp check_reset#input@shell
    
poke_check_space#input@shell:
    cmp g06, 0
    je poke_maybe_match#input@shell
    cmp g05, g06
    jne check_reset#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_poke_loop#input@shell

poke_maybe_match#input@shell:
    ; Check if next char is space or null
    cmp g05, 32
    je match_poke#input@shell
    cmp g05, 0
    je match_poke#input@shell
    jmp check_reset#input@shell

check_reset#input@shell:
    ; Check against "reset"
    mov g09, 0
    mov g10, 0
    
check_reset_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, reset#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne reset_not_both_null#input@shell
    cmp g06, 0
    je match_reset#input@shell
    jmp check_clear#input@shell
    
reset_not_both_null#input@shell:
    cmp g06, 0
    je check_clear#input@shell
    cmp g05, g06
    jne check_clear#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_reset_loop#input@shell

check_clear#input@shell:
    ; Check against "clear"
    mov g09, 0
    mov g10, 0
    
check_clear_loop#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, g09
    read
    mov g05, rs
    
    mov ad, clear#strings@malloc
    mov ap, g10
    read
    mov g06, rs
    pop ap
    pop ad
    
    cmp g05, 0
    jne clear_not_both_null#input@shell
    cmp g06, 0
    je match_clear#input@shell
    jmp no_match#input@shell
    
clear_not_both_null#input@shell:
    cmp g06, 0
    je no_match#input@shell
    cmp g05, g06
    jne no_match#input@shell
    
    add g09, 1
    mov g09, rs
    add g10, 1
    mov g10, rs
    jmp check_clear_loop#input@shell
    
no_match#input@shell:
    jmp nl_erase#input@shell
    
match_mem#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_mem_loop#input@shell:
    read
    cmp rs, 0
    je clear_mem_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_mem_loop#input@shell
clear_mem_done#input@shell:
    pop ap
    pop ad
    jmp mem@commands
    
match_halt#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_halt_loop#input@shell:
    read
    cmp rs, 0
    je clear_halt_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_halt_loop#input@shell
clear_halt_done#input@shell:
    pop ap
    pop ad
    jmp halt@commands

match_info#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_info_loop#input@shell:
    read
    cmp rs, 0
    je clear_info_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_info_loop#input@shell
clear_info_done#input@shell:
    pop ap
    pop ad
    jmp info@commands

match_uptime#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_uptime_loop#input@shell:
    read
    cmp rs, 0
    je clear_uptime_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_uptime_loop#input@shell
clear_uptime_done#input@shell:
    pop ap
    pop ad
    jmp uptime@commands

match_poke#input@shell:
    jmp poke@commands

match_reset#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_reset_loop#input@shell:
    read
    cmp rs, 0
    je clear_reset_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_reset_loop#input@shell
clear_reset_done#input@shell:
    pop ap
    pop ad
    jmp reset@commands

match_clear#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_clear_loop#input@shell:
    read
    cmp rs, 0
    je clear_clear_done#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_clear_loop#input@shell
clear_clear_done#input@shell:
    pop ap
    pop ad
    jmp clear@commands

nl_erase#input@shell:
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
nl_eloop#input@shell:
    read
    cmp rs, 0
    je nl_edone#input@shell
    write 0
    add ap, 1
    mov ap, rs
    jmp nl_eloop#input@shell
nl_edone#input@shell:
    pop ap
    pop ad
    mov g01, 0
    jmp prompt@shell


commands:
halt@commands:
    outp 0, 72
    outp 0, 97
    outp 0, 108
    outp 0, 116
    outp 0, 105
    outp 0, 110
    outp 0, 103
    outp 0, 32
    outp 0, 109
    outp 0, 97
    outp 0, 99
    outp 0, 104
    outp 0, 105
    outp 0, 110
    outp 0, 101
    outp 0, 46
    outp 0, 13
    outp 0, 10
    hlt
    
mem@commands:
    push g15
    push g16
    push ad
    push ap
    mov g15, ret#mem@commands
    jmp ramcounter
ret#mem@commands:
    mov g15, ret_npr#mem@commands
    outp 0, 77
    outp 0, 101
    outp 0, 109
    outp 0, 111
    outp 0, 114
    outp 0, 121
    outp 0, 32
    outp 0, 83
    outp 0, 105
    outp 0, 122
    outp 0, 101
    outp 0, 58
    outp 0, 32
    push rs
    div g16, 1024
    mov g16, rs
    pop rs
    jmp npr
ret_npr#mem@commands:
    pop ap
    pop ad
    pop g16
    pop g15
    outp 0, 107
    outp 0, 66
    outp 0, 115
    outp 0, 13
    outp 0, 10
    jmp shell

info@commands:
    outp 0, 67
    outp 0, 111
    outp 0, 100
    outp 0, 101
    outp 0, 88
    outp 0, 32
    outp 0, 83
    outp 0, 105
    outp 0, 108
    outp 0, 105
    outp 0, 99
    outp 0, 111
    outp 0, 110
    outp 0, 44
    outp 0, 32
    outp 0, 75
    outp 0, 97
    outp 0, 108
    outp 0, 101
    outp 0, 105
    outp 0, 100
    outp 0, 111
    outp 0, 115
    outp 0, 99
    outp 0, 111
    outp 0, 112
    outp 0, 101
    outp 0, 44
    outp 0, 32
    outp 0, 88
    outp 0, 101
    outp 0, 110
    outp 0, 111
    outp 0, 110
    outp 0, 49
    outp 0, 54
    outp 0, 47
    outp 0, 49
    outp 0, 64
    outp 0, 50
    outp 0, 55
    outp 0, 77
    outp 0, 72
    outp 0, 122
    outp 0, 44
    outp 0, 32
    outp 0, 115
    outp 0, 101
    outp 0, 114
    outp 0, 99
    outp 0, 111
    outp 0, 109
    outp 0, 109
    outp 0, 57
    outp 0, 54
    outp 0, 48
    outp 0, 48
    outp 0, 13
    outp 0, 10
    jmp shell

uptime@commands:
    push g15
    push g16
    mov g16, g02
    mov g15, ret#uptime@commands
    jmp npr
ret#uptime@commands:
    pop g16
    pop g15
    outp 0, 116
    outp 0, 107
    outp 0, 115
    outp 0, 13
    outp 0, 10
    jmp shell

poke@commands:
    ; Parse argument from input buffer
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
    mov g16, 0
    
skip_cmd#poke@commands:
    read
    cmp rs, 0
    je poke_no_arg#poke@commands
    cmp rs, 32
    je found_space#poke@commands
    add ap, 1
    mov ap, rs
    jmp skip_cmd#poke@commands
    
found_space#poke@commands:
    add ap, 1
    mov ap, rs
    
parse_num#poke@commands:
    read
    cmp rs, 0
    je poke_do#poke@commands
    sub rs, 48
    mov g12, rs
    cmp g12, 0
    js poke_no_arg#poke@commands
    cmp g12, 9
    jg poke_no_arg#poke@commands
    push rs
    mul g16, 10
    mov g16, rs
    pop rs
    add g16, g12
    mov g16, rs
    add ap, 1
    mov ap, rs
    jmp parse_num#poke@commands
    
poke_do#poke@commands:
    mov g12, g16
    pop ap
    pop ad
    push ad
    push ap
    mov ad, 0
    mov ap, g12
    read
    mov g16, rs
    pop ap
    pop ad
    
    outp 0, 91
    push g15
    push g16
    mov g16, g12
    mov g15, ret1#poke@commands
    jmp npr
ret1#poke@commands:
    pop g16
    pop g15
    
    outp 0, 93
    outp 0, 58
    outp 0, 32
    
    push g15
    mov g15, ret2#poke@commands
    jmp npr
ret2#poke@commands:
    pop g15
    outp 0, 13
    outp 0, 10
    
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_poke_loop#poke@commands:
    read
    cmp rs, 0
    je clear_poke_done#poke@commands
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_poke_loop#poke@commands
clear_poke_done#poke@commands:
    pop ap
    pop ad
    jmp shell
    
poke_no_arg#poke@commands:
    pop ap
    pop ad
    outp 0, 85
    outp 0, 115
    outp 0, 97
    outp 0, 103
    outp 0, 101
    outp 0, 58
    outp 0, 32
    outp 0, 112
    outp 0, 111
    outp 0, 107
    outp 0, 101
    outp 0, 32
    outp 0, 60
    outp 0, 97
    outp 0, 100
    outp 0, 100
    outp 0, 114
    outp 0, 101
    outp 0, 115
    outp 0, 115
    outp 0, 62
    outp 0, 13
    outp 0, 10
    push ad
    push ap
    mov ad, base@malloc
    mov ap, 0
clear_poke_err#poke@commands:
    read
    cmp rs, 0
    je clear_poke_err_done#poke@commands
    write 0
    add ap, 1
    mov ap, rs
    jmp clear_poke_err#poke@commands
clear_poke_err_done#poke@commands:
    pop ap
    pop ad
    jmp shell

reset@commands:
    jmp init

clear@commands:
    outp 0, 27
    outp 0, 91
    outp 0, 50
    outp 0, 74
    outp 0, 27
    outp 0, 91
    outp 0, 72
    jmp shell

ramcounter:
    push ad 
    push ap
    cc
    mov ad, 0
    mov ap, 0
    mov g16, 0
l@ramcounter:
    read
    add ap, 1
    mov ap, rs
    mov g16, ap
    jc e@ramcounter
    jnc c@ramcounter
    jmp l@ramcounter
e@ramcounter:
    pop ap
    pop ad
    cc
    jmp g15
c@ramcounter:
    jmp l@ramcounter

npr:
push g14
push g16
mov g14, 0
cmp g16, 0
je zero@npr
loop@npr:
    cmp g16, 0
    je done@npr
    mod g16, 10
    push rs
    div g16, 10
    mov g16, rs
    add g14, 1
    mov g14, rs
    jmp loop@npr
zero@npr:
    outp 0, 48
    jmp ok@npr
done@npr:
doneloop@npr:
    cmp g14, 0
    je ok@npr
    pop rs
    add rs, 48
    outp 0, rs
    sub g14, 1
    mov g14, rs
    jmp doneloop@npr
ok@npr:
    pop g16
    pop g14
    jmp g15

malloc:
strings@malloc:
push ad
push ap

mov ad, mem#strings@malloc
mov ap, 0
write 109
mov ap, 1
write 101
mov ap, 2
write 109
mov ap, 3
write 0

mov ad, halt#strings@malloc
mov ap, 0
write 104
mov ap, 1
write 97
mov ap, 2
write 108
mov ap, 3
write 116
mov ap, 4
write 0

mov ad, info#strings@malloc
mov ap, 0
write 105
mov ap, 1
write 110
mov ap, 2
write 102
mov ap, 3
write 111
mov ap, 4
write 0

mov ad, uptime#strings@malloc
mov ap, 0
write 117
mov ap, 1
write 112
mov ap, 2
write 116
mov ap, 3
write 105
mov ap, 4
write 109
mov ap, 5
write 101
mov ap, 6
write 0

mov ad, poke#strings@malloc
mov ap, 0
write 112
mov ap, 1
write 111
mov ap, 2
write 107
mov ap, 3
write 101
mov ap, 4
write 0

mov ad, reset#strings@malloc
mov ap, 0
write 114
mov ap, 1
write 101
mov ap, 2
write 115
mov ap, 3
write 101
mov ap, 4
write 116
mov ap, 5
write 0

mov ad, clear#strings@malloc
mov ap, 0
write 99
mov ap, 1
write 108
mov ap, 2
write 101
mov ap, 3
write 97
mov ap, 4
write 114
mov ap, 5
write 0

pop ap
pop ad
jmp g13

mem#strings@malloc:
    nop
halt#strings@malloc:
    nop
info#strings@malloc:
    nop
uptime#strings@malloc:
    nop
poke#strings@malloc:
    nop
reset#strings@malloc:
    nop
clear#strings@malloc:
    nop
base@malloc: