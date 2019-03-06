const express = require("express");
const webSocketServer = require("ws").Server;
const wsWrapper = require("ws-server-wrapper");
const http = require("http");
let PORT = process.env.PORT || 3001;
const path = require("path");

let app = express();
const server = http.createServer(app);
const wss = new wsWrapper(new webSocketServer({ server, path: "/socket" }));

let previousMsgs = [
	{ user: "Bobby", text: "This app doesn't work well" },
	{ user: "Martin", text: "I agree. Something's wrong" },
	{ user: "Voldemort", text: "I'll tell you what's wrong" }
];

wss.on("connection", socket => {
	console.log("socket connected");
	socket.emit("previousMsgs", previousMsgs);
});

wss.on("disconnect", socket => {
	console.log("wss disconnected");
});

wss.on("chatMsg", function(msg) {
	previousMsgs.push(msg);
	wss.emit("chatMsg", msg);
});

if (process.env.NODE_ENV && process.env.NODE_ENV.trim() === "production") {
	app.use(express.static(path.join(__dirname, "client/dist")));
	PORT = 80;
}

server.listen(PORT, function() {
	console.log("API Server now listening on PORT " + PORT);
});
