<app>
	<h3>Sample Chat Application</h3>
	<br />
	<div if="{connected}">
		<span><i class="fas fa-circle connected"></i></span>
		<strong>Connected </strong>
		
		<span if="{users.length === 0}">
			<i>No users connected</i>
		</span>

		<span if="{users.length > 0}">
			<span>{users.length} users connected: </span>
			<span each="{user in users}">{user} </span>
		</span>
	</div>
	
	<div if="{!connected}">
		<span><i class="fas fa-circle disconnected"></i></span>
		<span>Not connected</span>
	</div>
	<br>

	<div if="{!connectedUsername}">
		<form onsubmit="{setUsername}">
			<input
				onkeyup="{editNewUsername}"
				placeholder="Username"
				value="{newUsername}"
			/>
			<button disabled="{!newUsername}">Log in
		</form>
		</button>
	</div>

	<div if="{connectedUsername}">
		<span>Welcome, {connectedUsername}! </span>
		<button onClick="{resetUsername}">Log out</button>
	</div>

	<br />
	<table class="table">
		<thead>
			<tr>
				<th></th>
				<th>User</th>
				<th>Message</th>
				<th>Time sent</th>
			</tr>
		</thead>
		<tbody>
			<tr each="{msg in messages}">				
				<td if="{connectedUsername === msg.user}" class="active-btn" >
					<i onClick="{deleteMsg}" title="Delete message" class="fas fa-trash-alt"></i>
					<i onClick="{editMsg}" title="Edit message" value="{msg.id}" class="fas fa-edit"></i>
				</td>

				<td if="{connectedUsername !== msg.user}" class="disabled-btn">
					<i class="fas fa-trash-alt"></i>
					<i class="fas fa-edit"></i>
				</td>

				<td>{msg.user}</td>

				<td if="{editedMsgId !== msg.id}">{msg.text}</td>
				
				<td if="{editedMsgId === msg.id}">
					<span title="Discard changes" value="0" class="active-btn" onClick="{editMsg}">
						<i class="fas fa-ban"></i>
					</span>
					<span title="Save changes" value="{msg.id}" class="active-btn" onClick="{saveChanges}">
						<i class="fas fa-save"></i>
					</span>
					<input value="{editedMsgText}" onChange="{updateEditedMsg}"/>
				</td>

				<td>{msg.timeStamp}</td>
			</tr>
		</tbody>
	</table>

	<form onsubmit="{sendMessage}">
		<input
			onkeyup="{editNewText}"
			value="{newText}"
			placeholder="New message"
		/>
		<button disabled="{newText == '' || connectedUsername == ''}">
			Send
		</button>
	</form>

	<script>
		import moment from "moment"
		this.messages = [];
		this.users = [];
		this.connectedUsername = "";
		this.newText = "";
		this.connected = opts.socket.isConnected;
		this.editedMsgId = 0;
		this.editedMsgText = "";
		let {socket} = opts;
		//render function?

		/*--------DOM manipulation functions---------*/
		deleteMessage(msg) {
			this.messages.splice(msg.index, 1);
			this.update();
		}

		editNewUsername(event) {
			this.newUsername = event.target.value;
			this.update();
		}

		setUsername(event) {
			this.connectedUsername = this.newUsername;
			this.newUsername = "";
			this.updateUsers("add");
		}


		editMsg(event) {
			this.editedMsgId = event.target.value;
			this.editedMsgText = event.item.msg.text;
		}

		updateEditedMsg(event) {
			this.editedMsgText = event.target.value
		}

		editNewText(event) {
			this.newText = event.target.value;
			this.update()
		}

		receiveMessage(msg) {
			this.messages.push(msg);
			this.update()
		}

		setPreviousMsgs(msgs) {
			this.messages = msgs;
			this.update();
		}

		updateMsg(newMsg) {
			this.messages.some((oldMsg, index) => {
				if (newMsg.id === oldMsg.id) {
					this.messages[index] = newMsg
					return true;
				}
			})
			this.update();
		}

		resetUsername() {
			this.updateUsers("delete");
			this.connectedUsername = "";
		}

		updateUsersArray(users) {
			this.users = users;
			this.update();
		}

		/*---functions with routes sending data to web socket server---*/

		saveChanges(event) {
			//takes the username, message id, and edited text of a message and gives it a new timestamp
			let msg = {
				user: this.connectedUsername,
				text: this.editedMsgText,
				id: this.editedMsgId,
				timeStamp: moment().format("YYYY-MM-DD hh:mm:ss A")
			}

			//clear edited message info
			this.editedMsgText = "";
			this.editedMsgId = 0;

			socket.emit("editMsg", msg)
		}

		deleteMsg(event) {
			//riot js on click events can get the item of an array rendered with repeating html elements
			let msg = event.item.msg;
			let index = this.messages.indexOf(msg);
			msg.index = index;
			//send a message to the web socket server on the "deleteMsg" route with the message to be deleted
			socket.emit("deleteMsg", msg);
		}

		sendMessage(e) {
			//creates a new message from DOM inputs and with moment and 
			e.preventDefault();
			if (this.newText && this.connectedUsername) {
				const msg = {
					user: this.connectedUsername,
					text: this.newText,
					timeStamp: moment().format("YYYY-MM-DD hh:mm:ss A")
				}
				this.newText =  "";
				socket.emit("chatMsg", msg);

				//socket.request requests specific data from server and returns a promise
				socket.request("requestAPITest", 6000)
					.then(function(response) {
						console.log(response)
					})
			}
		}

		updateUsers(method) {
			//sends username to server to display/delete on all clients
			//method is either "add" or "delete"
			let userObj = {
				user: this.connectedUsername,
				method: method
			}
			socket.emit("updateUsers", userObj)
		}

		/*---web socket listeners---------*/

		//on connection and reconnection to web socket server, update whether the application is connected to display in the DOM
		socket.on("disconnect", () => {
			this.update({connected: socket.isConnected})
			this.users = [];
		})

		socket.on("open", () => {
			this.update({connected: socket.isConnected});
		});

		//if a msg is received on the channel "chatMsg", call the receiveMessage function and add it to messages array
		socket.on("chatMsg", this.receiveMessage)
		
		//if a msg is received on the channel deleteMessage, call the deleteMessage function and remove it from the messages array
		socket.on("deleteMsg", this.deleteMessage)

		//when the web socket server connects, it sends the current messages on the server to the client on the previousMsgs route. When the client receives the messages on this channel, it calls the setPreviousMsgs function to reset the messages array
		socket.on("previousMsgs", this.setPreviousMsgs)

		//receives a message that has been edited and calls updateMsg function to update the messages in memory on client
		socket.on("updatedMsg", this.updateMsg)

		//receives array of names of users connected to be displayed
		socket.on("users", this.updateUsersArray)
	</script>
</app>
