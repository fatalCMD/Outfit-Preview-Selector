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

; Slots 11-50 are script-backed persistent variables. Slots 1-10 remain
; properties so existing plugin records and saved outfits stay compatible.
Form[] Outfit11
Form[] Outfit12
Form[] Outfit13
Form[] Outfit14
Form[] Outfit15
Form[] Outfit16
Form[] Outfit17
Form[] Outfit18
Form[] Outfit19
Form[] Outfit20
Form[] Outfit21
Form[] Outfit22
Form[] Outfit23
Form[] Outfit24
Form[] Outfit25
Form[] Outfit26
Form[] Outfit27
Form[] Outfit28
Form[] Outfit29
Form[] Outfit30
Form[] Outfit31
Form[] Outfit32
Form[] Outfit33
Form[] Outfit34
Form[] Outfit35
Form[] Outfit36
Form[] Outfit37
Form[] Outfit38
Form[] Outfit39
Form[] Outfit40
Form[] Outfit41
Form[] Outfit42
Form[] Outfit43
Form[] Outfit44
Form[] Outfit45
Form[] Outfit46
Form[] Outfit47
Form[] Outfit48
Form[] Outfit49
Form[] Outfit50

string[] Property OutfitNames Auto
string[] Property OutfitIcons Auto
int Property Hotkey Auto
bool Property SettingsInitialized Auto
bool Property ShowNotifications Auto
bool Property UnequipBeforeEquip Auto
bool Property DebugFocusHighlight Auto
bool Property AnimatePlayerPreview Auto
float Property MenuScale Auto
bool Property CardView Auto
float Property CameraSide Auto
float Property CameraHeight Auto
int Property SettingsVersion Auto

int _hotkeyOptionID = -1
int _openOptionID = -1
int _notifyOptionID = -1
int _unequipOptionID = -1
int _debugFocusOptionID = -1
int _animateOptionID = -1
int _scaleOptionID = -1
int _cardViewOptionID = -1
int _cameraSideOptionID = -1
int _cameraHeightOptionID = -1
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
string _lastApplyMessage = ""

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
    _saveOptionIDs = new int[50]
    _equipOptionIDs = new int[50]
    InitSettings()
    InitArrays()
    BuildMenuRowsCache()
    RegisterMenuEvents()
    RegisterForKey(Hotkey)
EndEvent

Event OnPageReset(string page)
    _debugFocusOptionID = -1
    _animateOptionID = -1
    _cardViewOptionID = -1
    If page == "Outfits"
        SetCursorFillMode(LEFT_TO_RIGHT)
        AddHeaderOption("Selector")
        AddHeaderOption("Quick Slots")
        _openOptionID = AddTextOption("Open Outfit Preview Selector", "Open")
        AddEmptyOption()
        int i = 0
        While i < 50
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
        _cardViewOptionID = AddToggleOption("Default card view", CardView)
        _cameraSideOptionID = AddSliderOption("Camera horizontal", CameraSide, "{0}")
        _cameraHeightOptionID = AddSliderOption("Camera height", CameraHeight, "{0}")
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
    ElseIf option == _cardViewOptionID
        CardView = !CardView
        SetToggleOptionValue(_cardViewOptionID, CardView)
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
    While i < 50
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
    ElseIf option == _cameraSideOptionID
        SetSliderDialogStartValue(CameraSide)
        SetSliderDialogDefaultValue(-54.0)
        SetSliderDialogRange(-160.0, 160.0)
        SetSliderDialogInterval(2.0)
    ElseIf option == _cameraHeightOptionID
        SetSliderDialogStartValue(CameraHeight)
        SetSliderDialogDefaultValue(-24.0)
        SetSliderDialogRange(-120.0, 120.0)
        SetSliderDialogInterval(2.0)
    EndIf
EndEvent

Event OnOptionSliderAccept(int option, float value)
    If option == _scaleOptionID
        MenuScale = value / 100.0
        SetSliderOptionValue(_scaleOptionID, value, "{0}%")
        If _menuOpen
            ApplyMenuSettings()
        EndIf
    ElseIf option == _cameraSideOptionID
        CameraSide = value
        SetSliderOptionValue(_cameraSideOptionID, value, "{0}")
        If _menuOpen
            ApplyMenuSettings()
        EndIf
    ElseIf option == _cameraHeightOptionID
        CameraHeight = value
        SetSliderOptionValue(_cameraHeightOptionID, value, "{0}")
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
        CardView = false
        CameraSide = -54.0
        CameraHeight = -24.0
        SettingsVersion = 37
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
    If SettingsVersion < 35
        SettingsVersion = 35
    EndIf
    If SettingsVersion < 36
        CardView = false
        CameraSide = -54.0
        CameraHeight = -24.0
        SettingsVersion = 36
    EndIf
    If SettingsVersion < 37
        SettingsVersion = 37
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
    If !_saveOptionIDs || _saveOptionIDs.Length < 50
        _saveOptionIDs = new int[50]
    EndIf
    If !_equipOptionIDs || _equipOptionIDs.Length < 50
        _equipOptionIDs = new int[50]
    EndIf
    string[] oldNames = OutfitNames
    If !OutfitNames || OutfitNames.Length < 50
        OutfitNames = new string[50]
        int oldIndex = 0
        While oldNames && oldIndex < oldNames.Length && oldIndex < OutfitNames.Length
            OutfitNames[oldIndex] = oldNames[oldIndex]
            oldIndex += 1
        EndWhile
    EndIf
    string[] oldIcons = OutfitIcons
    If !OutfitIcons || OutfitIcons.Length < 50
        OutfitIcons = new string[50]
        int oldIconIndex = 0
        While oldIcons && oldIconIndex < oldIcons.Length && oldIconIndex < OutfitIcons.Length
            OutfitIcons[oldIconIndex] = oldIcons[oldIconIndex]
            oldIconIndex += 1
        EndWhile
    EndIf
    int i = 0
    While i < 50
        If OutfitNames[i] == ""
            OutfitNames[i] = "Outfit " + (i + 1)
        EndIf
        If OutfitIcons[i] == ""
            OutfitIcons[i] = "auto"
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
    Outfit11 = EnsureArray(Outfit11)
    Outfit12 = EnsureArray(Outfit12)
    Outfit13 = EnsureArray(Outfit13)
    Outfit14 = EnsureArray(Outfit14)
    Outfit15 = EnsureArray(Outfit15)
    Outfit16 = EnsureArray(Outfit16)
    Outfit17 = EnsureArray(Outfit17)
    Outfit18 = EnsureArray(Outfit18)
    Outfit19 = EnsureArray(Outfit19)
    Outfit20 = EnsureArray(Outfit20)
    Outfit21 = EnsureArray(Outfit21)
    Outfit22 = EnsureArray(Outfit22)
    Outfit23 = EnsureArray(Outfit23)
    Outfit24 = EnsureArray(Outfit24)
    Outfit25 = EnsureArray(Outfit25)
    Outfit26 = EnsureArray(Outfit26)
    Outfit27 = EnsureArray(Outfit27)
    Outfit28 = EnsureArray(Outfit28)
    Outfit29 = EnsureArray(Outfit29)
    Outfit30 = EnsureArray(Outfit30)
    Outfit31 = EnsureArray(Outfit31)
    Outfit32 = EnsureArray(Outfit32)
    Outfit33 = EnsureArray(Outfit33)
    Outfit34 = EnsureArray(Outfit34)
    Outfit35 = EnsureArray(Outfit35)
    Outfit36 = EnsureArray(Outfit36)
    Outfit37 = EnsureArray(Outfit37)
    Outfit38 = EnsureArray(Outfit38)
    Outfit39 = EnsureArray(Outfit39)
    Outfit40 = EnsureArray(Outfit40)
    Outfit41 = EnsureArray(Outfit41)
    Outfit42 = EnsureArray(Outfit42)
    Outfit43 = EnsureArray(Outfit43)
    Outfit44 = EnsureArray(Outfit44)
    Outfit45 = EnsureArray(Outfit45)
    Outfit46 = EnsureArray(Outfit46)
    Outfit47 = EnsureArray(Outfit47)
    Outfit48 = EnsureArray(Outfit48)
    Outfit49 = EnsureArray(Outfit49)
    Outfit50 = EnsureArray(Outfit50)
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
    RegisterForModEvent("OPS_SetCardView", "OnSetCardView")
    RegisterForModEvent("OPS_SetIcon", "OnSetIcon")
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
    UI.InvokeBool("CustomMenu", "_root.main.setCardView", CardView)
    UI.InvokeString("CustomMenu", "_root.main.setCameraOffsets", CameraSide + "|" + CameraHeight)
EndFunction

Event OnSetCardView(string eventName, string strArg, float numArg, Form sender)
    CardView = numArg > 0.0
EndEvent

Event OnSetIcon(string eventName, string strArg, float numArg, Form sender)
    int index = numArg as int
    If index < 0 || index >= 50
        Return
    EndIf
    string icon = NormalizeIcon(strArg)
    OutfitIcons[index] = icon
    UpdateMenuRowCache(index)
    RefreshMenuSlots()
EndEvent

Event OnApplySlot(string eventName, string strArg, float numArg, Form sender)
    If !_menuOpen
        Return
    EndIf
    int index = numArg as int
    _currentOutfit = index
    bool applied = ApplyOutfit(index)
    UpdateCurrentOutfit(true)
    int appliedValue = 0
    If applied
        appliedValue = 1
    EndIf
    UI.InvokeString("CustomMenu", "_root.main.setEquipResult", index + "|" + appliedValue + "|" + _lastApplyMessage)
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
    If !_menuRows || _menuRows.Length < 50
        BuildMenuRowsCache()
    EndIf
    UI.InvokeStringA("CustomMenu", "_root.main.setSlots", _menuRows)
EndFunction

Function BuildMenuRowsCache()
    _menuRows = new string[50]
    _outfitCounts = new int[50]
    int i = 0
    While i < 50
        UpdateMenuRowCache(i)
        i += 1
    EndWhile
EndFunction

Function UpdateMenuRowCache(int index)
    If index < 0 || index >= 50
        Return
    EndIf
    If !_menuRows || _menuRows.Length < 50
        _menuRows = new string[50]
    EndIf
    If !_outfitCounts || _outfitCounts.Length < 50
        _outfitCounts = new int[50]
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
    _menuRows[index] = index + "|" + GetOutfitName(index) + "|" + FormatCount(count) + "|" + ready + "|" + armorRating + "|" + itemText + "|" + GetOutfitIcon(index)
EndFunction

string Function GetOutfitIcon(int index)
    If OutfitIcons && index >= 0 && index < OutfitIcons.Length
        Return NormalizeIcon(OutfitIcons[index])
    EndIf
    Return "auto"
EndFunction

string Function NormalizeIcon(string icon)
    If icon == "armor" || icon == "heavy" || icon == "light" || icon == "arcane" || icon == "clothing"
        Return icon
    EndIf
    Return "auto"
EndFunction

int Function GetCachedOutfitCount(int index)
    If !_outfitCounts || _outfitCounts.Length < 50
        BuildMenuRowsCache()
    EndIf
    If index < 0 || index >= 50
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
    If _currentOutfit >= 0 && _currentOutfit < 50 && OutfitMatchesCurrentArmor(_currentOutfit, wornArmor)
        Return _currentOutfit
    EndIf

    int i = 0
    While i < 50
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
    If index < 0 || index >= 50
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
    If index < 0 || index >= 50
        Return
    EndIf
    If !OutfitNames || OutfitNames.Length < 50
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
    If index < 0 || index >= 50
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

bool Function ApplyOutfit(int index)
    _lastApplyMessage = ""
    If index < 0 || index >= 50 || GetCachedOutfitCount(index) == 0
        _lastApplyMessage = "Outfit is empty"
        Return false
    EndIf
    Form[] items = GetOutfitArray(index)
    Actor player = Game.GetPlayer()

    int missingCount = 0
    int namedMissing = 0
    string missingNames = ""
    int checkIndex = 0
    While checkIndex < items.Length
        If items[checkIndex] && player.GetItemCount(items[checkIndex]) <= 0
            missingCount += 1
            If namedMissing < 4
                string missingName = items[checkIndex].GetName()
                If missingName == ""
                    missingName = "Unknown item"
                EndIf
                If missingNames == ""
                    missingNames = missingName
                Else
                    missingNames = missingNames + ", " + missingName
                EndIf
                namedMissing += 1
            EndIf
        EndIf
        checkIndex += 1
    EndWhile

    If missingCount > 0
        If missingCount > namedMissing
            missingNames = missingNames + " +" + (missingCount - namedMissing) + " more"
        EndIf
        _lastApplyMessage = "Missing: " + missingNames
        If !_menuOpen
            Notify("Cannot equip " + GetOutfitName(index) + ". " + _lastApplyMessage)
        EndIf
        Return false
    EndIf

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
    _lastApplyMessage = "Equipped " + GetOutfitName(index)
    Return true
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
    ElseIf index == 10
        Return Outfit11
    ElseIf index == 11
        Return Outfit12
    ElseIf index == 12
        Return Outfit13
    ElseIf index == 13
        Return Outfit14
    ElseIf index == 14
        Return Outfit15
    ElseIf index == 15
        Return Outfit16
    ElseIf index == 16
        Return Outfit17
    ElseIf index == 17
        Return Outfit18
    ElseIf index == 18
        Return Outfit19
    ElseIf index == 19
        Return Outfit20
    ElseIf index == 20
        Return Outfit21
    ElseIf index == 21
        Return Outfit22
    ElseIf index == 22
        Return Outfit23
    ElseIf index == 23
        Return Outfit24
    ElseIf index == 24
        Return Outfit25
    ElseIf index == 25
        Return Outfit26
    ElseIf index == 26
        Return Outfit27
    ElseIf index == 27
        Return Outfit28
    ElseIf index == 28
        Return Outfit29
    ElseIf index == 29
        Return Outfit30
    ElseIf index == 30
        Return Outfit31
    ElseIf index == 31
        Return Outfit32
    ElseIf index == 32
        Return Outfit33
    ElseIf index == 33
        Return Outfit34
    ElseIf index == 34
        Return Outfit35
    ElseIf index == 35
        Return Outfit36
    ElseIf index == 36
        Return Outfit37
    ElseIf index == 37
        Return Outfit38
    ElseIf index == 38
        Return Outfit39
    ElseIf index == 39
        Return Outfit40
    ElseIf index == 40
        Return Outfit41
    ElseIf index == 41
        Return Outfit42
    ElseIf index == 42
        Return Outfit43
    ElseIf index == 43
        Return Outfit44
    ElseIf index == 44
        Return Outfit45
    ElseIf index == 45
        Return Outfit46
    ElseIf index == 46
        Return Outfit47
    ElseIf index == 47
        Return Outfit48
    ElseIf index == 48
        Return Outfit49
    ElseIf index == 49
        Return Outfit50
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
