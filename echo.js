var net = require('net');

var PORT = 8080;

net.createServer(function(connection) {
	console.log('Connection connected');

	connection
		.on('end', function() {
			console.log('Connection diconnected');
		})
		.on('data', function(data) {
			console.log('Connection data received ' + data.length);
		});

	connection.pipe(connection);
}).listen(PORT, function() {
	console.log('Server listening on port ' + PORT);
});
