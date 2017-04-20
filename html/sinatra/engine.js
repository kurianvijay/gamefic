var Gamefic = (function() {
	var startCallbacks = [];
	var inputCallbacks = [];
	var finishCallbacks = [];
	var responseCallbacks = {};
	var doReady = function(response) {
		startCallbacks.forEach(function(callback) {
			callback(response);
		});
	}
	var handle = function(response) {
		var handler = responseCallbacks[response.scene] || responseCallbacks['Active'];
		handler(response);
	}
	return {
		start: function() {
			var that = this;
      $.post('/start', function(response) {
				doReady(response);
				handle(response);
				finishCallbacks.forEach(function(callback) {
					callback(response);
				});
      });
		},
		update: function(input) {
			if (input != null) {
				$.post('/update', {command: input}, function(response) {
					inputCallbacks.forEach(function(callback) {
						callback(response);
					});
					doReady(response);
					handle(response);
					finishCallbacks.forEach(function(callback) {
						callback(response);
					});
				});
			}
		},
		onStart: function(callback) {
			startCallbacks.push(callback);
		},
		onInput: function(callback) {
			inputCallbacks.push(callback);
		},
		onFinish: function(callback) {
			finishCallbacks.push(callback);
		},
		handleResponse: function() {
			var states = [];
			var args = Array.prototype.slice.call(arguments);
			while (args.length > 1) {
				states.push(args.shift());
			}
			if (states.length == 0) states.push('Active');
			states.forEach(function (state) {
				responseCallbacks[state] = args[0];
			});
		},
		save: function(filename, data) {
			var json = Opal.JSON.$generate(data);
			localStorage.setItem(filename, json);
			Opal.GameficOpal.$static_character().$tell('Game saved.');
		},
		restore: function(filename) {
			var data = Opal.JSON.$parse(localStorage.getItem(filename));
			var metadata = data.$fetch('metadata');
			// HACK Converting hashes to strings for JavaScript comparison
			if (metadata.$to_s() != Opal.GameficOpal.$static_plot().$metadata().$to_s()) {
				Opal.GameficOpal.$static_character().$tell('The saved data is not compatible with this version of the game.');
				return Opal.nil;
			} else {
				return data;
			}
		}
	}
})();