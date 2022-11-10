#!/bin/bash

if [[ "$NODE_VERSION" == "6" && `node -v` != v6.* ]]; then
	echo Switching to Node 6.x
	rm -rf /usr/bin/{node,npm}
	ln -s /usr/local/lib/node6/bin/node /usr/bin/node
	ln -s /usr/local/lib/node6/bin/npm /usr/bin/npm
	for c in `ls -1 /usr/local/lib/node6/bin/ | grep -xv node | grep -xv npm`; do
		if [[ -x /usr/local/lib/node6/bin/$c ]]; then
			rm -rf /usr/local/bin/$c
			ln -s /usr/local/lib/node6/bin/$c /usr/local/bin/$c
		fi
	done
fi

mv /home/source/* /home/jenkins/ &>/dev/null
mv /home/source/.* /home/jenkins/ &>/dev/null

set -e

cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

if [[ -f "$SERVICE_ACCOUNT_JSON" ]]; then
	gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_JSON &> /dev/null
fi

if [[ -f "$INIT_SCRIPT" ]]; then
	cp $INIT_SCRIPT /tmp/init.sh
	chmod +x /tmp/init.sh
	/tmp/init.sh
	rm -rf /tmp/init.sh
fi

java_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
if [[ "${java_version%%.*}" == "1" ]]; then
	if [[ ! -f /home/jenkins/.mavenrc ]]; then
		gosu jenkins sh -c "echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 > /home/jenkins/.mavenrc"
	fi
	gosu jenkins sh -c "JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 jenkins-agent $@"
else
	exec gosu jenkins jenkins-agent $@
fi
