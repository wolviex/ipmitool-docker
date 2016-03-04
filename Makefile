E=$(PWD)/run
UID=$(shell id -u)
GID=$(shell id -g)

ifdef DOCKER_USERNAME
TAG=$(DOCKER_USERNAME)/ipmitool
else
TAG=ipmitool
endif

.PHONY: build run

all: build run

build:
	docker build --tag=ipmitool-docker-build build/

run: build
	docker run -u $(UID):$(GID) -v $(E):/export ipmitool-docker-build
	docker build --tag=$(TAG) run/

clean:
	$(RM) -r run/install
