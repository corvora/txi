module top #(
    parameter RAM_SIZ = 49152, // 48Kb
    parameter UART_FR = 234, // 115200 baud @ 27MHz = 234, 9600 baud @ 27MHz = 2812 (accurate)
    parameter BIOS_SIZ = 32767, // 32Kb
    parameter STACKSIZ = 16
) (
    input clk,
    input rst,
    output reg [5:0] gpo,
    input [0:0] gpi,
    output tx,
    input flashMiso, output reg flashMosi,
    output reg flashCs, output reg flashClk, input rx
); 
    
    // registers
    reg [15:0] sys_base;
    reg [15:0] regs [0:27];
    reg [15:0] stack [0:STACKSIZ-1];

    // icache
    reg [15:0] op;
    reg [15:0] dta;
    reg [15:0] va;
    reg [15:0] dtb;
    reg [15:0] vb;

    // ro-regs
    reg [15:0] sp;
    reg [15:0] pc;

    // loop control
    reg [15:0] idx;

    // register numbers
    localparam rflg = 0; // rw
    localparam rg01 = 1; // rw
    localparam rg02 = 2; // rw
    localparam rg03 = 3; // rw
    localparam rg04 = 4; // rw
    localparam rg05 = 5; // rw
    localparam rg06 = 6; // rw
    localparam rg07 = 7; // rw
    localparam rg08 = 8; // rw
    localparam rg09 = 9; // rw
    localparam rg10 = 10; // rw
    localparam rg11 = 11; // rw
    localparam rg12 = 12; // rw
    localparam rg13 = 13; // rw
    localparam rg14 = 14; // rw
    localparam rg15 = 15; // rw
    localparam rg16 = 16; // rw
    localparam rrs = 17; // rw
    localparam rad = 18; // rw
    localparam rap = 19; // rw
    localparam rsys1 = 20; // rw
    localparam rsys2 = 21; // rw 
    localparam rsys3 = 22; // rw
    localparam rsys4 = 23; // rw
    localparam rsys5 = 24; // rw
    localparam rsys6 = 25; // rw
    localparam rsys7 = 26; // rw 
    localparam rsys8 = 27; // rw

    // data type numbers
    localparam dreg = 0;
    localparam draw = 1;

    // instruction numbers
    localparam imov = 0; // done
    localparam iadd = 1; // done
    localparam isub = 2; // done
    localparam imul = 3; // done
    localparam idiv = 4; // done
    localparam iand = 5; // done
    localparam inot = 6; // done
    localparam ior = 7; // done
    localparam ixor = 8; // done
    localparam iinp = 9; // done
    localparam ioutp = 10; // done
    localparam ijmp = 11; // done
    localparam icmp = 12; // done
    localparam iread = 13; // done
    localparam iwrite = 14; // done
    localparam ije = 15; // done
    localparam ijne = 16; // done
    localparam ijg = 17; // done
    localparam ijs = 18; // done
    localparam ijc = 19; // done
    localparam ipush = 20; // done
    localparam ipop = 21; // done
    localparam isc = 22; // done
    localparam icc = 23; // done
    localparam icls = 24; // done
    localparam ihlt = 25; // done
    localparam ishl = 26; // done
    localparam ishr = 27; // done
    localparam ijnc = 28; // done
    localparam imod = 29; // done
    localparam inop = 30; // done
    localparam isys = 31; // done
    localparam isysbase = 32; // done


    // bram
    wire [7:0] dout;
    reg [7:0] din;
    reg [15:0] addr;
    reg ena;
    reg enw;
    
    ram #(
        .BITS     	(8      ),
        .SIZE     	(RAM_SIZ),
        .ADDRBITS 	(16    ))
    u_ram(
        .clk  	(clk),
        .ena  	(ena   ),
        .enw  	(enw   ),
        .din  	(din   ),
        .dout 	(dout  ),
        .addr 	(addr  )
    );

    reg uena;
    wire ens;
    reg [7:0] cdata;
    // Clock-sensitive
    uart_tx #(
        .FRAME_LENGTH(UART_FR)
    ) u_uart_tx (
        .clk   	(clk    ),
        .tx    	(tx     ),
        .ena   	(uena   ),
        .cdata 	(cdata  ),
        .ens    (ens    )
    );

    // output declaration of module divmod
    reg [15:0] A;
    reg [15:0] B;
    wire [15:0] C;
    wire [15:0] D;
    wire E;
    reg F;
    
    divmod #(
        .BITS 	(16  ))
    u_divmod(
        .clk 	(clk  ),
        .A   	(A    ),
        .B   	(B    ),
        .C   	(C    ),
        .D   	(D    ),
        .E   	(E    ),
        .F   	(F    )
    );
    
    reg [23:0] spf_addr;
    wire [7:0] spf_data;
    reg spf_ena;
    reg spf_reset;
    reg spf_done;
    initial spf_reset = 0;
    initial spf_addr = 0;
    initial spf_ena = 0;
    spiflash u_spiflash(
        .clk(clk),
        .flashMiso(flashMiso),
        .flashMosi(flashMosi),
        .flashCs(flashCs),
        .flashClk(flashClk),
        .addr(spf_addr),
        .data(spf_data),
        .ena(spf_ena),
        .done(spf_done)
    ); 
    
    wire [7:0] rx_data;
    wire rx_done;
    wire rx_idle;
    reg rx_ena;
    initial rx_ena = 0;
    // apparently rx doesnt need ENA
    uart_rx #(
        .FRAME_LENGTH(UART_FR)
    ) u_uart_rx(
        .clk  	(clk   ),
        .rx   	(rx    ),
        .data 	(rx_data  ),
        .done 	(rx_done  ),
        .ena  	(1   ),
        .idle 	(rx_idle  )
    );
    initial begin
        F = 0;
        idx = 0;
        cdata = 0;
        op = 0;
        dta = 0;
        va = 0;
        dtb = 0;
        vb = 0;
        pc = 0;
        sp = 0;
        ena = 0;
        enw = 0;
        din = 0;
        addr = 0;
        op = 0;
        dta = 0;
        dtb = 0;
        va = 0;
        vb = 0;
        uena = 0;
        gpo = 6'b111111;
        A = 0;
        B = 0;
        sys_base = 0;
        for (idx = 0; idx < 28; idx = idx + 1) regs[idx] = 0;
        for (idx = 0; idx < STACKSIZ; idx = idx + 1) begin
            stack[idx] = 0;
        end
        sp = 0;
    end
    localparam ST_RESET = 0;
    localparam ST_LOADADDR = 1;
    localparam ST_WAIT = 2;
    localparam ST_READ = 3;
    localparam ST_EXEC = 4;
    localparam ST_MBUS_W = 5;
    localparam ST_MBUS_R = 6;
    localparam ST_UART_STALLA = 7;
    localparam ST_UART_STALLB = 8;
    localparam ST_UART_STALLC = 9;
    localparam ST_DIVMOD = 10;
    localparam ST_DIVMOD_STALLA = 11;
    localparam ST_DIVMOD_STALLB = 12;
    localparam ST_DIVMOD_STALLC = 13;
    localparam ST_SPF_SETUP = 14;
    localparam ST_SPF_STALLA = 15;
    localparam ST_SPF_STALLB = 16;
    localparam ST_SPF = 17;
    localparam ST_RESET_CYC = 18;
    localparam ST_RESET_CYCSPFA = 19;
    localparam ST_RESET_CYCSPFB = 20;
    localparam STATE_UART_INIT = 21;
    localparam STATE_UART_WAIT_IDLE = 22;
    localparam STATE_UART_WAIT_DONE = 23;
    localparam STATE_UART_DONE = 24;

    reg isdiv;
    reg [15:0] idxcache;
    reg [15:0] bstate;
    reg [15:0] membus_w;
    reg [15:0] membus_cyc;
    initial membus_w = 0;
    initial membus_cyc = 0;
    initial bstate = ST_RESET;
    initial idxcache = 0;
    initial isdiv = 1;

    localparam RST_ST_CORE = 0;
    localparam RST_ST_RAM = 1;
    localparam RST_ST_SPF = 2;
    localparam RST_ST_END = 3;
    reg [15:0] restate;
    reg respf;
    initial restate = RST_ST_CORE;
    initial respf = 0;
    always @(posedge clk) begin
        if (~rst) begin
            bstate <= ST_RESET_CYC;
            restate <= RST_ST_CORE;
        end else begin
            // icache-bram state machine
            case (bstate)
                ST_RESET: begin
                    case (restate)
                        RST_ST_CORE: begin
                            for (idx = 0; idx < 28; idx = idx + 1) regs[idx] <= 0;
                            F <= 0;
                            membus_w <= 0;
                            membus_cyc <= 0;
                            idxcache <= 0;
                            cdata <= 0;
                            op <= 0;
                            dta <= 0;
                            rx_ena <= 0;
                            va <= 0;
                            dtb <= 0;
                            vb <= 0;
                            pc <= 0;
                            sp <= 0;
                            ena <= 0;
                            enw <= 0;
                            idx <= 0;
                            din <= 0;
                            addr <= 0;
                            op <= 0;
                            dta <= 0;
                            dtb <= 0;
                            va <= 0;
                            vb <= 0;
                            uena <= 0;
                            gpo <= 6'b011111;
                            A <= 0;
                            sys_base <= 0;
                            B <= 0;
                            restate <= RST_ST_RAM;
                            spf_reset <= 1;
                            bstate <= ST_RESET_CYC;
                            respf <= 0;
                            for (idx = 0; idx < STACKSIZ; idx = idx + 1) begin
                                stack[idx] <= 0;
                            end
                            sp <= 0;
                        end
                        RST_ST_RAM: begin
                            if (addr < RAM_SIZ) begin
                                case (membus_cyc)
                                    0: begin
                                        ena <= 1;
                                        enw <= 1;
                                        din <= 0;
                                        membus_cyc <= membus_cyc + 1;
                                    end
                                    1: begin
                                        membus_cyc <= membus_cyc + 1;
                                    end
                                    2: begin
                                        addr <= addr + 1;
                                        membus_cyc <= 0;
                                    end
                                endcase
                            end else begin
                                ena <= 0;
                                enw <= 0;
                                membus_cyc <= 0;
                                restate <= RST_ST_SPF;
                                addr <= 0;
                                gpo <= 6'b011111;
                            end
                        end
                        RST_ST_SPF: begin
                            ena <= 1;
                            enw <= 1;
                            spf_ena <= 1;
                            if (addr < BIOS_SIZ) begin
                                if (respf) begin
                                    din <= spf_data;
                                    respf <= 0;
                                    bstate <= ST_RESET_CYCSPFA;
                                end else begin
                                    spf_addr <= addr;
                                    spf_reset <= 1;
                                    bstate <= ST_SPF_SETUP;
                                end
                            end else begin
                                spf_ena <= 0;
                                ena <= 0;
                                enw <= 0;
                                spf_reset <= 0;
                                spf_addr <= 0;
                                addr <= 0;
                                respf <= 0;
                                restate <= RST_ST_END;
                                gpo <= 6'b011110;
                            end
                        end
                        RST_ST_END: begin
                            restate <= RST_ST_CORE;
                            bstate <= ST_LOADADDR;
                            gpo <= 6'b111111;
                        end
                    endcase
                end
                ST_LOADADDR: begin
                    addr <= pc + idxcache;
                    ena <= 1;
                    enw <= 0;
                    bstate <= ST_WAIT;
                end
                ST_WAIT: begin
                    bstate <= ST_READ;
                end
                ST_READ: begin
                    case (idxcache)
                        0: op <= dout << 8;
                        1: op <= op | (dout);

                        2: dta <= dout << 8;
                        3: dta <= dta | (dout);

                        4: va <= dout << 8;
                        5: va <= va | (dout);

                        6: dtb <= dout << 8;
                        7: dtb <= dtb | (dout);

                        8: vb <= dout << 8;
                        9: vb <= vb | (dout); 
                    endcase
                    if (idxcache < 9) begin
                        idxcache <= idxcache + 1;
                        bstate <= ST_LOADADDR;
                    end else begin
                        idxcache <= 0;
                        bstate <= ST_EXEC;
                        pc <= pc + 10;
                    end
                end
                ST_EXEC: begin
                    bstate <= ST_LOADADDR;
                    case (op)
                        iadd: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] + regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] + vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va + regs[vb];
                                end else begin
                                    regs[rrs] <= va + vb;
                                end
                            end
                        end
                        isub: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] - regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] - vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va - regs[vb];
                                end else begin
                                    regs[rrs] <= va - vb;
                                end
                            end
                        end
                        imul: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] * regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] * vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va * regs[vb];
                                end else begin
                                    regs[rrs] <= va * vb;
                                end
                            end
                        end
                        idiv: begin
                            bstate <= ST_DIVMOD_STALLA;
                            F <= 1;
                            isdiv <= 1;
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    A <= regs[va];
                                    B <= regs[vb];
                                end else begin
                                    A <= regs[va];
                                    B <= vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    A <= va;
                                    B <= regs[vb];
                                end else begin
                                    A <= va;
                                    B <= vb;
                                end
                            end
                        end
                        imod: begin
                            bstate <= ST_DIVMOD_STALLA;
                            F <= 1;
                            isdiv <= 0;
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    A <= regs[va];
                                    B <= regs[vb];
                                end else begin
                                    A <= regs[va];
                                    B <= vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    A <= va;
                                    B <= regs[vb];
                                end else begin
                                    A <= va;
                                    B <= vb;
                                end
                            end
                        end
                        // TODO: Add uart rx later.
                        iinp: begin
                            if (dta == dreg) begin
                                if (regs[va] != 0) begin
                                    regs[rrs] <= gpi[regs[va] - 1];
                                end else begin
                                    bstate <= STATE_UART_INIT;
                                end
                            end else begin
                                if (va != 0) begin
                                    regs[rrs] <= gpi[va - 1];
                                end else begin
                                    bstate <= STATE_UART_INIT;
                                end
                            end
                        end
                        ioutp: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    if (regs[va] != 0) begin
                                        gpo[regs[va] - 1] <= regs[vb];
                                    end else begin
                                        uena <= 1;
                                        cdata <= regs[vb] & 8'hff;
                                        bstate <= ST_UART_STALLA;
                                    end
                                end else begin
                                    if (regs[va] != 0) begin
                                        gpo[regs[va] - 1] <= vb;
                                    end else begin
                                        uena <= 1;
                                        cdata <= vb & 8'hff;
                                        bstate <= ST_UART_STALLA;
                                    end
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    if (va != 0) begin
                                        gpo[va - 1] <= regs[vb];
                                    end else begin
                                        uena <= 1;
                                        cdata <= regs[vb] & 8'hff;
                                        bstate <= ST_UART_STALLA;
                                    end
                                end else begin
                                    if (va != 0) begin
                                        gpo[va - 1] <= vb;
                                    end else begin
                                        uena <= 1;
                                        cdata <= vb & 8'hff;
                                        bstate <= ST_UART_STALLA;
                                    end
                                end
                            end
                        end
                        icmp: begin
                            regs[rflg][0] <= 0;
                            regs[rflg][1] <= 0;
                            regs[rflg][2] <= 0;
                            if (dta == dreg) begin
                                if (dtb == draw) begin
                                    if (regs[va] == vb) begin
                                        regs[rflg][0] <= 1;
                                    end
                                    if (regs[va] < vb) begin
                                        regs[rflg][1] <= 1;
                                    end
                                    if (regs[va] > vb) begin
                                        regs[rflg][2] <= 1;
                                    end
                                end else begin
                                    if (regs[va] == regs[vb]) begin
                                        regs[rflg][0] <= 1;
                                    end
                                    if (regs[va] < regs[vb]) begin
                                        regs[rflg][1] <= 1;
                                    end
                                    if (regs[va] > regs[vb]) begin
                                        regs[rflg][2] <= 1;
                                    end
                                end
                            end else begin
                                if (dtb == draw) begin
                                    if (va == vb) begin
                                        regs[rflg][0] <= 1;
                                    end
                                    if (va < vb) begin
                                        regs[rflg][1] <= 1;
                                    end
                                    if (va > vb) begin
                                        regs[rflg][2] <= 1;
                                    end
                                end else begin
                                    if (va == regs[vb]) begin
                                        regs[rflg][0] <= 1;
                                    end
                                    if (va < regs[vb]) begin
                                        regs[rflg][1] <= 1;
                                    end
                                    if (va > regs[vb]) begin
                                        regs[rflg][2] <= 1;
                                    end
                                end
                            end
                        end
                        isc: begin
                            regs[rflg][3] <= 1;
                        end
                        icc: begin
                            regs[rflg][3] <= 0;
                        end
                        imov: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[va] <= regs[vb];
                                end else begin
                                    regs[va] <= vb;
                                end
                            end
                        end 
                        ixor: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] ^ regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] ^ vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va ^ regs[vb];
                                end else begin
                                    regs[rrs] <= va ^ vb;
                                end
                            end
                        end
                        ior: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] | regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] | vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va | regs[vb];
                                end else begin
                                    regs[rrs] <= va | vb;
                                end
                            end
                        end
                        iand: begin
                            if (dta == dreg) begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= regs[va] & regs[vb];
                                end else begin
                                    regs[rrs] <= regs[va] & vb;
                                end
                            end else begin
                                if (dtb == dreg) begin
                                    regs[rrs] <= va & regs[vb];
                                end else begin
                                    regs[rrs] <= va & vb;
                                end
                            end
                        end
                        inot: begin
                            if (dta == dreg) begin
                                regs[rrs] <= ~regs[va];
                            end else begin
                                regs[rrs] <= ~va;
                            end
                        end
                        ishr: begin
                            if (dta == dreg) begin
                                if (dtb == draw) begin
                                    regs[rrs] <= regs[va] >> vb;
                                end else begin
                                    regs[rrs] <= regs[va] >> regs[vb];
                                end
                            end else begin
                                if (dtb == draw) begin
                                    regs[rrs] <= va >> vb;
                                end else begin
                                    regs[rrs] <= va >> regs[vb];
                                end
                            end
                        end
                        ishl: begin
                            if (dta == dreg) begin
                                if (dtb == draw) begin
                                    regs[rrs] <= regs[va] << vb;
                                end else begin
                                    regs[rrs] <= regs[va] << regs[vb];
                                end
                            end else begin
                                if (dtb == draw) begin
                                    regs[rrs] <= va << vb;
                                end else begin
                                    regs[rrs] <= va << regs[vb];
                                end
                            end
                        end
                        icls: begin
                            for (idx = 0; idx < STACKSIZ; idx = idx + 1) begin
                                stack[idx] <= 0;
                            end
                            sp <= 0;
                        end
                        ipush: begin
                            if (sp < STACKSIZ) begin
                                if (dta == dreg) begin
                                    stack[sp] <= regs[va];
                                end else begin
                                    stack[sp] <= va;
                                end
                                sp <= sp + 1;
                            end
                        end
                        ipop: begin
                            if (sp > 0) begin
                                sp <= sp - 1;
                                if (dta == dreg) begin
                                    regs[va] <= stack[sp - 1];
                                end
                            end
                        end
                        inop: begin

                        end
                        ije: begin
                            if (regs[rflg][0] == 1) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijne: begin
                            if (regs[rflg][0] == 0) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijg: begin
                            if (regs[rflg][2] == 1) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijs: begin
                            if (regs[rflg][1] == 1) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijc: begin
                            if (regs[rflg][3] == 1) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijnc: begin
                            if (regs[rflg][3] == 0) begin
                                if (dta == draw) begin
                                    pc <= va;
                                end else begin
                                    pc <= regs[va];
                                end
                            end
                        end
                        ijmp: begin
                            if (dta == draw) begin
                                pc <= va;
                            end else begin
                                pc <= regs[va];
                            end
                        end
                        ihlt: begin
                            pc <= pc - 10;
                        end
                        iread: begin
                            if ((regs[rad] + regs[rap]) < RAM_SIZ) begin
                                membus_cyc <= 0;
                                bstate <= ST_MBUS_R;
                            end else begin
                                regs[rflg][3] <= 1;
                            end
                        end
                        iwrite: begin
                            if (dta == dreg) begin
                                if (regs[va] < RAM_SIZ) begin
                                    membus_w <= regs[va];
                                    membus_cyc <= 0;
                                    bstate <= ST_MBUS_W;
                                end else begin
                                    regs[rflg][3] <= 1;
                                end
                            end else begin
                                if (va < RAM_SIZ) begin
                                    membus_w <= va;
                                    membus_cyc <= 0;
                                    bstate <= ST_MBUS_W;
                                end else begin
                                    regs[rflg][3] <= 1;
                                end
                            end
                        end
                        isys: begin
                            pc <= sys_base;
                        end
                        isysbase: begin
                            if (dta == draw) begin
                                sys_base <= va;
                            end else begin
                                sys_base <= regs[va];
                            end
                        end
                        default: begin
                        end
                    endcase
                end
                ST_MBUS_W: begin
                    ena <= 1;
                    enw <= 1;
                    case (membus_cyc)
                        0: begin
                            addr <= (regs[rad] + regs[rap]);
                            din <= (membus_w) & 8'hff;
                            membus_cyc <= membus_cyc + 1;
                        end
                        1: begin
                            membus_cyc <= membus_cyc + 1;
                        end
                        2: begin
                            membus_cyc <= 0;
                            ena <= 0;
                            enw <= 0;
                            bstate <= ST_LOADADDR;
                        end
                    endcase
                end
                ST_MBUS_R: begin
                    ena <= 1;
                    enw <= 0;
                    case (membus_cyc)
                        0: begin
                            addr <= (regs[rad] + regs[rap]);
                            membus_cyc <= membus_cyc + 1;
                        end
                        1: begin
                            membus_cyc <= membus_cyc + 1;
                        end
                        2: begin
                            regs[rrs] <= dout & 8'hff;
                            ena <= 0;
                            enw <= 0;
                            bstate <= ST_LOADADDR;
                        end
                    endcase
                end
                ST_UART_STALLA: begin
                    if (~ens) begin
                        bstate <= ST_UART_STALLB;
                    end else begin
                        bstate <= ST_UART_STALLA;
                    end
                end
                ST_UART_STALLB: begin
                    if (ens) begin
                        bstate <= ST_UART_STALLC;
                        uena <= 0;
                    end else begin
                        bstate <= ST_UART_STALLB;
                    end
                end
                ST_UART_STALLC: begin
                    if (~ens) begin 
                        bstate <= ST_LOADADDR;
                    end else begin
                        bstate <= ST_UART_STALLC;
                    end
                end
                // TODO: add 0 division fix
                ST_DIVMOD: begin
                    if (~E) begin
                        if (isdiv) regs[rrs] <= C; else regs[rrs] <= D;
                        bstate <= ST_LOADADDR;
                    end
                end
                ST_DIVMOD_STALLA: begin
                    if (~E) begin
                        bstate <= ST_DIVMOD_STALLB;
                        F <= 0;
                    end
                end
                ST_DIVMOD_STALLB: begin
                    if (E) begin
                        bstate <= ST_DIVMOD_STALLC;
                    end
                end
                ST_DIVMOD_STALLC: begin
                    if (~E) begin
                        bstate <= ST_DIVMOD;
                    end
                end
                ST_SPF_SETUP: begin
                    spf_ena <= 1;
                    bstate <= ST_SPF_STALLA;
                end
                ST_SPF_STALLA: begin
                    if (~spf_done) bstate <= ST_SPF_STALLB;
                    if (~spf_done) spf_ena <= 0;
                end
                ST_SPF_STALLB: begin
                    if (spf_done) bstate <= ST_SPF;
                end
                ST_SPF: begin
                    if (spf_reset) begin
                        bstate <= ST_RESET_CYC;
                        respf <= 1;
                    end else begin
                        bstate <= ST_LOADADDR;
                    end
                end
                ST_RESET_CYC: begin
                    bstate <= ST_RESET;
                end
                ST_RESET_CYCSPFA: begin
                    bstate <= ST_RESET_CYCSPFB;
                end
                ST_RESET_CYCSPFB: begin
                    addr <= addr + 1;
                    bstate <= ST_RESET_CYC;
                end
                STATE_UART_INIT: begin
                    rx_ena <= 1;
                    bstate <= STATE_UART_WAIT_IDLE;
                end
                STATE_UART_WAIT_IDLE: begin
                    if (rx_idle) begin
                        bstate <= STATE_UART_WAIT_DONE;
                        rx_ena <= 0;
                    end
                end
                STATE_UART_WAIT_DONE: begin
                    if (rx_done) bstate <= STATE_UART_DONE;
                end
                STATE_UART_DONE: begin
                    regs[rrs] <= rx_data;
                    bstate <= ST_LOADADDR;
                end
            endcase
        end
    end 
endmodule
