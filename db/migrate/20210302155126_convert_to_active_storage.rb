class ConvertToActiveStorage < ActiveRecord::Migration[6.1]
  require 'open-uri'

  def up
    active_storage_blob_statement = ActiveRecord::Base.connection.raw_connection.prepare('active_storage_blob_statement', <<-SQL)
      INSERT INTO active_storage_blobs (
        "key", filename, content_type, metadata, service_name, byte_size, checksum, created_at
      ) VALUES ($1, $2, $3, '{}', 'local', $4, $5, $6)
    SQL

    active_storage_attachment_statement = ActiveRecord::Base.connection.raw_connection.prepare('active_storage_attachment_statement', <<-SQL)
      INSERT INTO active_storage_attachments (
        name, record_type, record_id, blob_id, created_at
      ) VALUES ($1, $2, $3, #{"(SELECT max(id) from active_storage_blobs)"}, $4)
    SQL

    Rails.application.eager_load!
    models = ActiveRecord::Base.descendants.reject(&:abstract_class?)

    transaction do
      models.each do |model|
        attachments = model.column_names.map do |c|
          if c =~ /(.+)_file_name$/
            $1
          end
        end.compact

        if attachments.blank?
          next
        end

        model.find_each.each do |instance|
          attachments.each do |attachment|
            if instance.send(attachment).path.blank?
              next
            end

            ActiveRecord::Base.connection.raw_connection.exec_prepared(
              'active_storage_blob_statement', [
                key(instance, attachment),
                instance.send("#{attachment}_file_name"),
                instance.send("#{attachment}_content_type"),
                instance.send("#{attachment}_file_size"),
                checksum(instance.send(attachment)),
                instance.updated_at.iso8601
              ])

            ActiveRecord::Base.connection.raw_connection.exec_prepared(
              'active_storage_attachment_statement', [
                attachment,
                model.name,
                instance.id,
                instance.updated_at.iso8601,
              ])
          end
        end
      end
    end
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end

  private

  def key(instance, attachment)
    SecureRandom.uuid
    # Alternatively:
    # instance.send("#{attachment}_file_name")
  end

  def checksum(attachment)
    # local files stored on disk:
    url = attachment.path
    Digest::MD5.base64digest(File.read(url))

    # remote files stored on another person's computer:
    # url = attachment.url
    # Digest::MD5.base64digest(Net::HTTP.get(URI(url)))
  end
end 