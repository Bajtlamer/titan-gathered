-- **************************************************************************
-- * $Id: TitanGathered.lua 38 2012-09-08 16:49:42Z bajtlamer@gmail.com $
-- **************************************************************************
-- * by Medyn @ Radek Roza / Czech Rep.
-- * An addon for World of Warcraft that track materials and tradeitems
-- * in bank and bag and shows all count information in Titan panel tooltip.
-- *
-- * Credits: Please post bug to bajt@volny.cz
-- *          look to www.rrsoft.cz/titan-gathered.html for new update and releases.
-- **************************************************************************

-- ******************************** Constants *******************************
TITAN_ORE_ID = "Ore";
TITAN_ORE_PLAYER_CLASS = "";
local p, TITAN_ORE_PLAYER_CLASS = UnitClass("player");

TitanGathered = {}
-- Reduce the chance of functions and variables colliding with another addon.
local TG = TitanGathered
local infoBoardData = {}

TG.id = "Gathered";
TG.addon = "TitanGathered";
TG.email = "bajtlamer@gmail.com";
TG.www = "www.rrsoft.cz";
TG.boardCount = 5;
TG.showZero = 0;


--  Get data from the TOC file.
TG.version = tostring(GetAddOnMetadata(TG.addon, "Version")) or "Unknown"
TG.author = GetAddOnMetadata(TG.addon, "Author") or "Unknown"

-- Create about popup info text.
TG.about = TitanUtils_GetGreenText("Titan Panel [Gathered]")..
	TitanUtils_GetHighlightText(" By ")..TitanUtils_GetNormalText(TG.author).."\n"..
	TitanUtils_GetNormalText("Version: ")..TitanUtils_GetHighlightText(TG.version).."\n"..
	TitanUtils_GetNormalText("email: ")..TitanUtils_GetHighlightText(TG.email).." - "..
	TitanUtils_GetHighlightText(TG.www);

-- **************************************************************************
-- NAME : TitanGatheredButton_OnLoad()
-- DESC : Registers the add on upon it loading
-- **************************************************************************
function TG.Button_OnLoad(self)
	local tooltipAboutText;

    local function TitanGathered_SlashCommand(msg)
      local cmd,var = strsplit(' ', msg or "")
      if cmd then
        TitanGathered_addLootItem(cmd);
      elseif cmd == "reset" then
        TgFocusFrame_Reset();
      else
        TitanGathered_PrintInfo();
      end
    end


	SLASH_TOHISTORY1 = "/tgh"
	SLASH_TPHISTORY2 = "/tghistory"
	SlashCmdList["TOHISTORY"] = function(msg) TitanGathered_ShowHistory() end

	SLASH_TGRELOAD1 = "/tgreload"
    SlashCmdList["TGRELOAD"] = function(msg) ReloadUI() end

	SLASH_TOBANK1 = "/tgb"
	SLASH_TOBANK2 = "/tgbank"
	SlashCmdList["TOBANK"] = function(msg) TitanGathered_ShowBank() end

	echo(TG.addon.." ("..TITAN_ORE_GREEN..TG.version.."|cffff8020) loaded! Created By "..TG.author);

	tooltipAboutText = "|cffff8020"..TG.id.." "..TitanUtils_GetGreenText(TG.version).."\n";

	self.registry = {
		id = TG.id,
		version = TG.version,
		menuText = TG.id,
		buttonTextFunction = "TitanGatheredButton_GetButtonText",
		tooltipTitle = tooltipAboutText,
		category = "Information",
    	tooltipTextFunction = "TitanGatheredButton_GetTooltipText",
		icon = "Interface\\Addons\\TitanGathered\\Artwork\\TitanOre",
		iconWidth = 16,
		updateType = TITAN_PANEL_UPDATE_TOOLTIP,
		savedVariables = {
			ShowIcon = 1,
			ShowLabelText = 1,
			ShowColoredText = 1,
			ShowInfoTooltip = 1,
			ShowZerro = 1,
			ShowBankItems = 1,
			ExcludeZero = 1,
			ShowSkills = 1,
			ShowSecSkills = 1,
			ShowOre = 1,
			ShowBar = 1,
			ShowStone = 1,
			ShowGem = 1,
			ShowLeather = 1,
			ShowScale = 1,
			ShowHide = 1,
			ShowCloth = 1,
			ShowHerb = 1,
			ShowEssence = 1,
			ShowMisc = 1,
			ShowPmat = 1,
			ShowPoison = 1,
			ShowBandage = 1,
			ShowInscriptInk = 1,
			ShowInscriptPigment = 1,
			ShowCooking = 1,
			Debugmode = 1,
			displayitems = {},
			itemsHistory = {},
			bankHistory = {},
			clearItems = {},
		}
	};
		self:RegisterEvent("PLAYER_ENTERING_WORLD");
		self:RegisterEvent("PLAYER_LEAVING_WORLD");
		self:RegisterEvent("LOOT_OPENED");
		self:RegisterEvent("BANKFRAME_OPENED");
		self:RegisterEvent("BANKFRAME_CLOSED");

end

-- Button
function TitanGatheredButton_GetButtonText(self)

	local txtTitanTitle = " ";

	return TG.id, txtTitanTitle;
end

-- Tooltip
function TitanGatheredButton_GetTooltipText(self)
	local tooltipText = "";

	local i,e,cat,short,v_count;
	local val=0;

	local p, playerClass = UnitClass("player");

	local nextText="";

	local v_color=TITAN_ORE_GOLD;
	local prof_1, prof_2, archaeology, fishing, cooking, firstaid = GetProfessions();

	local nextText="";
	local val  = 1;
	local prof = 0;

-- TWO PRIMARY SKILLS
	if ( not TitanGetVar(TG.id, "ShowSkills")) then

		if (prof_1) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(prof_1);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
	   end
		if (prof_2) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(prof_2);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
		end

		if (val == 1) then
			tooltipText = tooltipText.."\n";
			tooltipText = tooltipText..TitanUtils_GetHighlightText(TITAN_ORE_LOCAL_PROFESSIONS.."\n");
			tooltipText = tooltipText..nextText;
		end
	end

	local nextText="";
	local val  = 1;
	local prof = 0;

-- SECONDARY SKILLS
	if ( not TitanGetVar(TG.id, "ShowSecSkills")) then

		if (archaeology) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(archaeology);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
		end
		if (fishing) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(fishing);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
	   end
		if (cooking) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(cooking);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
		end
		if (firstaid) then
			local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(firstaid);
			v_color = TitanGathered_GetSkillRankColor(skillrank,skillmax);
	    	nextText = nextText..v_color..skillName..":\t"..skillrank..TitanUtils_GetHighlightText(" of ")..skillmax.."\n";
		end

		if (val == 1) then
			tooltipText = tooltipText.."\n";
			tooltipText = tooltipText..TitanUtils_GetHighlightText(TITAN_ORE_LOCAL_SEC_PROFESSIONS.."\n");
			tooltipText = tooltipText..nextText;
		end
	end

	local nextText="";
	val=0;


for i,c in pairs(TITAN_ORE_CATEGORIES) do
	local nextText="";
	val=0;

	if (not TitanGetVar(TG.id, c.save)) then
		for i,e in pairs(TITAN_ORE_ITEMS) do

			if(e.cat == c.name) then

				v_count = TitanGathered_CountItem(e.tag);
				b_count = TitanGathered_CountItemStoredInBank(e.tag);
				--v_color = TitanGathered_GetSkilColor(e.skill,skills[c.skillneed]);

				if ( TitanGetVar(TG.id, "ShowZerro")) then
					if (v_count > 0) then
						nextText = nextText..TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count);
						--table.insert(_data, TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count));
						val=1;
					elseif (b_count >0 and not TitanGetVar(TG.id, "ExcludeZero") and not TitanGetVar(TG.id, "ShowBankItems")) then
						nextText = nextText..TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count);
						--table.insert(_data, TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count));
						val=1;
					end
						--val=0;
					--end
				else
						nextText = nextText..TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count);
						--table.insert(_data, TitanGathered_ShowTooltipRow(v_color,e.name,v_count,b_count));
						val=1;
				end
			end
		end
	end

	if (val == 1) then
		tooltipText = tooltipText.."\n";
		tooltipText = tooltipText..TitanUtils_GetHighlightText(c.name.."\n");
		tooltipText = tooltipText..nextText;
	end


end


	return tooltipText;
end

-- Item count function
function TitanGathered_CountItem(item_id)
		local nbslots, b, s, t, n;
		local i_count = 0;

		for b=0,4 do
			nbslots=GetContainerNumSlots(b);
			for s=0,nbslots do
				local texture, itemCount = GetContainerItemInfo(b, s);

				t = GetContainerItemLink(b, s);

				if (t) then

					local bName = GetItemInfo(t);
					local sName = GetItemInfo(item_id);

					if(bName==sName) then
						i_count = i_count + itemCount;
					end
				end
			end
		end
		return i_count;
end

-- show tooltip row
function TitanGathered_ShowTooltipRow(v_color,e_name,v_count,b_count)
	local t_row = "";

	if ( not TitanGetVar(TG.id, "ShowBankItems")) then
		t_row = v_color..e_name..":\t"..v_count.."/"..b_count.."\n";
	else
		t_row = v_color..e_name..":\t"..v_count.."\n";
	end

	return t_row;
end

-- bank item count function
function TitanGathered_CountItemStoredInBank(item_id)

		local dbb = TitanGetVar(TG.id, "bankHistory");
		local nbslots, i, e;
		local i_count = 0;
		echo(TitanGetVar(TG.id, "ShowBankItems"));

	for i,e in pairs(dbb) do

		local _,_, color, id, name = string.find(e.name, "|c(%x+)|Hitem:(%d+):[%d:]+|h%[(.-)%]|h|r");

		if (type(e) == "table") then

			if (id == item_id) then
				i_count = i_count + e.value;
			end
		end
	end
		return i_count;
end

-- Event
function TG.Button_OnEvent(self, event)

	local message;

		if (event == "PLAYER_LEAVING_WORLD") then
			self:UnregisterEvent("BAG_UPDATE");
		end
		if (event == "PLAYER_ENTERING_WORLD") then
			self:RegisterEvent("BAG_UPDATE");
			self:RegisterEvent("LOOT_OPENED");
		end
		if (event == "LOOT_OPENED") then
			TitanGathered_loot();
		end
		if (event == "BANKFRAME_OPENED") then
			TitanGathered_bankOpen();
		end
		if (event == "BANKFRAME_CLOSED") then
			TitanGathered_bankClose();
		end
		if (event == "UPDATE_MOUSEOVER_UNIT") then
			PickingSkill_GameTooltip_SetLootItem();
		end
		TitanPanelButton_UpdateButton(TG.id);
		TG.showZero = TitanGetVar(TG.id, "ShowZerro");
		--TitanPanelGatheredInfoBoard_OnLoad(self);
end

-- Menu
function TitanPanelRightClickMenu_PrepareGatheredMenu(self)
	local info;
	local i,e,cat,fce,save;

	if ( L_UIDROPDOWNMENU_MENU_LEVEL == 2 ) then

		if ( L_UIDROPDOWNMENU_MENU_VALUE == TITAN_ORE_LOCAL_SHARDS ) then
			if (TITAN_ORE_PLAYER_CLASS == "WARLOCK") then
				for i,e in pairs(TITAN_ORE_ITEMS) do
					if(e.cat == TITAN_ORE_LOCAL_SHARDS) then
						info = {};
						info.text = e.name;
						info.value = i;
						info.func = TitanGathered_SetDisplay;
						info.checked = TitanGatheredButton_isdisp(i);
						info.keepShownOnClick = 1;
						L_UIDropDownMenu_AddButton(info,L_UIDROPDOWNMENU_MENU_LEVEL);
					end
				end
			end
		end


		if ( L_UIDROPDOWNMENU_MENU_VALUE == TITAN_ORE_LOCAL_BANK_ITEMS ) then
			info = {};
			info.text = TITAN_ORE_LOCAL_SHOW_BANK;
			info.func = TitanGatheredButton_ToggleShowBankItems;
			info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowBankItems"));
			info.keepShownOnClick = 1;
			L_UIDropDownMenu_AddButton(info,L_UIDROPDOWNMENU_MENU_LEVEL);
		end

		if ( L_UIDROPDOWNMENU_MENU_VALUE == TITAN_ORE_LOCAL_BANK_ITEMS ) then
			info = {};
			info.text = TITAN_ORE_LOCAL_EXCLUDE_ZERO;
			info.func = TitanGatheredButton_ToggleEcludeZero;
			info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ExcludeZero"));
			info.keepShownOnClick = 1;
			L_UIDropDownMenu_AddButton(info,L_UIDROPDOWNMENU_MENU_LEVEL);
		end

		if ( L_UIDROPDOWNMENU_MENU_VALUE == "DisplayAbout" ) then
			info = {};
			info.text = TG.about;
			info.value = "AboutTextPopUP";
			info.notClickable = 1;
			info.isTitle = 0;
			L_UIDropDownMenu_AddButton(info, L_UIDROPDOWNMENU_MENU_LEVEL);
		end

		return;
	end

	TitanPanelRightClickMenu_AddTitle(TitanPlugins[TG.id].menuText);

	-- Show Skills
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_SKILLS;
	info.func = TitanGatheredButton_ToggleShowSkills;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowSkills"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Secondary Skills
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_SEC_SKILLS;
	info.func = TitanGatheredButton_ToggleShowSecSkills;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowSecSkills"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Hidde zero option
	info = {};
	info.text = TITAN_ORE_LOCAL_HIDDE_ZERO;
	info.func = TitanGatheredButton_ToggleShowZerro;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowZerro"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Info Tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_TOOLTIP;
	info.func = TitanGatheredButton_ToggleShowInfoTooltip;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowInfoTooltip"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Debug mode
	info = {};
	info.text = TITAN_ORE_LOCAL_DEBUG_MODE;
	info.func = TitanGatheredButton_ToggleDebugmode;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "Debugmode"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- bank items
	info = {};
	info.text = TITAN_ORE_LOCAL_BANK_ITEMS;
	info.value = TITAN_ORE_LOCAL_BANK_ITEMS;
	info.hasArrow = 1;
	L_UIDropDownMenu_AddButton(info);

	TitanPanelRightClickMenu_AddSpacer();

	-- categories label
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_CATEGORIES;
	info.isTitle = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Ore in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_ORE;
	info.func = TitanGatheredButton_ToggleShowOre;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowOre"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Bar in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_BAR;
	info.func = TitanGatheredButton_ToggleShowBar;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowBar"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Stone in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_STONE;
	info.func = TitanGatheredButton_ToggleShowStone;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowStone"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Gem in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_GEM;
	info.func = TitanGatheredButton_ToggleShowGem;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowGem"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Leather in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_LEATHER;
	info.func = TitanGatheredButton_ToggleShowLeather;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowLeather"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Scales in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_SCALE;
	info.func = TitanGatheredButton_ToggleShowScale;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowScale"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Hide in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_HIDE;
	info.func = TitanGatheredButton_ToggleShowHide;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowHide"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Cloths in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_CLOTH;
	info.func = TitanGatheredButton_ToggleShowCloth;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowCloth"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Herbs in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_HERB;
	info.func = TitanGatheredButton_ToggleShowHerb;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowHerb"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Essence in tooltip
	TITAN_ORE_TOGGLE_SHOW = "ShowEssence";
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_ESSENCE;
	info.func = TitanGatheredButton_ToggleShowEssence;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowEssence"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Misc in tooltip
	TITAN_ORE_TOGGLE_SHOW = "ShowMisc";
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_MISC;
	info.func = TitanGatheredButton_ToggleShowMisc;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowMisc"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Inscriptions Inks in tooltip
	TITAN_ORE_TOGGLE_SHOW = "ShowInscriptInk";
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_INSC_INK;
	info.func = TitanGatheredButton_ToggleShowInscriptionsInk;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowInscriptInk"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Inscriptions Pigments in tooltip
	TITAN_ORE_TOGGLE_SHOW = "ShowInscriptPigment";
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_INSC_PIG;
	info.func = TitanGatheredButton_ToggleShowInscriptionsPigment;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowInscriptPigment"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	-- Show Cooking mats in tooltip
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_COOKING;
	info.func = TitanGatheredButton_ToggleShowCooking;
	info.checked = TitanUtils_Toggle(TitanGetVar(TG.id, "ShowCooking"));
	info.keepShownOnClick = 1;
	L_UIDropDownMenu_AddButton(info);

	TitanPanelRightClickMenu_AddSpacer();

	if (TITAN_ORE_PLAYER_CLASS == "WARLOCK") then
		-- Shards submenu
		info = {};
		info.text = TITAN_ORE_LOCAL_SHARDS;
		info.value = TITAN_ORE_LOCAL_SHARDS;
		info.hasArrow = 1;
		L_UIDropDownMenu_AddButton(info);
	end

	-- titan panel options
	info = {};
	info.text = TITAN_ORE_LOCAL_SHOW_TITAN_OPT;
	info.isTitle = 1;
	L_UIDropDownMenu_AddButton(info);

	TitanPanelRightClickMenu_AddToggleIcon(TG.id);
	TitanPanelRightClickMenu_AddToggleLabelText(TG.id);
	TitanPanelRightClickMenu_AddCommand(TITAN_PANEL_MENU_HIDE, TG.id, TITAN_PANEL_MENU_FUNC_HIDE);

	-- info about plugin
	info = {};
	info.text = TITAN_ORE_ABOUT_TEXT;
	info.value = "DisplayAbout";
	info.hasArrow = 1;
	L_UIDropDownMenu_AddButton(info);

end

function TitanGathered_SetDisplay(self)
	local db = TitanGetVar(TG.id, "displayitems");
	local i,d,found;
	if(self.value == 0) then
		TitanSetVar(TG.id, "displayitems", {});
	else
		found = 0;
		for i,d in pairs(db) do
			if(d == self.value)then
				found = i;
			end
		end
		if(found > 0) then
			table.remove(db,found)
		else
			while(table.getn(db)>80) do
				table.remove(db);
			end;
			table.insert(db,self.value);
		end
		TitanSetVar(TG.id, "displayitems", db);
	end;
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_isdisp(val)
	local disp = TitanGetVar(TG.id, "displayitems");
	local i,d;

	if(type(disp) ~= "table") then
		return 0;
	end

	for i,d in pairs(disp) do
		if(d==val) then
			return 1;
		end
	end
	return nil;
end

function TitanGatheredButton_ToggleShowInfoTooltip()
	TitanToggleVar(TG.id, "ShowInfoTooltip");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleDebugmode()
	TitanToggleVar(TG.id, "Debugmode");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleEcludeZero()
	TitanToggleVar(TG.id, "ExcludeZero");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowZerro()
	TitanToggleVar(TG.id, "ShowZerro");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowSkills()
	TitanToggleVar(TG.id, "ShowSkills");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowSecSkills()
	TitanToggleVar(TG.id, "ShowSecSkills");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowOre()
	TitanToggleVar(TG.id, "ShowOre");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowBar()
	TitanToggleVar(TG.id, "ShowBar");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowStone()
	TitanToggleVar(TG.id, "ShowStone");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowGem()
	TitanToggleVar(TG.id, "ShowGem");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowLeather()
	TitanToggleVar(TG.id, "ShowLeather");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowScale()
	TitanToggleVar(TG.id, "ShowScale");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowHide()
	TitanToggleVar(TG.id, "ShowHide");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowHerb()
	TitanToggleVar(TG.id, "ShowHerb");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowCloth()
	TitanToggleVar(TG.id, "ShowCloth");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowEssence()
	TitanToggleVar(TG.id, "ShowEssence");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowBankItems()
	TitanToggleVar(TG.id, "ShowBankItems");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowMisc()
	TitanToggleVar(TG.id, "ShowMisc");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowInscriptionsInk()
	TitanToggleVar(TG.id, "ShowInscriptInk");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowInscriptionsPigment()
	TitanToggleVar(TG.id, "ShowInscriptPigment");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGatheredButton_ToggleShowCooking()
	TitanToggleVar(TG.id, "ShowCooking");
	TitanPanelButton_UpdateButton(TG.id);
end

function TitanGathered_GetSkillLevel(skilltype)
    local numskills = GetNumSkillLines();
    for i=1,numskills do
        local skillname, _, _, skillrank,_,_,skillmax = GetSkillLineInfo(i);

        if (skillname == "Mining" and skilltype == "Mining") then
        	return skillrank;
		elseif (skillname == "Herbalism" and skilltype == "Herbalism") then
          	return skillrank;
		elseif (skillname == "Skinning" and skilltype == "Skinning") then
        	return skillrank;
		elseif (skillname == "Alchemy" and skilltype == "Alchemy") then
        	return skillrank;
		elseif (skillname == "Enchanting" and skilltype == "Enchanting") then
        	return skillrank;
		elseif (skillname == "First Aid" and skilltype == "First Aid") then
        	return skillrank;
		elseif (skillname == "Poisons" and skilltype == "Poisons") then
        	return skillrank;
		elseif (skillname == "Inscription" and skilltype == "Inscription") then
        	return skillrank;
		elseif (skillname == "Cooking" and skilltype == "Cooking") then
        	return skillrank;
        end
    end
    return 0;
end

function TitanGathered_GetSkillRankColor(skill,skillmax)

	local color = TITAN_ORE_RED;

	TITAN_SKILLS_PERCENT = floor( ( (skill) / skillmax ) * 100 );

	if ( TITAN_SKILLS_PERCENT > 49) then
		color = TITAN_ORE_ORANGE;
	end
	if ( TITAN_SKILLS_PERCENT > 74 ) then
		color = TITAN_ORE_YELLOW;
	end
	if ( TITAN_SKILLS_PERCENT > 94) then
		color = TITAN_ORE_GREEN;
	end

	return color;
end

function TitanGathered_GetSkilColor(skillreq,skill)

	local color = TITAN_ORE_RED;

	if (skillreq == -1) then
                return TITAN_ORE_GREY;
	end

	if ( not skill or skill == 0) then
		return TITAN_ORE_RED;
	end

	if (skillreq > skill) then
		color = TITAN_ORE_RED;
	else
		color = TITAN_ORE_ORANGE;

		if (skillreq + 74 < skill) then
			return TITAN_ORE_GREY;
		end

		if (skillreq + 49 < skill) then
			return TITAN_ORE_GREEN;
		end

		if (skillreq + 24 < skill) then
			return TITAN_ORE_YELLOW;
		end
	end

	return color;
end

-------------------------------------------------------
-- TitanGathered_loot
-- On event LOOT_OPENED will stored all looted items
-------------------------------------------------------

function TitanGathered_loot()

	for index = 1, GetNumLootItems(), 1 do
		if (LootSlotHasItem(index)) then
	    	local lootIcon, lootName, lootQuantity, lootQuality, locked, isQuestItem, questID, isActive = GetLootSlotInfo(index)
		    	local sName, sLink, iRarity, iLevel, iMinLevel, sType, sSubType, iStackCount = GetItemInfo(lootName);
		    	local xlink GetLootSlotLink(index);

				if (xlink ~= nil) then
					return;
				else
					TitanGathered_updateHistory(lootName, lootQuantity, sLink);
			end
	 	end
	end

end

-------------------------------------------------------
-- TitanGathered_bankOpen()
-- On event BANKFRAME_OPEN will cleared all data in db
-------------------------------------------------------
function TitanGathered_bankOpen()
	TITAN_ORE_EV = 0;
end

-------------------------------------------------------
-- TitanGathered_bankClose()
-- On event BANKFRAME_CLOSE will stored data to db
-------------------------------------------------------
function TitanGathered_bankClose()
if (TITAN_ORE_EV == 1) then
	return;
else


	local dbb = {};

	if GetNumBankSlots() then
		maxBslot, _ = GetNumBankSlots();
	else
		maxBslot = 0;
	end
		local nbslots, b, s, t, n, nn;
		local i_count = 0;

			nbanka=GetContainerNumSlots(-1);
			TitanGathered_PrintDebug("bank ------>");
			for s=0, nbanka do
				local texture, itemCount = GetContainerItemInfo(-1, s);
				iName = GetContainerItemLink(-1, s);
				if (iName) then
					nitem = { name = iName, value = itemCount };
					table.insert(dbb,nitem);
					TitanGathered_PrintDebug(iName.." added: "..itemCount.." stack.");
				end
			end

	if (maxBslot >0) then
			TitanGathered_PrintDebug("bags in bank ------>");
		for b=1, maxBslot, 1 do
			ibag = b+4;
			nbslots=GetContainerNumSlots(ibag);

			for s=1,nbslots do
				local texture, itemCount = GetContainerItemInfo(ibag, s);
				iName = GetContainerItemLink(ibag, s);
				if (iName) then
					nitem = { name = iName, value = itemCount };
					table.insert(dbb,nitem);
					TitanGathered_PrintDebug(iName.." added: "..itemCount.." stack.");
				end
			end
		end
	end

   TITAN_ORE_EV = 1;

	echo(TITAN_ORE_GREEN.."Titan Gathered: "..TITAN_ORE_YELLOW.."bank database updated..");
	TitanSetVar(TG.id, "bankHistory", dbb);
end
end

function TitanGathered_addNewClearItem(name)
	local cdb = TitanGetVar(TG.id, "clearItems");

	table.insert(cdb,name);
end
-------------------------------------------------------
-- TitaTitanGathered_updateHistory(item as string,iQuantity as number)
-- Update item history in database
-------------------------------------------------------
function TitanGathered_updateHistory(item,iQuantity,link)
	local db = TitanGetVar(TG.id, "itemsHistory");
	local i,d,v,r,found;
	local nitem = {};
	local fnd = 0;
	local fndSUM = 0;
	local fndH = 0;
    local fndBags = 0;
    local fndBank = 0;

	if (link == nil) then
		link = item
	end

	found = 0;
	for i,d in pairs(db) do
		if (type(d) == "table")then
			if(d.name == item)then
				r = d.value;
				found = i;
			end
		end
	end

	fnd = TitanGathered_IsExistMat(item);

	if(found > 0) then
		local oldValue = 0;
		local newValue = 0;

		oldValue = r;
		newValue = oldValue + iQuantity;

		if (fnd > 0) then
    		fndBags = GetItemsFromBags(item);
	   	    fndBank = GetItemsFromBank(item);
	        fndH 	= GetItemsFromHistory(item);
	        fndSUM  = ((fndBags + iQuantity) + fndBank)*1;
			nitem = { name = item, value = newValue};
		    table.remove(db, found);
			table.insert(db,found,nitem);

			TitanGathered_PrintDebug("|cffffff20TG item found: |cffff00ff"..iQuantity.."x "..link.." |cffffff20Bags: |cffff00ff"..fndBags + iQuantity.." |cffffff20Bank: |cffff00ff"..fndBank.." |cffffff20Sum: |cffff00ff"..fndSUM);
		end
	else
		if (fnd > 0) then
			nitem = { name = item, value = iQuantity};
			table.insert(db,nitem);
			TitanGathered_PrintDebug("|cffffff20TG item found: |cffff00ff"..iQuantity.."x "..link.." |cffffff20Bags: |cffff00ff"..fndBags + iQuantity.." |cffffff20Bank: |cffff00ff"..fndBank.." |cffffff20Sum: |cffff00ff"..fndSUM);
		end
	end
	TitanSetVar(TG.id, "itemsHistory", db);
end

-------------------------------------------------------
-- TitanGathered_ShowHistory()
-- Show trade items history in default log
-------------------------------------------------------
function TitanGathered_ShowHistory()
	local db = TitanGetVar(TG.id, "itemsHistory");

	local i,d;
	local fnd = 0;
	found = 0;

	echo(TITAN_ORE_YELLOW.." ");
	echo(TITAN_ORE_YELLOW.."------------------------------------------");
	echo(TITAN_ORE_YELLOW.."Titan Gathered "..TITAN_ORE_GREEN..TG.version..TITAN_ORE_YELLOW.." history statistic:");
	echo(TITAN_ORE_YELLOW.."------------------------------------------");

	if (db) then
		for i,e in pairs(db) do
			if (type(e) == "table") then
				fnd = TitanGathered_IsExistMat(e.name);
				if (fnd > 0) then
					echo(e.name..": "..TITAN_ORE_GREEN..e.value);
				end
			end
		end
	end

	echo(TITAN_ORE_YELLOW.."--- end list -----------------------------");
end

-------------------------------------------------------
-- TitanGathered_ShowBank()
-- Show items stored at bank in default log
-------------------------------------------------------
function TitanGathered_ShowBank()
	local dbb = TitanGetVar(TG.id, "bankHistory");
	local i,e;

	echo(TITAN_ORE_YELLOW.." ");
	echo(TITAN_ORE_YELLOW.."------------------------------------------------");
	echo(TITAN_ORE_YELLOW.."Titan Gathered "..TITAN_ORE_GREEN..TG.version..TITAN_ORE_YELLOW.." bank items:");
	echo(TITAN_ORE_YELLOW.."------------------------------------------------");

	if (dbb) then
		for i,e in pairs(dbb) do
			if (type(e) == "table") then
				echo(e.name..": "..TITAN_ORE_GREEN..e.value);
			end
		end
	end

	echo(TITAN_ORE_YELLOW.."--- end list -----------------------------");
end

-------------------------------------------------------
-- TitanGathered_IsExistMat()
-- Check if materil is member of tradeskil mats
-------------------------------------------------------
function TitanGathered_IsExistMat(item)
	local i,iname;
	local f = 0;

	for i,iname in pairs(TITAN_ORE_ITEMS) do
		if (item == iname.name) then
			if (iname.cat == TITAN_ORE_LOCAL_ORES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_BARS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_STONES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_GEMS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_SHARDS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_LEATHERS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_SCALES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_CLOTHS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_HIDES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_HERBS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_ESSENCES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_MISC) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_BANDAGES) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_POISONS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_PMATS) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_INSCRIPT_INK) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_INSCRIPT_PIG) then
				return i;
			end
			if (iname.cat == TITAN_ORE_LOCAL_COOKINGS) then
				return i;
			end
		end
	end
	return 0;
end

-------------------------------------------------------
-- TitanGathered_IsExistMat()
-- Check if materil is member of tradeskil mats
-------------------------------------------------------
function TitanGathered_GetCategory(item)
	local i,iname;
	local f = 0;

	for i,iname in pairs(TITAN_ORE_ITEMS) do
		if (item == iname.name) then
			return iname.cat;
		end
	end
	return 0;
end

-------------------------------------------------------
-- TitanGathered_IsExistMat()
-- Check if materil is member of tradeskil mats
-------------------------------------------------------
function TitanGathered_GetCategorySkill(tag)
	local i,iname;
	local f = 0;

	for i,iname in pairs(TITAN_ORE_CATEGORIES) do

		if (tag == iname.tag) then
			return iname.skillneed;
		end
	end
	return 0;
end

-------------------------------------------------------
-- TitanGathered_IsExistMat()
-- Check if materil is member of tradeskil mats
-------------------------------------------------------
function TitanGathered_GetSkill(item)
	local i,iname;
	local f = 0;

	for i,iname in pairs(TITAN_ORE_ITEMS) do
		if (item == iname.name) then
			return iname.skill;
		end
	end
	return 0;
end

function TitanGathered_PrintInfo()

	echo("");
	echo(TITAN_ORE_YELLOW.."------------------------------------------------");
	echo(TITAN_ORE_YELLOW..TG.id.." "..TG.version..TITAN_ORE_GREEN..TG.author);
	echo(TITAN_ORE_YELLOW.."------------------------------------------------");
	echo("|cf0063000/to /tohelp - print this info");
	echo("/mh /mathistory - print history result");
	echo("/tob /tobank - print materil stored in bank");

end

function TitanGathered_PrintDebug(text)
    if ( not TitanGetVar(TG.id, "Debugmode")) then
		DEFAULT_CHAT_FRAME:AddMessage(TITAN_ORE_YELLOW..text);
	end
end

function echo(text)
	if (text) then DEFAULT_CHAT_FRAME:AddMessage(TITAN_ORE_YELLOW..text); end
end


-- Return boolean value even given item exist in the gathered db
function CheckIfItemIsGathered(item)
	local i,iname;
	local f = 0;

	for i,iname in pairs(TITAN_ORE_ITEMS) do
		if (item == iname.name) then
			return 1;
		end
	end
	return 0;
end

-- Return item counts from bank
function GetItemsFromBank(item)
	local dbb = TitanGetVar(TG.id, "bankHistory");
	local i,e;
	local eName;
	local i_count = 0;

	if (dbb) then
		for i,e in pairs(dbb) do
			if (type(e) == "table") then
				local bName = GetItemInfo(e.name);

				if (bName == item) then
					i_count = i_count + e.value;
				end
			end
		end
	end

	return i_count;
end

-- Return item count from history database
function GetItemsFromHistory(item)
	local dbb = TitanGetVar(TG.id, "itemsHistory");
	local i,e;
	local i_count = 0;

	if (dbb) then
		for i,e in pairs(dbb) do
			if (type(e) == "table") then
				if (e.name == item) then
					i_count = i_count + e.value;
				end
			end
		end
	end

	return i_count;
end

-- Return all intems from bags
function GetItemsFromBags(item)
	local nbslots, b, s, t, n;
	local i_count = 0;

		for b=0,4 do
			nbslots=GetContainerNumSlots(b);
			for s=0,nbslots do
				local texture, itemCount = GetContainerItemInfo(b, s);

				t = GetContainerItemLink(b, s);

				if (t) then

					local bName = GetItemInfo(t);

					if (bName == item) then
						i_count = i_count + itemCount;

					end
				end
			end
		end
	return i_count;
end


--Return Game tooltim string
--function TitanGatheredShowTooltip(item)
GameTooltip:HookScript("OnTooltipSetItem",function(self,...)

		if ( TitanGetVar(TG.id, "ShowInfoTooltip"))
			then return; end

		local lbl = getglobal("GameTooltipTextLeft1");
			local itemName = lbl:GetText();
			local no = getglobal(item);

		fndBags = 0;
		fndBank = 0;
		fndH 	= 0;
		skills = {};

		local skillInfo = "";
		local skill_color = TITAN_ORE_RED;

		local fndSkill      = TitanGathered_GetSkill(itemName);
		local fndCat        = TitanGathered_GetCategory(itemName);
		local fndReqSkill   = TitanGathered_GetCategorySkill(fndCat);
		local prof_1, prof_2, archaeology, fishing, cooking, firstaid = GetProfessions();

		if (prof_1) then skills[prof_1]               = "prof_1"; end
		if (prof_2) then skills[prof_2]               = "prof_2"; end
		if (archaelogy) then skills[archaeology]      = "Archaeology"; end
		if (fishing) then skills[fishing]             = "Fishing"; end
		if (cooking) then skills[cooking]             = "Cooking"; end
		if (firstaid) then skills[firstaid]           = "Firstaid" end

		for iSkill in pairs(skills) do
	        if ( fndCat and iSkill ) then
		       local skillName, icon, skillrank, skillmax, numspells, spelloffset, skillline = GetProfessionInfo(iSkill);
				if ( skillName == fndReqSkill) then
					skill_color = TitanGathered_GetSkilColor(fndSkill, skillrank);
				end
	        end
		end

	if (CheckIfItemIsGathered(itemName) == 1) then

		fndBags  = GetItemsFromBags(itemName);
		fndBank  = GetItemsFromBank(itemName);
		fndH 	 = GetItemsFromHistory(itemName);

	    if (fndSkill > 0) then
	       skillInfo = "|cffffff20Required Skill: |r"..fndReqSkill.."|r "..skill_color..fndSkill;
	    end
		self:AddLine(skillInfo, 0, 50, 255);
		self:AddLine("|cffffff20Sum:|cffff00ff "..fndBags+fndBank.."|cffffff20 Bags: |cffff00ff"..fndBags.."|cffffff20 Bank: |cffff00ff"..fndBank.."|r", 0, 50, 255);
	end

end
)



function TitanGathered_addLootItem(item)

	local db = TitanGetVar(TG.id, "clearItems");
	local i,d,v,r,found;
	local nitem = {};

	found = 0;
	for i,d in pairs(db) do
		if (type(d) == "table")then
			if(d.name == item)then
				r = d.value;
				found = i;
			end
		end
	end

	if(found > 0) then
	   echo(item.." allready exist in database!");
	else
		nitem = { name = item, value = 0};
	    echo(item.." added..");
	end

end
