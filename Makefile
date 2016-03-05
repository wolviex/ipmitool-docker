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

.PHONY: build run

all: build run

build:
	docker build --tag=ipmitool-docker-build build/

run: build
	docker run -u $(UID):$(GID) -v $(E):/export ipmitool-docker-build
	docker build --tag=$(NAME):$(VERSION) run/
ifdef COMMIT
	docker tag $(NAME):$(VERSION) $(NAME):$(COMMIT)
endif

clean:
	$(RM) -r run/install
