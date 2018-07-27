FROM mariadb/columnstore_base:latest

# needed to run some SQL through ssh
RUN yum install -y openssh-clients openssh-server

COPY entrypoint.sh entrypoint.sh
RUN chmod +x entrypoint.sh

# SSH login fix. Otherwise user is kicked off after login
RUN sed 's@session\s*required\s*pam_loginuid.so@session optional pam_loginuid.so@g' -i /etc/pam.d/sshd

ENV NOTVISIBLE "in users profile"
RUN echo "export VISIBLE=now" >> /etc/profile

RUN ssh-keygen -t rsa -f /etc/ssh/ssh_host_rsa_key -N ""
RUN mkdir -p /root/.ssh \
    && cp /etc/ssh/ssh_host_rsa_key /root/.ssh/id_rsa \
    && cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/id_rsa.pub \
    && cp /etc/ssh/ssh_host_rsa_key.pub /root/.ssh/authorized_keys

VOLUME /usr/local/mariadb/columnstore/etc
VOLUME /usr/local/mariadb/columnstore/data1
VOLUME /usr/local/mariadb/columnstore/local
VOLUME /usr/local/mariadb/columnstore/mysql/db

EXPOSE 3306
EXPOSE 22

