BUILD_IMAGE:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)
BUILD:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)
EXPORT:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)

UID:=$(shell id -u)
GID:=$(shell id -g)

NAME:=ipmitool
ifdef DOCKER_REPOSITORY
NAME:=$(DOCKER_REPOSITORY)
endif

ifdef CIRCLECI

ifdef CIRCLE_TAG
ifndef VERSION
VERSION:=$(CIRCLE_TAG)
endif
endif

ifdef CIRCLE_SHA1
ifndef VERSION
VERSION:=$(CIRCLE_SHA1)
endif
endif

ifdef CIRCLE_BRANCH
ifeq ($(CIRCLE_BRANCH),master)
BRANCH:=latest
else
BRANCH:=$(CIRCLE_BRANCH)
endif
endif

else

ifdef TRAVIS_TAG
ifndef VERSION
VERSION:=$(TRAVIS_TAG)
endif
endif

ifdef TRAVIS_COMMIT
ifndef VERSION
VERSION:=$(TRAVIS_COMMIT)
endif
endif

ifdef TRAVIS_BRANCH
ifeq ($(TRAVIS_BRANCH),master)
BRANCH:=latest
else
BRANCH:=$(TRAVIS_BRANCH)
endif
endif

endif

ifndef VERSION
VERSION:=latest
endif

ifdef REBUILD
DOCKER_OPTS:=--no-cache
endif

.PHONY: build-ipmitool ipmitool

all: build-ipmitool ipmitool

build-ipmitool:
	docker create --name=$(EXPORT) --user=$(UID):$(GID) --volume=/export alpine:3.5 /bin/true
	docker build $(DOCKER_OPTS) --tag=$(BUILD_IMAGE) build/
ifdef S
	docker run --name=$(BUILD) --user=$(UID):$(GID) --volumes-from=$(EXPORT) --volume=$(S):/tmp/ipmitool-0 $(BUILD_IMAGE)
else
	docker run --name=$(BUILD) --user=$(UID):$(GID) --volumes-from=$(EXPORT) $(BUILD_IMAGE)
endif
	docker cp $(EXPORT):/export/ run/install/
	docker rm $(EXPORT) $(BUILD)
	docker rmi $(BUILD_IMAGE)

ipmitool: build-ipmitool
	docker build --tag=$(NAME):$(VERSION) run/
ifdef BRANCH
	docker tag $(NAME):$(VERSION) $(NAME):$(BRANCH)
endif
