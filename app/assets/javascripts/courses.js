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
        var id = e.target.id.substring(5);
        $("#repl_"+id).toggle();
        $("#show_"+id).toggle();
        $("#hide_"+id).toggle();
    };

    $(".replies-to-feedback").hide();
    $(".feedback-hide-button").hide();
    $(".feedback-show-button").click(toggle_feedback_reply);
    $(".feedback-hide-button").click(toggle_feedback_reply);

    var deadline_group_toggle_status = false;

    var toggle_deadline_grouping = function (e) {
        deadline_group_toggle_status = !deadline_group_toggle_status;
        var id = e.target.id.substring(8);
        $("#group_" + id).toggle();
        $("#exercises_" + id).toggle();

        $("#group_" + id).find("input").each(function() {
            if (!$(this).hasClass("various")) {
                this.disabled = deadline_group_toggle_status;
            }
        });
        $("#exercises_" + id).find("input").each(function() {
            this.disabled = !deadline_group_toggle_status;
        });
    };

    $(".toggle-groups-exercises").click(toggle_deadline_grouping);

    var reset_group_deadlines = function (e) {
        if (!confirm("Clear deadlines in this group?")) {
            return;
        }

        deadline_group_toggle_status = !deadline_group_toggle_status;
        var id = e.target.id.substring(6);

        $("#group_" + id).find("input").each(function() {
            $(this).removeClass("various");
            this.value = '';
            this.disabled = false;
        });
        $("#exercises_" + id).find("input").each(function() {
            this.value = '';
            this.disabled = true;
        });

        $("#group_" + id).toggle();
        $("#exercises_" + id).toggle();
    };

    $(".reset-group-deadlines").click(reset_group_deadlines);

    var toggle_advanced_deadline_options = function (e) {
        $(".unlock-deadline-field").toggle();
    };

    $("#toggle-advanced-deadline-options").click(toggle_advanced_deadline_options);
});
