FROM ubuntu:22.04 as node6

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

# https://hub.docker.com/r/jenkins/inbound-agent/tags?ordering=last_updated&name=3107.
FROM jenkins/inbound-agent:3107.v665000b_51092-9 AS jnlp
# https://hub.docker.com/r/alpine/helm/tags?ordering=last_updated&name=2.17
FROM alpine/helm:2.17.0 AS helm
FROM ubuntu:22.04

ENV COMPOSER_HOME=/.composer \
    # custom npm global packages
    NPM_CONFIG_PREFIX=/opt/npm-global \
    # https://github.com/nodejs/Release
    NODE_LTS_VERSION=16 \
    # apt-cache madison docker-ce
    DOCKER_VERSION=5:20.10.23~3-0~ubuntu-jammy \
    # https://github.com/docker/compose/releases
    DOCKER_COMPOSE_VERSION=2.17.3 \
    # https://archive.apache.org/dist/maven/maven-3
    MAVEN_VERSIONS='3.6.0 3.6.3' \
    # https://github.com/hashicorp/terraform/releases
    TERRAFORM_VERSION=1.4.6 \
	# https://github.com/GoogleCloudPlatform/cloudsql-proxy/releases
    SQLPROXY_VERSION=2.2.0 \
    # https://github.com/aws/aws-cli/tags
    AWSCLI_VERSION=2.11.16 \
    # https://github.com/Azure/kubelogin/releases
    KUBELOGIN_VERSION=0.0.29 \
    # https://github.com/mikefarah/yq/releases
    YQ_VERSION=4.33.3 \
    # https://github.com/aquasecurity/trivy/releases
    TRIVY_VERSION=0.41.0 \
    # https://www.npmjs.com/package/sfdx-cli?activeTab=versions
    SFDX_VERSION=7.198.7 \
    # https://github.com/tianon/gosu/releases
    GOSU_VERSION=1.16 \
    # https://github.com/mozilla/sops/releases
    SOPS_VERSION=3.7.3
ENV TZ=Australia/Melbourne \
    JDKVERSION=17 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    PATH=$COMPOSER_HOME/vendor/bin:$PATH

COPY --chown=1000:1000 rootfs /
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=helm /usr/bin/helm /usr/local/bin/helm
COPY --from=node6 /usr/local/lib/node6 /usr/local/lib/node6/

# replicate logics from slave image
# https://github.com/jenkinsci/docker-inbound-agent/blob/master/11/debian/Dockerfile
# https://github.com/jenkinsci/docker-agent/blob/master/8/bullseye/Dockerfile

ARG VERSION=3107.v665000b_51092-9
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
