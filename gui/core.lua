module 'aux.gui'

local T = require 'T'
local aux = require 'aux'

M.font = [[Fonts\ARIALN.TTF]]

M.font_size = aux.immutable-{
	small = 13,
	medium = 15,
	large = 18,
}

--function aux.handle.LOAD()
--	do
--		local blizzard_backdrop, aux_background, aux_border
--
--		aux_border = DropDownList1:CreateTexture()
--		aux_border:SetTexture(1, 1, 1, .02)
--		aux_border:SetPoint('TOPLEFT', DropDownList1Backdrop, 'TOPLEFT', -2, 2)
--		aux_border:SetPoint('BOTTOMRIGHT', DropDownList1Backdrop, 'BOTTOMRIGHT', 1.5, -1.5)
--		aux_border:SetBlendMode('ADD')
--		aux_background = DropDownList1:CreateTexture(nil, 'OVERLAY')
--		aux_background:SetTexture(aux.color.content.background())
--		aux_background:SetAllPoints(DropDownList1Backdrop)
--		blizzard_backdrop = DropDownList1Backdrop:GetBackdrop()
--		aux.hook('ToggleDropDownMenu', function(...)
--			T.temp(arg)
--			local ret = T.temp-T.list(aux.orig.ToggleDropDownMenu(unpack(arg)))
--			local dropdown = _G[arg[4] or ''] or this:GetParent()
--			if strfind(dropdown:GetName() or '', '^aux.frame%d+$') then
--				set_aux_dropdown_style(dropdown)
--			else
--				set_blizzard_dropdown_style()
--			end
--			return unpack(ret)
--		end)
--
--		function set_aux_dropdown_style(dropdown)
--			DropDownList1Backdrop:SetBackdrop(T.empty)
--			aux_border:Show()
--			aux_background:Show()
--			DropDownList1:SetWidth(dropdown:GetWidth() * .9)
--			DropDownList1:SetHeight(DropDownList1:GetHeight() - 10)
--			DropDownList1:ClearAllPoints()
--			DropDownList1:SetPoint('TOPLEFT', dropdown, 'BOTTOMLEFT', -2, -2)
--			for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
--				local button = _G['DropDownList1Button' .. i]
--				button:SetPoint('TOPLEFT', 0, -((button:GetID() - 1) * UIDROPDOWNMENU_BUTTON_HEIGHT) - 7)
--				button:SetPoint('TOPRIGHT', 0, -((button:GetID() - 1) * UIDROPDOWNMENU_BUTTON_HEIGHT) - 7)
--				local text = button:GetFontString()
--				text:SetFont(font, 14)
--				text:SetPoint('TOPLEFT', 18, 0)
--				text:SetPoint('BOTTOMRIGHT', -8, 0)
--				local highlight = _G['DropDownList1Button' .. i .. 'Highlight']
--				highlight:ClearAllPoints()
--				highlight:SetDrawLayer('OVERLAY')
--				highlight:SetHeight(14)
--				highlight:SetPoint('LEFT', 5, 0)
--				highlight:SetPoint('RIGHT', -3, 0)
--				local check = _G['DropDownList1Button' .. i .. 'Check']
--				check:SetWidth(16)
--				check:SetHeight(16)
--				check:SetPoint('LEFT', 3, -1)
--			end
--		end
--
--		function set_blizzard_dropdown_style()
--			DropDownList1Backdrop:SetBackdrop(blizzard_backdrop)
--			aux_border:Hide()
--			aux_background:Hide()
--			for i = 1, UIDROPDOWNMENU_MAXBUTTONS do
--				local button = _G['DropDownList1Button' .. i]
--				local text = button:GetFontString()
--				text:SetFont([[Fonts\FRIZQT__.ttf]], 10)
--				text:SetShadowOffset(1, -1)
--				local highlight = _G['DropDownList1Button' .. i .. 'Highlight']
--				highlight:SetAllPoints()
--				highlight:SetDrawLayer('BACKGROUND')
--				local check = _G['DropDownList1Button' .. i .. 'Check']
--				check:SetWidth(24)
--				check:SetHeight(24)
--				check:SetPoint('LEFT', 0, 0)
--			end
--		end
--	end
--end

do
	local id = 1
	function M.unique_name()
		id = id + 1
		return 'aux.frame' .. id
	end
end

do
	local menu = CreateFrame('Frame', unique_name(), UIParent, 'UIDropDownMenuTemplate')
	M.menu = T.vararg-function(arg)
		HideDropDownMenu(1)
		UIDropDownMenu_Initialize(menu, function()
			for i = 1, getn(arg), 2 do
				UIDropDownMenu_AddButton(T.map('text', arg[i], 'notCheckable', true, 'func', arg[i + 1]))
			end
		end, 'MENU')
		ToggleDropDownMenu(1, nil, menu, 'cursor')
	end
end

-- Themes: 'blizzard' (default), 'modern' (flat dark) and 'pfui' (flat, follows pfUI colors/font/class color)
local current_theme = 'blizzard'

function M.set_global_theme(theme)
    current_theme = (theme == 'modern' or theme == 'pfui') and theme or 'blizzard'
    aux.set_color_theme(current_theme)
    if current_theme == 'pfui' and _G.pfUI then
        local config = _G.pfUI_config
        local pfui_font = config and config.global and config.global.font_default
        if type(pfui_font) ~= 'string' or not strfind(pfui_font, '\\', 1, true) then
            pfui_font = [[Interface\AddOns\pfUI\fonts\Myriad-Pro.ttf]]
        end
        M.font = pfui_font
    end
    if current_theme == 'pfui' then
        -- pfUI uses small text; the default sizes look huge and overflow
        M.font_size = aux.immutable-{small = 11, medium = 12, large = 13}
    end
end

function M.get_theme()
    return current_theme
end

-- Layout: blizzard and pfui share the Blizzard-style layout (spacing, widths); only 'modern' is tight.
function M.is_blizzard()
    return current_theme ~= 'modern'
end

-- Skin: true only for the real Blizzard textures/templates. pfui draws flat dark pfUI-style widgets in the Blizzard layout.
function M.blizzard_skin()
    return current_theme == 'blizzard'
end

-- Height of a frame in its own units, independent of effective-scale changes after creation
-- (pfUI rescales UIParent after aux builds its UI, which made rows too tall and overflow the window).
function M.frame_height(frame)
    local top, bottom = frame:GetTop(), frame:GetBottom()
    local ref = aux.frame
    if top and bottom and ref and ref:GetTop() and ref:GetBottom() and ref:GetTop() > ref:GetBottom() then
        return (top - bottom) / (ref:GetTop() - ref:GetBottom()) * ref:GetHeight()
    end
    return frame:GetHeight() / frame:GetEffectiveScale()
end

function M.is_pfui()
    return current_theme == 'pfui'
end

-- pfUI's own API (CreateBackdrop, SkinButton, SkinScrollbar, ...). nil when pfUI isn't loaded or not ready.
local function pfapi()
    local pf = _G.pfUI
    if pf and pf.api and pf.api.CreateBackdrop and _G.pfUI_config and _G.pfUI_config.appearance and _G.pfUI_config.global then
        return pf.api
    end
end

-- True when the pfui theme is active and pfUI's skinning functions can be used
function M.pfui_native()
    return current_theme == 'pfui' and pfapi() ~= nil
end

-- Gap between neighbouring buttons: pfUI packs them tightly
function M.gap(n)
    if pfui_native() then return 2 end
    return n
end

-- Calls a pfUI API function safely. Returns true on success; on any error the caller keeps aux's own look.
function M.pf_call(name, a, b, c, d, e, f)
    local api = pfapi()
    if current_theme ~= 'pfui' or not api or not api[name] then return false end
    local ok = pcall(api[name], a, b, c, d, e, f)
    return ok
end

-- pfUI tints highlights with the player's class color
function M.class_color()
    local _, class = UnitClass('player')
    local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
    if c then return c.r, c.g, c.b end
    return .9, .8, .2
end

function M.set_size(frame, width, height)
	frame:SetWidth(width)
	frame:SetHeight(height or width)
end

function M.set_frame_style(frame, backdrop_color, border_color, left, right, top, bottom)
    if not blizzard_skin() then
        frame:SetBackdrop{bgFile=[[Interface\Buttons\WHITE8X8]], edgeFile=[[Interface\Buttons\WHITE8X8]], edgeSize=(current_theme == 'pfui' and 1 or 1.5), tile=true, insets={left=left, right=right, top=top, bottom=bottom}}
        frame:SetBackdropColor(backdrop_color())
        frame:SetBackdropBorderColor(border_color())
    else
        frame:SetBackdrop({
            bgFile = [[Interface\Tooltips\UI-Tooltip-Background]],
            edgeSize = 11,
            tile = true
        })
        frame:SetBackdropColor(0.09, 0.09, 0.19)

        local border = CreateFrame('Frame', nil, frame)
        border:SetPoint('TOPLEFT', frame, 'TOPLEFT', -3, 3)
        border:SetPoint('BOTTOMRIGHT', frame, 'BOTTOMRIGHT', 3, -3)
        border:SetBackdrop({
            edgeFile = [[Interface\Tooltips\UI-Tooltip-Border]],
            edgeSize = 11,
            tileSize = 11,
            tile = true
        })
        border:SetBackdropBorderColor(0.6, 0.6, 0.6)
    end
end

-- pfUI-style rounded dark box (uses pfUI's own border texture when pfUI is installed)
function M.pfui_box(frame, transp)
    if pf_call('CreateBackdrop', frame, nil, true, transp) then return end
    local edge, size = [[Interface\Tooltips\UI-Tooltip-Border]], 12
    if _G.pfUI then edge, size = [[Interface\AddOns\pfUI\img\border_blizz]], 6 end
    frame:SetBackdrop{bgFile=[[Interface\Buttons\WHITE8X8]], edgeFile=edge, tile=true, tileSize=8, edgeSize=size, insets={left=3, right=3, top=3, bottom=3}}
    frame:SetBackdropColor(aux.color.content.background())
    frame:SetBackdropBorderColor(aux.color.content.border())
end

-- pfUI buttons keep Blizzard's gold text
local function button_text_color(enabled)
    if is_pfui() then
        if enabled then return 1, .82, 0 end
        return .5, .5, .5
    end
    if enabled then return aux.color.text.enabled() end
    return aux.color.text.disabled()
end

function M.set_window_style(frame, left, right, top, bottom)
    if pfui_native() then
        -- same as pfUI's Blizzard AH skin: CreateBackdrop(AuctionFrame, nil, nil, .75) + shadow
        pf_call('CreateBackdrop', frame, nil, true, .75)
        pf_call('CreateBackdropShadow', frame)
        return
    end
    set_frame_style(frame, aux.color.window.background, aux.color.window.border, left, right, top, bottom)
end

function M.set_panel_style(frame, left, right, top, bottom)
    if pfui_native() then return pfui_box(frame, .45) end
    set_frame_style(frame, aux.color.panel.background, aux.color.panel.border, left, right, top, bottom)
end

function M.set_content_style(frame, left, right, top, bottom)
    if is_pfui() then return pfui_box(frame) end
    set_frame_style(frame, aux.color.content.background, aux.color.content.border, left, right, top, bottom)
end

function M.set_scrollbar_style(scrollFrame, points)
    local scrollBar = _G[scrollFrame:GetName() .. 'ScrollBar']

    scrollBar:ClearAllPoints()
    local native = pfui_native()
    for _, pt in ipairs(points) do
        if native then
            -- pfUI keeps the up/down arrow buttons, which sit outside the bar: make room for them
            local y = pt[4] or 0
            if strfind(pt[1], 'TOP', 1, true) then y = y - 17 else y = y + 17 end
            scrollBar:SetPoint(pt[1], pt[2], pt[3] or 0, y)
        else
            scrollBar:SetPoint(unpack(pt))
        end
    end

    if native and pf_call('SkinScrollbar', scrollBar) then
        scrollBar:SetWidth(16)
    elseif not blizzard_skin() then
        scrollBar:SetWidth(10)
        local thumbTex = scrollBar:GetThumbTexture()
        thumbTex:SetPoint('CENTER', 0, 0)
        if is_pfui() then
            thumbTex:SetTexture(.55, .55, .55, .9)
        else
            thumbTex:SetTexture(aux.color.content.background())
        end
        thumbTex:SetHeight(150)
        thumbTex:SetWidth(scrollBar:GetWidth())
        _G[scrollBar:GetName() .. 'ScrollUpButton']:Hide()
        _G[scrollBar:GetName() .. 'ScrollDownButton']:Hide()
    else
        -- A hacky dynamicly sized scrollbar background

        local scrollUpButton = _G[scrollBar:GetName() .. 'ScrollUpButton']
        local scrollDownButton = _G[scrollBar:GetName() .. 'ScrollDownButton']

        local backgroundTop = scrollFrame:CreateTexture(nil, 'BACKGROUND')
        backgroundTop:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]])
        backgroundTop:SetWidth(31)
        backgroundTop:SetHeight(128)
        backgroundTop:SetPoint('BOTTOM', scrollUpButton, 'TOP', 0, -128 + 4)
        backgroundTop:SetTexCoord(0, 0.484375, 0, 0.5)

        local backgroundBottom = scrollFrame:CreateTexture(nil, 'BACKGROUND')
        backgroundBottom:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]])
        backgroundBottom:SetWidth(31)
        backgroundBottom:SetHeight(106)
        backgroundBottom:SetPoint('TOP', scrollDownButton, 'BOTTOM', 0, 106 - 2)
        backgroundBottom:SetTexCoord(0.515625, 1.0, 0, 0.4140625)

        local backgroundMiddle = scrollFrame:CreateTexture(nil, 'BACKGROUND')
        backgroundMiddle:SetTexture([[Interface\PaperDollInfoFrame\UI-Character-ScrollBar]])
        backgroundMiddle:SetWidth(31)
        backgroundMiddle:SetPoint('TOP', backgroundTop, 'BOTTOM', 0, 0)
        backgroundMiddle:SetTexCoord(0, 0.484375, 0.125, 0.875)
        backgroundMiddle:Hide()

        scrollBar:SetScript('OnSizeChanged', function()
            -- Scrollbar height value is scaled, but the button heights aren't..
            local missingSpace = (scrollBar:GetHeight() / scrollBar:GetEffectiveScale()) + 
                scrollUpButton:GetHeight() + scrollDownButton:GetHeight() + 10 - 
                (backgroundTop:GetHeight() + backgroundBottom:GetHeight())
            if missingSpace > 0 then
                backgroundMiddle:SetHeight(missingSpace)
                backgroundMiddle:SetTexCoord(0, 0.484375, 0.125, 0.125 + (missingSpace / 256))
                backgroundMiddle:Show()
            else
                backgroundMiddle:Hide()
            end
        end)
    end
end

function M.panel(parent)
    local panel = CreateFrame('Frame', nil, parent)
    set_panel_style(panel)
    return panel
end

function M.checkbutton(parent, text_height)
    local button = button(parent, text_height)
    button.state = false
    if not blizzard_skin() then
        button:SetBackdropColor(aux.color.state.disabled())
    end
    function button:SetChecked(state)
        if state then
            if not blizzard_skin() then
                self:SetBackdropColor(aux.color.state.enabled())
            end
            self.state = true
        else
            if not blizzard_skin() then
                self:SetBackdropColor(aux.color.state.disabled())
            end
            self.state = false
        end
    end
    function button:GetChecked()
        return self.state
    end
    return button
end

function M.button(parent, text_height)
    text_height = text_height or font_size.large
    local button = CreateFrame('Button', unique_name(), parent, blizzard_skin() and "UIPanelButtonTemplate2" or nil)
    set_size(button, 80, 24)
    
    if not blizzard_skin() then
        set_content_style(button)
        local highlight = button:CreateTexture(nil, 'HIGHLIGHT')
        highlight:SetAllPoints()
        if is_pfui() then
            highlight:SetTexture(0, 0, 0, 0)
        else
            highlight:SetTexture(1, 1, 1, .2)
        end
        button.highlight = highlight
        if is_pfui() then
            local set_script = button.SetScript
            button:SetScript('OnEnter', function()
                if this:IsEnabled() == 1 then this:GetFontString():SetTextColor(1, 1, 1) end
                do (this.pf_enter or pass)() end
            end)
            button:SetScript('OnLeave', function()
                if this:IsEnabled() == 1 then this:GetFontString():SetTextColor(button_text_color(true)) end
                do (this.pf_leave or pass)() end
            end)
            function button:SetScript(name, fn)
                if name == 'OnEnter' then self.pf_enter = fn
                elseif name == 'OnLeave' then self.pf_leave = fn
                else set_script(self, name, fn) end
            end
        end
        do
            local label = button:CreateFontString()
            label:SetFont(font, text_height)
            label:SetAllPoints(button)
            label:SetJustifyH('CENTER')
            label:SetJustifyV('CENTER')
            label:SetTextColor(button_text_color(true))
            button:SetFontString(label)
        end
        if pfui_native() and pf_call('SkinButton', button) then
            button:GetFontString():SetFont(font, text_height, 'OUTLINE')
            button:GetFontString():SetTextColor(button_text_color(true))
        end
    end

    
    local buttonParts = blizzard_skin() and {_G[button:GetName() .. "Left"], 
        _G[button:GetName() .. "Middle"], _G[button:GetName() .. "Right"]}
    -- Shenanigans to make UIPanelButtonTemplate2 use the disabled texture when disabled
    local realSetTexture = blizzard_skin() and buttonParts[1].SetTexture
    local textureLock = function() end

    button.default_Enable = button.Enable
    function button:Enable()
	    if self:IsEnabled() == 1 then return end
        if not blizzard_skin() then
            self:GetFontString():SetTextColor(button_text_color(true))
        else
            for _, part in ipairs(buttonParts) do
                part.SetTexture = realSetTexture
                part:SetTexture([[Interface\Buttons\UI-Panel-Button-Up]])
            end
        end
        return self:default_Enable()
    end
    button.default_Disable = button.Disable
    function button:Disable()
	    if self:IsEnabled() == 0 then return end
        if not blizzard_skin() then
            self:GetFontString():SetTextColor(button_text_color(false))
        else
            for _, part in ipairs(buttonParts) do
                part:SetTexture([[Interface\Buttons\UI-Panel-Button-Disabled]])
                part.SetTexture = textureLock
            end
        end
        return self:default_Disable()
    end

    return button
end

-- Button with a smooth anti-aliased arrow ('left' or 'right') from textures/arrow_<direction>.tga, tinted like button text.
-- If setup fails it falls back to a plain '<' / '>' text button.
function M.arrow_button(parent, direction)
    local btn = button(parent)
    local tex
    local function tint(enabled)
        if not tex then return end
        if enabled then
            tex:SetVertexColor(1, .82, 0)
        else
            tex:SetVertexColor(.5, .5, .5)
        end
    end
    local function build()
        local holder = CreateFrame('Frame', nil, btn)
        holder:SetFrameLevel(btn:GetFrameLevel() + 2)
        holder:SetWidth(16)
        holder:SetHeight(16)
        holder:SetPoint('CENTER', btn, 'CENTER', 0, 0)
        tex = holder:CreateTexture(nil, 'OVERLAY')
        tex:SetAllPoints(holder)
        tex:SetTexture([[Interface\AddOns\aux-addon\textures\arrow_]] .. direction)
        tint(true)
    end
    if pcall(build) then
        local enable, disable = btn.Enable, btn.Disable
        if enable then
            function btn:Enable() local ret = enable(self); tint(true); return ret end
        end
        if disable then
            function btn:Disable() local ret = disable(self); tint(false); return ret end
        end
    else
        btn:SetText(direction == 'left' and '<' or '>')
    end
    return btn
end

do
	local mt = {__index=T.acquire()}
	function mt.__index:create_tab(text)
		local id = getn(self._tabs) + 1

		local tab = CreateFrame('Button', "$parentTab"..id, self._frame, blizzard_skin() and "CharacterFrameTabButtonTemplate" or nil)
		tab.id = id
		tab.group = self

        if not blizzard_skin() then
            tab:SetHeight(27)
            set_panel_style(tab)
            if is_pfui() then pfui_box(tab) end
            tab.pf_native = pfui_native()
            local dock = tab:CreateTexture(nil, 'OVERLAY')
            dock:SetHeight(3)
            if self._orientation == 'UP' then
                dock:SetPoint('BOTTOMLEFT', 1, -1)
                dock:SetPoint('BOTTOMRIGHT', -1, -1)
            elseif self._orientation == 'DOWN' then
                dock:SetPoint('TOPLEFT', 1, 1)
                dock:SetPoint('TOPRIGHT', -1, 1)
            end
            dock:SetTexture(aux.color.panel.background())
            tab.dock = dock
            local highlight = tab:CreateTexture(nil, 'HIGHLIGHT')
            highlight:SetAllPoints()
            if is_pfui() then
                highlight:SetTexture(0, 0, 0, 0)
                tab:SetScript('OnEnter', function() this.text:SetTextColor(1, 1, 1) end)
                tab:SetScript('OnLeave', function()
                    if this.group._selected == this.id then this.text:SetTextColor(1, 1, 1) else this.text:SetTextColor(1, .82, 0) end
                end)
            else
                highlight:SetTexture(1, 1, 1, .2)
            end
            tab.highlight = highlight

            tab.text = tab:CreateFontString()
            tab.text:SetAllPoints()
            tab.text:SetJustifyH('CENTER')
            tab.text:SetJustifyV('CENTER')
            tab.text:SetFont(font, font_size.large)
            tab:SetFontString(tab.text)
        else
            tab:RegisterForClicks("LeftButtonUp")
        end

		tab:SetText(text)

		tab:SetScript('OnClick', function()
			if this.id ~= this.group.selected then
				PlaySound('igCharacterInfoTab')
				this.group:select(this.id)
                if blizzard_skin() then
                    PanelTemplates_SetTab(self._frame, this.id)
                end
			end
		end)

		if getn(self._tabs) == 0 then
			if self._orientation == 'UP' then
				tab:SetPoint('BOTTOMLEFT', self._frame, 'TOPLEFT', 4, blizzard_skin() and -8 or -1)
			elseif self._orientation == 'DOWN' then
				tab:SetPoint('TOPLEFT', self._frame, 'BOTTOMLEFT', 4, blizzard_skin() and -8 or (tab.pf_native and -1 or 1))
            end
		else
			if self._orientation == 'UP' then
				tab:SetPoint('BOTTOMLEFT', self._tabs[getn(self._tabs)], 'BOTTOMRIGHT', blizzard_skin() and -16 or (tab.pf_native and 1 or 2), 0)
			elseif self._orientation == 'DOWN' then
				tab:SetPoint('TOPLEFT', self._tabs[getn(self._tabs)], 'TOPRIGHT', blizzard_skin() and -16 or (tab.pf_native and 1 or 2), 0)
			end
		end

        if not blizzard_skin() then
		    tab:SetWidth(tab:GetFontString():GetStringWidth() + 24)
        end

		tinsert(self._tabs, tab)

        if blizzard_skin() then
            PanelTemplates_SetNumTabs(self._frame, getn(self._tabs))
            PanelTemplates_SetTab(self._frame, 1)
        end
	end
	function mt.__index:select(id)
		self._selected = id
		self:update()
        if blizzard_skin() then
            PanelTemplates_SetTab(self._frame, id)
        end
		do (self._on_select or pass)(id) end
	end
	function mt.__index:update()
        if not blizzard_skin() then
            for _, tab in self._tabs do
                if tab.group._selected == tab.id then
                    if is_pfui() then tab.text:SetTextColor(1, 1, 1) else tab.text:SetTextColor(aux.color.label.enabled()) end
                    tab:Disable()
                    tab:SetBackdropColor(aux.color.panel.background())
                    if tab.pf_native then tab.dock:Hide(); tab:SetBackdropBorderColor(class_color()) else tab.dock:Show() end
                    tab:SetHeight(tab.pf_native and 25 or 32)
                else
                    if is_pfui() then tab.text:SetTextColor(1, .82, 0) else tab.text:SetTextColor(aux.color.text.enabled()) end
                    tab:Enable()
                    tab:SetBackdropColor(aux.color.content.background())
                    if tab.pf_native then tab:SetBackdropBorderColor(aux.color.content.border()) end
                    tab.dock:Hide()
                    tab:SetHeight(tab.pf_native and 25 or 27)
                end
            end
        end
	end
	function M.tabs(parent, orientation)
		local self = {
			_frame = parent,
			_orientation = orientation,
			_tabs = T.acquire(),
		}
	    return setmetatable(self, mt)
	end
end

function M.editbox(parent)
    local editbox = CreateFrame('EditBox', unique_name(), parent, blizzard_skin() and "InputBoxTemplate" or nil)
    editbox:SetAutoFocus(false)
    editbox:SetTextInsets(1.5, 1.5, 3, 3)
    editbox:SetMaxLetters(nil)
    editbox:SetHeight(24)
    editbox:SetTextColor(0, 0, 0, 0)
    if not blizzard_skin() then
        set_content_style(editbox)
    end
    editbox:SetScript('OnEscapePressed', function()
        this:ClearFocus()
	    do (this.escape or pass)() end
    end)
    editbox:SetScript('OnEnterPressed', function() (this.enter or pass)() end)
    editbox:SetScript('OnEditFocusGained', function()
	    if this.block_focus then
		    this.block_focus = false
		    this:ClearFocus()
		    return
	    end
	    this.overlay:Hide()
	    this:SetTextColor(aux.color.text.enabled())
	    this.focused = true
	    this:HighlightText()
	    do (this.focus_gain or pass)() end
    end)
    editbox:SetScript('OnEditFocusLost', function()
	    this.overlay:Show()
	    this:SetTextColor(0, 0, 0, 0)
	    this.focused = false
	    this:HighlightText(0, 0)
	    this:SetScript('OnUpdate', nil)
	    do (this.focus_loss or pass)() end
    end)
    editbox:SetScript('OnTextChanged', function()
	    this.overlay:SetText(this.formatter and this.formatter(this:GetText()) or this:GetText())
	    do (this.change or pass)() end
    end)
    editbox:SetScript('OnChar', function() (this.char or pass)() end)
    do
        local last_click = T.map('t', 0)
        editbox:SetScript('OnMouseDown', function()
	        if arg1 == 'RightButton' then
		        this:SetText('')
		        this:ClearFocus()
		        this.block_focus = true
	        else
	            local x, y = GetCursorPosition()
	            -- local offset = x - editbox:GetLeft()*editbox:GetEffectiveScale() TODO use a fontstring to measure getstringwidth for structural highlighting
	            -- or use an overlay with itemlinks
	            if GetTime() - last_click.t < .5 and x == last_click.x and y == last_click.y then
	                aux.thread(function() editbox:HighlightText() end)
	            end
	            T.wipe(last_click)
	            last_click.t = GetTime()
	            last_click.x = x
	            last_click.y = y
	        end
        end)
    end
    function editbox:SetAlignment(alignment)
	    self:SetJustifyH(alignment)
	    self.overlay:SetJustifyH(alignment)
    end
    function editbox:SetFontSize(size)
	    self:SetFont(font, size)
	    self.overlay:SetFont(font, size)
    end
    local overlay = label(editbox)
    overlay:SetPoint('LEFT', 1.5, 0)
    overlay:SetPoint('RIGHT', -1.5, 0)
    overlay:SetTextColor(aux.color.text.enabled())
    editbox.overlay = overlay
    editbox:SetAlignment('LEFT')
    editbox:SetFontSize(font_size.medium)
    return editbox
end

do
	local function update_bar()
		if this:GetValue() < 1 then
			this:SetAlpha(1 - (sin(GetTime() * 180) + 1) / 5)
		else
			this:SetAlpha(this.idle_alpha or 1)
		end
	end
	-- pfUI skin: the fill eases toward its target, a spark rides its leading edge, and it fades out shortly after completing
	local function update_bar_main()
		local value, target, now = this:GetValue(), this.target, GetTime()
		local elapsed = arg1 or 0.02
		if target then
			if target < value then
				value = target
			else
				value = value + (target - value) * min(1, elapsed * 6)
				if target - value < .002 then value = target end
			end
			this:SetValue(value)
		end
		if target and target >= 1 and value >= 1 then
			if not this.done_at then this.done_at = now end
		else
			this.done_at = nil
		end
		local goal = 1
		if this.done_at and now - this.done_at > .45 then goal = 0 end
		local alpha = this.fade or goal
		alpha = alpha + (goal - alpha) * min(1, elapsed * 3)
		if abs(goal - alpha) < .01 then alpha = goal end
		this.fade = alpha
		this:SetAlpha(alpha)
		if this.spark then
			local width = this:GetWidth()
			if value > .004 then
				-- leading edge rides the fill and ends up flush with the right side when finished
				local x = value * width
				this.spark:ClearAllPoints()
				this.spark:SetPoint('TOPRIGHT', this, 'TOPLEFT', x, 0)
				this.spark:SetPoint('BOTTOMRIGHT', this, 'BOTTOMLEFT', x, 0)
				this.glow:SetWidth(max(1, min(16, x - 2)))
				if target and target >= 1 and value >= 1 then
					this.spark:SetAlpha(1)
				else
					this.spark:SetAlpha(.75 + .25 * sin(now * 300))
				end
				this.spark:Show()
				this.glow:Show()
			else
				this.spark:Hide()
				this.glow:Hide()
			end
			if target == 0 and value <= .004 then
				-- waiting for the first page: sweep a soft highlight back and forth so it's clear something is happening
				local phase = now * .8
				phase = phase - floor(phase)
				local half = 36
				local x = phase * (width + half * 2) - half * 2
				local a_left, a_right = max(0, x), min(width, x + half)
				local b_left, b_right = max(0, x + half), min(width, x + half * 2)
				if a_right > a_left then
					this.sweep_a:ClearAllPoints()
					this.sweep_a:SetPoint('TOPLEFT', this, 'TOPLEFT', a_left, 0)
					this.sweep_a:SetPoint('BOTTOMLEFT', this, 'BOTTOMLEFT', a_left, 0)
					this.sweep_a:SetWidth(a_right - a_left)
					this.sweep_a:Show()
				else
					this.sweep_a:Hide()
				end
				if b_right > b_left then
					this.sweep_b:ClearAllPoints()
					this.sweep_b:SetPoint('TOPLEFT', this, 'TOPLEFT', b_left, 0)
					this.sweep_b:SetPoint('BOTTOMLEFT', this, 'BOTTOMLEFT', b_left, 0)
					this.sweep_b:SetWidth(b_right - b_left)
					this.sweep_b:Show()
				else
					this.sweep_b:Hide()
				end
			else
				this.sweep_a:Hide()
				this.sweep_b:Hide()
			end
		end
	end
	local function set_target(bar, value)
		if is_pfui() then
			bar.target = value
			if value < bar:GetValue() then bar:SetValue(value) end
		else
			bar:SetValue(value)
		end
	end
	-- progress accent for the pfUI skin: the same gold as the button text
	local accent_r, accent_g, accent_b = 1, .82, 0
	function M.status_bar(parent)
	    local self = CreateFrame('Frame', nil, parent)
	    local level = parent:GetFrameLevel()
	    self:SetFrameLevel(level + 1)
	    local inset = 0
	    if pfui_native() then pfui_box(self); inset = 1 end
	    do
	        local status_bar = CreateFrame('StatusBar', nil, self, 'TextStatusBar')
	        status_bar:SetOrientation('HORIZONTAL')
	        status_bar:SetMinMaxValues(0, 1)
	        if inset > 0 then status_bar:SetPoint('TOPLEFT', self, 'TOPLEFT', inset, -inset); status_bar:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -inset, inset) else status_bar:SetAllPoints() end
	        status_bar:SetStatusBarTexture(blizzard_skin() and [[Interface\Glues\LoadingBar\Loading-BarFill]] or 
                [[Interface\Buttons\WHITE8X8]])
            if not blizzard_skin() then
	            if is_pfui() then
	                status_bar:Hide() -- unused on pfUI: the single fill below shows the furthest progress
	            else
	                status_bar:SetStatusBarColor(.42, .42, .42, 1)
	            end
            end
	        status_bar:SetFrameLevel(level + 2)
	        if not is_pfui() then status_bar:SetScript('OnUpdate', update_bar) end
	        self.secondary_status_bar = status_bar
	    end
	    do
	        local status_bar = CreateFrame('StatusBar', nil, self, 'TextStatusBar')
	        status_bar:SetOrientation('HORIZONTAL')
	        status_bar:SetMinMaxValues(0, 1)
	        if inset > 0 then status_bar:SetPoint('TOPLEFT', self, 'TOPLEFT', inset, -inset); status_bar:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -inset, inset) else status_bar:SetAllPoints() end
	        status_bar:SetStatusBarTexture(blizzard_skin() and [[Interface\Glues\LoadingBar\Loading-BarFill]] or 
                [[Interface\Buttons\WHITE8X8]])
            if is_pfui() then
                -- fill sits inside the button's border, with a soft vertical gradient, a glow and a bright leading edge
                local pad = inset + 2
                status_bar:ClearAllPoints()
                status_bar:SetPoint('TOPLEFT', self, 'TOPLEFT', pad, -pad)
                status_bar:SetPoint('BOTTOMRIGHT', self, 'BOTTOMRIGHT', -pad, pad)
                status_bar:SetStatusBarColor(accent_r, accent_g, accent_b, 1)
                local fill = status_bar:GetStatusBarTexture()
                pcall(function()
                    fill:SetGradientAlpha('VERTICAL', accent_r, accent_g, accent_b, .42, accent_r, accent_g, accent_b, .16)
                end)
                -- the spark and glow are positioned by hand every frame (anchoring to the fill texture doesn't follow it)
                local spark = status_bar:CreateTexture(nil, 'OVERLAY')
                spark:SetTexture([[Interface\Buttons\WHITE8X8]])
                spark:SetVertexColor(1, .93, .45, 1)
                spark:SetWidth(2)
                local glow = status_bar:CreateTexture(nil, 'OVERLAY')
                glow:SetTexture([[Interface\Buttons\WHITE8X8]])
                glow:SetWidth(16)
                glow:SetPoint('TOPRIGHT', spark, 'TOPLEFT', 0, 0)
                glow:SetPoint('BOTTOMRIGHT', spark, 'BOTTOMLEFT', 0, 0)
                pcall(function()
                    glow:SetGradientAlpha('HORIZONTAL', accent_r, accent_g, accent_b, 0, accent_r, accent_g, accent_b, .38)
                end)
                -- sweeping highlight shown while waiting for the first results (no measurable progress yet)
                local sweep_a = status_bar:CreateTexture(nil, 'ARTWORK')
                local sweep_b = status_bar:CreateTexture(nil, 'ARTWORK')
                for _, tex in {sweep_a, sweep_b} do
                    tex:SetTexture([[Interface\Buttons\WHITE8X8]])
                    tex:Hide()
                end
                pcall(function()
                    sweep_a:SetGradientAlpha('HORIZONTAL', accent_r, accent_g, accent_b, 0, accent_r, accent_g, accent_b, .30)
                    sweep_b:SetGradientAlpha('HORIZONTAL', accent_r, accent_g, accent_b, .30, accent_r, accent_g, accent_b, 0)
                end)
                glow:Hide()
                spark:Hide()
                status_bar.glow, status_bar.spark = glow, spark
                status_bar.sweep_a, status_bar.sweep_b = sweep_a, sweep_b
            elseif not blizzard_skin() then
	            status_bar:SetStatusBarColor(.19, .22, .33, 1)
            end
	        status_bar:SetFrameLevel(level + 3)
	        status_bar:SetScript('OnUpdate', is_pfui() and update_bar_main or update_bar)
	        self.primary_status_bar = status_bar
	    end
	    do
	        local text_frame = CreateFrame('Frame', nil, self)
	        text_frame:SetFrameLevel(level + 4)
	        text_frame:SetAllPoints(self)
	        local text = label(text_frame, font_size.medium)
	        text:SetTextColor(aux.color.text.enabled())
	        text:SetPoint('CENTER', 0, 0)
	        self.text = text
	    end
        
        if blizzard_skin() then
            local statusBarBorder = CreateFrame("Frame", nil, self)
            statusBarBorder:SetPoint("TOPLEFT", self, "TOPLEFT", -4, 4)
            statusBarBorder:SetPoint("BOTTOMRIGHT", self, "BOTTOMRIGHT", 4, -4)

            statusBarBorder:SetFrameLevel(level + 5)
            statusBarBorder:SetBackdrop({edgeFile="Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 20, 
                tile = true, tileSize = 20})
        end

	    function self:update_status(primary_status, secondary_status)
	        if is_pfui() then
	            -- one fill showing whichever progress is further along (query progress or page progress)
	            if primary_status then self.progress_a = primary_status end
	            if secondary_status then self.progress_b = secondary_status end
	            set_target(self.primary_status_bar, max(self.progress_a or 0, self.progress_b or 0))
	            return
	        end
	        if primary_status then
	            set_target(self.primary_status_bar, primary_status)
	        end
	        if secondary_status then
	            set_target(self.secondary_status_bar, secondary_status)
	        end
	    end
	    function self:set_text(text)
	        self.text:SetText(text)
	    end
	    return self
	end
end

function M.item(parent)
    local item = CreateFrame('Frame', nil, parent)
    set_size(item, 260, 40)
    local btn = CreateFrame('CheckButton', unique_name(), item, 'ActionButtonTemplate')
    item.button = btn
    btn:SetPoint('LEFT', 2, .5)
    btn:SetHighlightTexture(nil)
    btn:RegisterForClicks()
    item.texture = _G[btn:GetName() .. 'Icon']
    item.texture:SetTexCoord(.06, .94, .06, .94)
    if pfui_native() then
        btn:SetNormalTexture(nil)
        btn:SetPushedTexture(nil)
        -- Don't use pfUI's HandleIcon: it re-parents/re-anchors the icon texture and on some pfUI versions the
        -- icon ends up hidden behind the backdrop. Draw the border on a separate frame below the button instead.
        local border = CreateFrame('Frame', nil, btn)
        border:SetFrameLevel(max(btn:GetFrameLevel() - 1, 0))
        border:SetAllPoints(btn)
        if not pf_call('CreateBackdrop', border, nil, true) then
            border:SetBackdrop{bgFile=[[Interface\Buttons\WHITE8X8]], edgeFile=[[Interface\Buttons\WHITE8X8]], edgeSize=1}
            border:SetBackdropColor(0, 0, 0, 1)
            border:SetBackdropBorderColor(.3, .3, .3, 1)
        end
        item.texture:SetTexCoord(.08, .92, .08, .92)
        item.texture:SetDrawLayer('ARTWORK')
        item.texture:ClearAllPoints()
        item.texture:SetPoint('TOPLEFT', btn, 'TOPLEFT', 1, -1)
        item.texture:SetPoint('BOTTOMRIGHT', btn, 'BOTTOMRIGHT', -1, 1)
        item.texture:Show()
    end
    item.name = label(btn, font_size.medium)
    item.name:SetJustifyH('LEFT')
    item.name:SetPoint('LEFT', btn, 'RIGHT', 10, 0)
    item.name:SetPoint('RIGHT', item, 'RIGHT', -10, .5)
    item.count = _G[btn:GetName() .. 'Count']
    item.count:SetTextHeight(17)
    return item
end

function M.label(parent, size)
    local label = parent:CreateFontString()
    label:SetFont(font, size or font_size.small)
    label:SetTextColor(aux.color.label.enabled())
    return label
end

function M.horizontal_line(parent, y_offset, inverted_color)
    local texture = parent:CreateTexture()
    texture:SetPoint('TOPLEFT', parent, 'TOPLEFT', 2, y_offset)
    texture:SetPoint('TOPRIGHT', parent, 'TOPRIGHT', -2, y_offset)
    texture:SetHeight(2)
    if inverted_color then
        texture:SetTexture(aux.color.panel.background())
    else
        texture:SetTexture(aux.color.content.background())
    end
    return texture
end

function M.vertical_line(parent, x_offset, top_offset, bottom_offset, inverted_color)
    local texture = parent:CreateTexture()
    texture:SetPoint('TOPLEFT', parent, 'TOPLEFT', x_offset, top_offset or -2)
    texture:SetPoint('BOTTOMLEFT', parent, 'BOTTOMLEFT', x_offset, bottom_offset or 2)
    texture:SetWidth(2)
    if inverted_color then
        texture:SetTexture(aux.color.panel.background())
    else
        texture:SetTexture(aux.color.content.background())
    end
    return texture
end

function M.dropdown(parent)
    local dropdown = CreateFrame('Frame', unique_name(), parent, 'UIDropDownMenuTemplate')

    if not blizzard_skin() then
        set_content_style(dropdown, 0, 0, 4, 4)

        _G[dropdown:GetName() .. 'Left']:Hide()
        _G[dropdown:GetName() .. 'Middle']:Hide()
        _G[dropdown:GetName() .. 'Right']:Hide()
    else
        local left = _G[dropdown:GetName() .. 'Left']
        local a,b,c,d,e = left:GetPoint(1)
        left:ClearAllPoints()
        left:SetPoint(a,b,c, -20, e - 1)
    end

    local dropdownSetWidth = dropdown.SetWidth
    dropdown.SetWidth = function(self, width)
        _G[dropdown:GetName() .. 'Middle']:SetWidth(width - 15)
        dropdownSetWidth(self, width)
        _G[dropdown:GetName() .. 'Text']:SetWidth(width - 25)
        dropdown.noResize = 1
    end

    local button = _G[dropdown:GetName() .. 'Button']
    dropdown.button = button

    if not blizzard_skin() then
        button:ClearAllPoints()
        if pfui_native() then
            button:SetScale(1)
            button:SetPoint('RIGHT', dropdown, 'RIGHT', -3, 0)
            if not pf_call('SkinArrowButton', button, 'down', 16) then button:SetScale(.9) end
        else
            button:SetScale(.9)
            button:SetPoint('RIGHT', dropdown, 0, 0)
        end

        local text = _G[dropdown:GetName() .. 'Text']
        text:ClearAllPoints()
        text:SetPoint('RIGHT', button, 'LEFT', -2, 0)
        text:SetPoint('LEFT', 8, 0)
        text:SetFont(font, font_size.medium)
        text:SetShadowColor(0, 0, 0, 0)
    end

    return dropdown
end

function M.slider(parent)

    local slider = CreateFrame('Slider', unique_name(), parent, blizzard_skin() and "OptionsSliderTemplate" or nil)
    slider:SetOrientation('HORIZONTAL')
    if not blizzard_skin() then
        slider:SetHeight(6)
    end
    slider:SetHitRectInsets(0, 0, -12, -12)
    slider:SetValue(0)

    if not blizzard_skin() then
        set_panel_style(slider)
        local thumb_texture = slider:CreateTexture(nil, 'ARTWORK')
        thumb_texture:SetPoint('CENTER', 0, 0)
        if is_pfui() then thumb_texture:SetTexture(1, .82, 0, 1) else thumb_texture:SetTexture(aux.color.content.background()) end
        thumb_texture:SetHeight(18)
        thumb_texture:SetWidth(8)
        set_size(thumb_texture, 8, 18)
        slider:SetThumbTexture(thumb_texture)
    else
        slider.low = _G[slider:GetName() .. 'Low']
        slider.low:SetText("")
        slider.high = _G[slider:GetName() .. 'High']
        slider.high:SetText("")
    end

    local label = slider:CreateFontString(nil, 'OVERLAY')
    label:SetPoint('BOTTOMLEFT', slider, 'TOPLEFT', -3, 8)
    label:SetPoint('BOTTOMRIGHT', slider, 'TOPRIGHT', 6, 8)
    label:SetJustifyH('LEFT')
    label:SetHeight(13)
    label:SetFont(font, font_size.small)
    label:SetTextColor(aux.color.label.enabled())

    local editbox = editbox(slider)
    editbox:SetPoint('LEFT', slider, 'RIGHT', 5, 0)
    set_size(editbox, 45, 18)
    editbox:SetAlignment('CENTER')
    editbox:SetFontSize(17)

    slider.label = label
    slider.editbox = editbox
    return slider
end

function M.checkbox(parent)
    local checkbox = CreateFrame('CheckButton', nil, parent, 'UICheckButtonTemplate')
    local size = blizzard_skin() and 24 or 16
    checkbox:SetWidth(size)
    checkbox:SetHeight(size)
    if not blizzard_skin() then
        set_content_style(checkbox)
        checkbox:SetNormalTexture(nil)
        checkbox:SetPushedTexture(nil)
        checkbox:GetHighlightTexture():SetAllPoints()
        checkbox:GetHighlightTexture():SetTexture(1, 1, 1, .2)
        checkbox:GetCheckedTexture():SetTexCoord(.12, .88, .12, .88)
        checkbox:GetHighlightTexture('BLEND')
    end
    return checkbox
end

do
	local editbox = CreateFrame'EditBox'
	editbox:SetAutoFocus(false)
	function M.clear_focus()
		editbox:SetFocus()
		editbox:ClearFocus()
	end
end

function M.percentage_historical(pct, bid)
	local text = (pct > 10000 and '>10000' or pct) .. '%'
	if bid then
		return aux.color.gray(text)
	elseif pct < 50 then
		return aux.color.blue(text)
	elseif pct < 80 then
		return aux.color.green(text)
	elseif pct < 110 then
		return aux.color.yellow(text)
	elseif pct < 135 then
		return aux.color.orange(text)
	else
		return aux.color.red(text)
	end
end