.DEFAULT_GOAL := install

##@ Development Tools install

.PHONY: install
install: init-submodules	## Initialize submodules and generate all bundles
	./gen-bundle-version.sh all	

.PHONY: update
update: update-submodules	## Update submodules and bundles
	./gen-bundle-version.sh all

# Initialize git submodules
.PHONY: init-submodules
init-submodules:
	git submodule update --init --recursive

# Update git submodules
.PHONY: update-submodules
update-submodules: init-submodules
	git submodule foreach git pull origin master

.PHONY: help
help:
	@echo ""
	@echo "\033[1mUsage\033[0m"
	@echo "  make \033[36m<target>\033[0m"
	@echo "  make \033[36mhelp\033[0m        Shows this help"
	@awk 'BEGIN {FS = ":.*##"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
	@echo ""
