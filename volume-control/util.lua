local util = {}

function util.readcommand(command)
	local file = io.popen(command)
	if file == nil then
		print("volume-control: Failed to execute command: " .. command)
		return nil
	end
	local text = file:read("*all")
	file:close()
	return text
end

local function quote_arg(str)
	return "'" .. string.gsub(str, "'", "'\\''") .. "'"
end

local function table_map(func, tab)
	local result = {}
	for i, v in ipairs(tab) do
		result[i] = func(v)
	end
	return result
end

function util.make_argv(args)
	return table.concat(table_map(quote_arg, args), " ")
end

local function new(self, ...)
	local instance = setmetatable({}, { __index = self })
	return instance:init(...) or instance
end

function util.class(base)
	return setmetatable({ new = new }, {
		__call = new,
		__index = base,
	})
end
return util
