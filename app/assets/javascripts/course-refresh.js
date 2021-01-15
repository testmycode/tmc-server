//= require action_cable
console.log("Course refresh")
const cable = ActionCable.createConsumer()

const connection = cable.subscriptions.create('CourseRefreshChannel', {
    connected() {
        console.log("Socket connected")
    },

    disconnected() {
        connection.unsubscribe()
        console.log("Socket disconnected")
    },

    received(data) {
        console.log(data)
    }
})
