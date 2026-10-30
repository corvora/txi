all:
	@echo "Available targets: xe16rom, xe16ram, xe16upd"

xe16rom:
	@make -C xutils xe16
	@echo "TAS main.S"
	@./xutils/xe16-tas main.S main.bin 0
	@make -C core xe16rom
	@openFPGALoader -b tangnano9k --external-flash main.bin

xe16ram:
	@make -C xutils xe16
	@echo "TAS main.S"
	@./xutils/xe16-tas main.S main.bin 0
	@make -C core xe16ram
	@openFPGALoader -b tangnano9k --external-flash main.bin

xe16upd:
	@make -C xutils xe16
	@echo "TAS main.S"
	@./xutils/xe16-tas main.S main.bin 0
	@openFPGALoader -b tangnano9k --external-flash main.bin