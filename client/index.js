const riot = require("riot");
require("./tags/app.tag");
import WebSocketWrapper from "ws-wrapper";

//determines where to listen for socket requests depending on production or development mode
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
		//Auto reconnect if the socket is open and disconnects because of an error
		setTimeout(() => {
			socket.bind(new WebSocket("ws://" + endpoint + "/socket"));
		}, 5000);
	}
});

document.addEventListener("DOMContentLoaded", () => {
	//after the initial basic html page has loaded, mount the riot.js components and bind the web socket connection to the correct endpoint
	riot.mount("app", { socket });
	socket.bind(new WebSocket("ws://" + endpoint + "/socket"));
});
