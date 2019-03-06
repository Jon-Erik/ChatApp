<app>
	<h3>Sample Chat Application</h3>
	<br />
	<div if="{connected}">
		<span><i class="fas fa-circle connected"></i></span>
		<strong>Connected</strong>
	</div>

	<div if="{!connected}">
		<span><i class="fas fa-circle disconnected"></i></span>
		<span>Not connected</span>
	</div>
	<br />
	<table class="table">
		<thead>
			<tr>
				<th>User</th>
				<th>Message</th>
			</tr>
		</thead>
		<tbody>
			<tr each="{messages}">
				<td>{user}</td>
				<td>{text}</td>
			</tr>
		</tbody>
	</table>

	<form onsubmit="{sendMessage}">
		<input
			onchange="{editNewUsername}"
			value="{newUsername}"
			placeholder="Username"
		/>
		<input
			onchange="{editNewText}"
			value="{newText}"
			placeholder="New message"
		/>
		<button disabled="{newMessage == '' || newUsername == ''}">Send</button>
	</form>

	<script>
		this.messages = []

		this.newUsername= ""
		this.newText=""
		this.connected = opts.socket.isConnected;

		editNewUsername(event) {
			this.newUsername = event.target.value
		}

		editNewText(event) {
			this.newText = event.target.value
		}

		receiveMessage(msg) {
			this.messages.push(msg)
			this.update()
		}

		setPreviousMsgs(msgs) {
			console.log("setting previous msgs")
			this.messages = msgs;
			this.update()
		}

		opts.socket.on("disconnect", () => {
			this.update({connected: opts.socket.isConnected})
		})

		opts.socket.on("open", () => {
			this.update({connected: opts.socket.isConnected});
		});

		opts.socket.on("chatMsg", this.receiveMessage)

		opts.socket.on("previousMsgs", this.setPreviousMsgs)

		sendMessage(e) {
			e.preventDefault();
			if (this.newText && this.newUsername) {
				const msg = {
					user: this.newUsername,
					text: this.newText
				}
				this.newUsername =  ""
				this.newText =  ""
				opts.socket.emit("chatMsg", msg);
			}
		}
	</script>
</app>
