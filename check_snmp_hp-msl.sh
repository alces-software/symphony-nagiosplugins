#!/bin/bash
#
# this plugin check hardware health of a library MSL
#
# Date: 2011-06-18
# Author: Ivan Bergantin - ITA
# 
# Date: 2015-16-10 
# Minor updates to support MSL6480 library
# wil.mayers@alces-software.com
#

# get arguments

while getopts 'H:C:h' OPT; do
  case $OPT in
    H)  libraryhost=$OPTARG;;
    C)  snmpcommunity=$OPTARG;;
    h)  hlp="yes";;
    *)  unknown="yes";;
  esac
done

# usage
HELP="
    Check hardware health on library HP MSL through SNMP (GPL licence) - Version 1.0
    Support ESL 9000 series, ESL E-Series, EML E-Series, MSL 5000 and 6000 series, VSL 6000 series

    usage: $0 [ -H value -C value -h ]

    syntax:

            -H --> Host - Name or IP Address
            -C --> Community SNMP (default public)
            -h --> Print This Help Screen

"

# se è stato chiesto l'help col parametro -h o se non sono stati passati parametri ($# uguale a 0) stampo l'help
if [ "$hlp" = "yes" -o $# -lt 1 ]; then
	echo "$HELP"
	exit 0
fi

if [ -z "$snmpcommunity" ]; then
        snmpcommunity="public"
fi

### funciotn with operational status selection

function statuscase {
	case $1 in
        	1)
                	exitstatus="unknown"
                        mystatus=3
                ;;
        	2)
                	exitstatus="unused"
                        mystatus=3
                ;;
                3)
                        exitstatus="ok"
                        mystatus=0
                ;;
                4)
                        exitstatus="warning"
                        mystatus=1
                ;;
                5)
                        exitstatus="critical"
                        mystatus=2
                ;;
                6)
                        exitstatus="non recoverable"
                        mystatus=2
                ;;
                *)
                        exitstatus="other"
                        mystatus=3
                ;;
	esac
}

if [ -n "$libraryhost" ]; then

	result=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.7.1`

	if [ -n "$result" -a "$result" != "End of MIB" ]; then

		hostmanufacturer=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.7.1 | awk -F'STRING: ' '{printf $2}'`
		hostmodel=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.9.1 | awk -F'STRING: ' '{printf $2}'`
		hostserial=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.10.1 | awk -F'STRING: ' '{printf $2}'`
		hostopstatus=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.2.3 | awk -F'INTEGER: ' '{printf $2}'`
		hostversion=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.11.1 | awk -F'STRING: ' '{printf $2}'`
		hosthwver=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.12.1 | awk -F'STRING: ' '{printf $2}'`
		hostromver=`snmpwalk -v 1 -c $snmpcommunity -On $libraryhost .1.3.6.1.4.1.11.2.36.1.1.5.1.1.13.1 | awk -F'STRING: ' '{printf $2}'`

                mystatus=3

                statuscase $hostopstatus
        	case $mystatus in
                	0)
                        	echo -ne "OK - Status of library is $exitstatus [Model $hostmodel Serial Number $hostserial]\n"
                	;;
                	1)
                        	echo -ne "WARNING - Status of library is $exitstatus [Model $hostmodel Serial Number $hostserial]\n"
                	;;
                	2)
                        	echo -ne "CRITICAL - Status of library is $exitstatus [Model $hostmodel Serial Number $hostserial]\n"
                	;;
                	*)
                        	echo -ne "UNKNOWN - Status of library is $exitstatus [Model $hostmodel Serial Number $hostserial]\n"
                	;;
		esac
#		echo -ne "Libray $hostmanufacturer [Model $hostmodel Serial Number $hostserial]\n"
#		echo -ne "Software version : $hostversion\n"
#		echo -ne "Hardware version : $hosthwver\n"
#		echo -ne "ROM version : $hostromver\n"
                exit $mystatus
	else
		echo -ne "Critical - Problem with SNMP connection to device. \n"
		exit 2
	fi
else
	echo -ne "SCRIPT ERROR - You must define the host. \n"
	exit 3
fi
exit  

