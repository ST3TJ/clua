require 'libs.global'

local files = require 'libs.files'
local lexer = require 'libs.lexer'
local vm = require 'libs.vm'

local code = files.read('code.lasm')

if not code then
    return
end

vm.load(code)
vm.run()
