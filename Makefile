

install: install_all

install_all: install_deps install_plugin rsource_agnet

install_deps:
	./install.sh

install_plugin: install_python_plugins
	mkdir -p /usr/lib/ocf/resource.d/ibm-cloud/
	cp scripts/ibm_cloud_pacemaker_fail_over.py /usr/local/bin
	cp -a ibm-cloud-ocf/* /usr/lib/ocf/resource.d/ibm-cloud/
	chmod +x /usr/lib/ocf/resource.d/ibm-cloud/*
# install the plugins until we push them upstream
install_python_plugins:
	sudo sed -e 's|#!@PYTHON@|#!/usr/bin/python3|' ibm-cloud-ocf/ibm-cloud-vpc-cr-vip.in   > /usr/lib/ocf/resource.d/ibm-cloud/ibm-cloud-vpc-cr-vip
	sudo chmod 755 /usr/lib/ocf/resource.d/ibm-cloud/ibm-cloud-vpc-cr-vip
	sudo sed -e 's|#!@PYTHON@|#!/usr/bin/python3|' ibm-cloud-ocf/ibm-cloud-vpc-move-fip.in   > /usr/lib/ocf/resource.d/ibm-cloud/ibm-cloud-vpc-move-fip
	sudo chmod 755 /usr/lib/ocf/resource.d/ibm-cloud/ibm-cloud-vpc-move-fip
	cp deps/ibm_cloud_fail_over/src/ibm_cloud_fail_over/ibm_cloud_fail_over.py  /usr/lib/ocf/resource.d/ibm-cloud/ibm_cloud_fail_over.py

deps/resource-agents/heartbeat/ibmcloud-vpc-move-route:
	git submodule update --init
	cd deps/resource-agents ; ./autogen.sh ; ./configure ; make

rsource_agnet: deps/resource-agents/heartbeat/ibmcloud-vpc-move-route rsource_agnet_install

rsource_agnet_install: deps/resource-agents/heartbeat/ibmcloud-vpc-move-route
	cd deps/resource-agents ;make install
