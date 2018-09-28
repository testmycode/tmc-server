# frozen_string_literal: true

require 'system_commands'

class SafeUnzipper
  def unzip(zip_path, dest_dir)
    dest_dir = File.absolute_path(dest_dir)
    # Ideally we'd protect against `unzip` exploits too by running in a sandbox
    SystemCommands.sh!('unzip', '-qqu', zip_path, '-d', dest_dir)
    clean_up(dest_dir, dest_dir)
  end

  private

    def clean_up(root_dir_abs, file)
      if File.symlink?(file)
        dest = File.absolute_path(File.readlink(file), File.dirname(file))
        unless dest.start_with?(root_dir_abs)
          ::Rails.logger.warn("Cleaning up external symlink to: #{dest}")
          File.unlink(file)
        end
      elsif File.directory?(file)
        Dir.entries(file).each do |entry|
          if entry != '.' && entry != '..'
            clean_up(root_dir_abs, file + '/' + entry)
          end
        end
      elsif !File.file?(file)
        # Not a symlink, directory or regular file. Nuke.
        # Currently unzip should never create these, according to the man page.
        ::Rails.logger.warn("Cleaning up unusual file: #{file}")
        File.unlink(file)
      end
    end
end
