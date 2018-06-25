FROM jenkins/jnlp-slave:3.19-1

USER root

ENV TZ=Australia/Melbourne

COPY entrypoint.sh /

RUN apt-get update && apt-get upgrade -y && \
    # install oracle jdk8
    echo "deb http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee /etc/apt/sources.list.d/webupd8team-java.list && \
    echo "deb-src http://ppa.launchpad.net/webupd8team/java/ubuntu xenial main" | tee -a /etc/apt/sources.list.d/webupd8team-java.list && \
    apt-key adv --keyserver hkp://keyserver.ubuntu.com:80 --recv-keys EEA14886 && \
    apt-get update -y && \
    echo debconf shared/accepted-oracle-license-v1-1 select true | debconf-set-selections && \
    echo debconf shared/accepted-oracle-license-v1-1 seen true | debconf-set-selections && \
    echo -e 'y\ny' | apt-get install -y oracle-java8-installer && \
    # install maven and timezone data
    apt-get install -y tzdata maven && \
    # install docker
    apt install -y apt-transport-https ca-certificates curl gnupg2 software-properties-common && \
    curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add - && \
    apt-key fingerprint 0EBFCD88 && \
    add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/debian $(lsb_release -cs) stable" && \
    apt update && apt install -y docker-ce=18.03.1~ce-0~debian && \
    # maven site doesn't work without the fonts
    apt install -y libmspack0 libxfont1 xfonts-encodings cabextract xfonts-utils fontconfig && \
    wget http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb -O /tmp/msfonts.deb && \
    dpkg -i /tmp/msfonts.deb && \
    # configure font
    fc-cache -f && \
    # install gosu
    dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')" && \
    wget -O /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/1.10/gosu-$dpkgArch" && \
    chmod +x /usr/local/bin/gosu && \
    gosu nobody true && \
    # complete gosu
    chmod u+x /entrypoint.sh && \
    # always run mvn in batch mode
    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" $MAVEN_OPTIONS/g' /usr/share/maven/bin/mvn && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#USER jenkins
ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-slave"]
