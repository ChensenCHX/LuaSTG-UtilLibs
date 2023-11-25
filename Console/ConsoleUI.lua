function Print(...)
    local args = { ... }
    print(">>MyCon \n" .. table.concat(args))
end

---------------------------------------------

local hmt = {
    __index = function()
        Print("No such command. Try using --help command.\n")
    end
}

local HelpList = setmetatable({
    ["help"] = [[
        A helper for this console application.
        Receive 0~1 arguments.
        
        --help
            -> return command list.
        --help [CommandName]
            -> return [CommandName]'s help message.
    ]],

    ["exit"] = [[
        Exit this program by callin ISO C function exit().
        (with default success return value.)
        Receive no argument.
    ]],

    ["clear"] = [[
        Clear all of outputs before this command.
        Receive no argument.
    ]]
}, hmt)
---------------------------------------------

local cmt = {
    __index = function()
        Print("No such command. Try using --help command.\n")
        return function(...) end
    end
}

CommandArgs = setmetatable({
    ["help"] = function(...)
        local args = { ... }
        if #args > 1 then
            Print("Too many arguments. Help could only receive one argument maximum.\n")
            return
        end

        if #args == 1 then
            Print(HelpList[args[1]])
        else
            Print("Available command list: ")
            for k, v in pairs(CommandArgs) do
                print("--" .. k .. ", ")
            end
            print("using --help [name] for more infomation.\n")
        end
    end,

    ["exit"] = function()
        os.exit()
    end,

    ["clear"] = function()
        os.execute("cls")
    end
}, cmt)

---------------------------------------------

function main()
    print(">>MyCon  ")
    GlobalArgs = io.read("*l")
    print("\n")
    for str in string.gmatch(GlobalArgs, "%-+[^%-]+") do
        local args = {}
        for str_arg in string.gmatch(str, "[^ %-]+") do
            table.insert(args, str_arg)
        end

        local carg = args[1]
        table.remove(args, 1)

        CommandArgs[carg](unpack(args))
    end

end

while true do
    main()
end