local vmt = {}
local vpd = {}
local errc = {
	function (d) if type(d) ~= "number" then error("glmvec: expected number or table with numbers",2) end end,
	function (d,i) if #d>i then error("glmvec: too many arguments",2) end end,
}
local errlib = function(c,...)
	errc[c](...)
end

local loadvars = function(t,m)
	for i,e in pairs(m) do
		t[i]=e
	end
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
	loadvars(v,vpd[1])
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
--				error("glmvec: argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
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
				error("glmvec: argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
			end
		end
	end
	if #v == 1 then
		v = {v[1],v[1],v[1]}
	end
	loadvars(v,vpd[2])
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
				error("glmvec: argument missmatch v:\n"..errstr.."\ninput:\n"..in_str,2)
		end
	end
	if #v == 1 then
		v = {v[1],v[1],v[1],v[1]}
	end
	loadvars(v,vpd[3])
	return setmetatable(v,vmt[3])
end
local function pass(x) return x[1] end
local lib = {vec2=vec2, vec3=vec3, vec4=vec4}
local env = {vec2=vec2, vec3=vec3, vec4=vec4, type=type, rawset=rawset, rawget=rawget, math=math, pass=pass, ipairs=ipairs}
local ops = "+-*/"
local ast = "xyzw"
local cst = "rgba"

local nmt = debug.getmetatable(0) or {}
local mpn = {"__add","__sub","__mul","__div"}
for a=1,4 do
	local ac = ops:sub(a,a)
	nmt[mpn[a]] = load("local vecconv={pass,vec2,vec3,vec4};return function(a,b)if type(b)=='table'then local v=vecconv[#b](b);for i,e in ipairs(b) do rawset(v,i,a"..ac.."e) end return b else return a"..ac.."b end end"
	,"numvec:"..mpn[a],'t',env)()
end
debug.setmetatable(0, nmt)

local vecgenmt = function (vt)
	local vc = "a[1] %s c[1]"
	local vts = tostring(vt)
	local tss = ""
	local lss = ""
	local iss = ""
	for i=2,vt do
		local s = tostring(i)
		vc = vc..",a["..s.."] %s c["..s.."]"
		tss = tss.."','..v["..s.."].."
		lss = lss.."+v["..s.."]*v["..s.."]"
		iss = iss..string.format(",%s=%s,%s=%s",ast:sub(i,i),s,cst:sub(i,i),s)
	end
	local fbs = string.format("return function(a,b)local c = vec%s(b);return vec%s(%s)end", vts,vts,vc)
	local fn_a = {}
	for a=1,4 do
		local ac = ops:sub(a,a)
		--trace(string.format(fbs,ac,ac,ac,ac))
		fn_a[a] = load(string.format(fbs,ac,ac,ac,ac),"vec"..vts..":"..mpn[a],'t',env)()
	end
	local fn_ln = load("return function(v)return math.sqrt(v[1]*v[1]"..lss..")end","vec"..vts..":lenght",'t',env)()
	local fn_i = load("local vecconv={pass, vec2, vec3, vec4};return function(t,k)if type(k)=='string'then local vt={}if#k>4then error('glmvec: Invalid vector type'..tostring(#k),2)end local ds={x=1,r=1"..iss.."}for i=1,#k do local c=k:sub(i,i);vt[i]=rawget(t,ds[c])end return vecconv[#vt](vt)elseif type(k)=='number'then return rawget(t,k)else error('glmvec: invalid index type',2)end end"
	,"vec"..vts..":__index",'t',env)()
	local fn_ni = load("return function(t,k,v)if type(k)=='string'then if(#k<="..vts..")then local ds={x=1,r=1"..iss.."}if type(v)=='table'then if(#k==#v)then for i=1,#k do local c=k:sub(i,i);rawset(t,ds[c],v[i])end else error('glmvec: data length missmatch',2)end elseif type(v)=='number'then for i=1,#k do local c=k:sub(i,i);rawset(t,ds[c],v)end end else error('glmvec: invalid type',2)end elseif type(k)=='number'then rawset(t,k,v)else error('glmvec: invalid index type',2)end end"
	,"vec"..vts..":__newindex",'t',env)()
	return {
		__add = fn_a[1],
		__sub = fn_a[2],
		__mul = fn_a[3],
		__div = fn_a[4], --it doesnt have multiply optimization
		__tostring = load("return function(v)return '<'..v[1].."..tss.."'>' end","vec"..vts..":tostring",'t',env)(),
		__index = fn_i,
		__newindex = fn_ni,
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
		__ipairs = function (v)
			local i = 0
			return function()
				i = i + 1
				local value = rawget(v,i)
				if value then
					return i, value
				else
					return
				end
			end
		end
	}, {
		_class = "vec",
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
	vmt[i], vpd[i] = vecgenmt(i+1)
end

vpd[2].cross = function (a, b) return vec3(a.y*b.z - a.z*b.y, a.z*b.x - a.x*b.z, a.x*b.y - a.y*b.x) end

return lib--TODO: error and type checking