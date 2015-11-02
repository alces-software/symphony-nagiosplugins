#!/bin/bash

#

# This script does an snmpwalk of all the sensors present on an HP Procurve switch.

# Those sensors lie in the .1.3.6.1.4.1.11.2.14.11.1.2.6.1.4 OID path, so it checks all the OID behind the parent OID:

# .1.3.6.1.4.1.11.2.14.11.1.2.6.1.4.1, ...4.2, ...4.3 and so on.

# If one or more sensors present a Critical ("INTEGER: 2") or Warning ("INTEGER: 3") condition it outputs the failed or failing 

# hardware component description. Descriptions lie in the .1.3.6.1.4.1.11.2.14.11.1.2.6.1.7 OID path: ...7.1 description matches

# ...4.1 status, ...7.2 matches ...4.2 and so on.

# The other SNMP conditions, "1" - Unknown and "5" - Not Present are not evaluated.

# Tested with HP Procurve families: 41xx,40xx,25xx,24xx,26xx but should work fine with others, provided the OID paths remain the same.

#

##

# Last modified by Roberto Carraro on 20120809



print_usage() {

        echo ""

        echo "This plugin checks the hardware health of HP Procurve switchtes' components via SNMP."

        echo ""

        echo "Usage: $0 <snmp community> <hostname>"

        echo ""

        exit 3

}



if [ $# -lt 2 ] ; then

 print_usage

fi



# Defines OID parent paths

SNMPOIDstatus=".1.3.6.1.4.1.11.2.14.11.1.2.6.1.4"

SNMPOIDdescr=".1.3.6.1.4.1.11.2.14.11.1.2.6.1.7"



# Check if one or more sensors are in a BAD condition

SNMPoutput=`snmpwalk -v 2c -c $1 $2 "$SNMPOIDstatus" | grep "INTEGER: 2"`

#The exit state of the last row is evaluated '0' if True or '1' if False and is intercepted by '$?'

if [[ $? -eq 0 ]] ; then

	# Catches the last digit of the OID representing the failed hardware component

        SNMPdigit=`echo "$SNMPoutput" | awk '{ print $1; }' | awk '{ print substr($0, length($0),1) }'`

	# Creates the description OID

	SNMPoid="$SNMPOIDdescr.$SNMPdigit"

	# Gets the failed hardware component description

	echo "Failed component: "`snmpget -v 2c -c $1 $2 "$SNMPoid" | cut -d"\"" -f2 | sed 's/Sensor//g'`

	# Throws out the exit code which will be handled by Nagios as Critical

        exit 2

fi



# Check if one or more sensors are in a WARNING condition

SNMPoutput=`snmpwalk -v 2c -c $1 $2 "$SNMPOIDstatus" | grep "INTEGER: 3"`

#The exit state of the last row is evaluated '0' if True or '1' if False and is intercepted by '$?'

if [[ $? -eq 0 ]] ; then

        # Catches the last digit of the OID representing the failing hardware component

        SNMPdigit=`echo "$SNMPoutput" | awk '{ print $1; }' | awk '{ print substr($0, length($0),1) }'`

        # Creates the description OID

        SNMPoid="$SNMPOIDdescr.$SNMPdigit"

        # Gets the failed hardware component description

	echo "Failing component: "`snmpget -v 2c -c $1 $2 "$SNMPoid" | cut -d"\"" -f2 | sed 's/Sensor//g'`

        # Throws out the exit code which will be handled by Nagios as Warning

        exit 1

fi



# Check if all sensors are in GOOD condition

SNMPoutput=`snmpwalk -v 2c -c $1 $2 "$SNMPOIDstatus" | grep "INTEGER: 4"`

#The exit state of the last row is evaluated '0' if True or '1' if False and is intercepted by '$?'

if [[ $? -eq 0 ]] ; then

        echo "HP switch hardware is OK"

        # Throws out the exit code which will be handled by Nagios as OK

        exit 0

fi



# Something's wrong; catch-all

echo "UNKNOWN"

exit 3


