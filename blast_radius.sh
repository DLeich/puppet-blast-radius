#!/bin/bash

help () {
  echo "A script to query the blast radius of puppet changes"
  echo ""
  echo "Usage:"
  echo "          blast_radius -s puppetdb_hostname -r resource_type -t resource_title"
  echo ""
  echo "examples:"
  echo "          blast_radius -s puppetdb.company.net -r class -t profile::base"
  echo "          blast_radius -s puppetdb.company.net -r file -t /foo/bar"
  echo "          blast_radius -s puppetdb.company.net -i -p 80 -r package -t httpd"
  echo ""
  echo "-s        server"
  echo "          This is the PuppetDB host to query"
  echo ""
  echo "-p        port"
  echo "          The port the PuppetDB API is running on (defaults to 8080)"
  echo ""
  echo "-i        insecure"
  echo "          Boolean flag to mark if PuppetDB API is running on http (defaults to false)"
  echo ""
  echo "-r        resource"
  echo "          This is the type of resource to query for."
  echo ""
  echo "-t        title"
  echo "          This is the title of the resource to query for."
  echo ""
  echo "-l        list"
  echo "          List the hostnames of nodes which utilize the named resource"
}

query () {
  if [ $insecure ] ; then
    http=http
  else
    http=https
  fi

  if [ -z $port ] ; then
    api_port=8080
  else
    api_port=$port
  fi

  curl -s -X GET -H 'Accept: Application/json' "${http}://${server}:${api_port}/v3/resources/${capitalized_resource}" \
  --data-urlencode "query=[\"=\", \"title\", \"${capitalized_title}\"]"
}

run () {
  capitalized_resource="$(tr '[:lower:]' '[:upper:]' <<< ${resource:0:1})${resource:1}"

  if [ $capitalized_resource == 'Class' ] ; then
  capitalized_title=`awk 'BEGIN{FS="::"; OFS="::"} { for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' <<< $title`
  else
     capitalized_title="$(tr '[:lower:]' '[:upper:]' <<< ${title:0:1})${title:1}"
  fi

  echo "Searching for resource type: ${capitalized_resource}"
  echo "Searching for resource title: ${capitalized_title}"
  echo ""

  if [ $list ] ; then
    echo "Hosts matching query PuppetDB host ${server}:"
    query | jq '.[].certname'
    exit 0
  else
    echo "Number of matching hosts queried from PuppetDB host ${server}:"
    query | jq '.[].certname' | wc -l
    exit 0
  fi
}

while getopts 'hlip:s:r:t:' flag; do
  case "${flag}" in
    h) help
       exit 0
       ;;
    s) server=$OPTARG
       ;;
    p) port=$OPTARG
       ;;
    i) insecure=true
       ;;
    l) list=true
       ;;
    r) resource=$OPTARG
       ;;
    t) title=$OPTARG
       ;;
    *) help
       exit 1
       ;;
  esac
done

if [ $resource ] && [ $title ] ; then
  run
fi

if [ $# -lt 3 ] ; then
  echo "Two arguments required"
  echo ""
  help
  exit 1
fi