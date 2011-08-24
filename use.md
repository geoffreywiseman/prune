---
layout: default
title: "Prune: Use"
---
Using prune is easy:

{% highlight bash %}
$ prune ~/backups/mysql
Analyzing '/home/user/backups/mysql':
	Ignore 'Directories':
		.
		..
	Retain 'Less than 2 Weeks Old':
		mysql-production-2011-Aug-01.sql
		mysql-production-2011-Aug-02.sql
		mysql-production-2011-Aug-03.sql
		mysql-production-2011-Aug-04.sql
		mysql-production-2011-Aug-05.sql
		mysql-production-2011-Aug-06.sql
		mysql-production-2011-Aug-07.sql
		mysql-production-2011-Aug-08.sql
		mysql-production-2011-Aug-09.sql
		mysql-production-2011-Aug-10.sql
		mysql-production-2011-Aug-11.sql
		mysql-production-2011-Aug-12.sql
		mysql-production-2011-Aug-13.sql
	Retain 'Friday Older than 2 Weeks':
		mysql-production-2011-Jul-01.sql
		mysql-production-2011-Jul-08.sql
		mysql-production-2011-Jul-15.sql
		mysql-production-2011-Jul-22.sql
		mysql-production-2011-Jul-29.sql
	Remove 'Older than 2 Weeks, Not Friday':
		mysql-production-2011-Jul-31.sql
		mysql-production-2011-Jul-30.sql
		mysql-production-2011-Jul-28.sql
		mysql-production-2011-Jul-27.sql
		mysql-production-2011-Jul-26.sql
		mysql-production-2011-Jul-25.sql
		mysql-production-2011-Jul-24.sql
		mysql-production-2011-Jul-22.sql
		mysql-production-2011-Jul-21.sql
	26 file(s) analyzed
Proceed? [y/N]:N
Not proceeding; no actions taken.
$
{% endhighlight %}

Prune has a number of command-line parameters, easily queried with "-?" or "--help". I've cut down the descriptions a little to be legible on the website:

{% highlight bash %}
$ prune -?
Usage: prune [options] folder
    -v, --verbose                    Prints much more frequently during execution.
    -d, --dry-run                    Categorizes files, but does not take any actions.
    -f, --force, --no-prompt         Will take action without asking permissions.
    -a, --archive-folder FOLDER      The folder in which archives should be stored.
        --no-archive                 Don't perform archival.
        --version                    Displays version information.
    -?, --help                       Shows quick help about using prune.
$
{% endhighlight %}

You can employ Prune in an automated fashion, pruning one or more directories on a cron job or using some other kind of automation:

{% highlight bash %}
#!/bin/bash
prune ~/backups/mysql
prune --no-archive ~/backups/subversion
{% endhighlight %}