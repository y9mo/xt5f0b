PROJECT := xt5f0b

.PHONY: lint
lint:
	ansible-lint playbook.yml
