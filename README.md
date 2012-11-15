# Prune:  Deleting and archiving files by date 
[![Build Status](https://travis-ci.org/geoffreywiseman/prune.png)](https://travis-ci.org/geoffreywiseman/prune) [![Dependency Status](https://gemnasium.com/geoffreywiseman/prune.png)](https://gemnasium.com/geoffreywiseman/prune) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/geoffreywiseman/prune)

We have some nightly processes that archive information that we'd like to retain, either for reference or for possible restoration.  In order to keep space usage somewhat reasonable, we'd like to prune some of those files as they get older.  Prune satisfies that need.

Prune is written as a Ruby library with an optional command-line interface and a wrapping shell script.

## Usage

Prune has a command-line interface and a configurable retention policy. It is packaged as a gem, which can be installed easily:

	gem install geoffreywiseman-prune

At which point you should be able to prune a directory using the default retention policy:

	prune <directory>

And get more information on using it:

	prune --help

The retention policy is [configurable](http://geoffreywiseman.github.com/prune/configure.html).

## Continuous Integration

Prune is built by [Travis CI](http://travis-ci.org/#!/geoffreywiseman/prune).