--TODO: error and type checking
local vmt = {}
local errc = {
	function (d) if type(d) ~= "number" then error("expected number or table with numbers",4) end end,
	function (d,i) if #d>i then error("too many arguments",4) end end,
}
local errlib = function(c,...)
	errc[c](...)
end

local vec2 = function (x, y)
	local v = {}
	if type(x) == "table" then
		errlib(1,x[1])
		errlib(1,x[2])
		v = x
	else
		errlib(1,x)
		y = y or x
		errlib(1,y)
		v = {x,y}
	end
	return setmetatable(v,vmt[1])
end

--finish compression
--local env = {vmt=vmt,errlib=errlib,tostring=tostring,ipairs=ipairs,error=error,setmetatable=setmetatable,type=type}
--
--
--local vec3, vec4
--for ii=0,1 do
--	local i = i == 1
--	local a = tostring(i and 4 or 3)
--	local b = (i and "v[1]" or '')
--	local c = tostring(i and 3 or 2)
--	local c_new, err = load(
--[[return function (...)
--	local v = {}
--	local it = {...}
--	for i,e in ipairs(it) do
--		if #v < ]]--..a..[[ then
--			if type(e) == "table" then
--				for _,n in ipairs(e) do
--					errlib(1,n)
--					v[#v+1] = n
--				end
--			else
--				errlib(1,e)
--				v[#v+1] = e
--			end
--		else
--			if #v == ]]..a..[[ then
--				errlib(2,it,i)
--			else
--				local in_str = ""
--				for i,e in pairs(it) do
--					in_str = in_str..tostring(i)..": "..tostring(e).."\n"
--				end
--				error("argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
--			end
--		end
--	end
--	if #v == 1 then
--		v = {v[1],v[1],]]..b..[[}
--	end
--	return setmetatable(v,vmt[]]..c..[[])
--end]]
--	,"vec"..(i and "4" or "3"),"t",env)
--	fn_new, err = pcall(c_new)
--	if fn_new then error(err) end
--	if i then
--		vec4 = fn_new
--	else
--		vec3 = fn_new
--	end
--end

local vec3 = function (...)
	local v = {}
	local it = {...}
	for i,e in ipairs(it) do
		if #v < 3 then
			if type(e) == "table" then
				for _,n in ipairs(e) do
					errlib(1,n)
					v[#v+1] = n
				end
			else
				errlib(1,e)
				v[#v+1] = e
			end
		else
			if #v == 3 then
				errlib(2,it,i)
			else
				local in_str = ""
				for i,e in pairs(it) do
					in_str = in_str..tostring(i)..": "..tostring(e).."\n"
				end
				error("argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
			end
		end
	end
	if #v == 1 then
		v = {v[1],v[1],v[1]}
	end
	return setmetatable(v,vmt[2])
end

local vec4 = function (...)
	local v = {}
	local it = {...}
	for i,e in pairs(it) do
		if #v < 4 then
			if (type(e) == "table") then
				for _,n in ipairs(e) do
					--errlib(1,n)
					v[#v+1] = n
				end
			else
				errlib(1,e)
				v[#v+1] = e
			end
		else
			if #v == 4 then
				errlib(2,it,i)
			end
				local in_str = ""
				for ke,va in pairs(it) do
					in_str = in_str..tostring(ke)..": "..tostring(va).."\n"
				end
				error("argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
		end
	end
	if #v == 1 then
		v = {v[1],v[1],v[1],v[1]}
	end
	return setmetatable(v,vmt[3])
end
local lib = {vec2=vec2, vec3=vec3, vec4=vec4}
local env = lib
local vecconv = {tonumber, vec2, vec3, vec4}
local ops = "+-*/"
local ast = "xyzw"

local nmt = debug.getmetatable(0) or {}
local mpn = {"__add","__sub","__mul","__div"}
for a=1,4 do
	local ac = ops:sub(a,a)
	nmt[mpn[a]] = load(
		[[return function(a,b)
		if type(b) == 'table' then
			for i,e in ipairs(b) do  --todo: number checking
				b[i] = a]]..ac..[[e end
		return b
		else
			return a]]..ac.."b\nend end"
	)()
end
debug.setmetatable(0, nmt)

local vecgenmt = function (vt)
	local vc = "a[1] %s c[1]"
	local vts = tostring(vt)
	local tss = ""
	local lss = ""
	for i=2,vt do
		local s = tostring(i)
		vc = vc..",a["..s.."] %s c["..s.."]"
		tss = tss.."','..v["..s.."].."
		lss = lss.."+v["..s.."]*v["..s.."]"
	end
	local fbs = string.format("return function (a, b)\nlocal c = vec%s(b)\nreturn vec%s(%s) \nend", vts,vts,vc)
	local fn_a = {}
	for a=1,4 do
		local ac = ops:sub(a,a)
		fn_a[a] = load(string.format(fbs,ac,ac,ac,ac),"vec"..vts..":"..mpn[a],'t',env)()
	end
	local fn_ln = load("return function ( v ) return math.sqrt(v[1]*v[1]"..lss..") \nend","vec"..vts..":lenght",'t',env)()
	local fn_i -- TODO: compress code
	return {
		__add = fn_a[1],
		__sub = fn_a[2],
		__mul = fn_a[3],
		__div = fn_a[4], --it doesnt have multiply optimization
		__tostring = load("return function ( v ) return '<'..v[1].."..tss.."'>' end","vec"..vts..":tostring",'t',env)(),
		__index = fn_i,
		__pairs = function (v)
			local i, value, key
			return function()
				i, value = next(v, i)
				if i then
					key = ast:sub(i,i)
					return key, value
				else
					return
				end
			end
		end,
		_type = "vec"..vts,--compatability with Matrix.lua
		dot = function (a, b)
			local m = a*b
			return m[1] + m[2]
		end,
		length = fn_ln,
		normalize = function (v)
			local dl = 1/fn_ln(v)
			return v*dl
		end
	}
end

for i=1,3 do
	vmt[i] = vecgenmt(i+1)
end

vmt[2].cross = function (a, b) return vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x) end

vmt[1].__index = function (t, k)
	if type(k) == "string" then
		local vt = {}
		if #k > 4 then error("Invalid vector type"..tostring(#k),2) end
		for i = 1, #k do
			local c = k:sub(i,i)
			vt[i] = rawget(t,('x' == c) and 1 or 2)
		end
		
		return vecconv[#vt](vt)
	elseif type(k) == "number" then
		return rawget(t,k)
	else
		error("invalid index type",2)
	end
end

vmt[2].__index = function (t, k)
	if type(k) == "string" then
		local vt = {}
		if #k > 4 then error("Invalid vector type"..tostring(#k),2) end
		local ds = {x=1, y=2, z=3}
		for i = 1, #k do
			local c = k:sub(i,i)
			vt[i] = rawget(t,ds[c])
		end
		return vecconv[#vt](vt)
	elseif type(k) == "number" then
		return rawget(t,k)
	else
		error("invalid index type",2)
	end
end

vmt[3].__index = function (t, k)
	if type(k) == "string" then
		local vt = {}
		if #k > 4 then error("Invalid vector type"..tostring(#k),2) end
		local ds = {x=1, y=2, z=3, w=4}
		for i = 1, #k do
			local c = k:sub(i,i)
			vt[i] = rawget(t,ds[c])
		end
		return vecconv[#vt](vt)
	elseif type(k) == "number" then
		return rawget(t,k)
	else
		error("invalid index type",2)
	end
end

return lib