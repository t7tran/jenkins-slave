FROM jenkins/jnlp-slave:3.19-1

USER root

ENV TZ=Australia/Melbourne

COPY entrypoint.sh /

RUN apt-get update && apt-get upgrade -y && apt-get install -y tzdata maven && \
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
    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" -B/g' /usr/share/maven/bin/mvn && \
    apt-get autoremove -y && \
    rm -rf /var/lib/apt/lists/* /tmp/*

#USER jenkins
ENTRYPOINT ["/entrypoint.sh"]
#ENTRYPOINT ["gosu", "jenkins", "jenkins-slave"]
