

install: install_all

install_all: install_deps install_plugin

install_deps:
	./install.sh

install_plugin:
	mkdir -p /usr/lib/ocf/resource.d/ibm-cloud/
	cp scripts/ibm_cloud_pacemaker_fail_over.py /usr/local/bin
	cp -a ibm-cloud-ocf/* /usr/lib/ocf/resource.d/ibm-cloud/
	chmod +x /usr/lib/ocf/resource.d/ibm-cloud/*
