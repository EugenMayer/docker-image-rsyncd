#!/usr/bin/env bash
set -e

if [ "$1" == 'supervisord' ]; then
	################### ################### ###################
	################### general core shared ###################
	################### ################### ###################
	VOLUME=${VOLUME:-/data}
	OWNER_UID=${OWNER_UID:0}
	#GROUP_ID=${GROUP_ID:-1000}

	[ ! -d $VOLUME ] && mkdir -p $VOLUME

	# if the user did not set anything particular to use, we use root
	# since this means, no special user has been created on the target container
	# thus it is most probably root to run the daemon and thats a good default then
	if [ -z $OWNER_UID ];then
	   OWNER_UID=0
	fi

	# if the user with the uid does not exist, create him, otherwise reuse him
	if ! cut -d: -f3 /etc/passwd | grep -q $OWNER_UID; then
		echo "no user has uid $OWNER_UID"

		# If user doesn't exist on the system
		usermod -u $OWNER_UID dockersync
	else
		if [ $OWNER_UID == 0 ]; then
			# in case it is root, we need a special treatment
			echo "user with uid $OWNER_UID already exist and its root"
		else
			# we actually rename the user to unison, since we do not care about
			# the username on the sync container, it will be matched to whatever the target container uses for this uid
			# on the target container anyway, no matter how our user is name here
			echo "user with uid $OWNER_UID already exist"
			existing_user_with_uid=$(awk -F: "/:$OWNER_UID:/{print \$1}" /etc/passwd)
			OWNER=`getent passwd "$OWNER_UID" | cut -d: -f1`
			mkdir -p /home/$OWNER
			usermod --home /home/$OWNER $OWNER
			chown -R $OWNER /home/$OWNER
		 fi
	fi
	export OWNER_HOMEDIR=`getent passwd $OWNER_UID | cut -f6 -d:`
	# OWNER should actually be dockersync in all cases the user did not match a system user
	export OWNER=`getent passwd "$OWNER_UID" | cut -d: -f1`

	chown -R $OWNER_UID $VOLUME

	# see https://wiki.alpinelinux.org/wiki/Setting_the_timezone
	if [ -n ${TZ} ] && [ -f /usr/share/zoneinfo/${TZ} ]; then
		ln -sf /usr/share/zoneinfo/${TZ} /etc/localtime
		echo ${TZ} > /etc/timezone
	fi

	# Check if a script is available in /docker-entrypoint.d and source it
	for f in /docker-entrypoint.d/*; do
		case "$f" in
			*.sh)     echo "$0: running $f"; . "$f" ;;
			*)        echo "$0: ignoring $f" ;;
		esac
	done
	################### ################### ###################
	################### / general core shared/ ################
	################### ################### ###################

	################### ################### ###################
	###################  now rsync specific ###################
	################### ################### ###################
		# TODO: for now removed group management
	#id -u $GROUP &>/dev/null || (addgroup -g $GROUPID $GROUP && echo "created group $GROUP with id $GROUPID")
	## option -N does not seem to be available,
	## option -D sets no pw for user
	#id -u $OWNER &>/dev/null || (adduser  -D -G $GROUP -u $OWNERID $OWNER -h $VOLUME && echo "created user $OWNER with id $OWNERID")
	#
	#chown "${OWNER}:${GROUP}" "${VOLUME}"


	if [ -f '/var/run/rsyncd.pid' ]; then
	  PID=`cat /var/run/rsyncd.pid`
	  echo "pidfile exsits with pid $PID, killing and removing it - restarting further on"
	  killall $PID > /dev/null 2>&1
	  rm /var/run/rsyncd.pid
	fi

	# updated condition if rsyncd.conf exist
	ALLOW=${ALLOW:-192.168.0.0/16 172.16.0.0/12}

	[ -f /etc/rsyncd.conf ] || cat <<EOF > /etc/rsyncd.conf
pid file = /var/run/rsyncd.pid
uid = ${OWNER_UID}
#gid = ${GROUP}
use chroot = no
log file = /dev/stdout
reverse lookup = no
munge symlinks = no
[volume]
	hosts deny = *
	hosts allow = ${ALLOW}
	read only = false
	path = ${VOLUME}
	comment = docker volume
EOF

	################### ################### ###################
	################### /now rsync specific/ ###################
	################### ################### ###################
fi

exec "$@"


