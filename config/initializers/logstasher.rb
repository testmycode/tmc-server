# frozen_string_literal: true

if LogStasher.enabled?
  LogStasher.add_custom_fields do |fields|
    # This block is run in application_controller context,
    # so you have access to all controller methods
    begin
      fields[:user] = if current_user&.login
        current_user.login
      else
        'guest'
      end
    rescue NameError
      fields[:user] = 'pghero/api?'
    end

    begin
      if params
        fields[:client] = params[:client] if params[:client]
        fields[:client_version] = params[:client_version] if params[:client_version]
      end
    rescue NameError
    end

    fields[:site] = /^\/api/.match?(request.path) ? 'api' : 'user'

    # If you are using custom instrumentation, just add it to logstasher custom fields
    LogStasher::CustomFields.add(:myapi_runtime)
  end
end
