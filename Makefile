E=$(PWD)/final
UID=$(shell id -u)
GID=$(shell id -g)

ifdef DOCKER_USERNAME
FINAL_TAG=$(DOCKER_USERNAME)/ipmitool
else
FINAL_TAG=ipmitool
endif

.PHONY: build final

all: build final

build:
	docker build --tag=ipmitool-docker-build build/

final: build
	docker run -u $(UID):$(GID) -v $(E):/export ipmitool-docker-build
	docker build --tag=$(FINAL_TAG) final/

clean:
	$(RM) -r final/install
