.PHONY: tools
tools:
	brew install terraform vault kubernetes-cli helm linkerd awscli k9s

.PHONY: completion
completion:
	echo "\ncomplete -C '`brew --prefix`/bin/aws_completer' aws" >> $(HOME)/.bashrc
	echo "\nsource <(kubectl completion bash)" >> $(HOME)/.bashrc
	echo "alias k=kubectl" >> $(HOME)/.bashrc
	echo "complete -F __start_kubectl k" >> $(HOME)/.bashrc
	echo "export KUBE_EDITOR='code --wait'" >> $(HOME)/.bashrc
	echo "\nsource <(helm completion bash)" >> $(HOME)/.bashrc
	echo "\nsource <(linkerd completion bash)" >> $(HOME)/.bashrc
	echo "\ncomplete -C $$HOME/bin/terraform terraform" >> $(HOME)/.bashrc

.PHONY: kubeconfig
kubeconfig:
	aws eks update-kubeconfig --name eks-lab --alias eks-lab

.PHONY: help
help:  ## Display this help menu
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-20s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)
