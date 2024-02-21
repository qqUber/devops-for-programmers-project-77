prepare:
	terraform login; terraform init
setup-infrastructure:
	terraform apply; \
	terraform output -raw ansible_inventory > ../ansible/inventory.ini; \
	terraform output -raw vault > ../ansible/group_vars/webservers/vault_generated.yml
destroy:
	terraform destroy;