//= require action_cable
$(document).ready(function() {
    var hostCableUrl = window.location.origin + "/cable"
    var cable = ActionCable.createConsumer(hostCableUrl);
    var connection = cable.subscriptions.create(
        { 
            channel: `CourseTemplateRefreshChannel`, 
            courseTemplateId: `${window.courseTemplateId}`
        }, 
        {
            connected() {
                console.log("Socket connected");
            },

            disconnected() {
                connection.unsubscribe();
                console.log("Socket disconnected");
            },

            received(cableData) {
                if(cableData.refresh_initialized) {
                    document.getElementById("refresh-btn").classList.add('disabled');
                    document.getElementById("refresh-progress-row").innerHTML = "";
                }
                var refreshDiv = document.getElementById("refresh-progress-div");
                refreshDiv.style.display = "block";

                if(cableData.message) {
                    var refreshRow = document.createElement("DIV");
                    refreshRow.classList.add('row');
                    refreshRow.innerHTML = `<div class='col-md-4'>
                                                ${cableData.message}
                                            </div>
                                            <div class='col-md'>
                                                time (ms): ${cableData.time}
                                            </div>
                                            `;
                    refreshDiv.appendChild(refreshRow);

                    var progressBar = document.getElementById('refresh-progress-bar');
                    var newPcg = Math.floor(Number(cableData.percent_done)*100);
                    progressBar.setAttribute('aria-valuenow', newPcg);
                    progressBar.setAttribute('style', 'width:'+ newPcg + '%');
                    progressBar.innerHTML = newPcg + ' %';
                }
                if (Number(cableData.percent_done) === 1 || Number(cableData.percent_done) === 0) {
                    window.location.href = window.location.href + `?generate_report=${cableData.course_template_refresh_id}`;
                }
            }
        }
    );
});