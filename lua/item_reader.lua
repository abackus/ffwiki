-- <nowiki>
local p = {}
local getArgs = require('Dev:Arguments').getArgs
local disciplineIcons = mw.loadData('Module:Icon/data/FFXIV/Discipline')

local DATA_DIRECTORY = "Module:XIVAPI/Item/"
local ICON_DATA_DIRECTORY = "Module:XIVAPI/Item Icon/"

local PLACEHOLDER_ICON = "Image Placeholder.png|128px"

local EMPTY_ITEM = {
	["Name"] = "",
	["ID"] = 0,
	["IconID"] = 0,
	["Link"] = "Final Fantasy XIV items"
}

local function subdir(name)
   -- Return the three-character subdirectory for the item
   if #name >= 3 then
      return name:sub(1, 3):lower()
   else
      return "*"
   end
end

local function lookup_item(name)
   -- Return the data table for the item
   local b, v = pcall(mw.loadData, DATA_DIRECTORY .. subdir(name))
   return (b and v[name]) or EMPTY_ITEM
end

local function lookup_item_icon(id)
   -- Return the data table for the item icon
   if (id == 0) then return PLACEHOLDER_ICON end
   local b, v = pcall(mw.loadData, DATA_DIRECTORY .. subdir(tostring(id)))
   return (b and v) or PLACEHOLDER_ICON
end

local function create_li(str)
   -- Return an <li> object with wikitext the string
   return mw.html.create('li'):wikitext(str)
end

local function create_class_icon(class)
   -- Return an image and link to a class
   -- Takes in the name of the class
   class = disciplineIcons[class]
   return "[[File:" .. class.file .. "|" .. class.name .. "|link=" .. class.link .. "|20px]]"
end

local function create_item_icon(item, px)
	-- Return an item icon, takes in an item table.
	item = item or EMPTY_ITEM
	if px then 
		return "[[File:" .. lookup_item_icon(item.IconID) .. "|" .. item.Name .. "|link=" .. item.Link .. "|" .. tostring(px) .. "px]]"
	else
		return "[[File:" .. lookup_item_icon(item.IconID) .. "|" .. item.Name .. "|link=" .. item.Link .. "]]"
	end
end

local function create_trs(item)
   -- Return a list of <tr> objects for an item
   local tr = {}

   tr[1] = mw.html.create('tr')
   tr[2] = mw.html.create('tr')

   -- Left cell
   local name_cell_wt = (item.Name or "")
   if not (item.IconID == 0) then
      name_cell_wt = name_cell_wt .. "[[File:" .. lookup_item_icon(item.IconID) .. "]]"
   end
   
   -- Item type row
   local type_cell = mw.html.create('th'):
      wikitext((item.ItemKind or "&mdash;") .. " (" .. (item.ItemUICategory or "&mdash;") .. ")")
   
   -- Level row      
   local level_cell = mw.html.create('ul')
   if item.LevelEquip or item.ClassJobCategory then
      -- item.ClassJobCategory should be formatted as {'arcanist', etc.}
      local s = "Equip to: "
      for _, class in ipairs(item.ClassJobCategory or {}) do
	 s = s .. create_class_icon(class)
      end
      s = s .. " " .. tostring(item.LevelEquip or 0)
      level_cell:node(create_li(s))
   end
   level_cell:node(create_li("Item level: " ..
			     tostring(item.LevelItem or 0)))
   level_cell:node(create_li("Stack size: " ..
			     tostring(item.StackSize or 0)))
   level_cell:node(create_li("ID: " .. tostring(item.ID or 0)))

   
   -- Stats row
   local stats_cell = mw.html.create('ul')
   if item.Block then
      stats_cell:node(create_li("Block strength: " .. tostring(item.Block)))
   end
   if item.BlockRate then
      stats_cell:node(create_li("Block rate: " .. tostring(item.BlockRate)))
   end
   if item.DamagePhys then
      stats_cell:node(create_li("Physical damage: " .. tostring(item.DamagePhys)))
   end
   if item.DamageMag then
      stats_cell:node(create_li("Magic damage: " .. tostring(item.DamageMag)))
   end
   if item.DefensePhys then
      stats_cell:node(create_li("Physical defense: " .. tostring(item.DefensePhys)))
   end
   if item.DefenseMag then
      stats_cell:node(create_li("Magic defense: " .. tostring(item.DefenseMag)))
   end
   if item.DelayMs then
      stats_cell:node(create_li("Attack delay: " .. tostring(item.DelayMs) .. " ms"))
   end
   if item.CooldownS then
      stats_cell:node(create_li("Cooldown: " .. tostring(item.CooldownS) .. " s"))
   end
   
	 

   -- Repair row
   local repair_cell = mw.html.create('ul')
   if item.ClassJobRepair then
      repair_cell:node(create_li("Repair job: " ..
				 create_class_icon(item.ClassJobRepair)))
   end
   if item.ItemRepair then
      repair_cell:node(create_li("Repair catalyst: " ..
				 create_item_icon(lookup_item(item.ItemRepair), 20)))
   end
   if item.ItemGlamour then
      repair_cell:node(create_li("Glamour prism: " ..
				 create_item_icon(lookup_item(item.ItemGlamour), 20)))
   end
   if item.MateriaSlotCount then
      local s = "Materia slots: " .. tostring(item.MateriaSlotCount)
      if item.IsAdvancedMeldingPermitted then
	 s = s .. " (can overmeld)"
      end
      repair_cell:node(create_li(s))
   end
   
   if not (tostring(repair_cell) == "<ul></ul>") then
      table.insert(tr, mw.html.create('tr'):
		   tag('td'):
		   tag('div'):
		   attr('class', 'columns'):
		   node(repair_cell):
		   allDone())
   end

   -- Materia row
   if item.Materia then
      table.insert(tr, mw.html.create('tr'):
		   tag('td'):
		   wikitext('Modifies ' .. item.Materia.BaseParam .. ' by ' .. tostring(item.Materia.Value)):
		   allDone())
   end
   
   -- TODO: Recipe rows

   local descr_string = (item.Description and (item.Description .. "<br/>")) or ""
   if item.IsDyeable then
      descr_string = descr_string .. "Is dyeable. "
   end
   if item.AetherialReduce then
      descr_string = descr_string .. "Can be aetherially reduced. "
   end
   if item.Desynth then
      descr_string = descr_string .. "Can be desynthesized. "
   end
   if item.EquipRestriction then
      descr_string = descr_string .. "Gender/race locked. "
   end
   if item.ItemAction then
      descr_string = descr_string .. "Can be used. "
   end
   if item.CanBeHq then
      descr_string = descr_string .. "Can be made HQ. "
   end
   if item.IsCollectable then
      descr_string = descr_string .. "Collectable. "
   end
   if item.IsUnique then
      descr_string = descr_string .. "Unique. "
   end
   if item.IsUntradable then
      descr_string = descr_string .. "Untradable. "
   end
   if item.IsCrestWorthy then
      descr_string = descr_string .. "Can be given FC crest. "
   end
   if item.IsIndisposable then
      descr_string = descr_string .. "Cannot be discarded. "
   end
   if item.AlwaysCollectable then
      descr_string = descr_string .. "Can be crafted as a collectable. "
   end
   if item.ItemSeries then
      descr_string = descr_string .. "Part of the " .. item.ItemSeries .. " collection. "
   end
   if item.GrandCompany then
      descr_string = descr_string .. item.GrandCompany .. " uniform."
   end
   if not (descr_string == "") then
      table.insert(tr, mw.html.create('tr'):
		   tag('td'):
		   wikitext(descr_string):
		   done())
   end
   
   tr[1]:tag('th'):
      wikitext(name_cell_wt):
      attr('rowspan', #tr):
      done():
      node(type_cell)
   tr[2]:tag('td'):
      tag('div'):
      attr('class', 'columns'):
      node(level_cell)
   
   return tr
end

local function table_header()
   -- Return a basic table header
   return mw.html.create('table'):
      attr('class', 'full-width article-table ffxiv-item-table'):
      tag('tr'):
      tag('th'):
      attr('style', 'width:128px;'):
      wikitext('Item'):
      done():
      tag('th'):
      wikitext('Description'):
      allDone()
end

function p.Test()
   item = {}
   item.Name = "Big Big Weapon"
   item.Link = "Project:Sandsea"
   item.ClassJobCategory = {"arcanist", "scholar"}
   item.LevelEquip = 6
   item.LevelItem = 4
   item.ItemRepair = "grade 5 dark matter"
   item.IsIndisposable = 1
   item.IconID = 10000
   item.ClassJobRepair = "weaver"
   item.Description = "A big weapon."
   item.IsCrestWorthy = 1
   item.MateriaSlotCount = 2
   item.ItemKind = "Medicines & Meals"
   item.ItemUICategory = "Gladiator's Arm"
   item.IsAdvancedMeldingPermitted = 1
   item.AlwaysCollectable = 1
   local t = table_header()
   local trs = create_trs(item)
   for i, tr in ipairs(trs) do
      t:node(tr)
   end
   return t
end

return p
