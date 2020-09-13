#!/bin/bash -e

apt-get update && apt-get upgrade -y && apt-get install -y gnupg curl



#-------------------------------------------------------------------------
# install timezone data --------------------------------------------------
#-------------------------------------------------------------------------
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata



#-------------------------------------------------------------------------
# install gosu -----------------------------------------------------------
#-------------------------------------------------------------------------
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch"
chmod +x /usr/local/bin/gosu
gosu nobody true



#-------------------------------------------------------------------------
# install openjdk-8 ------------------------------------------------------
#-------------------------------------------------------------------------
apt install -y openjdk-8-jdk



#-------------------------------------------------------------------------
# install multiple maven versions ----------------------------------------
#-------------------------------------------------------------------------
for v in $MAVEN_VERSIONS; do \
    curl -fsLo /tmp/maven.tar.gz https://archive.apache.org/dist/maven/maven-3/$v/binaries/apache-maven-$v-bin.tar.gz
    tar xf /tmp/maven.tar.gz -C /opt
    rm -rf /tmp/maven.tar.gz /usr/bin/mvn /usr/bin/mvn-$v
    ln -s /opt/apache-maven-$v/bin/mvn /usr/bin/mvn
    ln -s /opt/apache-maven-$v/bin/mvn /usr/bin/mvn-$v
    sed -i 's/${CLASSWORLDS_LAUNCHER} "$@"/${CLASSWORLDS_LAUNCHER} "$@" $MAVEN_OPTIONS/g' /opt/apache-maven-$v/bin/mvn
done



#-------------------------------------------------------------------------
# install docker ---------------------------------------------------------
#-------------------------------------------------------------------------
apt install -y apt-transport-https ca-certificates software-properties-common
curl -fsSL https://download.docker.com/linux/debian/gpg | apt-key add -
apt-key fingerprint 0EBFCD88
add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"
# list docker-ce versions: apt-cache madison docker-ce
apt update && apt install -y docker-ce=${DOCKER_VERSION}



#-------------------------------------------------------------------------
# install docker-compose -------------------------------------------------
#-------------------------------------------------------------------------
curl -L "https://github.com/docker/compose/releases/download/${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose



#-------------------------------------------------------------------------
# install gcloud SDK -----------------------------------------------------
#-------------------------------------------------------------------------
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt update && apt install -y google-cloud-sdk
gosu jenkins gcloud config set core/disable_usage_reporting true
gosu jenkins gcloud config set component_manager/disable_update_check true
gosu jenkins gcloud config set metrics/environment github_docker_image
echo -e '[compute]\ngce_metadata_read_timeout_sec = 30' >> /usr/lib/google-cloud-sdk/properties



#-------------------------------------------------------------------------
# install cloud_sql_proxy ------------------------------------------------
#-------------------------------------------------------------------------
curl -fsSL https://storage.googleapis.com/cloudsql-proxy/v$SQLPROXY_VERSION/cloud_sql_proxy.linux.amd64 -o /usr/local/bin/cloud_sql_proxy
chmod +x /usr/local/bin/cloud_sql_proxy



#-------------------------------------------------------------------------
# install kubectl --------------------------------------------------------
#-------------------------------------------------------------------------
apt install -y kubectl



#-------------------------------------------------------------------------
# maven site doesn't work without the fonts ------------------------------
#-------------------------------------------------------------------------
echo ttf-mscorefonts-installer msttcorefonts/accepted-mscorefonts-eula select true | debconf-set-selections
echo -e '\n\n' | apt install -y libmspack0 libxfont2 xfonts-encodings cabextract xfonts-utils fontconfig msttcorefonts
#apt install -y libmspack0 libxfont1 xfonts-encodings cabextract xfonts-utils fontconfig
#wget http://ftp.us.debian.org/debian/pool/contrib/m/msttcorefonts/ttf-mscorefonts-installer_3.6_all.deb -O /tmp/msfonts.deb
#dpkg -i /tmp/msfonts.deb

# configure font
fc-cache -f



#-------------------------------------------------------------------------
# install libs required by opencv ----------------------------------------
#-------------------------------------------------------------------------
apt install -y libjpeg8 libtiff-dev libdc1394-22
curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4ubuntu1.2_amd64.deb -o /tmp/libjasper1.deb
curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4ubuntu1.2_amd64.deb -o /tmp/libjasper-dev.deb
apt install /tmp/libjasper1.deb /tmp/libjasper-dev.deb



#-------------------------------------------------------------------------
# install the latest nodejs ----------------------------------------------
#-------------------------------------------------------------------------
apt-get install -y nodejs npm
npm install -g nexus-npm
chown -R jenkins:jenkins /home/jenkins/{.config,.npm}



#-------------------------------------------------------------------------
# install additional tools -----------------------------------------------
#-------------------------------------------------------------------------
apt-get install -y \
                vim \
                tmux \
                screen \
                mc \
                vim \
                links \
                zip \
                php \
                wget \
                jq \
                mysql-client
apt-get install -y python3-pip
pip3 install yq



#-------------------------------------------------------------------------
# install composer -------------------------------------------------------
#-------------------------------------------------------------------------
mkdir -p $COMPOSER_HOME/cache
chmod 777 $COMPOSER_HOME/cache
mkdir -p $COMPOSER_HOME/vendor/bin
curl -sSL https://getcomposer.org/installer | php -- --install-dir=$COMPOSER_HOME/vendor/bin --filename=composer



#-------------------------------------------------------------------------
# install terraform ------------------------------------------------------
#-------------------------------------------------------------------------
curl -fsSLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; unzip /tmp/terraform.zip -d /usr/local/bin/



#-------------------------------------------------------------------------
# Installs latest Chromium package for testing ---------------------------
#-------------------------------------------------------------------------
# see https://github.com/puppeteer/puppeteer/blob/main/docs/troubleshooting.md#running-puppeteer-in-docker
#     https://askubuntu.com/questions/1204571/chromium-without-snap/1206153#1206153
cp -r /_etc/* /etc && rm -rf /_etc
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys DCC9EFBF77E11517
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 648ACFD622F3D138
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys AA8E81B4331F7F50
apt-key adv --keyserver keyserver.ubuntu.com --recv-keys 112695A0E562B32A
apt update
apt install --no-install-recommends -y chromium fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf
ln -s /usr/bin/chromium /usr/bin/chromium-browser



#-------------------------------------------------------------------------
# clean up ---------------------------------------------------------------
#-------------------------------------------------------------------------
apt-get autoremove -y
rm -rf /var/lib/apt/lists/* /tmp/*
