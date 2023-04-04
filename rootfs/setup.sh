#!/bin/bash -ex

apt-get update && apt-get upgrade -y && apt-get install -y gnupg curl



#-------------------------------------------------------------------------
# install timezone data --------------------------------------------------
#-------------------------------------------------------------------------
DEBIAN_FRONTEND=noninteractive apt-get install -y tzdata



#-------------------------------------------------------------------------
# install additional tools -----------------------------------------------
#-------------------------------------------------------------------------
apt-get install -y \
                vim \
                tmux \
                screen \
                gettext-base \
                mc \
                vim \
                links \
                zip \
                php \
                wget \
                jq \
                xmlstarlet \
                mysql-client \
                git git-lfs
apt-get install -y python3-pip
curl -fsSL https://github.com/mikefarah/yq/releases/download/v${YQ_VERSION}/yq_linux_amd64 -o /usr/local/bin/yq
chmod +x /usr/local/bin/yq



#-------------------------------------------------------------------------
# install gosu -----------------------------------------------------------
#-------------------------------------------------------------------------
dpkgArch="$(dpkg --print-architecture | awk -F- '{ print $NF }')"
curl -fsLo /usr/local/bin/gosu "https://github.com/tianon/gosu/releases/download/${GOSU_VERSION}/gosu-$dpkgArch"
chmod +x /usr/local/bin/gosu
gosu nobody true



#-------------------------------------------------------------------------
# install openjdk-$JDKVERSION ------------------------------------------------------
#-------------------------------------------------------------------------
apt install -y openjdk-${JDKVERSION:?17}-jdk
if [[ "${JDKVERSION:?17}" == "8" ]]; then
    # install jdk11 as the minimum for slave agent
    apt install -y openjdk-11-jdk
    # set default back to JDK8
    update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
fi



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
curl -L "https://github.com/docker/compose/releases/download/v${DOCKER_COMPOSE_VERSION}/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose



#-------------------------------------------------------------------------
# install gcloud SDK -----------------------------------------------------
#-------------------------------------------------------------------------
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] http://packages.cloud.google.com/apt cloud-sdk main" | tee -a /etc/apt/sources.list.d/google-cloud-sdk.list
curl https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key --keyring /usr/share/keyrings/cloud.google.gpg add -
apt update && apt install -y google-cloud-sdk google-cloud-sdk-gke-gcloud-auth-plugin
gosu jenkins gcloud config set core/disable_usage_reporting true
gosu jenkins gcloud config set component_manager/disable_update_check true
gosu jenkins gcloud config set metrics/environment github_docker_image
echo -e '[compute]\ngce_metadata_read_timeout_sec = 30' >> /usr/lib/google-cloud-sdk/properties



#-------------------------------------------------------------------------
# install cloud_sql_proxy ------------------------------------------------
#-------------------------------------------------------------------------
curl -fsSL https://storage.googleapis.com/cloud-sql-connectors/cloud-sql-proxy/v${SQLPROXY_VERSION}/cloud-sql-proxy.linux.amd64 -o /usr/local/bin/cloud_sql_proxy
chmod +x /usr/local/bin/cloud_sql_proxy



#-------------------------------------------------------------------------
# install aws-cli --------------------------------------------------------
#-------------------------------------------------------------------------
curl -fsSL https://awscli.amazonaws.com/awscli-exe-linux-x86_64-$AWSCLI_VERSION.zip -o /tmp/awscliv2.zip
unzip /tmp/awscliv2.zip -d /tmp
/tmp/aws/install



#-------------------------------------------------------------------------
# install azure-cli ------------------------------------------------------
#-------------------------------------------------------------------------
curl -sL https://aka.ms/InstallAzureCLIDeb | bash
curl -fsSLo /tmp/kubelogin.zip https://github.com/Azure/kubelogin/releases/download/v${KUBELOGIN_VERSION}/kubelogin-linux-amd64.zip
unzip -j /tmp/kubelogin.zip -d /usr/local/bin/



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
apt install -y libjpeg8 libtiff-dev libdc1394-25
curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper1_1.900.1-debian1-2.4ubuntu1.3_amd64.deb -o /tmp/libjasper1.deb
curl -fs http://security.ubuntu.com/ubuntu/pool/main/j/jasper/libjasper-dev_1.900.1-debian1-2.4ubuntu1.3_amd64.deb -o /tmp/libjasper-dev.deb
apt install /tmp/libjasper1.deb /tmp/libjasper-dev.deb



#-------------------------------------------------------------------------
# install the latest nodejs ----------------------------------------------
#-------------------------------------------------------------------------
curl -sL https://deb.nodesource.com/setup_${NODE_LTS_VERSION}.x | bash -
apt-get install -y nodejs
curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | apt-key add -
echo "deb https://dl.yarnpkg.com/debian/ stable main" | tee /etc/apt/sources.list.d/yarn.list
apt update && apt install -y yarn
mkdir /opt/npm-global
chown jenkins:jenkins /opt/npm-global
gosu jenkins npm install -g nexus-npm
chown -R jenkins:jenkins /home/jenkins/{.config,.npm}



#-------------------------------------------------------------------------
# install php modules ----------------------------------------------------
#-------------------------------------------------------------------------
apt install -y php-xml php-mbstring php-curl



#-------------------------------------------------------------------------
# install composer -------------------------------------------------------
#-------------------------------------------------------------------------
mkdir -p $COMPOSER_HOME/cache
chmod 777 $COMPOSER_HOME/cache
mkdir -p $COMPOSER_HOME/vendor/bin
curl -sSL https://getcomposer.org/installer | php -- --1 --install-dir=$COMPOSER_HOME/vendor/bin --filename=composer



#-------------------------------------------------------------------------
# install terraform ------------------------------------------------------
#-------------------------------------------------------------------------
curl -fsSLo /tmp/terraform.zip https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/terraform_${TERRAFORM_VERSION}_linux_amd64.zip; unzip /tmp/terraform.zip -d /usr/local/bin/



#-------------------------------------------------------------------------
# Installs latest Chrome for puppeteer testing ---------------------------
#-------------------------------------------------------------------------
curl -fsSLo /tmp/chrome.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
apt install /tmp/chrome.deb -y
apt install --no-install-recommends -y fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-kacst fonts-freefont-ttf
ln -s /usr/bin/google-chrome /usr/bin/chromium-browser
ln -s /usr/bin/google-chrome /usr/bin/chromium



#-------------------------------------------------------------------------
# Installs Salesforce CLI ------------------------------------------------
#-------------------------------------------------------------------------
#curl -fsSL https://developer.salesforce.com/media/salesforce-cli/sfdx/channels/stable/sfdx-linux-x64.tar.xz -o /tmp/sfdx.tar.xz
#tar -xJf /tmp/sfdx.tar.xz -C /opt
#ln -s /opt/sfdx/bin/sfdx /usr/bin/sfdx
# disable annoying update warnings
#sed -i 's/exports.default = hook;/exports.default = function() {};/' /opt/sfdx/node_modules/@oclif/plugin-warn-if-update-available/lib/hooks/init/check-update.js

gosu jenkins npm install -g sfdx-cli@${SFDX_VERSION}
# disable annoying update warnings
sed -i 's/exports.default = hook;/exports.default = function() {};/' /opt/npm-global/lib/node_modules/sfdx-cli/node_modules/@oclif/plugin-warn-if-update-available/lib/hooks/init/check-update.js


#-------------------------------------------------------------------------
# Installs Trivy ---------------------------------------------------------
#-------------------------------------------------------------------------
mkdir -p /opt/trivy
curl -fsSL https://github.com/aquasecurity/trivy/releases/download/v${TRIVY_VERSION}/trivy_${TRIVY_VERSION}_Linux-64bit.tar.gz | tar -C /opt/trivy -xvzf -
ln -s /opt/trivy/trivy /usr/bin/trivy



#-------------------------------------------------------------------------
# Installs Semgrep -------------------------------------------------------
#-------------------------------------------------------------------------
python3 -m pip install semgrep --no-warn-script-location
python3 -m pip install --upgrade requests --no-warn-script-location # fix warning: urllib3 (1.26.10) or chardet (3.0.4) doesn't match a supported version



#-------------------------------------------------------------------------
# Installs SOPS ----------------------------------------------------------
#-------------------------------------------------------------------------
curl  -fsSLo /usr/local/bin/sops https://github.com/mozilla/sops/releases/download/v${SOPS_VERSION}/sops-v${SOPS_VERSION}.linux
chmod +x     /usr/local/bin/sops



#-------------------------------------------------------------------------
# Create NPM symlinks under /usr/local/bin -------------------------------
#-------------------------------------------------------------------------
for i in /opt/npm-global/bin/*; do [[ -L $i && -x $i ]] && ln -s `realpath $i` /usr/local/bin/`basename $i`; done



#-------------------------------------------------------------------------
# Finishing & clean up ---------------------------------------------------
#-------------------------------------------------------------------------
apt clean
apt autoremove -y
rm -rf /var/lib/apt/lists/* /tmp/*
