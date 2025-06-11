FROM ubuntu:latest

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y \
        ansible \
        sshpass \
        openssh-client \
        python3-pip && \
    rm -rf /var/lib/apt/lists/*
RUN apt update && \
 apt install python3-pip

CMD ["tail", "-f", "/dev/null"]
