// ...
//= require jquery-ui
//= require jquery.dataTables.min
//= require shCore
//= require shBrushColdFusion
//= require shBrushJavaFX
//= require shBrushSql
//= require shBrushCpp
//= require shBrushPerl
//= require shBrushVb
//= require shBrushCss
//= require shBrushPhp
//= require shBrushXml
//= require shBrushDelphi
//= require shBrushPlain
//= require shAutoloader
//= require shBrushDiff
//= require shBrushPowerShell
//= require shLegacy
//= require shBrushAS3
//= require shBrushErlang
//= require shBrushPython
//= require shBrushAppleScript
//= require shBrushGroovy
//= require shBrushRuby
//= require shBrushBash
//= require shBrushJScript
//= require shBrushSass
//= require shBrushCSharp
//= require shBrushJava
//= require shBrushScala
//= require comet_connection
//= require review_notifications

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
