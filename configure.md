---
layout: default
title: "Prune: Configure"
---

There are a few things you might want to configure in prune. At the moment, you can customize the retention policy used for a particular folder fairly easily using a light domain-specific-language (DSL) written in Ruby. You might also find yourself wanting to customize the pruner to add new actions, but in order to do that, you'll need to modify Prune's source files.

Although I can imagine lots of ways to further allow customization of Prune, this will be mostly driven by my needs and user requests -- if I don't need a customization and nobody requests it, I'm not terribly likely to build it just for the sheer entertainment value.

## Retention Policy ##

The retention policy is where you specify the rules that determine how you analyze and categories the files to be retained, removed, archived or ignored. This is the area I imagine most people would want to make changes to the defaults that I've established for Prune. The default retention policy for prune can be found in <code>lib/prune/default_retention.rb</code>, but you don't need to change that.

If you're going to invoke prune regularly on a particular folder, and you'd like to customize the retention policy, simply create a <code>.prune</code> file in the target folder and implement a retention policy using Prune's simple DSL. Here's the default retention policy by way of example:

{% highlight ruby %}
preprocess do |file|
  file.modified_time = File.mtime( file.name )

  modified_date = Date.parse modified_time.to_s
  file.days_since_modified = Date.today - modified_date
  file.months_since_modified = ( Date.today.year - modified_date.year ) * 12 + (Date.today.month - modified_date.month)
end

category "Ignoring directories" do
  match { |file| File.directory?(file.name) }
  ignore
  quiet
end

category "Retaining Files from the Last Two Weeks" do
  match do |file|
    file.days_since_modified <= 14
  end
  retain
end

category "Retaining 'Friday' files Older than Two Weeks" do
  match { |file| file.modified_time.wday == 5 && file.months_since_modified < 2 && file.days_since_modified > 14 }
  retain
end

category "Removing 'Non-Friday' files Older than Two Weeks" do
  match { |file| file.modified_time.wday != 5 && file.days_since_modified > 14 }
  remove 
end

category "Archiving Files Older than Two Months" do 
  match { |file| file.modified_time.wday == 5 && file.months_since_modified >= 2 }
  archive
end
{% endhighlight %}

The preprocess block allows you to calculate values in advance that might be checked by more than one category. You could use this to increase the performance of Prune, but it's mostly intended to reduce duplication by avoiding writing the same kind of code in several categories. The file context object passed in to the preprocess block supports fully dynamic properties through the magic of Ruby's <code>method_missing</code>, so you have a fair amount of flexibility here.

Each category you define will be checked in order; the first matched category will be the category assigned to the file at analysis time.

The matching criteria can be customized by passing a block to the match method, where a return value of true would indicate a match. The action taken with files matching the category is customized by calling one of: ignore, retain, remove, archive. If you call the <code>quiet</code> method, this is a way of indicating that matches will not be displayed in output unless you invoke prune with the <code>--verbose</code> flag.

Finally, any file that does not fit within one of these categories will go into a quiet category of unmatched files; use the <code>--verbose</code> flag if you wish to see these, particularly when you're building your DSL for the first time.

## Pruner ##

The pruner, in <code>lib/prune/pruner.rb</code>, is where you might add new actions if ignore, remove, retain and archive aren't sufficient for your needs. You could modify the retention policy to return different categories, then modify the pruner to take a new action based on the new category.
