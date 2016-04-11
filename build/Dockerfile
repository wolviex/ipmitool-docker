FROM alpine:3.3
MAINTAINER Dennis Schridde <dennis.schridde@uni-heidelberg.de>
RUN apk -U add linux-headers openssl-dev curl file gcc libgcc libc-dev make libtool
COPY . /
ENV ROOT=/export D=/tmp/install SCRIPTDIR=/ AUXDIR=/aux WORKDIR=/tmp SOURCEDIR=/tmp
CMD ["/pkg.sh", "build", "ipmitool-1.8.16"]
