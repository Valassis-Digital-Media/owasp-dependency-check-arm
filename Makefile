SELF_DIR_SCRIPTS := $(dir $(lastword $(MAKEFILE_LIST)))

VERSION ?= $(shell cat $(SELF_DIR_SCRIPTS)version.txt)

PROJECT_NAME = dependency-check
DOCKER_HUB ?= 155136788633.dkr.ecr.eu-west-1.amazonaws.com
DOCKER_IMAGE_NAME=owasp/${PROJECT_NAME}
DOCKER_IMAGE_ID = $(DOCKER_HUB)/$(DOCKER_IMAGE_NAME)
DOCKER_IMAGE_URI=${DOCKER_IMAGE_ID}:${VERSION}

export PLATFORM_ARCH=linux/amd64,linux/arm64,linux/arm64/v8
export AWS_DEFAULT_REGION=eu-west-1

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
	--platform ${PLATFORM_ARCH} \
	--builder=mybuilder \
	--push \
	--tag ${DOCKER_IMAGE_URI} \
	--tag ${DOCKER_IMAGE_ID}:latest .

docker-inspect-multi-arch:
	docker inspect ${DOCKER_IMAGE_URI}

docker-ecr-login:
	aws ecr get-login-password | docker login --username AWS --password-stdin $(DOCKER_HUB)

aws-ecr-create-repository:
	aws ecr create-repository --repository-name $(DOCKER_IMAGE_NAME)

# SSH into the image built by `docker-build` to inspect the contents of the image
docker-ssh:
	docker run -it  --entrypoint='/bin/bash' ${DOCKER_IMAGE_URI}

docker-install-qemu-emulators:
	docker run -it --rm --privileged tonistiigi/binfmt --install all

#----PODMAN----

podman-machine-bootstrap:
	podman machine init
	podman machine start

podman-build:
	buildah build --jobs=4 --platform=${PLATFORM_ARCH} --manifest shazam .
	skopeo inspect --raw containers-storage:localhost/shazam | \
          jq '.manifests[].platform.architecture'
	buildah tag localhost/shazam $(DOCKER_IMAGE_URI)
	buildah tag localhost/shazam ${DOCKER_IMAGE_ID}:latest
	buildah manifest rm localhost/shazam
	buildah manifest push --all $(DOCKER_IMAGE_URI) docker://$(DOCKER_IMAGE_URI)
	buildah manifest push --all ${DOCKER_IMAGE_ID}:latest docker://${DOCKER_IMAGE_ID}:latest

podman-ecr-login:
	aws ecr get-login-password | podman login --username AWS --password-stdin $(DOCKER_HUB)

get-arch-multiarch-with-docker:
	docker pull --platform "linux/arm64" "${DOCKER_IMAGE_URI}"
	docker pull --platform "linux/amd64" "${DOCKER_IMAGE_URI}"
	docker run --rm --entrypoint=/usr/bin/arch $(DOCKER_IMAGE_URI)
	docker run --rm --platform linux/arm64 --entrypoint=/usr/bin/arch $(DOCKER_IMAGE_URI)
	docker run --rm --platform linux/amd64 --entrypoint=/usr/bin/arch $(DOCKER_IMAGE_URI)
