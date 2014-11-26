var PagePresence = (function() {
  var changeCallbacks = [];
  var initialCallbacks = [];
  var initial = null;

  CometConnection.connected(function(cometd) {
    var thisPage = getMeta('current_path');
    cometd.subscribe('/broadcast/page-presence' + thisPage, pagePresenceUpdate);
  });

  function pagePresenceUpdate(message) {
    var users = message.data.users;
    if (initial == null) {
      initial = users;
      fireInitial();
    }

    fireChange(users);
  }

  function fireChange(users) {
    _.each(changeCallbacks, function(callback) {
      callback(users);
    });
  }

  function fireInitial() {
    _.each(initialCallbacks, function(callback) {
      callback(initial);
    });
    initialCallbacks = [];
  }

  return {
    change: function(callback) {
      changeCallbacks.push(callback);
      if (initial != null) {
        callback(initial);
      }
    },
    initial: function(callback) {
      if (initial == null) {
        initialCallbacks.push(callback);
      } else {
        callback(initial);
      }
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
      _.each(users, function(user, i) {
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