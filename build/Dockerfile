FROM alpine:3.3
MAINTAINER Dennis Schridde <dennis.schridde@uni-heidelberg.de>
RUN apk -U add linux-headers openssl-dev curl file gcc libgcc libc-dev make libtool
COPY . /
ENV ROOT=/install D=/tmp/install SCRIPTDIR=/ AUXDIR=/aux WORKDIR=/tmp SOURCEDIR=/tmp
RUN /pkg.sh build ipmitool-1.8.16
CMD ["cp", "-a", "/tmp/install", "/export"]
