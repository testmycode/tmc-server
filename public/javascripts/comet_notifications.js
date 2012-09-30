$(document).ready(function() {
  var notificationsEnabled = true;
  window.disableCometNotifications = function() {
    notificationsEnabled = false;
  };

  var cometd = $.cometd;
  var username = $('meta[name=username]').attr('content');
  if (!cometd || !username) { // some common situations: cometd failed to load or not logged in
    return;
  }

  var cometUrl = $('meta[name=comet_server_baseurl]').attr('content');
  var tmcBaseUrl = $('meta[name=comet_tmc_baseurl]').attr('content');
  var sessionCookieName = $('meta[name=session_cookie_name]').attr('content');
  var sessionId = $.cookie(sessionCookieName);

  cometd.configure({
    url: cometUrl
  });

  function log(msg) {
    if (window.console && console.log) {
      console.log(msg);
    }
  }

  function startConnecting() {
    cometd.addListener('/meta/handshake', function(message) {
      if (message.successful) {
        startSubscribing();
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

  function startSubscribing() {
    cometd.subscribe('/broadcast/user/' + username + '/review-available', onReviewAvailable);
  }

  function onReviewAvailable(message) {
    var exerciseName = message.data['exercise_name'];
    var url = message.data['url'];
    var html = '<p>' +
        'Your submission for ' +
        escapeHtml(exerciseName) +
        ' was <a href="' + url + '">reviewed</a>.' +
        '</p>';
    showNotification(html);
  }

  function showNotification(content) {
    if (!notificationsEnabled) {
      return;
    }

    var $dialog = $(document.createElement('section'));
    var $dismissButton = $('<div class="dialog-buttons"><button class="dialog-dismiss">Close</button></div>');
    $dialog.append($(content));
    $dialog.append($dismissButton);
    $dialog.dialog({
      title: 'Notification',
      width: 350,
      height: 200,
      dialogClass: 'big-drop-shadow'
    });
    $dismissButton.click(function() {
      $dialog.dialog('close');
    });
  }

  startConnecting();

});