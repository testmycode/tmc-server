require "tempfile"

last_rev = nil
STDIN.each do |line|
  old, new, ref = line.chomp.split
  last_rev = new
end

Dir.mktmpdir do |dir|
  exit 1 unless system "git archive #{last_rev} | tar -x -C #{dir}"

  exit 1 if FileTest.exists? "#{dir}/valid_course_repository"
  system "rake course_repo:validate[#{dir}]"
  exit 1 unless FileTest.exists? "#{dir}/valid_course_repository"
end

exit 0

