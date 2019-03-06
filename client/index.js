const riot = require("riot");
require("./tags/app.tag");
const WebSocketWrapper = require("ws-wrapper");

let endpoint;
if (process.env.NODE_ENV === "development") {
	endpoint = "localhost:3001";
} else {
	endpoint = "localhost:80";
}

let socket = new WebSocketWrapper(null);

socket.on("error", () => {
	socket.disconnect();
});

socket.on("disconnect", function(wasOpen) {
	//console.log("wss disconnected");
	if (wasOpen) {
		//console.log("Reconnecting in 5 seconds");
		setTimeout(() => {
			socket.bind(new WebSocket("ws://" + endpoint + "/socket"));
		}, 5000);
	}
});

document.addEventListener("DOMContentLoaded", () => {
	riot.mount("app", { socket });
	socket.bind(new WebSocket("ws://" + endpoint + "/socket"));
});
