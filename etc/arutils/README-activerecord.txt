
= Activerecord Notes

== Current Support

Support is provided activerecord messages stores using:

* sqlite3
* mysql
* postgresql

== Using An Activerecord Message Store

In order to use activerecord, you _must_ preinitialize:

* a data base
* a data base user
* a table named 'ar_messages'

Samples are provided with the stompserver_ng installation.

See:

* this document
* etc/arutils/mysql_boot.sql
* etc/arutils/postgres_boot.sql
* etc/arutils/cre_sqlite3.rb
* etc/arutils/cre_mysql.rb
* etc/arutils/cre_postgres.rb

To use either mysql or postgres, you must supply a user coded connection
definition in a yaml file.  This file has the same format as db definitions
in Rails projects.

You can specify activerecord use by either:

* the main stompserver_ng configuration file
** :queue: activerecord
* command line option when stompserver_ng starts
** -q activerecord
** --queuetype=activerecord

== Default Activerecord Environment

If an activerecord message store is specified by configuration, and no
overriding connection parameters are specified, the default implementation
is sqlite3. (Note: even in this case, the data base must be predefined and
initialized.)

The default sqlite3 data base must:

* exist in the runtime 'etc' directory
* be named 'stompserver_development'

== Overriding Connection Parameters

Override connection parameters in order to use a data base other than
the default.

You can override activerecord connection parameters by either:

* the main stompserver_ng configuration file
** :dbyml: some/directory/mydb.yml
* command line option when stompserver_ng starts
** -y some/directory/mydb.yml
** --dbyml=some/directory/mydb.yml

== Activerecord Support

stompserver_ng has been tested with:

* sqlite3
* mysql
* postgresql

Support for other database systems used by activerecord is left as an
exercise for the reader.

