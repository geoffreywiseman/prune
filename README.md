# Prune:  Maintaining Steady State in a Folder/Tree
[![Build Status](https://travis-ci.org/geoffreywiseman/prune.png)](https://travis-ci.org/geoffreywiseman/prune) [![Dependency Status](https://gemnasium.com/geoffreywiseman/prune.png)](https://gemnasium.com/geoffreywiseman/prune) [![Code Climate](https://codeclimate.com/badge.png)](https://codeclimate.com/github/geoffreywiseman/prune)

Prune's raison d'etre is to allow you to maintain a folder in a steady state by setting up rules to determine which files should be
retained, removed, archived, etc.

Prune was created to maintain a set of backups by retaining two weeks, removing files older than two weeks except the 'friday' files,
and archiving things older than two months, but for the most part,
the nature of those rules is configurable so that you can make the decisions that make sense for your own project.

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
