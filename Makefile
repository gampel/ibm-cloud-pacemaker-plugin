


install_all: install_deps install_plugin

install_deps:
	./install.Ubuntu
	cp scripts/ibm-cloud-pacemaker-fail-over.py /usr/local/bin

install_plugin:
	mkdir -p /usr/lib/ocf/resource.d/ibm-cloud/
	cp -a ibm-cloud-ocf/* /usr/lib/ocf/resource.d/ibm-cloud/
	chmod +x /usr/lib/ocf/resource.d/ibm-cloud/*
