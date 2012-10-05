var PagePresence = (function() {
  var callbacks = [];

  CometConnection.connected(function(cometd) {
    var thisPage = getMeta('current_path');
    cometd.subscribe('/broadcast/page-presence' + thisPage, pagePresenceUpdate);
  });

  function pagePresenceUpdate(message) {
    var users = message.data.users;
    $.each(callbacks, function(i, callback) {
      callback(users);
    });
  }

  return {
    change: function(callback) {
      callbacks.push(callback);
    }
  }
})();

$(document).ready(function() {
  PagePresence.change(function(users) {
    var $pp = $('#page-presence');
    $pp.html('');
    $pp.append('<span>Users on this page:</span> ');
    if (users.length <= 1) {
      $pp.append('<span>just you</span>');
    } else {
      $.each(users, function(i, user) {
        var $user = $('<span class="user"></span>');
        $user.text(user);
        $pp.append($user);
        if (i < users.length - 1) {
          $pp.append(', ');
        }
      });
    }
  })
});