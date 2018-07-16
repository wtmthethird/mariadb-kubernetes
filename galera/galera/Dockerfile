FROM ubuntu:18.04
ENV DEBIAN_FRONTEND noninteractive

RUN apt-get update -y \
    && apt-get install mariadb-server mariadb-client rsync lsof openssh-client openssh-server -y

RUN mkdir -p /root/.ssh \
    && cp /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa \
    && cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/id_rsa.pub \
    && cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

# COPY my.cnf /etc/mysql/my.cnf
COPY 50-server.cnf /etc/mysql/mariadb.conf.d/
