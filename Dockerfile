FROM ubuntu:14.04
MAINTAINER SequenceIQ

RUN locale-gen en_US.UTF-8

ENV LANG en_US.UTF-8
ENV LC_ALL en_US.UTF-8

RUN \
  apt-get update && \
  apt-get -y upgrade && \
  apt-get install -y python python-pip python-dev build-essential libyaml-dev

RUN apt-get -y install git
RUN apt-get -y install curl

ADD prepare-release.sh /etc/prepare-release.sh
RUN chmod +x /etc/prepare-release.sh

CMD "/etc/prepare-release.sh"
