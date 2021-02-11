var messaging = {
	
	// FIXME: this doesn't work if 5000 is not the port
	port: 5000,
	send: async function sendMessage(msg) {
		var chunk_size = 512;
		var messages = [];
		
		let chunk = "";
		while(true) {
			let chunk = msg.substring(messages.length * chunk_size, (messages.length+1) * chunk_size);
			
			if(chunk.length > 0)
				messages.push(chunk);
			else
				break;
		}
		
		// if it's splitted append
		if(messages.length > 1) {
			messages.push("END OF SPLITTED MESSAGE");
			console.log(JSON.stringify(messages))
		}
		
		for(var i=0; i<messages.length; i++) {
			let response = await fetch("http://127.0.0.1:" + this.port + "/API", {
				headers: {
					// if it's partial or not - big messages are divided in chucnks
					// looks like i can't make POST request work
					"size": messages.length,
					// if it's splitted, identifier
					"id": encodeURI(msg.substring(0, 15)),
					// the message
					"message": encodeURI(messages[i])
				}
			});
		}
	}

	
}
