module ApplicationCable
  class Connection < ActionCable::Connection::Base
    identified_by :current_user

    def connect
      Rails.logger.info("Trying to connect")
      self.current_user = find_verified_user
    end

    private
      def find_verified_user
        Rails.logger.info("Connectionh")
        byebug
        if verified_user = User.find_by(id: 1)
          verified_user
        else
          reject_unauthorized_connection
        end
      end
  end
end
