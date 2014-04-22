local t = {}

t.Foo = 
	function() 
		print("foo") 
	end

t.Bar = 
	function() 
		print("bar") 
	end

t.Help = 
	function(funcNameOrFunc) 
		--input argument can be a string or a function.  Should return a description (of arguments and expected side effects)
		if funcNameOrFunc == "Foo" or funcNameOrFunc == t.Foo then 
			return "Function Foo.  Arguments: None.  Side effect: prints foo" 
		elseif funcNameOrFunc == "Bar" or funcNameOrFunc == t.Bar then 
			return "Function Bar.  Arguments: None.  Side effect: prints bar" 
		end 
	end

return t