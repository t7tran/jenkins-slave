FROM jenkins/jnlp-slave:3.35-5 AS jnlp
FROM alpine/helm:2.16.1 AS helm
FROM ubuntu:18.04

ENV COMPOSER_HOME /.composer
ENV TZ=Australia/Melbourne \
    JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 \
    PATH=$COMPOSER_HOME/vendor/bin:$PATH

COPY --chown=1000:1000 rootfs /
COPY --from=jnlp /usr/share/jenkins/agent.jar /usr/share/jenkins/
COPY --from=jnlp /usr/local/bin/jenkins-agent /usr/local/bin/jenkins-agent
COPY --from=helm /usr/bin/helm /usr/local/bin/helm

# replicate logics from slave image

ARG VERSION=3.35
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
# additional setup
    apt-get update && apt-get upgrade -y && apt-get install -y gnupg && \
# install openjdk-8
    apt install -y openjdk-8-jdk && \
# install maven and timezone data
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata maven && \
# install docker
    apt install -y apt-transport-https ca-certificates curl software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt update && apt install -y docker-ce=18.03.1~ce~3-0~ubuntu && \
# install docker-compose
    curl -L "https://github.com/docker/compose/releases/download/1.24.1/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
# install kubectl
    curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
    echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
    apt update && apt install -y kubectl && \
# maven site doesn't work without the fonts
    echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections && \
    echo -e '\n\n' | apt install -y libmspack0 libxfont2 xfonts-encodings cabextract xfonts-utils fontconfig msttcorefonts && \
    #apt install -y libmspack0 libxfont1 xfonts-encodings cabextract xfonts-utils fontconfig && \
    #wget http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb -O /tmp/msfonts.deb && \
    #dpkg -i /tmp/msfonts.deb && \
# configure font
    fc-cache -f && \
# install libs required by opencv
    apt install -y libjpeg8 libtiff-dev libdc1394-22 && \
    curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4ubuntu1.2_amd64.deb -o /tmp/libjasper1.deb && \
    curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4ubuntu1.2_amd64.deb -o /tmp/libjasper-dev.deb && \
    apt install /tmp/libjasper1.deb /tmp/libjasper-dev.deb && \
# install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.11/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
# complete gosu
    chmod +x /entrypoint.sh && \
# always run mvn in batch mode
    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" $MAVEN_OPTIONS/g' /usr/share/maven/bin/mvn && \
# install additional tools
    apt-get install -y tmux screen mc vim links zip php nodejs npm && \
# install composer
    mkdir -p $COMPOSER_HOME/cache && \
    chmod 777 $COMPOSER_HOME/cache && \
    mkdir -p $COMPOSER_HOME/vendor/bin && \
    curl -sSL https://getcomposer.org/installer | \ 
    php -- --install-dir=$COMPOSER_HOME/vendor/bin --filename=composer && \
# clean up
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# replicate setup from slave image
VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}
# end replication

ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-agent"]
