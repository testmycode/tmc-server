# frozen_string_literal: true

require 'xmlsimple'

class MavenPomFile
  def initialize(file)
    @data = XmlSimple.xml_in(file.to_s)
  end

  attr_reader :data

  def artifact_id
    @data['artifactId'][0]
  end

  def artifact_version
    maybe_from_parent('version')
  end

  def artifact_group_id
    maybe_from_parent('groupId')
  end

  def packaging
    @data['packaging'][0]
  end

  private

    def maybe_from_parent(value)
      version = @data[value]
      if !version.nil?
        version[0]
      else
        # For multimodule maven projects like langs
        @data['parent'][0][value][0]
      end
    end
end
