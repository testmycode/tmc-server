//= require action_cable
console.log("Course refresh")
const cable = ActionCable.createConsumer()

const connection = cable.subscriptions.create('CourseRefreshChannel', {
    connected() {
        console.log("Hello")
    },

    disconnected() {
        connection.unsubscribe()
    },

    received(data) {
        console.log(data)
    }
})
