//= require action_cable
console.log("Course refresh")
const cable = ActionCable.createConsumer()

const connection = cable.subscriptions.create('CourseRefreshChannel', {
    connected() {
        console.log("Hello")
    },

    disconnected() {
        console.log("Disconnect")
        connection.unsubscribe()
    },

    received(data) {
        console.log("Hello data")
        console.log(data)
    }
})
