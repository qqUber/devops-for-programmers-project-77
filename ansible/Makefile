prepare:
	ansible-galaxy install -r requirements.yml
clean-up-workdir:
	rm -rf group_vars/webservers/vault_generated.yml inventory.ini

run-playbook:
	ansible-playbook playbook.yml -i inventory.ini --vault-password-file ../vault-password --tags $(TAGS)

encrypt:
	ansible-vault encrypt --vault-password-file ../vault-password group_vars/webservers/vault_generated.yml
decrypt:
	ansible-vault decrypt --vault-password-file ../vault-password group_vars/webservers/vault_generated.yml

setup-servers:
	make -C . encrypt && \
	make -C . run-playbook TAGS="setup"