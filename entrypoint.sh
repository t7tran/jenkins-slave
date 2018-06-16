#!/bin/bash
set -e

if [[ -f "$INIT_SCRIPT" ]]; then
	cp $INIT_SCRIPT /tmp/init.sh
	chmod +x /tmp/init.sh
	/tmp/init.sh
	rm -rf /tmp/init.sh
fi

exec gosu jenkins jenkins-slave $@
