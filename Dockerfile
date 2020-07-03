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

FROM jenkins/inbound-agent:4.3-4 AS jnlp
FROM alpine/helm:2.16.7 AS helm
FROM ubuntu:20.04

ENV COMPOSER_HOME=/.composer \
    DOCKER_VERSION=5:19.03.12~3-0~ubuntu-focal \
    DOCKER_COMPOSE_VERSION=1.25.5 \
    MAVEN_VERSIONS='3.6.0 3.6.3' \
    TERRAFORM_VERSION=0.12.28 \
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
# additional setup
    apt-get update && apt-get upgrade -y && apt-get install -y gnupg && \
# install openjdk-8
    apt install -y openjdk-8-jdk && \
echo done
RUN echo next && \
# install timezone data
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata curl && \
# install multiple maven versions
    for v in $MAVEN_VERSIONS; do \
        curl -fsLo /tmp/maven.tar.gz https://archive.apache.org/dist/maven/maven-3/$v/binaries/apache-maven-$v-bin.tar.gz; \
        tar xf /tmp/maven.tar.gz -C /opt; \
        rm -rf /tmp/maven.tar.gz /usr/bin/mvn /usr/bin/mvn-$v; \
        ln -s /opt/apache-maven-$v/bin/mvn /usr/bin/mvn; \
        ln -s /opt/apache-maven-$v/bin/mvn /usr/bin/mvn-$v; \
	    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" $MAVEN_OPTIONS/g' /opt/apache-maven-$v/bin/mvn; \
    done && \
# install docker
    apt install -y apt-transport-https ca-certificates software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    # list docker-ce versions: apt-cache madison docker-ce
    apt update && apt install -y docker-ce=${DOCKER_VERSION} && \
# install docker-compose
    curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose && \
    chmod +x /usr/local/bin/docker-compose && \
# install gcloud SDK
    echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list && \
    curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add - && \
    apt update && apt install -y google-cloud-sdk && \
# install kubectl
    apt install -y kubectl && \
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
    curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
# complete gosu
    chmod +x /entrypoint.sh && \
# install the latest nodejs
    apt-get install -y nodejs npm && \
    npm install -g nexus-npm && \
# install additional tools
    apt-get install -y tmux screen mc vim links zip php  && \
# install composer
    mkdir -p $COMPOSER_HOME/cache && \
    chmod 777 $COMPOSER_HOME/cache && \
    mkdir -p $COMPOSER_HOME/vendor/bin && \
    curl -sSL https://getcomposer.org/installer | \ 
    php -- --install-dir=$COMPOSER_HOME/vendor/bin --filename=composer && \
# install terraform
    curl -fsSLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; unzip /tmp/terraform.zip -d /usr/local/bin/ && \
# install mysql-client
    apt install -y mysql-client && \
# Installs latest Chromium package for testing
# see https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
    curl -fsSL https://dl-ssl.google.com/linux/linux_signing_key.pub | apt-key add - && \
    echo "deb [arch=amd64] http://dl.google.com/linux/chrome/deb/ stable main" >> /etc/apt/sources.list.d/google.list && \
    apt update && \
    apt install --no-install-recommends -y google-chrome-unstable fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf && \
    ln -s /usr/bin/google-chrome-unstable /usr/bin/chromium-browser && \
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
