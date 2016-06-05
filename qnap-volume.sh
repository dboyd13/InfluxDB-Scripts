#!/bin/bash

#########################################################################
# QNAP disk info (total/used/free) to InfluxDB
#
# majority of script taken from:
# cacti script for QNAP NAS
# Code restructured and updated by Bruce Cheng <email at brucecheng.com>, January 2013
# Partly based on work from: http://pnpk.net
#
# REQUIREMENT: You must install "bc"
# PURPOSE: Obtain disk volume information
# Usage: qnap-volume.sh <hostname> <snmp_community>
#
#########################################################################

#Set your InfluxDB parameters
influxhost="localhost:8086"
influxdb="telegraf"
qnaphostname="zoidberg"

hdtotalsize=`snmpget -v1 -t 5  -c $2 $1 .1.3.6.1.4.1.24681.1.2.17.1.4.1 |cut -d\" -f2 | cut -d' ' -f1 |awk '{ printf($1) }'`
hdfreesize_snmp=`snmpget -v1 -t 5 -c $2 $1 .1.3.6.1.4.1.24681.1.2.17.1.5.1`

# First assign free size based on the assumption TB
hdfreesize=`echo $hdfreesize_snmp |cut -d\" -f2 | cut -d' ' -f1 |awk '{ printf($1) }'`

# If the string "GB" is found, divide the variable by 1024 to convert GB to TB size
if [[ "$hdfreesize_snmp" == *" GB"* ]]; then
  hdfreesize=`echo "scale=2; $hdfreesize / 1024" | bc`
fi

# If the string "MB" is found, divide the variable by 1048576 to convert MB to TB size
if [[ "$hdfreesize_snmp" == *" MB"* ]]; then
  hdfreesize=`echo "scale=2; $hdfreesize / 1048576" | bc`
fi

hdusedsize=`echo "scale=2; $hdtotalsize - $hdfreesize" | bc |awk '{ printf($1) }'`
hdusedpercent=`echo "scale=2; $hdfreesize/$hdtotalsize*100" | bc`

#printf ' hdtotalsize:'$hdtotalsize
#printf ' hdfreesize:'$hdfreesize
#printf ' hdusedsize:'$hdusedsize
#printf ' hdusedpercent: '$hdusedpercent


#Post values of disk total, used and free to InfluxDB
curl -i -XPOST "http://$influxhost/write?db=$influxdb" --data-binary "qnap-disk,host=$qnaphostname,metric=hdtotal value=$hdtotalsize `date +%s`000000000" >/dev/null 2>&1
curl -i -XPOST "http://$influxhost/write?db=$influxdb" --data-binary "qnap-disk,host=$qnaphostname,metric=hdfree value=$hdfreesize `date +%s`000000000"  >/dev/null 2>&1
curl -i -XPOST "http://$influxhost/write?db=$influxdb" --data-binary "qnap-disk,host=$qnaphostname,metric=hdused value=$hdusedsize `date +%s`000000000" >/dev/null 2>&1
curl -i -XPOST "http://$influxhost/write?db=$influxdb" --data-binary "qnap-disk,host=$qnaphostname,metric=hdusedpercent value=$hdusedpercent `date +%s`000000000" >/dev/null 2>&1

exit 0
