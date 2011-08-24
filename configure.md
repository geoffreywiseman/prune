---
layout: default
title: "Prune: Configure"
---

There are a few things you might want to configure in prune. At the moment, configuration in prune is really just a kind of modification -- you can think of prune as an example script that you can modify for your own needs. I imagine the things you might want to modify are the retention policy and the pruner itself.

This approach not ideal, but it works for my immediate needs. I've put some thought into how I'd like configuration to work, but it's not there yet.

## Retention Policy ##

The retention policy, in <code>lib/prune/retention.rb</code>, is where you specify the rules that determine how you analyze and categories the files to be retained, removed, archived or ignored. This is the area I imagine most people would want to make changes to the defaults that I've established for Prune. 

## Pruner ##

The pruner, in <code>lib/prune/pruner.rb</code>, is where you might add new actions if ignore, remove, retain and archive aren't sufficient for your needs. You could modify the retention policy to return different categories, then modify the pruner to take a new action based on the new category.


## Future Thoughts ##

Eventually, I'd like to have two primary paths for configuration:

- Allow prune to be used in ruby scripts, so that you can write a script that invokes prune in several directories with a retention policy specified in Ruby DSL.
- External configuration (probably Ruby or YAML) so that you can invoke Prune, point it at an external configuration, and let it go.