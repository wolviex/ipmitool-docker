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

ifdef REBUILD
DOCKER_OPTS:=--no-cache
endif

.PHONY: build-ipmitool ipmitool

all: build-ipmitool ipmitool

build-ipmitool:
	docker build $(DOCKER_OPTS) --tag=$(BUILD_IMAGE) build/
	docker volume create $(EXPORT)
	docker run --mount=source=$(EXPORT),target=/export --tty --rm docker.io/library/alpine:3.7 /bin/chown -R $(UID):$(GID) /export
ifdef S
	docker run --name=$(BUILD) --user=$(UID):$(GID) --mount=source=$(EXPORT),target=/export --volume=$(S):/tmp/ipmitool-0:ro --tty $(BUILD_IMAGE)
else
	docker run --name=$(BUILD) --user=$(UID):$(GID) --mount=source=$(EXPORT),target=/export --tty $(BUILD_IMAGE)
endif
	docker cp $(BUILD):/export/ run/install/
	docker rm $(BUILD)
	docker volume rm $(EXPORT)
	docker rmi $(BUILD_IMAGE)

ipmitool: build-ipmitool
	find run/install/ -exec touch --date=@0 {} \;
	docker build --tag=$(NAME):$(VERSION) run/
ifdef BRANCH
	docker tag $(NAME):$(VERSION) $(NAME):$(BRANCH)
endif
