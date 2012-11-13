require 'xmlsimple'

class MavenPomFile
  def initialize(file)
    @data = XmlSimple.xml_in(file.to_s)
  end

  def artifact_id
    @data['artifactId'][0]
  end

  def artifact_version
    @data['version'][0]
  end

  def artifact_group_id
    @data['groupId'][0]
  end

  def packaging
    @data['packaging'][0]
  end
end
