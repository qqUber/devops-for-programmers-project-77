generate_password:
	echo $RANDOM | base64 | head -c 20 > vault-password
prepare:
	make generate_password; make -C ansible prepare; make -C terraform prepare;

setup:
	make -C ansible clean-up-workdir && \
	make -C terraform setup-infrastructure && \
	make -C ansible setup-servers
	
destroy:
	make -C terraform destroy
	
deploy:
	make -C ansible run-playbook TAGS="deploy"

all: prepare setup deploy