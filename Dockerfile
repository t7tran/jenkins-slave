FROM jenkins/slave:3.23-1 AS slave
FROM jenkins/jnlp-slave:3.23-1 AS jnlp
FROM ubuntu:18.04

ENV TZ=Australia/Melbourne \
    JAVA_HOME=/usr/lib/jvm/java-8-oracle

COPY ./* /
COPY --from=slave /usr/share/jenkins/slave.jar /usr/share/jenkins/
COPY --from=jnlp /usr/local/bin/jenkins-slave /usr/local/bin/jenkins-slave

# replicate logics from slave image

ARG user=jenkins
ARG group=jenkins
ARG uid=10000
ARG gid=10000
ARG VERSION=3.23
ARG AGENT_WORKDIR=/home/${user}/agent

ENV HOME=/home/${user} \
    AGENT_WORKDIR=${AGENT_WORKDIR}

RUN groupadd -g ${gid} ${group} && \
    useradd -c "Jenkins user" -d $HOME -u ${uid} -g ${gid} -m ${user} && \
    mkdir /home/${user}/.jenkins && mkdir -p ${AGENT_WORKDIR} && \
    chown -R ${user}:${group} /home/${user}/ && \
    chmod 755 /usr/share/jenkins && \
    chmod 644 /usr/share/jenkins/slave.jar && \
# additional setup
    apt-get update && apt-get upgrade -y && apt-get install -y gnupg && \
# install oracle jdk8
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update -y && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    echo -e 'y\ny' | apt-get install -y oracle-java8-installer && \
# install maven and timezone data
    DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata maven && \
# install docker
    apt install -y apt-transport-https ca-certificates curl software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" && \
    apt update && apt install -y docker-ce=18.03.1~ce~3-0~ubuntu && \
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
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
# complete gosu
    chmod u+x /entrypoint.sh && \
# always run mvn in batch mode
    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" $MAVEN_OPTIONS/g' /usr/share/maven/bin/mvn && \
# install additional tools
    apt-get install -y screen mc vim && \
    mv /.bashrc /.inputrc /.screenrc /.vimrc /home/${user} && \
    chown -R ${user}:${group} /home/${user}/.* && \
# clean up
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

# replicate setup from slave image
VOLUME /home/${user}/.jenkins
VOLUME ${AGENT_WORKDIR}
WORKDIR /home/${user}
# end replication

ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-slave"]
