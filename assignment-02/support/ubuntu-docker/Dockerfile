FROM ubuntu:bionic

RUN apt-get update &&\
	apt-get install -y \
	curl \
	git-core \
	wget \
	vim \
	python3-dev libffi-dev gcc libssl-dev
RUN apt install -y python3-pip
RUN pip3 install -U pip
RUN apt install -y ansible
RUN pip3 install kolla-ansible
RUN mkdir -p /etc/kolla
RUN cp -r /usr/local/share/kolla-ansible/etc_examples/kolla/* /etc/kolla
# WORKDIR /root
# RUN git clone https://github.com/openstack/kolla &&\
# 	git clone https://github.com/openstack/kolla-ansible
# RUN pip3 install ./kolla
# RUN pip3 install ./kolla-ansible
RUN pip3 install python-openstackclient