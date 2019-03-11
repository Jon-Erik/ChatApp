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
				onchange="{editNewUsername}"
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
				<td class="delete" title="Delete message">
					<i onClick="{deleteMsg}" class="fas fa-trash-alt"></i>
				</td>
				<td>{msg.user}</td>
				<td>{msg.text}</td>
				<td>{msg.timeStamp}</td>
			</tr>
		</tbody>
	</table>

	<form onsubmit="{sendMessage}">
		<input
			onchange="{editNewText}"
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

		/*--------DOM manipulation functions---------*/
		deleteMessage(msg) {
			this.messages.splice(msg.index, 1)
			this.update()
		}

		editNewUsername(event) {
			this.newUsername = event.target.value
		}

		setUsername(event) {
			this.connectedUsername = this.newUsername
			this.newUsername = ""
			this.updateUsers("add");
		}

		editNewText(event) {
			this.newText = event.target.value
			this.update()
		}

		receiveMessage(msg) {
			this.messages.push(msg)
			this.update()
		}

		setPreviousMsgs(msgs) {
			this.messages = msgs;
			this.update();
		}

		resetUsername() {
			this.updateUsers("delete")
			this.connectedUsername = "";
		}

		updateUsersArray(users) {
			this.users = users;
			this.update();
		}

		/*---functions with routes sending data to web socket server---*/

		deleteMsg(event) {
			//riot js on click events can get the item of an array rendered with repeating html elements
			let msg = event.item.msg
			let index = this.messages.indexOf(msg)
			msg.index = index
			//send a message to the web socket server on the "deleteMsg" route with the message to be deleted
			opts.socket.emit("deleteMsg", msg)
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
				opts.socket.emit("chatMsg", msg);
			}
		}

		updateUsers(method) {
			//sends username to server to display/delete on all clients
			//method is either "add" or "delete"
			let userObj = {
				user: this.connectedUsername,
				method: method
			}
			opts.socket.emit("updateUsers", userObj)
		}

		/*---web socket listeners---------*/

		//on connection and reconnection to web socket server, update whether the application is connected to display in the DOM
		opts.socket.on("disconnect", () => {
			this.update({connected: opts.socket.isConnected})
			this.users = [];
		})

		opts.socket.on("open", () => {
			this.update({connected: opts.socket.isConnected});
		});

		//if a msg is received on the channel "chatMsg", call the receiveMessage function and add it to messages array
		opts.socket.on("chatMsg", this.receiveMessage)
		
		//if a msg is received on the channel deleteMessage, call the deleteMessage function and remove it from the messages array
		opts.socket.on("deleteMsg", this.deleteMessage)

		//when the web socket server connects, it sends the current messages on the server to the client on the previousMsgs route. When the client receives the messages on this channel, it calls the setPreviousMsgs function to reset the messages array
		opts.socket.on("previousMsgs", this.setPreviousMsgs)

		//receives array of names of users connected to be displayed
		opts.socket.on("users", this.updateUsersArray)
	</script>
</app>
