.PHONY: build-all release-all

# Use bash for inline if-statements in test target
SHELL:=bash

OWNER:=lujianmei


build-all: docker build --rm --force-rm -t $(OWNER)/metabase-docker:latest .
# build-all: $(foreach I,$(ALL_IMAGES),arch_patch/$(I) build/$(I) ) ## build all stacks

dev/%: ARGS?=
dev/%: DARGS?=
dev/%: PORT?=3000
dev/%: ## run a foreground container for a stack
	docker run -it --rm -p $(PORT):3000 $(DARGS) $(OWNER)/metabase-docker $(ARGS)

push/%: ## push the latest and HEAD git SHA tags for a stack to Docker Hub
	docker login -u=$(DOCKER_NAME) -p=$(DOCKER_PASSWORD)
	docker push $(OWNER)/metabase-docker:latest
	#docker push $(OWNER)/$(notdir $@):$(GIT_MASTER_HEAD_SHA)


refresh/%: ## pull the latest image from Docker Hub for a stack
# skip if error: a stack might not be on dockerhub yet
	-docker pull $(OWNER)/metabase-docker:latest


release-all: build-all push

test/%: ## run a stack container, check for jupyter server liveliness
	@-docker rm -f container-test
	@docker run -d --name container-test $(OWNER)/metabase-docker
	@for i in $$(seq 0 9); do \
		sleep $$i; \
		docker exec container-test bash -c 'wget http://localhost:3000 -O- | grep -i metabase'; \
		if [[ $$? == 0 ]]; then exit 0; fi; \
	done ; exit 1
