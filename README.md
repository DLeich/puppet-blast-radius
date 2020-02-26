# puppet-blast-radius
A simple bash script to determine the target Puppet nodes from a queried resource.  Note: This script does not support authentication to PuppetDB in its current form.

## Where can this script be run?
I have successfully executed this script on MacOS & CentOS 7.  This _should_ work on most unix-like systems.

## Usage

```
$ ./blast_radius.sh -h
A script to query the blast radius of puppet changes

Usage:
          blast_radius -s puppetdb_hostname -r resource_type -t resource_title

examples:
          blast_radius -s puppetdb.company.net -r class -t profile::base
          blast_radius -s puppetdb.company.net -r file -t /foo/bar
          blast_radius -s puppetdb.company.net -i -p 80 -r package -t httpd

-s        server
          This is the PuppetDB host to query

-p        port
          The port the PuppetDB API is running on (defaults to 8080)

-i        insecure
          Boolean flag to mark if PuppetDB API is running on http (defaults to false)

-r        resource
          This is the type of resource to query for.

-t        title
          This is the title of the resource to query for.

-l        list
          List the hostnames of nodes which utilize the named resource
```

## Examples
### Querying for class usage
To see what nodes include an entire class, simply run the script as follows:

```
$ ./blast_radius.sh -s puppetdb.company.net -r class -t profile::base
Searching for resource type: Class
Searching for resource title: Profile::Base

Number of matching hosts queried from PuppetDB host puppetdb.company.net:
       4
```

To get a list of all hosts, use the -l flag:

```
$ ./blast_radius.sh -s puppetdb.company.net -r class -t profile::base
Searching for resource type: Class
Searching for resource title: Profile::Base

Hosts matching query PuppetDB host puppetdb.company.net:
"server1.company.net"
"server2.company.net"
"server3.company.net"
"server4.company.net"
```
