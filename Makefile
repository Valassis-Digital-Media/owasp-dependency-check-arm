SELF_DIR_SCRIPTS := $(dir $(lastword $(MAKEFILE_LIST)))

VERSION ?= $(shell cat $(SELF_DIR_SCRIPTS)version.txt)

PROJECT_NAME = dependency-check
DOCKER_HUB ?= 155136788633.dkr.ecr.eu-west-1.amazonaws.com
DOCKER_IMAGE_NAME=owasp/${PROJECT_NAME}
DOCKER_IMAGE_ID = $(DOCKER_HUB)/$(DOCKER_IMAGE_NAME)
DOCKER_IMAGE_URI=${DOCKER_IMAGE_ID}:${VERSION}

get-docker-tag:
	@echo ${DOCKER_IMAGE_URI}

get-version:
	@echo ${VERSION}

get-project-name:
	@echo ${PROJECT_NAME}

docker-create-builder:
	docker buildx create --name mybuilder --driver-opt network=host --use

docker-build:
	docker build --rm -t ${DOCKER_IMAGE_ID}:arm \
	--no-cache \
	-f $(SELF_DIR_SCRIPTS)Dockerfile $(SELF_DIR_SCRIPTS)
	$(MAKE) docker-push

docker-push:
	docker push ${DOCKER_IMAGE_ID}:arm

docker-build-multi-arch:
	docker buildx build \
	--no-cache \
	--platform linux/arm64/v8,linux/amd64 \
	--builder=mybuilder \
	--push \
	--tag ${DOCKER_IMAGE_URI} \
	--tag ${DOCKER_IMAGE_ID}:latest .

docker-inspect-multi-arch:
	docker inspect ${DOCKER_IMAGE_URI}

docker-ecr-login:
	aws ecr get-login-password | docker login --username AWS --password-stdin $(DOCKER_HUB)

docker-ecr-create-repository:
	aws ecr create-repository --repository-name $(DOCKER_IMAGE_NAME)

# SSH into the image built by `docker-build` to inspect the contents of the image
docker-ssh:
	docker run -it  --entrypoint='/bin/bash' ${DOCKER_IMAGE_URI}

#----PODMAN----

podman-build:
	podman build --rm -t ${DOCKER_IMAGE_URI} \
	--no-cache \
	--arch=amd64 \
	-f $(SELF_DIR_SCRIPTS)Dockerfile ./$(SELF_DIR_SCRIPTS)
	podman tag ${DOCKER_IMAGE_URI} ${DOCKER_IMAGE_ID}:arm

install-qemu-emulators:
	docker run -it --rm --privileged tonistiigi/binfmt --install all
