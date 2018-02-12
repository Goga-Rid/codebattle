U := deploy

production-setup:
	ansible-playbook ansible/site.yml -i ansible/production -u $U --ask-sudo-pass

production-env-update:
	ansible-playbook ansible/deploy.yml -i ansible/production -u $U --tag env

production-deploy:
	ansible-playbook ansible/deploy.yml -i ansible/production -u $U --ask-vault-pass
