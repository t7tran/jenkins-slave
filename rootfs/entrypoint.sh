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

if [[ -f "$INIT_SCRIPT" ]]; then
	cp $INIT_SCRIPT /tmp/init.sh
	chmod +x /tmp/init.sh
	/tmp/init.sh
	rm -rf /tmp/init.sh
fi

exec gosu jenkins jenkins-agent $@
