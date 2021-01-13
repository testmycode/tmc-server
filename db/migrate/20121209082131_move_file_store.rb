require 'fileutils'

class MoveFileStore < ActiveRecord::Migration[4.2]
  def up
    return true if 1==1
    FileUtils.mkdir_p("#{::Rails.root}/db")
    if File.exist?("#{::Rails.root}/tmp/cache")
      FileUtils.move("#{::Rails.root}/tmp/cache", "#{::Rails.root}/db/files")
    else
      FileUtils.mkdir_p("#{::Rails.root}/db/files")
    end
  end

  def down
    FileUtils.mkdir_p("#{::Rails.root}/tmp")
    if File.exist?("#{::Rails.root}/db/files")
      FileUtils.move("#{::Rails.root}/db/files", "#{::Rails.root}/tmp/cache")
    else
      FileUtils.mkdir_p("#{::Rails.root}/tmp/cache")
    end
  end
end
