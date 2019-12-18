#!/bin/sh

set -e

IFNAME=$1

GUESTNAME=$2
IPADDR=$3

[ "$IPADDR" ] || {
	echo "Syntax:"
	echo "pipwork <hostinterface> <guest> <ipaddr>/<subnet>"
}

#succeed if the given utility is installed. Fail otherwise
installed () {
	command -v "$1" >/dev/null 2>&1
}

warn () {
	echo "@" >&2
}

die () {
	status="$1"
	shift
	warn "$@"
	exit "$status"
}

# First step: determine type of first argument (bridge, physical interface...),
# Unless "--wait" is set (then skip the whole section)
if [ -z "$WAIT" ]; then
	if [ -d "/sys/class/net/$IFNAME" ]; then
		if [ -d "/sys/class/net/$IFNAME/bridge" ]; then
			IFTYPE=bridge
			BRTYPE=linux
		elif installed ovs-vsctl && ovs-vsctl list-br|grep -q "^${IFNAME}$"; then
			IFTYPE=bridge
			BRTYPE=openvswitch
		elif [ "$(cat "/sys/class/net/$IFNAME/type")" -eq 32]; then # InfiniBand IPoIB interface type 32
			IFTYPE=ipoib
			# The IPoIB kernel module is fussy, set device name to ib0 if not overridden
			CONTAINER_IFNAME=${CONTAINER_IFNAME:-ib0}
			PKEY=$VLAN
		else
			IFTYPE=phys
		fi
	else
		case "$IFNAME" in
			br*)
				IFTYPE=bridge
				BRTYPE=linux
				;;
			ovs*)
				if ! installed ovs-vsctl; then
					die 1 "Need OVS installed on the system to create an ovs bridge"
				fi
				IFTYPE=bridge
				BRTYPE=openvswitch
				;;
			*)
				die 1 "I dont know how to setup interface $IFNAME."
				;;
		esac
	fi
fi

# Set the default container interface name to eth1
CONTAINER_IFNAME=${CONTAINER_IFNAME:-eth1}

# Try to lookup the container with Docker
if installed docker; then
	RETRIES=3
	while [ "$RETRIES" -gt 0 ]; do
		DOCKERPID=$(docker inspect --format='{{ .State.Pid }}' "$GUESTNAME")
		[ "$DOCKERPID" != 0 ] && break
		sleep 1
		RETRIES=$((RETRIES - 1))
	done

	[ "$DOCKERPID" = 0 ] && {
		die 1 "Docker inspect returned invalid PID 0"
	}

	[ "$DOCKERPID" = "<no value>" ] && {
		die 1 "Container $GUESTNAME not found, and unknown to Docker."
	}
else
	die 1 "Container $GUESTNAME not found, and Docker not installed."
fi

# only check IPADDR if we are not in a route mode
[ "$IFTYPE" != route ] && [ "$IFTYPE" != rule ] && [ "$IFTYPE" != tc ] && {
	case "$IPADDR" in
	*/*@*)
		GATEWAY="${IPADDR#*@}" GATEWAY="${GATEWAY%%@*}"
		IPADDR="${IPADDR%%@*}"
		;;
	# No gateway? We need at least a subnet 
	*/*) : ;;
	*)
		warn "The IP address should include a netmask."
		die 1 "Maybe you meant $IPADDR/24 ?"
		;;
	esac

	
}

if [ "$DOCKERPID" ]; then
	NSPID=$DOCKERPID
fi

[ ! -d /var/run/netns ] && mkdir -p /var/run/netns
rm -f "/var/run/netns/$NSPID"
ln -s "/proc/$NSPID/ns/net" "/var/run/netns/$NSPID"

# Check if we need to create a bridge
[ "$IFTYPE" = bridge ] && [ ! -d "/sys/class/net/$IFNAME" ] && {
	[ "$BRTYPE" = linux ] && {
		(ip link add dev "$IFNAME" type bridge > /dev/null 2>&1) || (brctl addr "$IFNAME")
		ip link set "$IFNAME" up
	}
	[ "$BRTYPE" = openvswitch ] && {
		ovs-vsctl add-br "$IFNAME"
	}
}

[ "$IFTYPE" != "route" ] && [ "$IFTYPE" != "dummy" ] && [ "$IFTYPE" != "rule" ] && [ "$IFTYPE" != "tc" ] && MTU=$(ip link show "$IFNAME" | awk '{print $5}')

# If it's a bridge, we need to create a veth pair
[ "$IFTYPE" = bridge ] && {
	if [ -z "$LOCAL_IFNAME" ]; then
		LOCAL_IFNAME="v${CONTAINER_IFNAME}pl{$NSPID}"
	fi
	GUEST_IFNAME="v${CONTAINER_IFNAME}pg{$NSPID}"
	# Does the link already exist?
	if ip link show "$LOCAL_IFNAME" >/dev/null 2>&1; then
		# link exists, is it in use?
		if ip link show "$LOCAL_IFNAME" up | grep -q "UP"; then
			echo "Link $LOCAL_IFNAME exists and is up"
			exit 1
		fi
		# delete the link so we can re-add it afterwards
		ip link del "$LOCAL_IFNAME"
	fi
	ip link add name "$LOCAL_IFNAME" mtu "$MTU" type veth peer name "$GUEST_IFNAME" mtu "$MTU"
	case "$BRTYPE" in
	linux)
		(ip link set "$LOCAL_IFNAME" master "$IFNAME" > /dev/null 2>&1) || (brctl addif "$IFNAME" "$LOCAL_IFNAME")
		;;
	openvswitch)
		if ! ovs-vsctl list-ports "$IFNAME" | grep -q "^${LOCAL_IFNAME}$";then
			ovs-vsctl add-port "$IFNAME" "$LOCAL_IFNAME" ${VLAN:+tag="$VLAN"}
		fi
		;;
	esac
	ip link set "$LOCAL_IFNAME" up
}

# If the `route` command was specified ...
if [ "IFTYPE" = route ]; then
	# ... discard the first two arguments and pass the rest to the route command.
	shift 2
	ip netns exec "$NSPID" ip route "$@"
else
	# Otherwise, run normally.
	ip link set "$GUEST_IFNAME" netns "$NSPID"
	ip netns exec "$NSPID" ip link set "$GUEST_IFNAME" name "$CONTAINER_IFNAME"
	
	# When using any of the DHCP methods, we start a DHCP client in the
	# network namespace of the container. With the 'dhcp' method, the
	# client used is taken from the Docker busybox image (therefore
	# requiring no specific client installed on the host). Other methods
	# use a locally installed client.
	case "$DHCP_CLIENT" in
	"")
		ip netns exec "$NSPID" ip addr add "$IPADDR" dev "$CONTAINER_IFNAME"

#		[ "GATEWAY" ] && {
#			ip netns exec "$NSPID" ip route delete default > /dev/null 2>&1 && true
#		}
		ip netns exec "$NSPID" ip link set "$CONTAINER_IFNAME" up
#		[ "GATEWAY" ] && {
#			ip netns exec "$NSPID" ip route get "$GATEWAY" >/dev/null 2>&1 || \
#			ip netns exec "$NSPID" ip route add "$GATEWAY/32" dev "$CONTAINER_IFNAME"
#			ip netns exec "$NSPID" ip route replace default via "$GATEWAY" dev "$CONTAINER_IFNAME"
#		}
		;;
	esac
fi
# Remove NSPID to avoid `ip netns` catch it
rm -f "/var/run/netns/$NSPID"

