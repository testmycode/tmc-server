var CometConnection = (function() {
  var isReady = false;
  var cometd;
  var readyCallbacks = [];

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

    function log(msg) {
      if (window.console && console.log) {
        console.log(msg);
      }
    }

    function startConnecting() {
      cometd.addListener('/meta/handshake', function(message) {
        if (message.successful) {
          onReady();
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

    function onReady() {
      isReady = true;
      $.each(readyCallbacks, function(i, cb) {
        cb(cometd);
      });
      readyCallbacks = [];
    }
  });

  return {
    ready: function(callback) {
      if (isReady) {
        callback(cometd);
      } else {
        readyCallbacks.push(callback);
      }
    }
  };
})();