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

//messages array to be update as messages are sent and received
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
let msgIdCounter = 1;

wss.on("connection", socket => {
	//console.log("socket connected");
	//when web socket server connects to a client, send any existing messages and existing users
	socket.emit("previousMsgs", messages);
	socket.emit("users", users);
});

wss.on("disconnect", socket => {
	//console.log("wss disconnected");
});

wss.on("requestAPITest", function(data) {
	//response to socket.request in the client on event
	console.log("hitting test request");
	//return data for promise in client
	return data * 2;
});

wss.on("chatMsg", function(msg) {
	//when a new chat msg is received, first give it an id
	msg.id = msgIdCounter;
	msgIdCounter++;
	//then push the new message object to the messages array
	messages.push(msg);
	//send the new message to all clients
	wss.emit("chatMsg", msg);
});

wss.on("deleteMsg", function(msg) {
	//delete message based on its index in the messages array
	messages.splice(msg.index, 1);
	//send the message to be deleted to the client to be deleted from browser memory
	wss.emit("deleteMsg", msg);
});

wss.on("updateUsers", function(userObj) {
	if (userObj.method === "add") {
		// if a user has logged in and is being added, push the new user to users array
		users.push(userObj.user);
	} else if (userObj.method === "delete") {
		// if a user has logged out and needs to be deleted, find the user in the users array and delete the user from it
		users.some((user, index) => {
			if (user === userObj.user) {
				users.splice(index, 1);
				return true;
			}
		});
	}
	//send the updated user list to the client
	wss.emit("users", users);
});

wss.on("editMsg", function(newMsg) {
	//if a message is being updated, find the the original old message and update its text and timestamp based on the new msg
	messages.some(oldMsg => {
		if (oldMsg.id === newMsg.id && oldMsg.user === newMsg.user) {
			oldMsg.text = newMsg.text;
			oldMsg.timeStamp = newMsg.timeStamp;
			return true;
		}
	});
	//send the new msg to the client to be deleted from browser memory
	wss.emit("updatedMsg", newMsg);
});

//determine whether the server is in production or development mode; if server is production mode, serve the static riot.js files bundled/built with parcel.js and change the port of the server
if (process.env.NODE_ENV && process.env.NODE_ENV.trim() === "production") {
	app.use(express.static(path.join(__dirname, "client/dist")));
	PORT = 80;
}

server.listen(PORT, function() {
	console.log("API Server now listening on PORT " + PORT);
});
