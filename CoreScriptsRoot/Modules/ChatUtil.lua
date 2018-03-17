local Util = {}
do
	function Util.Signal()
		local sig = {}

		local mSignaler = Instance.new('BindableEvent')

		local mArgData = nil
		local mArgDataCount = nil
		
		function sig:Fire(...)
			mArgData = {...}
			mArgDataCount = select('#', ...)
			mSignaler:Fire()
		end
		
		-- deprecated
		function sig:fire(...)
			self:Fire(...)
		end
		
		function sig:Connect(f)
			if not f then error("connect(nil)", 2) end
			return mSignaler.Event:connect(function()
				f(unpack(mArgData, 1, mArgDataCount))
			end)
		end
		
		-- deprecated
		function sig:connect(f)
			self:Connect(f)
		end
		
		function sig:Wait()
			mSignaler.Event:wait()
			assert(mArgData, "Missing arg data, likely due to :TweenSize/Position corrupting threadrefs.")
			return unpack(mArgData, 1, mArgDataCount)
		end
		
		-- deprecated
		function sig:wait()
			sig:Wait();
		end

		return sig
	end
end

return Util