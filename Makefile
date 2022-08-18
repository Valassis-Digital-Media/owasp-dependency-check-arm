SELF_DIR_SCRIPTS := $(dir $(lastword $(MAKEFILE_LIST)))

VERSION ?= $(shell cat $(SELF_DIR_SCRIPTS)version.txt)

PROJECT_NAME = dependency-check
DOCKER_HUB ?= 155136788633.dkr.ecr.eu-west-1.amazonaws.com
DOCKER_IMAGE_ID = $(DOCKER_HUB)/owasp/${PROJECT_NAME}
DOCKER_IMAGE_URI=${DOCKER_IMAGE_ID}:${VERSION}

get-docker-tag:
	@echo ${DOCKER_IMAGE_URI}

get-version:
	@echo ${VERSION}

get-project-name:
	@echo ${PROJECT_NAME}

docker-build:
	docker build --rm -t ${DOCKER_IMAGE_URI} \
	--no-cache \
	-f $(SELF_DIR_SCRIPTS)Dockerfile ./$(SELF_DIR_SCRIPTS)
	docker tag ${DOCKER_IMAGE_URI} ${DOCKER_IMAGE_ID}:arm

docker-build-multi-arch:
	docker buildx build \
    --platform linux/arm/v7,linux/arm64/v8,linux/amd64 \
    --tag ${DOCKER_IMAGE_ID}:buildx-latest .

# SSH into the image built by `docker-build` to inspect the contents of the image
docker-ssh:
	docker run -it  --entrypoint='/bin/bash' ${DOCKER_IMAGE_URI}

podman-build:
	podman build --rm -t ${DOCKER_IMAGE_URI} \
	--no-cache \
	--arch=amd64 \
	-f $(SELF_DIR_SCRIPTS)Dockerfile ./$(SELF_DIR_SCRIPTS)
	podman tag ${DOCKER_IMAGE_URI} ${DOCKER_IMAGE_ID}:arm
