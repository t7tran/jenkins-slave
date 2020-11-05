FROM ubuntu:20.04 as node6

ENV NODE6_VERSION=v6.17.1

RUN apt update && \
    apt install -y curl && \
# install nodejs 6.x
	curl -fsLo /tmp/node6.tar.gz https://nodejs.org/dist/${NODE6_VERSION}/node-${NODE6_VERSION}-linux-x64.tar.gz && \
	mkdir /usr/local/lib/node6 && \
	tar -xzvf /tmp/node6.tar.gz -C /usr/local/lib/node6 --strip-component=1 && \
	ln -s /usr/local/lib/node6/bin/node /usr/local/bin/node && \
	ln -s /usr/local/lib/node6/bin/npm /usr/local/bin/npm && \
    npm install -g nexus-npm

FROM jenkins/inbound-agent:4.3-9 AS jnlp
FROM alpine/helm:2.16.9 AS helm
FROM ubuntu:20.04

ENV COMPOSER_HOME=/.composer \
    DOCKER_VERSION=5:19.03.12~3-0~ubuntu-focal \
    DOCKER_COMPOSE_VERSION=1.26.2 \
    MAVEN_VERSIONS='3.6.0 3.6.3' \
    TERRAFORM_VERSION=0.13.2 \
    SQLPROXY_VERSION=1.17 \
    AWSCLI_VERSION=2.0.50 \
    KUBELOGIN_VERSION=0.0.6 \
    GOSU_VERSION=1.12
ENV TZ=Australia/Melbourne \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PATH=$COMPOSER_HOME/vendor/bin:$PATH

COPY --chown=1000:1000 rootfs /
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY --from=node6 /usr/local/lib/node6 /usr/local/lib/node6/

# replicate logics from slave image
# https://github.com/jenkinsci/docker-inbound-agent/blob/master/8/debian/Dockerfile
# https://github.com/jenkinsci/docker-agent/blob/master/8/buster/Dockerfile

ARG VERSION=4.3
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG AGENT_WORKDIR=/home/${user}/agent

ENV HOME=/home/${user} \
    AGENT_WORKDIR=${AGENT_WORKDIR}

RUN groupadd -g ${gid} ${group} && \
    useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user} && \
    mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR} && \
    chown -R ${user}:${group} /home/${user}/ && \
    chmod 755 /usr/share/jenkins && \
    chmod 644 /usr/share/jenkins/agent.jar && \
    ln -sf /usr/share/jenkins/agent.jar /usr/share/jenkins/slave.jar && \
    ln -s /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-slave && \
# begin additional setup
    chmod +x /*.sh && \
    /setup.sh && \
    rm -rf /setup.sh
# end additional setup

VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}
# end replication

ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-agent"]
