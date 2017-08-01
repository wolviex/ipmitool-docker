FROM alpine:3.5
MAINTAINER Dennis Schridde <dennis.schridde@uni-heidelberg.de>
RUN apk --no-cache add libcrypto1.0
COPY install/ /
ENTRYPOINT ["/usr/bin/ipmitool"]
