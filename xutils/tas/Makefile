all:
	@echo "Available targets: xe16"

xe16:
	@rm -fr xe16-tas
	@echo "CC tas.c"
	@gcc -Werror -DCONFIG_XE16 -DCONFIG_DONE -DCONFIG_LABELDUMP asmparse.c xe16-asm.c tas.c -o xe16-tas
	@echo "STRIP xe16-tas"
	@strip xe16-tas