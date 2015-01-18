var CometConnection = (function() {
  var isReady = false;
  var cometd;
  var connectedCallbacks = [];

  $(document).ready(function() {
    cometd = $.cometd;
    var username = getMeta('username');
    if (!cometd || !username) { // some common situations: cometd failed to load or not logged in
      return;
    }

    var cometUrl = getMeta('comet_server_baseurl');
    var tmcBaseUrl = getMeta('comet_tmc_baseurl');
    var sessionCookieName = getMeta('session_cookie_name');
    var sessionId = $.cookie(sessionCookieName);

    cometd.configure({
      url: cometUrl
    });

    startConnecting();

    $(window).unload(function() {
      cometd.disconnect(true);
    });

    function log(msg) {
      if (window.console && console.log) {
        console.log(msg);
      }
    }

    function startConnecting() {
      cometd.addListener('/meta/handshake', function(message) {
        if (message.successful) {
          fireConnected();
        } else {
          if (message.error) {
            log("cometd handshake failed: " + message.error);
          } else {
            log("cometd handshake failed");
          }
        }
      });

      cometd.registerExtension("authentication", {
        outgoing: function(message) {
          if (message.channel == '/meta/handshake') {
            if (!message.ext) {
              message.ext = {}
            }
            message.ext.authentication = {
              username: username,
              serverBaseUrl: tmcBaseUrl,
              sessionId: sessionId
            }
          }
        }
      });

      cometd.handshake();
    }

    function fireConnected() {
      isReady = true;
      _.each(connectedCallbacks, function(callback) {
        callback(cometd);
      });
    }
  });

  return {
    connected: function(callback) {
      if (isReady) {
        callback(cometd);
      } else {
        connectedCallbacks.push(callback);
      }
    }
  };
})();