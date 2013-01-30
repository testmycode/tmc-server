$(document).ready(function() {
    $(".feedback-reply-form").hide();

    var toggle_reply_form_and_button = function (e) {
        var id = e.target.id.substring(7);
        console.log(id);
        $("#form_"+id).toggle();
        $("#button_"+id).toggle();
    };

    $(".feedback-reply-button").click(toggle_reply_form_and_button);
    $(".feedback-reply-cancel-button").click(toggle_reply_form_and_button);
});
