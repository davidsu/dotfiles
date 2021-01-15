local isModuleAvailable = require 'utils'.isModuleAvailable
if not isModuleAvailable('galaxyline') then
  return
end

local gl = require('galaxyline')
local vcs = require('galaxyline.provider_vcs')
local fileinfo = require('galaxyline.provider_fileinfo')
local gls = gl.section
gl.short_line_list = {'fugitive'}

local colors = {
  bg = '#282c34',
  yellow = '#916d1d',
  cyan = '#008080',
  darkblue = '#081633',
  green = '#afd700',
  orange = '#965102',
  purple = '#413459',
  magenta = '#d16d9e',
  grey = '#c0c0c0',
  blue = '#044b75',
  red = '#96141a'
}

function islongstatus() return vim.api.nvim_get_var('shortstatusline') == 0 end
local buffer_not_empty = function()
  if vim.fn.empty(vim.fn.expand('%:t')) ~= 1 then
    return true
  end
  return false
end

local leftSeparator = ''

function modeColor()
    local alias = {
        R  = 'REPLACE',
        Rv = 'VIRTUAL',
        S  = 'SELECT',
        V= 'VISUAL',
        [''] = 'SELECT',
        [''] = 'VISUAL',
        ['!']  = 'SHELL',
        ['r']  = 'HIT-ENTER',
        ['r?'] = ':CONFIRM',
        c= 'COMMAND',
        fzf = 'FZF',
        nvimtree = 'NvimTree',
        i = 'INSERT',
        modified = 'MODIFIED',
        n = 'NORMAL',
        rm = '--MORE',
        s  = 'SELECT',
        t  = 'TERMINAL',
        v ='VISUAL',
    }
    local mode = vim.fn.mode()
    local color = colors.yellow
    local modified = vim.fn.getbufvar('.', '&mod') == 1
    if modified then
        color = colors.red
        mode = 'modified'
    end
    if vim.fn.match(vim.fn.expand('%:t'), 'FZF$') ~= -1 then
        mode = 'fzf'
    end
    if vim.bo.filetype == 'NvimTree' then
      mode = 'nvimtree'
    end

    return {
        text = alias[mode] or '',
        color = color
    }

end

local ViMode = {
  provider = function()
    local vars = modeColor()
    local text = vars.text
    local color = vars.color

    if #text == 0 then text= vim.fn.substitute(vim.fn.expand('%:t'), '\\A', '', 'g') end
    local surround = (' '):rep(math.floor((12 - #text) / 2))
    text = surround .. text .. surround
    text = (' '):rep(12 - #text) .. text
    if color then
        vim.api.nvim_command('hi GalaxyViMode guibg='..color)
    end
    return text
  end,
  condition = islongstatus,
  highlight = {colors.darkblue,colors.yellow,'bold'},
}

local ViModeSeparator = {
    provider = function() 
        local vars = modeColor()
        local text = vars.text
        local color = vars.color
        vim.api.nvim_command('hi GalaxyViModeSeparator guibg='..colors.purple..' guifg='..color)
        return leftSeparator
    end,
    condition = islongstatus,
    highlight = {colors.yellow,colors.purple},
}

function gitContition() 
  return buffer_not_empty() and
    islongstatus() and
    vcs.get_git_branch() and
    vim.bo.filetype ~= 'NvimTree'
end

local GitIcon = { 
  provider = function() if(vcs.get_git_branch()) then return '   ' end return '' end,
  condition = gitContition,
  highlight = {colors.orange,colors.purple}
}
local GitBranch = { provider = 'GitBranch', condition = gitContition, highlight = {colors.grey,colors.purple} }
local GitSeparator = { provider = function() return '' end, separator =  leftSeparator, separator_highlight = {colors.purple,colors.darkblue} }

RelativeFilePath = {
  provider = function()
    local filepath = vim.fn.expand('%:p')
    if #filepath > 200 and vim.fn.match(filepath, 'FZF$') then
        return ''
    end
    if vim.bo.filetype == 'NvimTree' then
      return ''
    end

    if string.match(filepath, '^term://') then
      return ' ' .. vim.fn.expand('%:t')
    end
    local cwd = vim.fn.getcwd()
    return ' ' .. string.sub(filepath, string.len(cwd) + 2) .. ' '
  end,
  separator = leftSeparator,
  separator_highlight = {colors.darkblue,colors.bg},
  highlight = {colors.magenta,colors.darkblue}
}

local End = { condition = buffer_not_empty, provider = function() return ' ' end, highlight = { colors.bg, colors.bg } }

gls.left = {
  { ViMode = ViMode },
  { ViModeSeparator = ViModeSeparator },
  { GitIcon= GitIcon },
  { GitBranch= GitBranch },
  { GitSeparator = GitSeparator  },
  { RelativeFilePath = RelativeFilePath },
  { End= End },
}

local rightSeparator = ''
local FileType = { 
  provider = function() return vim.bo.filetype .. '   ' end,
  condition = function() return buffer_not_empty() and vim.bo.filetype ~= 'NvimTree' end,
  highlight = {colors.white,colors.bg}, 
}
function cwdCondition()
  return islongstatus() and 
    vim.bo.filetype ~= 'fzf' and
    vim.bo.filetype ~= 'NvimTree'
end
local Cwd = {
  provider = function()
    local cwd = vim.fn.getcwd()
    local withoutHome = vim.fn.substitute(cwd, os.getenv('HOME') .. '/', '', '')
    withoutHome = vim.fn.substitute(withoutHome, 'projects/', '', '')
    if string.find(withoutHome, 'nvim/startup') then
      return ' NVIM/STARTUP ' 
    elseif string.find(withoutHome, 'nvim/lua') then
      return ' NVIM/LUA '
    end
    return ' ' .. withoutHome .. ' '
  end,
  condition = cwdCondition,
  highlight = {colors.magenta,colors.darkblue}
}
local cwdSeparator = {
  provider = function() return '' end,
  separator = rightSeparator,
  separator_highlight = {colors.darkblue,colors.bg},
  condition = islongstatus,
}
local LineSeparator = { 
  provider = function() return ' ' end,
  condition = islongstatus,
  separator = rightSeparator,
  separator_highlight = {colors.purple,colors.darkblue},
  highlight = {colors.purple,colors.purple}
}
local LineInfo = { 
  provider = function()
    if vim.bo.filetype == 'NvimTree' then
      return ''
    end
    return ' ' .. fileinfo.line_column() .. ' ' 
  end,
  highlight = {colors.grey,colors.purple}, }
local PerCent = { provider = 'LinePercent', separator = rightSeparator, separator_highlight = {colors.yellow,colors.purple}, highlight = {colors.darkblue,colors.yellow}, }

gls.right = {
  {FileType = FileType},
  {cwdSeparator = cwdSeparator},
  {Cwd = Cwd},
  {LineSeparator = LineSeparator},
  {LineInfo = LineInfo},
  {PerCent = PerCent},
}

gls.short_line_left[1] = {
  BufferType = {
    provider = 'FileName',
    separator = '',
    separator_highlight = {colors.purple,colors.bg},
    highlight = {colors.grey,colors.purple}
  }
}
