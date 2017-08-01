BUILD_IMAGE:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)
BUILD:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)
EXPORT:=$(shell mktemp -u tmp.XXXXXXXXXX | tr A-Z a-z)

UID:=$(shell id -u)
GID:=$(shell id -g)

NAME:=ipmitool
ifdef DOCKER_REPOSITORY
NAME:=$(DOCKER_REPOSITORY)
endif

BRANCH:=latest

ifdef CIRCLECI

ifdef CIRCLE_BRANCH
ifneq ($(CIRCLE_BRANCH),master)
BRANCH:=$(CIRCLE_BRANCH)
endif
endif

ifdef CIRCLE_TAG
TAG:=$(CIRCLE_TAG)
endif

ifdef CIRCLE_SHA1
COMMIT:=$(CIRCLE_SHA1)
endif

else

ifdef TRAVIS_BRANCH
ifneq ($(TRAVIS_BRANCH),master)
BRANCH:=$(TRAVIS_BRANCH)
endif
endif

ifdef TRAVIS_TAG
TAG:=$(TRAVIS_TAG)
endif

ifdef TRAVIS_COMMIT
COMMIT:=$(TRAVIS_COMMIT)
endif

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
	docker build --tag=$(NAME):$(BRANCH) run/
ifdef TAG
	docker tag $(NAME):$(BRANCH) $(NAME):$(TAG)
endif
ifdef COMMIT
	docker tag $(NAME):$(BRANCH) $(NAME):$(COMMIT)
endif
