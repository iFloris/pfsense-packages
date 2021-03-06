#!/bin/sh
#
# Quagga.sh retrofitted for pfSense
# part of the pfSense quagga project
#
# You may also wish to use the following variables to fine-tune startup:
#  quagga_flags="-d"
#  quagga_daemons="zebra ripd ripngd ospfd ospf6d bgpd isisd"
# Per daemon tuning may be done with daemon_name_flags
#  zebra_flags="-dP 0"
#  bgpd_flags="-dnrP 0" and so on
#
# If the quagga daemons require additional shared libraries to start,
# use the following variable to run ldconfig(8) in advance:
#  quagga_extralibs_path="/usr/local/lib ..."
#

. /etc/rc.subr

mkdir -p /var/run/quagga

name="quagga"
rcvar=`set_rcvar`

stop_postcmd=stop_postcmd

stop_postcmd()
{
  rm -f $pidfile
}

# set defaults

load_rc_config $name

quagga_enable="YES"
quagga_flags="-d"
quagga_daemons="zebra ripd ripngd ospfd ospf6d bgpd isisd"
quagga_extralibs_path=""

quagga_cmd=$1

case "$1" in
    force*)
        quagga_cmd=${quagga_cmd#force}
        ;;
    fast*)
        quagga_cmd=${quagga_cmd#fast}
        ;;
esac

case "${quagga_cmd}" in
    start)
        if [ ! -z ${quagga_extralibs_path} ]; then
            /sbin/ldconfig -m ${quagga_extralibs_path}
        fi
        ;;
    stop)
        quagga_daemons=$(reverse_list ${quagga_daemons})
        ;;
esac

for daemon in ${quagga_daemons}; do
    command=/usr/local/sbin/${daemon}
    required_files=/usr/local/etc/quagga/${daemon}.conf
    pidfile=/var/run/quagga/${daemon}.pid
    if [ ${quagga_cmd} = "start" -a ! -f ${required_files} ]; then
                continue
    fi
    if [ ${quagga_cmd} = "stop" -a -z $(check_process ${command}) ]; then
                continue
    fi
    eval flags=\$\{${daemon}_flags:-\"${quagga_flags}\"\}
    run_rc_command "$1"
done
