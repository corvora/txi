.PHONY: all

all:
	@echo "ram (run temporarily)"
	@echo "rom (run permanently)"

ram:
	@rm -fr top.json top_pnr.json top.fs
	@echo "YSY ram.v, top.v"
	@yosys -p "read_verilog -sv spiflash.v divmod.v uart_tx.v uart_rx.v ram.v top.v; synth_gowin -nowidelut -top top -json top.json;"
	@echo "PNR top.json"
	@nextpnr-himbaechel --freq 15 --json top.json --write top_pnr.json --device GW1NR-LV9QN88PC6/I5 --vopt cst=tangnano9k.cst --vopt family=GW1N-9C --threads=32
	@echo "PACK top_pnr.json"
	@gowin_pack -d GW1N-9C -o top.fs top_pnr.json
	@echo "LDR top.fs"
	@openFPGALoader -b tangnano9k top.fs

rom:
	@rm -fr top.json top_pnr.json top.fs
	@echo "YSY ram.v, top.v"
	@yosys -p "read_verilog -sv spiflash.v divmod.v uart_tx.v uart_rx.v ram.v top.v; synth_gowin -nowidelut -top top -json top.json;"
	@echo "PNR top.json"
	@nextpnr-himbaechel --freq 15 --json top.json --write top_pnr.json --device GW1NR-LV9QN88PC6/I5 --vopt cst=tangnano9k.cst --vopt family=GW1N-9C --threads=32
	@echo "PACK top_pnr.json"
	@gowin_pack -d GW1N-9C -o top.fs top_pnr.json
	@echo "LDR top.fs"
	@openFPGALoader -b tangnano9k -f top.fs