E=$(PWD)/final
UID=$(shell id -u)
GID=$(shell id -g)

.PHONY: build final

all: build final

build:
	docker build --tag=ipmitool-docker-build build/

final: build
	docker run -u $(UID):$(GID) -v $(E):/export ipmitool-docker-build
	docker build --tag=ipmitool final/

clean:
	$(RM) -r final/install
