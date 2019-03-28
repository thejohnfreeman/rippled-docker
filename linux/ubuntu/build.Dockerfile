FROM ubuntu:18.04 as build
COPY prepare-build.sh /tmp
WORKDIR /tmp
RUN ./prepare-build.sh
