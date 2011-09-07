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

