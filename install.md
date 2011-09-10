---
layout: default
title: "Prune: Install"
---
Prune is packed as a [ruby gem](https://rubygems.org/gems/geoffreywiseman-prune) and available from rubygems.org. I expect that's the way that most of you will choose to deploy and use prune. It's the easiest way to try Prune:

{% highlight bash %}
$ gem install geoffreywiseman-prune
Fetching: minitar-0.5.3.gem (100%)
Fetching: geoffreywiseman-prune-1.1.1.gem (100%)
Successfully installed minitar-0.5.3
Successfully installed geoffreywiseman-prune-1.1.1
2 gems installed
Installing ri documentation for minitar-0.5.3...
Installing ri documentation for geoffreywiseman-prune-1.1.1...
Installing RDoc documentation for minitar-0.5.3...
Installing RDoc documentation for geoffreywiseman-prune-1.1.1...
$ prune --help
Usage: prune [options] folder
    -v, --verbose                    Prints much more frequently during execution about what it's doing.
    -d, --dry-run                    Categorizes files, but does not take any actions on them.
    -f, --force, --no-prompt         Will take action without asking permissions; useful for automation.
    -a, --archive-folder FOLDER      The folder in which archives should be stored; defaults to <folder>/../<folder-name>-archives.
        --no-archive                 Don't perform archival; typically if the files you're pruning are already compressed.
        --version                    Displays version information.
    -?, --help                       Shows quick help about using prune.
{% endhighlight %}

Prune is also available as a [Zip archive](https://github.com/downloads/geoffreywiseman/prune/prune-1.1.1.zip), a [Tarball](https://github.com/downloads/geoffreywiseman/prune/prune-1.1.1.tar.gz) or [directly through GitHub](http://github.com/geoffreywiseman/prune/), all visible in the banner above.