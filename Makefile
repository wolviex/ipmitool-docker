BUILD:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)
EXPORT:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)

UID:=$(shell id -u)
GID:=$(shell id -g)

NAME:=ipmitool
ifdef DOCKER_REPOSITORY
NAME:=$(DOCKER_REPOSITORY)
endif

VERSION:=latest
ifdef TRAVIS_BRANCH
ifneq ($(TRAVIS_BRANCH),master)
VERSION:=$(TRAVIS_BRANCH)
endif
endif

ifdef TRAVIS_COMMIT
COMMIT:=$(TRAVIS_COMMIT)
endif

ifdef REBUILD
DOCKER_OPTS:=--no-cache
endif

.PHONY: build-ipmitool ipmitool

all: build-ipmitool ipmitool

build-ipmitool:
	docker create --name=$(EXPORT) --volume=/export alpine:3.5 /bin/true
	docker build $(DOCKER_OPTS) --tag=$(BUILD) build/
ifdef S
	docker run -u $(UID):$(GID) --volume=$(S):/tmp/ipmitool-0 --volumes-from=$(EXPORT) $(BUILD)
else
	docker run -u $(UID):$(GID) --volumes-from=$(EXPORT) $(BUILD)
endif
	docker cp $(EXPORT):/export/ run/install/
	docker rm $(EXPORT)
	docker rmi $(BUILD)

ipmitool: build-ipmitool
	docker build --tag=$(NAME):$(VERSION) run/
ifdef COMMIT
	docker tag $(NAME):$(VERSION) $(NAME):$(COMMIT)
endif
