PHONY: install  

# Default command to pass to install.sh  
BUILD ?=   

install:  
	./scripts/install.sh $(BUILD)  

run:
	./scripts/run.sh