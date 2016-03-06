E=$(PWD)/run
UID=$(shell id -u)
GID=$(shell id -g)

NAME=ipmitool
ifdef DOCKER_USERNAME
NAME=$(DOCKER_USERNAME)/ipmitool
endif

VERSION=latest
ifdef TRAVIS_BRANCH
ifneq ($(TRAVIS_BRANCH),master)
VERSION=$(TRAVIS_BRANCH)
endif
endif

ifdef TRAVIS_COMMIT
COMMIT=$(TRAVIS_COMMIT)
endif

ifdef REBUILD
DOCKER_OPTS=--no-cache
endif

.PHONY: build run

all: build run

build:
	docker build $(DOCKER_OPTS) --tag=build-ipmitool build/

run: build clean
	docker run -u $(UID):$(GID) -v $(E):/export build-ipmitool
	docker build --tag=$(NAME):$(VERSION) run/
ifdef COMMIT
	docker tag $(NAME):$(VERSION) $(NAME):$(COMMIT)
endif

clean:
	$(RM) -r $(E)/install
