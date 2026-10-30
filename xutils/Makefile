all:
	@echo "Available targets: xe16"

xe16:
	@rm -fr xe16-tas 
	@rm -fr xe16-tpd
	@make -C tas xe16
	@make -C tpd xe16
	@echo "CP tas/xe16-tas"
	@cp tas/xe16-tas .
	@echo "CP tas/xe32-tpd"
	@cp tpd/xe16-tpd .