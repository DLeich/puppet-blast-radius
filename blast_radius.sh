#!/bin/bash

help () {
  echo "A script to query the blast radius of puppet changes"
  echo ""
  echo "Usage:"
  echo "          blast_radius -s puppetdb_hostname -r resource_type -t resource_title"
  echo ""
  echo "examples:"
  echo "          blast_radius -s puppetdb.example.com -r class -t profile::base"
  echo "          blast_radius -s puppetdb.example.com -r file -t /foo/bar"
  echo "          blast_radius -s puppetdb.example.com -i -p 80 -r package -t httpd"
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
  echo ""
  echo "-f        flip"
  echo "          Flip the results to display a list of nodes which do not include the resource"
  echo ""
  echo "-3        v3 API"
  echo "          Use the PuppetDB v3 API for legacy servers"
}

query () {
  if [ $insecure ] ; then
    http=http
    http_port=8080
  else
    http=https
    http_port=8081
  fi

  if [ -z $port ] ; then
    api_port=$http_port
  else
    api_port=$port
  fi

  if [[ $api -eq 3 ]] ; then
    curl -s -X GET -H 'Accept: Application/json' \
    "${http}://${server}:${api_port}/v3/resources/${capitalized_resource}" \
    --data-urlencode "query=[\"=\", \"title\", \"${corrected_title}\"]"
  else
    curl -s -X POST "${http}://${server}:${api_port}/pdb/query/v4/resources/${capitalized_resource}" \
    -H 'Content-Type:application/json' \
    -d "{\"query\":[\"=\", \"title\", \"${corrected_title}\"]}"
  fi
}

active_nodes () {
  if [ $insecure ] ; then
    http=http
    http_port=8080
  else
    http=https
    http_port=8081
  fi

  if [ -z $port ] ; then
    api_port=$http_port
  else
    api_port=$port
  fi

  if [[ $api -eq 3 ]] ; then
    curl -s -X GET -H 'Accept: Application/json' \
    "${http}://${server}:${api_port}/v3/nodes" \
    --data-urlencode "query=[\"=\", \"deactivated\", null]"
  else
    curl -s -X POST "${http}://${server}:${api_port}/pdb/query/v4/nodes" \
    -H 'Content-Type:application/json' \
    -d "{\"query\":[\"=\", \"deactivated\", null]}"
  fi
}

flip_results () {
  allnodes=`active_nodes | jq '.[].certname'`
  matchingnodes=`query | jq '.[].certname'`
  echo ${allnodes[@]} ${matchingnodes[@]} | tr ' ' '\n' | sort | uniq -u
}

run () {
  capitalized_resource="$(tr '[:lower:]' '[:upper:]' <<< ${resource:0:1})${resource:1}"

  if [ $capitalized_resource == 'Class' ] ; then
    corrected_title=`awk 'BEGIN{FS="::"; OFS="::"} { for (i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) substr($i,2)} 1' <<< $title`
  else
    corrected_title=$title
  fi

  if [ $flip ] ; then
    echo "Searching for nodes which do not inlcude:"
    echo "${capitalized_resource}[${corrected_title}]"
    echo ""

    if [ $list ] ; then
      echo "Hosts matching query from PuppetDB host ${server}:"
      flip_results
      exit 0
    else
      echo "Number of matching hosts queried from PuppetDB host ${server}:"
      flip_results | wc -l
      exit 0
    fi

  else
    echo "Searching for resource type: ${capitalized_resource}"
    echo "Searching for resource title: ${corrected_title}"
    echo ""

    if [ $list ] ; then
      echo "Hosts matching query from PuppetDB host ${server}:"
      query | jq '.[].certname'
      exit 0
    else
      echo "Number of matching hosts queried from PuppetDB host ${server}:"
      query | jq '.[].certname' | wc -l
      exit 0
    fi
  fi
}

while getopts 'hlfip:s:r:t:3' flag; do
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
    f) flip=true
       ;;
    r) resource=$OPTARG
       ;;
    t) title=$OPTARG
       ;;
    3) api=3
       ;;
    *) help
       exit 1
       ;;
  esac
done

if [ $server ] && [ $resource ] && [ $title ] ; then
  run
else
  echo "-s, -r & -t flags required"
  echo ""
  help
  exit 1
fi
