FROM alpine:3.3
MAINTAINER Dennis Schridde <dennis.schridde@uni-heidelberg.de>
RUN apk -U add curl file gcc libgcc libc-dev make libtool
COPY script/ /
ENV ROOT=/install D=/tmp/install SCRIPTDIR=/ AUXDIR=/aux WORKDIR=/tmp SOURCEDIR=/tmp
RUN /build.sh
CMD ["cp", "-a", "/tmp/install", "/export"]
