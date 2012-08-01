require 'pathname'
require 'find'

# A background process that feeds all pom.xml files to the maven caches of all sandboxes.
class MavenCacheSeeder
  # course_dir: path to a clone of a course
  # servers: list of RemoteSandbox objects.
  def self.start(clone_dir, servers)
    # We need to operate on absolute paths since the process working dir
    # may change at any time.
    # It's also possible for the clone dir to disappear while we're working.
    # Then we just fail, no biggie.

    clone_dir = Pathname(clone_dir).realpath
    Thread.start do
      pom_xmls = find_pom_xmls(clone_dir)
      for pom_xml in pom_xmls
        for server in servers
          server.try_to_seed_maven_cache(pom_xml)
        end
      end
    end
  end

private
  def self.find_pom_xmls(clone_dir)
    result = []
    clone_dir.find do |path|
      result << path if path.basename.to_s == 'pom.xml'
    end
    result
  end
end