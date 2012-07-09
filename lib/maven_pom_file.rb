require 'xmlsimple'

class MavenPomFile
  def initialize(file)
    @data = XmlSimple.xml_in(file.to_s)
  end

  def artifact_version
    @data['version'][0]
  end
end
