//= require action_cable
$(document).ready(function() {
    var cable = ActionCable.createConsumer();
    var connection = cable.subscriptions.create(
        { 
            channel: `CourseRefreshChannel`, 
            courseId: `${window.courseId}`
        }, 
        {
            connected() {
                console.log("Socket connected");
            },

            disconnected() {
                connection.unsubscribe();
                console.log("Socket disconnected");
            },

            received(data) {
                console.log(data);
            }
        }
    );
});