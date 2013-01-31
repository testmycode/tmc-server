$(document).ready(function() {
    var toggle_reply_form_and_button = function (e) {
        var id = e.target.id.substring(7);
        $("#form_"+id).toggle();
        $("#button_"+id).toggle();
    };

    $(".feedback-reply-form").hide();
    $(".feedback-reply-button").click(toggle_reply_form_and_button);
    $(".feedback-reply-cancel-button").click(toggle_reply_form_and_button);

    var toggle_feedback_reply = function (e) {
        var id = e.target.id.substring(7);
        $("#feedbk_"+id).toggle();
        $("#showfb_"+id).toggle();
        $("#hidefb_"+id).toggle();
    };

    $(".replies-to-feedback").hide();
    $(".feedback-hide-button").hide();
    $(".feedback-show-button").click(toggle_feedback_reply);
    $(".feedback-hide-button").click(toggle_feedback_reply);
});