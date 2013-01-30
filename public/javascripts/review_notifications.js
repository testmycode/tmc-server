var ReviewNotifications = (function() {
  var notificationsEnabled = true;

  CometConnection.connected(function(cometd) {
    var username = getMeta('username');
    cometd.subscribe('/broadcast/user/' + username + '/review-available', onReviewAvailable);
  });

  function onReviewAvailable(message) {
    if (notificationsEnabled) {
      var exerciseName = message.data['exercise_name'];
      var url = message.data['url'];
      var html = '<p>' +
          'Your submission for ' +
          escapeHtml(exerciseName) +
          ' was <a href="' + url + '">reviewed</a>.' +
          '</p>';
      showNotification(html);
    }
  }

  function showNotification(content) {
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

  return {
    disable: function() {
      notificationsEnabled = false;
    }
  }
})();

$(document).ready(function() {
    $(".feedback-reply-form").hide();

    $(".feedback-reply-button").click(
        function (e){
            id = e.target.id
            console.log(e.target.id);
            $("#id"+id).toggle();
            $("#"+id).toggle();
        }
    );
});


