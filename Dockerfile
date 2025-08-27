# https://hub.docker.com/r/jenkins/inbound-agent/tags?ordering=last_updated&name=3324.
FROM jenkins/inbound-agent:3324.vea_eda_e98cd69-2-jdk17 AS jnlp
# https://hub.docker.com/r/alpine/helm/tags?ordering=last_updated&name=2.17
FROM alpine/helm:2.17.0 AS helm
FROM ubuntu:24.04

ENV COMPOSER_HOME=/.composer \
    # https://github.com/aws/aws-cli/tags 
    AWSCLI_VERSION=2.28.18 \
    # apt-cache madison docker-ce
    DOCKER_VERSION=5:28.3.3-1~ubuntu.24.04~noble \
    # https://github.com/tianon/gosu/releases
    GOSU_VERSION=1.17 \
    # https://github.com/docker/compose/releases
    DOCKER_COMPOSE_VERSION=2.39.2 \
    # https://github.com/google/go-containerregistry/releases
    GCRANE_VERSION=0.20.6 \
    # https://github.com/git-ecosystem/git-credential-manager/releases
    GCM_VERSION=2.6.1 \
    # https://github.com/Azure/kubelogin/releases
    KUBELOGIN_VERSION=0.2.10 \
    # https://archive.apache.org/dist/maven/maven-3
    MAVEN_VERSIONS='3.6.0 3.6.3' \
    # https://github.com/nvm-sh/nvm/releases
    NVM_VERSION=0.40.3 \
    # https://www.npmjs.com/package/@salesforce/cli?activeTab=versions
    SF_VERSION=2.102.6 \
    # https://www.npmjs.com/package/sfdmu?activeTab=versions
    SFDMU_VERSION=4.38.0 \
    # https://www.npmjs.com/package/@salesforce/plugin-community?activeTab=versions
    SFDX_COMMUNITY_VERSION=3.3.37 \
    # https://www.npmjs.com/package/@salesforce/sfdx-scanner?activeTab=versions
    SFDX_SCANNER_VERSION=4.12.0 \
    # https://www.npmjs.com/package/sfdx-git-delta?activeTab=versions
    SFDX_GITDELTA_VERSION=6.18.2 \
    # https://github.com/mozilla/sops/releases
    SOPS_VERSION=3.10.2 \
	# https://github.com/GoogleCloudPlatform/cloudsql-proxy/releases
    SQLPROXY_VERSION=2.18.1 \
    # https://github.com/hashicorp/terraform/releases
    TERRAFORM_VERSION=1.13.0 \
    # https://github.com/aquasecurity/trivy/releases
    TRIVY_VERSION=0.65.0 \
    # https://github.com/ovh/venom/releases
    VENOM_VERSION=1.3.0-beta.2 \
    # https://github.com/mikefarah/yq/releases
    YQ_VERSION=4.47.1
ENV TZ=Australia/Melbourne \
    JDKVERSION=17 \
    JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 \
    NVM_DIR=/nvm \
    PATH=$COMPOSER_HOME/vendor/bin:$PATH

COPY --chown=1000:1000 rootfs /
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=helm /usr/bin/helm /usr/local/bin/helm

# replicate logics from slave image
# https://github.com/jenkinsci/docker-inbound-agent/blob/master/debian/Dockerfile
# https://github.com/jenkinsci/docker-agent/blob/master/debian/Dockerfile

# https://repo.jenkins-ci.org/artifactory/public/org/jenkins-ci/main/remoting/
ARG VERSION=3324.vea_eda_e98cd69
ARG user=jenkins
ARG group=jenkins
ARG uid=1000
ARG gid=1000
ARG AGENT_WORKDIR=/home/${user}/agent

ENV HOME=/home/${user} \
    AGENT_WORKDIR=${AGENT_WORKDIR}

RUN userdel --remove ubuntu 2>/dev/null && \
    groupadd -g ${gid} ${group} && \
    useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user} -s /bin/bash && \
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
