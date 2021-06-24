/**
 * Utility Singleton class 
 * Library dependency:
 *	JQuery
 */
var GatewayMapUtil = (function() {
	
	//ajax request data
	var getData = function(url, callback) {
		$.ajax({
			url: url
		})
		.done(callback);
	};
	
	//shallow clone an object
	//or using: return $.extend({}, oldObject);
	var cloneObject = function(baseObj) {
		if(typeof(baseObj) != 'object') {
			return {};
		}
		
		var cloneObj = {};
		for(var prop in baseObj) {
			cloneObj[prop] = baseObj[prop];
		}
		
		return cloneObj;
	};
	
	//calculate colors in between given start, end colors, and how many colors in total
	var getColorsFromStartEnd= function(startColor, endColor, colorCount, opacity) {
		if(
			!(startColor instanceof Array) || startColor.length != 3 ||
			!(endColor instanceof Array) || endColor.length != 3 ||
			typeof(colorCount) != 'number' || colorCount < 1 
			) {
			return;
		}
		
		 var r1 = startColor[0],
			g1 = startColor[1],
			b1 = startColor[2];
		var r2 = endColor[0],
			g2 = endColor[1],
			b2 = endColor[2];
			
        var ri = (r2 - r1) / colorCount,
            gi = (g2 - g1) / colorCount,
            bi = (b2 - b1) / colorCount;
		
		var _formatRGB = function(r, g, b) {
			if(opacity && opacity != 0) {
				return "rgba(" + r + "," + g + "," + b + "," + opacity + ")";
			} else
				return "rgb(" + r + "," + g + "," + b + ")";
		};
		
		var colors = [];
		var r,g,b;
		for(var i=0; i<colorCount; i++) {
			
			if(i === 0) {
				r = r1;
				g = g1;
				b = b1;
			} else if(i === (colorCount - 1)){
				r = r2;
				g = g2;
				b = b2;
			} else {
				r += ri,
				g += gi,
				b += bi;
			}
			
			colors.push(_formatRGB(parseInt(r), parseInt(g), parseInt(b)));
		};
		
		return colors;
	};

	//format numbers
	var formatNumber = function(num, formatConfigs) {
		if(typeof(num) != 'number') {
			return num;
		}
		formatConfigs = formatConfigs || {};
		var format = formatConfigs.format;
		var options = formatConfigs.options || {};
		var result = num;
		switch(format) {
			case 'number':
				result = $.formatNumber(num, options);
				break;
			case 'currency':
				result = '$' + $.formatNumber(num, options);
				break;
			case 'percent':
				var decimalDigits = options.decimal || 0;
				result = (num * 100).toFixed(decimalDigits) + '%';
			default:
				break;
		}

		return result;
	};
	
	/**
 * Function generates a random string for use in unique IDs, etc
 *
 * @param <int> n - The length of the string
 */

	var randString = function(n) {
    if(!n)
    {
        n = 5;
    }

    var text = '';
    var possible = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';

    for(var i=0; i < n; i++)
    {
        text += possible.charAt(Math.floor(Math.random() * possible.length));
    }

    return text;
	};

	//public accessible
	return {
		getData: getData,
		getColorsFromStartEnd: getColorsFromStartEnd,
		cloneObject: cloneObject,
		formatNumber: formatNumber,
		randString: randString
	};
	
})();