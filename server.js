const express = require("express");
const webSocketServer = require("ws").Server;
const wsWrapper = require("ws-server-wrapper");
const http = require("http");
let PORT = process.env.PORT || 3001;
const path = require("path");
const moment = require("moment");

let app = express();
const server = http.createServer(app);
//creates a web socket server on the path /socket
const wss = new wsWrapper(new webSocketServer({ server, path: "/socket" }));

//previous messages to be sent on connection
let messages = [
	/* ----sample messages to use in testing---- */
	// {
	// 	user: "Bobby",
	// 	text: "This app doesn't work well",
	// 	timeStamp: moment().format("YYYY-MM-DD hh:mm:ss A")
	// },
	// {
	// 	user: "Martin",
	// 	text: "I agree. Something's wrong",
	// 	timeStamp: moment().format("YYYY-MM-DD hh:mm:ss A")
	// },
	// {
	// 	user: "Voldemort",
	// 	text: "I'll tell you what's wrong",
	// 	timeStamp: moment().format("YYYY-MM-DD hh:mm:ss A")
	// }
];

let users = [];

wss.on("connection", socket => {
	//console.log("socket connected");
	//when web socket server connects to a client, send initial sample messages to the client
	socket.emit("previousMsgs", messages);
	socket.emit("users", users);
});

wss.on("disconnect", socket => {
	//console.log("wss disconnected");
});

wss.on("chatMsg", function(msg) {
	messages.push(msg);
	wss.emit("chatMsg", msg);
	console.log(messages);
});

wss.on("deleteMsg", function(msg) {
	messages.splice(msg.index, 1);
	wss.emit("deleteMsg", msg);
	console.log(messages);
});

wss.on("updateUsers", function(userObj) {
	if (userObj.method === "add") {
		users.push(userObj.user);
	} else if (userObj.method === "delete") {
		users.some((user, index) => {
			if (user === userObj.user) {
				users.splice(index, 1);
				return true;
			}
		});
	}
	wss.emit("users", users);
	console.log(users);
});

//determine whether the server is in production or development mode
//if server is production mode, serve the static riot.js files bundled/built with parcel.js and change the port of the server
if (process.env.NODE_ENV && process.env.NODE_ENV.trim() === "production") {
	app.use(express.static(path.join(__dirname, "client/dist")));
	PORT = 80;
}

server.listen(PORT, function() {
	console.log("API Server now listening on PORT " + PORT);
});
