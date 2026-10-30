all:
	@echo "Available targets: xe16"

xe16:
	@rm -fr xe16-tpd
	@echo "CC tpd.c"
	@gcc -Werror -DCONFIG_DONE -DCONFIG_XE16 ../tas/xe16-asm.c tpd.c -o xe16-tpd
	@echo "STRIP xe16-tpd"
	@strip xe16-tpd