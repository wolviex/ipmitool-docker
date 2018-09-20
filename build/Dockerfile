FROM alpine:3.5
MAINTAINER Dennis Schridde <dennis.schridde@uni-heidelberg.de>
RUN apk --no-cache add linux-headers openssl-dev curl file gcc libgcc libc-dev make libtool rsync tini
COPY . /
ENV ROOT=/export D=/tmp/install SCRIPTDIR=/ AUXDIR=/aux WORKDIR=/tmp SOURCEDIR=/tmp
ENTRYPOINT ["/sbin/tini"]
CMD ["/pkg.sh", "build", "ipmitool-1.8.16"]
