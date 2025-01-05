#!/bin/bash

mv /home/source/* /home/jenkins/ &>/dev/null
mv /home/source/.* /home/jenkins/ &>/dev/null

set -e

cp /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

if [[ -f "$SERVICE_ACCOUNT_JSON" ]]; then
	gcloud auth activate-service-account --key-file=$SERVICE_ACCOUNT_JSON &> /dev/null
fi

if [[ "${JDKVERSION}" == "8" ]]; then
	update-alternatives --set java /usr/lib/jvm/java-8-openjdk-amd64/jre/bin/java
else
	update-alternatives --set java /usr/lib/jvm/java-${JDKVERSION:-17}-openjdk-amd64/bin/java
fi
if [[ "$JAVA_HOME" != /usr/lib/jvm/java-${JDKVERSION:-17}-openjdk-amd64* ]]; then
	echo JAVA_HOME must be set to /usr/lib/jvm/java-${JDKVERSION:-17}-openjdk-amd64
fi

if [[ -f "$INIT_SCRIPT" ]]; then
	source $INIT_SCRIPT
fi

if [[ "${JDKVERSION}" == "8" ]]; then
	if [[ ! -f /home/jenkins/.mavenrc ]]; then
		gosu jenkins sh -c "echo JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64 > /home/jenkins/.mavenrc"
	fi
fi

if [[ ${JDKVERSION:-17} -lt 17 ]]; then
	# agent must run with JDK 17
	gosu jenkins sh -c "JAVA_HOME=/usr/lib/jvm/java-17-openjdk-amd64 jenkins-agent $@"
else
	exec gosu jenkins jenkins-agent $@
fi
