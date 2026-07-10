Scriptname OutfitPreviewSe extends SKI_ConfigBase

Form[] Property Outfit1 Auto
Form[] Property Outfit2 Auto
Form[] Property Outfit3 Auto
Form[] Property Outfit4 Auto
Form[] Property Outfit5 Auto
Form[] Property Outfit6 Auto
Form[] Property Outfit7 Auto
Form[] Property Outfit8 Auto
Form[] Property Outfit9 Auto
Form[] Property Outfit10 Auto

string[] Property OutfitNames Auto
int Property Hotkey Auto
bool Property SettingsInitialized Auto
bool Property ShowNotifications Auto
bool Property UnequipBeforeEquip Auto
bool Property DebugFocusHighlight Auto
bool Property AnimatePlayerPreview Auto
float Property MenuScale Auto
int Property SettingsVersion Auto

int _hotkeyOptionID = -1
int _openOptionID = -1
int _notifyOptionID = -1
int _unequipOptionID = -1
int _debugFocusOptionID = -1
int _animateOptionID = -1
int _scaleOptionID = -1
int[] _saveOptionIDs
int[] _equipOptionIDs
float _lastPlayerX = 0.0
float _lastPlayerY = 0.0
float _lastPlayerZ = 0.0
bool _menuOpen = false
int _currentOutfit = -1
int _escapeKey = 1
int _escapeAsciiKey = 27
string[] _menuRows
int[] _outfitCounts

Event OnGameReload()
    Parent.OnGameReload()
    InitSettings()
    InitArrays()
    BuildMenuRowsCache()
    RegisterMenuEvents()
    RegisterForKey(Hotkey)
EndEvent

Event OnConfigInit()
    ModName = "Outfit Preview Selector"
    Pages = new string[2]
    Pages[0] = "Outfits"
    Pages[1] = "Settings"
    _saveOptionIDs = new int[10]
    _equipOptionIDs = new int[10]
    InitSettings()
    InitArrays()
    BuildMenuRowsCache()
    RegisterMenuEvents()
    RegisterForKey(Hotkey)
EndEvent

Event OnPageReset(string page)
    _debugFocusOptionID = -1
    _animateOptionID = -1
    If page == "Outfits"
        SetCursorFillMode(LEFT_TO_RIGHT)
        AddHeaderOption("Selector")
        AddHeaderOption("Quick Slots")
        _openOptionID = AddTextOption("Open Outfit Preview Selector", "Open")
        AddEmptyOption()
        int i = 0
        While i < 10
            If CountOutfitItems(i) > 0
                _equipOptionIDs[i] = AddTextOption(GetOutfitName(i), "Equip")
            Else
                _equipOptionIDs[i] = AddTextOption(GetOutfitName(i) + " [Empty]", "-")
            EndIf
            _saveOptionIDs[i] = AddTextOption("Save current to " + SlotNum(i), "Save")
            i += 1
        EndWhile
    ElseIf page == "Settings"
        SetCursorFillMode(LEFT_TO_RIGHT)
        AddHeaderOption("Controls")
        AddHeaderOption("Behavior")
        _hotkeyOptionID = AddKeyMapOption("Open Selector Hotkey", Hotkey)
        _openOptionID = AddTextOption("Open Outfit Preview Selector", "Open")
        _notifyOptionID = AddToggleOption("Show notifications", ShowNotifications)
        _unequipOptionID = AddToggleOption("Unequip current gear first", UnequipBeforeEquip)
        _animateOptionID = AddToggleOption("Animate player in preview", AnimatePlayerPreview)
        _scaleOptionID = AddSliderOption("Menu scale", MenuScale * 100.0, "{0}%")
    EndIf
EndEvent

Event OnOptionSelect(int option)
    If option == _openOptionID
        OpenSelector()
        Return
    ElseIf option == _notifyOptionID
        ShowNotifications = !ShowNotifications
        SetToggleOptionValue(_notifyOptionID, ShowNotifications)
        Return
    ElseIf option == _unequipOptionID
        UnequipBeforeEquip = !UnequipBeforeEquip
        SetToggleOptionValue(_unequipOptionID, UnequipBeforeEquip)
        Return
    ElseIf option == _animateOptionID
        AnimatePlayerPreview = !AnimatePlayerPreview
        SetToggleOptionValue(_animateOptionID, AnimatePlayerPreview)
        If _menuOpen
            ApplyMenuSettings()
        EndIf
        Return
    ElseIf option == _debugFocusOptionID
        DebugFocusHighlight = !DebugFocusHighlight
        SetToggleOptionValue(_debugFocusOptionID, DebugFocusHighlight)
        Return
    EndIf

    int i = 0
    While i < 10
        If option == _saveOptionIDs[i]
            SaveCurrentOutfit(i)
            ForcePageReset()
            Return
        ElseIf option == _equipOptionIDs[i]
            ApplyOutfit(i)
            ForcePageReset()
            Return
        EndIf
        i += 1
    EndWhile
EndEvent

Event OnOptionSliderOpen(int option)
    If option == _scaleOptionID
        SetSliderDialogStartValue(MenuScale * 100.0)
        SetSliderDialogDefaultValue(90.0)
        SetSliderDialogRange(45.0, 100.0)
        SetSliderDialogInterval(5.0)
    EndIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
    If option == _scaleOptionID
        MenuScale = value / 100.0
        SetSliderOptionValue(_scaleOptionID, value, "{0}%")
        If _menuOpen
            ApplyMenuSettings()
        EndIf
    EndIf
EndEvent

Event OnOptionKeyMapChange(int option, int keyCode, string conflictControl, string conflictScope)
    If option == _hotkeyOptionID
        UnregisterForKey(Hotkey)
        Hotkey = keyCode
        RegisterForKey(Hotkey)
        SetKeyMapOptionValue(_hotkeyOptionID, Hotkey)
    EndIf
EndEvent

Event OnKeyDown(int keyCode)
    If _menuOpen && (keyCode == _escapeKey || keyCode == _escapeAsciiKey)
        UI.CloseCustomMenu()
        Return
    EndIf
    If keyCode == Hotkey && !Utility.IsInMenuMode()
        OpenSelector()
    EndIf
EndEvent

Function InitSettings()
    If !SettingsInitialized
        SettingsInitialized = true
        Hotkey = 79
        ShowNotifications = true
        UnequipBeforeEquip = true
        DebugFocusHighlight = false
        AnimatePlayerPreview = true
        MenuScale = 0.90
        SettingsVersion = 34
    EndIf
    If SettingsVersion < 21
        MenuScale = 0.8
    EndIf
    If SettingsVersion < 22
        DebugFocusHighlight = false
        SettingsVersion = 22
    EndIf
    If SettingsVersion < 23
        SettingsVersion = 23
    EndIf
    If SettingsVersion < 24
        SettingsVersion = 24
    EndIf
    If SettingsVersion < 25
        SettingsVersion = 25
    EndIf
    If SettingsVersion < 26
        MenuScale = MenuScale * 0.7
        SettingsVersion = 26
    EndIf
    If SettingsVersion < 27
        MenuScale = 0.56
        SettingsVersion = 27
    EndIf
    If SettingsVersion < 28
        SettingsVersion = 28
    EndIf
    If SettingsVersion < 29
        SettingsVersion = 29
    EndIf
    If SettingsVersion < 30
        If MenuScale >= 0.54 && MenuScale <= 0.58
            MenuScale = 0.80
        EndIf
        SettingsVersion = 30
    EndIf
    If SettingsVersion < 31
        If MenuScale >= 0.78 && MenuScale <= 0.82
            MenuScale = 0.90
        EndIf
        SettingsVersion = 31
    EndIf
    If SettingsVersion < 32
        AnimatePlayerPreview = true
        SettingsVersion = 32
    EndIf
    If SettingsVersion < 33
        SettingsVersion = 33
    EndIf
    If SettingsVersion < 34
        AnimatePlayerPreview = true
        SettingsVersion = 34
    EndIf
    DebugFocusHighlight = false
    If Hotkey == 0
        Hotkey = 79
    EndIf
    If MenuScale <= 0.0
        MenuScale = 0.90
    ElseIf MenuScale < 0.45
        MenuScale = 0.45
    ElseIf MenuScale > 1.0
        MenuScale = 1.0
    EndIf
EndFunction

Function InitArrays()
    If !OutfitNames || OutfitNames.Length < 10
        OutfitNames = new string[10]
    EndIf
    int i = 0
    While i < 10
        If OutfitNames[i] == ""
            OutfitNames[i] = "Outfit " + (i + 1)
        EndIf
        i += 1
    EndWhile
    Outfit1 = EnsureArray(Outfit1)
    Outfit2 = EnsureArray(Outfit2)
    Outfit3 = EnsureArray(Outfit3)
    Outfit4 = EnsureArray(Outfit4)
    Outfit5 = EnsureArray(Outfit5)
    Outfit6 = EnsureArray(Outfit6)
    Outfit7 = EnsureArray(Outfit7)
    Outfit8 = EnsureArray(Outfit8)
    Outfit9 = EnsureArray(Outfit9)
    Outfit10 = EnsureArray(Outfit10)
EndFunction

Form[] Function EnsureArray(Form[] items)
    If items && items.Length >= 32
        Return items
    EndIf
    Form[] fixedItems = new Form[32]
    int i = 0
    While items && i < items.Length && i < fixedItems.Length
        fixedItems[i] = items[i]
        i += 1
    EndWhile
    Return fixedItems
EndFunction

Function OpenSelector()
    InitSettings()
    InitArrays()
    RegisterForKey(_escapeKey)
    RegisterForKey(_escapeAsciiKey)

    Actor player = Game.GetPlayer()
    _lastPlayerX = player.GetAngleX()
    _lastPlayerY = player.GetAngleY()
    _lastPlayerZ = player.GetAngleZ()
    _menuOpen = true

    SendModEvent("OPS_NativePreviewOpen", "", 0.0)
    UI.OpenCustomMenu("OutfitPreviewSelector32/menu")
EndFunction

Function RegisterMenuEvents()
    RegisterForModEvent("OPS_MenuReady", "OnMenuReady")
    RegisterForModEvent("OPS_ApplySlot", "OnApplySlot")
    RegisterForModEvent("OPS_SaveSlot", "OnSaveSlot")
    RegisterForModEvent("OPS_RenameSlot", "OnRenameSlot")
    RegisterForModEvent("OPS_ClearSlot", "OnClearSlot")
    RegisterForModEvent("OPS_CloseMenu", "OnCloseMenu")
    RegisterForModEvent("OPS_MenuClosed", "OnMenuClosed")
    RegisterForModEvent("OPS_NativeMouseClick", "OnNativeMouseClick")
    RegisterForModEvent("OPS_NativeMouseMove", "OnNativeMouseMove")
EndFunction

Event OnMenuReady(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    ApplyMenuSettings()
    RefreshMenuSlots()
    UpdateCurrentOutfit(true)
EndEvent

Function ApplyMenuSettings()
    UI.InvokeFloat("CustomMenu", "_root.main.setMenuScale", MenuScale)
    UI.InvokeBool("CustomMenu", "_root.main.setDebugFocusHighlight", false)
    UI.InvokeBool("CustomMenu", "_root.main.setIdleAnimationEnabled", AnimatePlayerPreview)
EndFunction

Event OnApplySlot(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    int index = numArg as int
    _currentOutfit = index
    ApplyOutfit(index)
    UpdateCurrentOutfit(true)
EndEvent

Event OnSaveSlot(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    SaveCurrentOutfit(numArg as int)
    RefreshMenuSlots()
    UpdateCurrentOutfit(true)
EndEvent

Event OnRenameSlot(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    RenameOutfit(numArg as int, strArg)
    RefreshMenuSlots()
    UpdateCurrentOutfit(true)
EndEvent

Event OnClearSlot(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    ClearOutfit(numArg as int)
    RefreshMenuSlots()
    UpdateCurrentOutfit(true)
EndEvent

Event OnCloseMenu(string eventName, string strArg, float numArg, Form sender)
    If _menuOpen
        UI.CloseCustomMenu()
    EndIf
EndEvent

Event OnNativeMouseClick(string eventName, string strArg, float numArg, Form sender)
    If _menuOpen
        UI.InvokeString("CustomMenu", "_root.main.nativeMouseClick", strArg)
    EndIf
EndEvent

Event OnNativeMouseMove(string eventName, string strArg, float numArg, Form sender)
    If _menuOpen
        UI.InvokeString("CustomMenu", "_root.main.nativeMouseMove", strArg)
    EndIf
EndEvent

Event OnMenuClosed(string eventName, string strArg, float numArg, Form sender)
    CloseSelectorState()
EndEvent

Function CloseSelectorState()
    If !_menuOpen
        Return
    EndIf
    _currentOutfit = FindCurrentOutfit()
    UnregisterForKey(_escapeKey)
    UnregisterForKey(_escapeAsciiKey)
    RegisterForKey(Hotkey)
    SendModEvent("OPS_NativePreviewClose", "", 0.0)
    Actor player = Game.GetPlayer()
    player.SetAngle(_lastPlayerX, _lastPlayerY, _lastPlayerZ)
    _menuOpen = false
EndFunction

Function RefreshMenuSlots()
    If !_menuRows || _menuRows.Length < 10
        BuildMenuRowsCache()
    EndIf
    UI.InvokeStringA("CustomMenu", "_root.main.setSlots", _menuRows)
EndFunction

Function BuildMenuRowsCache()
    _menuRows = new string[10]
    _outfitCounts = new int[10]
    int i = 0
    While i < 10
        UpdateMenuRowCache(i)
        i += 1
    EndWhile
EndFunction

Function UpdateMenuRowCache(int index)
    If index < 0 || index >= 10
        Return
    EndIf
    If !_menuRows || _menuRows.Length < 10
        _menuRows = new string[10]
    EndIf
    If !_outfitCounts || _outfitCounts.Length < 10
        _outfitCounts = new int[10]
    EndIf

    Form[] items = GetOutfitArray(index)
    int count = 0
    int armorRating = 0
    string itemText = ""
    int shown = 0
    int i = 0
    While items && i < items.Length
        If items[i]
            count += 1
            Armor armorItem = items[i] as Armor
            If armorItem
                armorRating += armorItem.GetArmorRating()
            EndIf
            If shown < 12
                string itemName = items[i].GetName()
                If itemName == ""
                    itemName = "Item"
                EndIf
                If itemText == ""
                    itemText = itemName
                Else
                    itemText = itemText + "~" + itemName
                EndIf
                shown += 1
            EndIf
        EndIf
        i += 1
    EndWhile

    int ready = 0
    If count > 0
        ready = 1
    EndIf
    _outfitCounts[index] = count
    _menuRows[index] = index + "|" + GetOutfitName(index) + "|" + FormatCount(count) + "|" + ready + "|" + armorRating + "|" + itemText
EndFunction

int Function GetCachedOutfitCount(int index)
    If !_outfitCounts || _outfitCounts.Length < 10
        BuildMenuRowsCache()
    EndIf
    If index < 0 || index >= 10
        Return 0
    EndIf
    Return _outfitCounts[index]
EndFunction

Function UpdateCurrentOutfit(bool forceUpdate = false)
    int matchedOutfit = FindCurrentOutfit()
    If forceUpdate || matchedOutfit != _currentOutfit
        _currentOutfit = matchedOutfit
        If _menuOpen
            UI.InvokeInt("CustomMenu", "_root.main.setCurrentOutfit", _currentOutfit)
        EndIf
    EndIf
EndFunction

int Function FindCurrentOutfit()
    Form[] wornArmor = GetCurrentArmor()
    If _currentOutfit >= 0 && _currentOutfit < 10 && OutfitMatchesCurrentArmor(_currentOutfit, wornArmor)
        Return _currentOutfit
    EndIf

    int i = 0
    While i < 10
        If OutfitMatchesCurrentArmor(i, wornArmor)
            Return i
        EndIf
        i += 1
    EndWhile
    Return -1
EndFunction

Form[] Function GetCurrentArmor()
    Form[] wornArmor = new Form[32]
    Actor player = Game.GetPlayer()
    int found = 0
    int slot = 30
    While slot <= 61 && found < wornArmor.Length
        Armor worn = player.GetWornForm(Armor.GetMaskForSlot(slot)) as Armor
        If worn && !Contains(wornArmor, worn)
            wornArmor[found] = worn
            found += 1
        EndIf
        slot += 1
    EndWhile
    Return wornArmor
EndFunction

bool Function OutfitMatchesCurrentArmor(int index, Form[] wornArmor)
    Form[] items = GetOutfitArray(index)
    int itemCount = GetCachedOutfitCount(index)
    If !items || itemCount == 0 || CountForms(wornArmor) != itemCount
        Return false
    EndIf

    int i = 0
    While i < items.Length
        If items[i]
            Armor armorItem = items[i] as Armor
            If !armorItem || !Contains(wornArmor, armorItem)
                Return false
            EndIf
        EndIf
        i += 1
    EndWhile
    Return true
EndFunction

int Function CountForms(Form[] items)
    If !items
        Return 0
    EndIf
    int count = 0
    int i = 0
    While i < items.Length
        If items[i]
            count += 1
        EndIf
        i += 1
    EndWhile
    Return count
EndFunction

Function SaveCurrentOutfit(int index)
    If index < 0 || index >= 10
        Return
    EndIf
    Form[] items = GetOutfitArray(index)
    If !items
        Return
    EndIf

    int i = 0
    While i < items.Length
        items[i] = None
        i += 1
    EndWhile

    Actor player = Game.GetPlayer()
    int saved = 0
    int slot = 30
    While slot <= 61 && saved < items.Length
        Armor worn = player.GetWornForm(Armor.GetMaskForSlot(slot)) as Armor
        If worn && !Contains(items, worn)
            items[saved] = worn
            saved += 1
        EndIf
        slot += 1
    EndWhile
    UpdateMenuRowCache(index)
    Notify("Saved " + saved + " pieces to " + GetOutfitName(index))
EndFunction

Function RenameOutfit(int index, string newName)
    If index < 0 || index >= 10
        Return
    EndIf
    If !OutfitNames || OutfitNames.Length < 10
        InitArrays()
    EndIf
    If newName == ""
        newName = "Outfit " + (index + 1)
    EndIf
    OutfitNames[index] = newName
    UpdateMenuRowCache(index)
    Notify("Renamed outfit " + SlotNum(index))
EndFunction

Function ClearOutfit(int index)
    If index < 0 || index >= 10
        Return
    EndIf
    Form[] items = GetOutfitArray(index)
    If !items
        Return
    EndIf
    int i = 0
    While i < items.Length
        items[i] = None
        i += 1
    EndWhile
    UpdateMenuRowCache(index)
    Notify("Cleared " + GetOutfitName(index))
EndFunction

Function ApplyOutfit(int index)
    If index < 0 || index >= 10 || GetCachedOutfitCount(index) == 0
        Return
    EndIf
    Form[] items = GetOutfitArray(index)
    Actor player = Game.GetPlayer()
    If UnequipBeforeEquip
        UnequipCurrentArmor(player)
    EndIf
    int i = 0
    While i < items.Length
        If items[i]
            player.EquipItem(items[i], false, true)
        EndIf
        i += 1
    EndWhile
    player.QueueNiNodeUpdate()
EndFunction

Function UnequipCurrentArmor(Actor player)
    int slot = 30
    While slot <= 61
        Armor worn = player.GetWornForm(Armor.GetMaskForSlot(slot)) as Armor
        If worn
            player.UnequipItem(worn, false, true)
        EndIf
        slot += 1
    EndWhile
EndFunction

Form[] Function GetOutfitArray(int index)
    If index == 0
        Return Outfit1
    ElseIf index == 1
        Return Outfit2
    ElseIf index == 2
        Return Outfit3
    ElseIf index == 3
        Return Outfit4
    ElseIf index == 4
        Return Outfit5
    ElseIf index == 5
        Return Outfit6
    ElseIf index == 6
        Return Outfit7
    ElseIf index == 7
        Return Outfit8
    ElseIf index == 8
        Return Outfit9
    ElseIf index == 9
        Return Outfit10
    EndIf
    Return None
EndFunction

int Function CountOutfitItems(int index)
    Form[] items = GetOutfitArray(index)
    If !items
        Return 0
    EndIf
    int count = 0
    int i = 0
    While i < items.Length
        If items[i]
            count += 1
        EndIf
        i += 1
    EndWhile
    Return count
EndFunction

string Function GetOutfitItemsText(int index)
    Form[] items = GetOutfitArray(index)
    If !items
        Return ""
    EndIf
    string result = ""
    int shown = 0
    int i = 0
    While i < items.Length && shown < 12
        If items[i]
            string itemName = items[i].GetName()
            If itemName == ""
                itemName = "Item"
            EndIf
            If result == ""
                result = itemName
            Else
                result = result + "~" + itemName
            EndIf
            shown += 1
        EndIf
        i += 1
    EndWhile
    Return result
EndFunction

int Function GetOutfitArmorRating(int index)
    Form[] items = GetOutfitArray(index)
    If !items
        Return 0
    EndIf
    int total = 0
    int i = 0
    While i < items.Length
        Armor armorItem = items[i] as Armor
        If armorItem
            total += armorItem.GetArmorRating()
        EndIf
        i += 1
    EndWhile
    Return total
EndFunction

bool Function Contains(Form[] items, Form item)
    int i = 0
    While i < items.Length
        If items[i] == item
            Return true
        EndIf
        i += 1
    EndWhile
    Return false
EndFunction

string Function GetOutfitName(int index)
    If OutfitNames && index >= 0 && index < OutfitNames.Length && OutfitNames[index] != ""
        Return OutfitNames[index]
    EndIf
    Return "Outfit " + (index + 1)
EndFunction

string Function FormatCount(int count)
    If count == 1
        Return "1 piece"
    EndIf
    Return count + " pieces"
EndFunction

string Function SlotNum(int index)
    If index < 9
        Return "0" + (index + 1)
    EndIf
    Return "" + (index + 1)
EndFunction

float Function NormalizeAngle(float value)
    While value >= 360.0
        value -= 360.0
    EndWhile
    While value < 0.0
        value += 360.0
    EndWhile
    Return value
EndFunction

Function Notify(string message)
    If ShowNotifications
        Debug.Notification(message)
    EndIf
EndFunction
