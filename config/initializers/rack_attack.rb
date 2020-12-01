class Rack::Attack
    # Ban login spammers for 15 minutes after 20 attempts in a minute, regardless of whether login credentials were correct or not
    Rack::Attack.blocklist('login spammers') do |req|
        Rack::Attack::Allow2Ban.filter(req.ip, maxretry: 21, findtime: 1.minutes, bantime: 15.minutes) do
            req.path == '/sessions' && req.post?
        end
    end
end
