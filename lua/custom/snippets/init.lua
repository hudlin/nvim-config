local ls = require("luasnip")
-- some shorthands...
local s = ls.snippet
local sn = ls.snippet_node
local t = ls.text_node
local i = ls.insert_node
local f = ls.function_node
local c = ls.choice_node
local d = ls.dynamic_node
local r = ls.restore_node
local l = require("luasnip.extras").lambda
local rep = require("luasnip.extras").rep
local p = require("luasnip.extras").partial
local m = require("luasnip.extras").match
local n = require("luasnip.extras").nonempty
local dl = require("luasnip.extras").dynamic_lambda
local fmt = require("luasnip.extras.fmt").fmt
local fmta = require("luasnip.extras.fmt").fmta
local types = require("luasnip.util.types")
local conds = require("luasnip.extras.conditions")
local conds_expand = require("luasnip.extras.conditions.expand")

local tsutils = require("nvim-treesitter.ts_utils")

local function get_go_return_args()
  local list = {
    t("err"),
    sn(nil, {
      i(1, "nil"),
      t(", "),
      i(2, "err"),
    }),
  }

  local cnode = tsutils.get_node_at_cursor()

  while (cnode ~= nil and cnode:type() ~= "function_declaration" and cnode:type() ~= "method_declaration")
  do
    cnode = cnode:parent()
  end

  local result_types = {}

  if cnode ~= nil then
    local result = vim.treesitter.query.parse('go', [[
      (function_declaration
        result: (parameter_list
          (parameter_declaration
            type: (type_identifier)+ @foo)))
    ]])

    local bufnr = vim.api.nvim_get_current_buf()

    for _, node, _ in result:iter_captures(cnode, bufnr, cnode:start(), cnode:end_()) do
      local node_text = vim.treesitter.get_node_text(node, bufnr, nil)
      table.insert(result_types, node_text)
    end
  end

  if #result_types == 1 and result_types[1] == "error" then
    return sn(nil, c(1, list))
  end

  if #result_types > 0 then
    local snips = {}

    for k, v in ipairs(result_types) do
      if k > 1 then
        table.insert(snips, t(", "))
      end

      if v == "error" then
        table.insert(snips, i(k, "err"))
      else
        table.insert(snips, i(k, v .. "{}"))
      end
    end

    table.insert(list, sn(3, snips))
  end

  return sn(nil, c(1, list))
end

ls.add_snippets("go", {
  s("iferr", {
    t({"if err != nil {", "\treturn "}),
    d(1, get_go_return_args),
    t({"", "}"}),
  }),
})


