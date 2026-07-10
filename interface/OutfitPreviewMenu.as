class OutfitPreviewMenu {
    private var root:MovieClip;
    private var panel:MovieClip;
    private var slots:Array;
    private var selected:Number;
    private var nextDepth:Number;
    private var keyListener:Object;
    private var mouseListener:Object;
    private var clickZones:Array;
    private var dragging:Boolean;
    private var lastMouseX:Number;
    private var lastApplied:Number;
    private var viewMode:String;
    private var editIndex:Number;
    private var renameField:TextField;
    private var initialized:Boolean;
    private var editingName:Boolean;
    private var listColumn:Number;
    private var navCursorVisible:Boolean;
    private var useHandleInput:Boolean;
    private var listRow:Number;
    private var detailFocus:Number;
    private var lastInputTime:Number;
    private var textInputAllowed:Boolean;
    private var lastRealMouseX:Number;
    private var lastRealMouseY:Number;
    private var menuScale:Number;
    private var debugFocusHighlight:Boolean;
    private var closing:Boolean;
    private var lastInputAction:String;
    private var escWasDown:Boolean;
    private var lastMouseHitTime:Number;
    private var nativeCursor:MovieClip;
    private var nativeMouseStageX:Number;
    private var nativeMouseStageY:Number;
    private var nativeMouseReady:Boolean;
    private var introPlayed:Boolean;
    private var animateCurrent:Boolean;
    private var idleAnimationEnabled:Boolean;
    private var lastIdleAnimationTime:Number;

    public function OutfitPreviewMenu(rootClip:MovieClip) {
        root = rootClip;
        root._lockroot = true;
        root.focusEnabled = false;
        root.tabEnabled = false;
        root.tabChildren = false;
        root._focusrect = false;
        slots = new Array();
        clickZones = new Array();
        selected = 0;
        nextDepth = 10;
        dragging = false;
        lastMouseX = 0;
        lastApplied = -1;
        viewMode = "list";
        editIndex = 0;
        initialized = false;
        editingName = false;
        listColumn = 0;
        navCursorVisible = false;
        useHandleInput = false;
        listRow = 0;
        detailFocus = 0;
        lastInputTime = 0;
        textInputAllowed = false;
        lastRealMouseX = _root._xmouse;
        lastRealMouseY = _root._ymouse;
        menuScale = 0.90;
        debugFocusHighlight = false;
        closing = false;
        lastInputAction = "";
        escWasDown = false;
        lastMouseHitTime = -999;
        nativeMouseStageX = _root._xmouse;
        nativeMouseStageY = _root._ymouse;
        nativeMouseReady = false;
        introPlayed = false;
        animateCurrent = false;
        idleAnimationEnabled = true;
        lastIdleAnimationTime = 0;

        installKeys();
        installMouse();
        draw();
        if (panel != undefined) {
            panel._alpha = 0;
        }
        disableFocusTarget(root);
        if (_root != undefined) {
            disableFocusTarget(_root);
        }
        if (_level0 != undefined) {
            disableFocusTarget(_level0);
        }
        Selection.setFocus(null);
        Mouse.show();

        var self:OutfitPreviewMenu = this;
        var boot:MovieClip = root.createEmptyMovieClip("opsBoot", 9998);
        boot.onEnterFrame = function():Void {
            delete this.onEnterFrame;
            self.sendEvent("OPS_MenuReady", "", 0);
            this.removeMovieClip();
        };

        root.onEnterFrame = function():Void {
            Mouse.show();
            self.pollEscape();
            self.tickPlayerIdleAnimation();
            self.updateNativeCursor();
        };

        root.onUnload = function():Void {
            self.setTextInputMode(false);
            Key.removeListener(self.keyListener);
            Mouse.removeListener(self.mouseListener);
            delete self.root.onEnterFrame;
            if (self.nativeCursor != undefined) {
                self.nativeCursor.removeMovieClip();
            }
            self.sendEvent("OPS_NativePreviewClose", "", 0);
            self.sendEvent("OPS_MenuClosed", "", 0);
        };
    }

    public function setSlots(raw:Object):Void {
        slots = new Array();
        var rows:Array = new Array();
        var i:Number = 0;
        if (arguments.length > 1) {
            while (i < arguments.length && i < 10) {
                rows.push(String(arguments[i]));
                i++;
            }
        } else if (raw != undefined) {
            if (typeof(raw) == "string") {
                rows.push(String(raw));
            } else {
                while (i < raw.length && i < 10) {
                    rows.push(String(raw[i]));
                    i++;
                }
            }
        }

        i = 0;
        while (i < rows.length && i < 10) {
            slots.push(parseSlot(String(rows[i])));
            i++;
        }

        if (selected < 0) {
            selected = 0;
        }
        if (selected >= slots.length) {
            selected = slots.length - 1;
        }
        if (selected < 0) {
            selected = 0;
        }
        editIndex = selected;
        listRow = selected;
        initialized = true;
        draw();
        if (!introPlayed) {
            introPlayed = true;
            animatePanelIntro();
        }
    }

    public function setCurrentOutfit(slotIndex:Number):Void {
        if (isNaN(slotIndex) || slotIndex < 0 || slotIndex >= 10) {
            slotIndex = -1;
        }
        var changed:Boolean = lastApplied != slotIndex;
        if (changed) {
            lastApplied = slotIndex;
            animateCurrent = slotIndex >= 0;
            draw();
        }
    }

    public function setIdleAnimationEnabled(enabled:Boolean):Void {
        idleAnimationEnabled = enabled;
        lastIdleAnimationTime = 0;
        if (_global.skse != undefined && _global.skse.plugins != undefined) {
            var api:Object = _global.skse.plugins.OutfitPreviewSelectorCamera;
            if (api != undefined && api.ReportPreviewAnimationState != undefined) {
                api.ReportPreviewAnimationState(enabled);
            }
        }
    }

    public function nativeMouseClick(raw:String):Void {
        var handled:Boolean = false;
        rememberNativeMouse(raw);
        updateNativeCursor();

        var parts:Array = safe(raw).split("|");
        if (parts.length >= 2) {
            var rawX:Number = Number(parts[0]);
            var rawY:Number = Number(parts[1]);
            var nativeW:Number = Number(parts[2]);
            var nativeH:Number = Number(parts[3]);
            var stageW:Number = Number(Stage.width);
            var stageH:Number = Number(Stage.height);

            if (!isNaN(rawX) && !isNaN(rawY)) {
                if (!isNaN(nativeW) && nativeW > 0 && !isNaN(nativeH) && nativeH > 0) {
                    if (!isNaN(stageW) && stageW > 0 && !isNaN(stageH) && stageH > 0) {
                        handled = runMouseHitActionAt(rawX * stageW / nativeW, rawY * stageH / nativeH);
                    }
                    if (!handled) {
                        handled = runMouseHitActionAt(rawX * 1280 / nativeW, rawY * 720 / nativeH);
                    }
                }
                if (!handled) {
                    handled = runMouseHitActionAt(rawX, rawY);
                }
            }
        }

        if (!handled) {
            if (nativeMouseReady) {
                handled = runMouseHitActionAt(nativeMouseStageX, nativeMouseStageY);
            }
            if (!handled) {
                runMouseHitAction();
            }
        }
    }

    public function nativeMouseMove(raw:String):Void {
        if (rememberNativeMouse(raw)) {
            noteMouseInput(true);
            updateNativeCursor();
        }
    }

    private function rememberNativeMouse(raw:String):Boolean {
        var parts:Array = safe(raw).split("|");
        if (parts.length < 2) {
            return false;
        }

        var rawX:Number = Number(parts[0]);
        var rawY:Number = Number(parts[1]);
        if (isNaN(rawX) || isNaN(rawY)) {
            return false;
        }

        var nativeW:Number = Number(parts[2]);
        var nativeH:Number = Number(parts[3]);
        var stageW:Number = Number(Stage.width);
        var stageH:Number = Number(Stage.height);
        if (!isNaN(nativeW) && nativeW > 0 && !isNaN(nativeH) && nativeH > 0) {
            if (!isNaN(stageW) && stageW > 0 && !isNaN(stageH) && stageH > 0) {
                nativeMouseStageX = rawX * stageW / nativeW;
                nativeMouseStageY = rawY * stageH / nativeH;
            } else {
                nativeMouseStageX = rawX * 1280 / nativeW;
                nativeMouseStageY = rawY * 720 / nativeH;
            }
        } else {
            nativeMouseStageX = rawX;
            nativeMouseStageY = rawY;
        }

        nativeMouseReady = true;
        return true;
    }

    private function hideNativeCursor():Void {
        if (nativeCursor != undefined) {
            nativeCursor._visible = false;
        }
    }

    private function updateNativeCursor():Void {
        if (!nativeMouseReady) {
            hideNativeCursor();
            return;
        }

        ensureNativeCursor();
        nativeCursor._x = nativeMouseStageX;
        nativeCursor._y = nativeMouseStageY;
        nativeCursor._visible = true;
        Mouse.show();
    }

    private function ensureNativeCursor():Void {
        if (nativeCursor != undefined) {
            return;
        }

        nativeCursor = root.createEmptyMovieClip("opsNativeCursor", 9997);
        nativeCursor.lineStyle(1, 0x141516, 90, true, "normal", "none", "miter", 3);
        nativeCursor.beginFill(0xB8A074, 92);
        nativeCursor.moveTo(0, 0);
        nativeCursor.lineTo(0, 16);
        nativeCursor.lineTo(5, 12);
        nativeCursor.lineTo(8, 20);
        nativeCursor.lineTo(12, 18);
        nativeCursor.lineTo(9, 11);
        nativeCursor.lineTo(16, 11);
        nativeCursor.lineTo(0, 0);
        nativeCursor.endFill();
        nativeCursor._visible = false;
    }

    private function parseSlot(raw:String):Object {
        var parts:Array = raw.split("|");
        var slot:Object = new Object();
        slot.index = Number(parts[0]);
        slot.name = safe(parts[1]);
        slot.count = safe(parts[2]);
        slot.ready = Number(parts[3]) == 1;
        slot.armor = "0";
        slot.items = new Array();

        if (isNaN(slot.index)) {
            slot.index = 0;
        }
        if (slot.name == "") {
            slot.name = "Outfit " + (slot.index + 1);
        }
        if (slot.count == "") {
            slot.count = "0 pieces";
        }
        var itemPart:Number = 4;
        if (parts[5] != undefined) {
            slot.armor = safe(parts[4]);
            itemPart = 5;
        }
        if (slot.armor == "") {
            slot.armor = "0";
        }
        if (parts[itemPart] != undefined && String(parts[itemPart]).length > 0) {
            var rawItems:Array = String(parts[itemPart]).split("~");
            var i:Number = 0;
            while (i < rawItems.length && i < 12) {
                if (safe(rawItems[i]) != "") {
                    slot.items.push(safe(rawItems[i]));
                }
                i++;
            }
        }
        return slot;
    }

    private function installKeys():Void {
        var self:OutfitPreviewMenu = this;

        self.keyListener = new Object();
        self.keyListener.onKeyDown = function():Void {
            var code:Number = Key.getCode();
            if (code == Key.ESCAPE || code == 1 || code == 27) {
                self.closeMenu();
                return;
            }
            if (self.editingName) {
                if (code == Key.ENTER || code == 28 || code == 156) {
                    self.commitRename();
                }
            } else {
                self.handleKey(code);
            }
        };
        Key.addListener(self.keyListener);

        bindInputClip(root);
        if (_root != root) {
            bindInputClip(_root);
        }
        if (_level0 != undefined && _level0 != root && _level0 != _root) {
            bindInputClip(_level0);
        }
    }

    private function bindInputClip(target:MovieClip):Void {
        if (target == undefined) {
            return;
        }
        var self:OutfitPreviewMenu = this;
        target.focusEnabled = false;
        target.tabEnabled = false;
        target.tabChildren = false;
        target._focusrect = false;
        target.onKeyDown = function():Void {
            var code:Number = Key.getCode();
            if (self.isEscapeCode(code)) {
                self.closeMenu();
                return;
            }
            self.handleKey(code);
        };
        target.handleInput = function(inputDetails:Object, pathToFocus:Array):Boolean {
            return self.handleInputDetails(inputDetails);
        };
    }

    private function handleInputDetails(inputDetails:Object):Boolean {
        if (inputDetails == undefined || inputDetails == null) {
            return false;
        }

        if (isCancelInput(inputDetails)) {
            closeMenu();
            return true;
        }

        var nav:String = safe(inputDetails.navEquivalent).toLowerCase();
        var code:Number = Number(inputDetails.skseKeycode);
        if (isNaN(code) || code == 0) {
            code = Number(inputDetails.keyCode);
        }

        if (isPrimaryMouseInput(code, inputDetails)) {
            if (!isPressInput(inputDetails)) {
                dragging = false;
                return true;
            }
            if (runMouseHitAction()) {
                return true;
            }
            if (_root._xmouse > 500) {
                dragging = true;
                lastMouseX = _root._xmouse;
                return true;
            }
            return false;
        }

        var action:String = normalizeInputAction(nav, code, inputDetails);
        if (action == "") {
            return handleKey(code);
        }

        if (action == "cancel" || action == "back") {
            closeMenu();
            return true;
        }

        if (!isPressInput(inputDetails)) {
            return true;
        }
        if (editingName) {
            if (action == "accept") {
                commitRename();
                return true;
            }
            return false;
        }
        if (isDebounced(action)) {
            return true;
        }
        return runInputAction(action);
    }

    private function installMouse():Void {
        var self:OutfitPreviewMenu = this;
        mouseListener = new Object();
        mouseListener.onMouseDown = function():Void {
            self.lastRealMouseX = _root._xmouse;
            self.lastRealMouseY = _root._ymouse;
            if (self.runMouseHitAction()) {
                self.dragging = false;
                return;
            }
            self.noteMouseInput(false);
            if (_root._xmouse > 500) {
                self.dragging = true;
                self.lastMouseX = _root._xmouse;
            }
        };
        mouseListener.onMouseUp = function():Void {
            self.dragging = false;
        };
        mouseListener.onMouseMove = function():Void {
            Mouse.show();
            var realDx:Number = Math.abs(_root._xmouse - self.lastRealMouseX);
            var realDy:Number = Math.abs(_root._ymouse - self.lastRealMouseY);
            if (realDx >= 2 || realDy >= 2) {
                self.lastRealMouseX = _root._xmouse;
                self.lastRealMouseY = _root._ymouse;
                self.noteMouseInput(true);
            }
            if (self.dragging) {
                var dx:Number = _root._xmouse - self.lastMouseX;
                if (Math.abs(dx) >= 5) {
                    self.sendEvent("OPS_RotatePlayer", "", dx);
                    self.lastMouseX = _root._xmouse;
                }
            }
        };
        Mouse.addListener(mouseListener);
    }

    private function handleKey(code:Number):Boolean {
        if (isNaN(code) || code == 0) {
            return false;
        }

        if (isEscapeCode(code)) {
            closeMenu();
            return true;
        }

        var action:String = normalizeInputAction("", code, new Object());
        if (action != "") {
            if (isDebounced(action)) {
                return true;
            }
            return runInputAction(action);
        }

        if (viewMode == "detail" && (code == Key.BACKSPACE || code == 14)) {
            noteNavInput(false);
            showList();
            return true;
        }
        return false;
    }

    private function pollEscape():Void {
        var isDown:Boolean = Key.isDown(Key.ESCAPE) || Key.isDown(1) || Key.isDown(27);
        if (isDown && !escWasDown) {
            closeMenu();
        }
        escWasDown = isDown;
    }

    private function tickPlayerIdleAnimation():Void {
        if (!idleAnimationEnabled || !initialized || closing) {
            lastIdleAnimationTime = 0;
            return;
        }

        var now:Number = getTimer();
        if (lastIdleAnimationTime <= 0) {
            lastIdleAnimationTime = now;
            return;
        }

        var delta:Number = (now - lastIdleAnimationTime) / 1000;
        lastIdleAnimationTime = now;
        if (delta <= 0) {
            return;
        }
        if (delta > 0.05) {
            delta = 0.05;
        }

        if (_global.skse != undefined && _global.skse.plugins != undefined) {
            var api:Object = _global.skse.plugins.OutfitPreviewSelectorCamera;
            if (api != undefined && api.TickPlayerAnimation != undefined) {
                api.TickPlayerAnimation(delta);
            }
        }
    }

    private function normalizeInputAction(nav:String, code:Number, inputDetails:Object):String {
        var control:String = safe(inputDetails.control).toLowerCase();
        var name:String = safe(inputDetails.name).toLowerCase();
        var keyName:String = safe(inputDetails.keyName).toLowerCase();
        var merged:String = nav + "|" + control + "|" + name + "|" + keyName;
        if (merged.indexOf("cancel") >= 0 || merged.indexOf("escape") >= 0 || merged.indexOf("esc") >= 0 || isEscapeCode(code) || code == 277) {
            return "cancel";
        }
        if (control == "back" || name == "back" || nav == "back" || nav == "tabback" || code == 270 || code == 271) {
            return "back";
        }
        if (merged.indexOf("accept") >= 0 || merged.indexOf("activate") >= 0 || code == Key.ENTER || code == Key.SPACE || code == 28 || code == 57 || code == 156 || code == 276) {
            return "accept";
        }
        if (merged.indexOf("up") >= 0 || code == Key.UP || code == 87 || code == 200 || code == 17 || code == 266) {
            return "up";
        }
        if (merged.indexOf("down") >= 0 || code == Key.DOWN || code == 83 || code == 208 || code == 31 || code == 267) {
            return "down";
        }
        if (merged.indexOf("left") >= 0 || code == Key.LEFT || code == 65 || code == 203 || code == 30 || code == 268 || code == 274) {
            return "left";
        }
        if (merged.indexOf("right") >= 0 || code == Key.RIGHT || code == 68 || code == 205 || code == 32 || code == 269 || code == 275) {
            return "right";
        }
        if (code == 278) {
            return "edit";
        }
        if (code == 279) {
            return "save";
        }
        return "";
    }

    private function isPressInput(inputDetails:Object):Boolean {
        var state:String = safe(inputDetails.value).toLowerCase();
        if (state == "") {
            state = safe(inputDetails.event).toLowerCase();
        }
        if (state == "") {
            state = safe(inputDetails.type).toLowerCase();
        }
        if (state == "") {
            return true;
        }
        var numeric:Number = Number(state);
        if (!isNaN(numeric)) {
            return numeric != 0;
        }
        return state == "1" || state == "1.0" || state == "true" || state.indexOf("down") >= 0 || state.indexOf("press") >= 0;
    }

    private function isCancelInput(inputDetails:Object):Boolean {
        var nav:String = safe(inputDetails.navEquivalent).toLowerCase();
        var control:String = safe(inputDetails.control).toLowerCase();
        var name:String = safe(inputDetails.name).toLowerCase();
        var keyName:String = safe(inputDetails.keyName).toLowerCase();
        var merged:String = nav + "|" + control + "|" + name + "|" + keyName;
        return merged.indexOf("cancel") >= 0 || merged.indexOf("escape") >= 0 || merged.indexOf("esc") >= 0 || nav == "back" || nav == "tabback" || control == "back" || name == "back";
    }

    private function isEscapeCode(code:Number):Boolean {
        return code == Key.ESCAPE || code == 1 || code == 27;
    }

    private function runInputAction(action:String):Boolean {
        if (action == "cancel" || action == "back") {
            closeMenu();
            return true;
        }
        if (action == "up") {
            noteNavInput(false);
            moveSelection(-1);
            return true;
        }
        if (action == "down") {
            noteNavInput(false);
            moveSelection(1);
            return true;
        }
        if (action == "left") {
            noteNavInput(false);
            moveColumn(-1);
            return true;
        }
        if (action == "right") {
            noteNavInput(false);
            moveColumn(1);
            return true;
        }
        if (action == "accept") {
            noteNavInput(true);
            acceptSelection();
            return true;
        }
        if (action == "edit") {
            noteNavInput(true);
            openFocusedDetail();
            return true;
        }
        if (action == "save") {
            noteNavInput(true);
            saveSelected();
            return true;
        }
        return false;
    }

    private function isDebounced(action:String):Boolean {
        var now:Number = getTimer();
        if ((action == "accept" || action == "cancel" || action == "edit" || action == "save" || action == "back") && lastInputAction == action && now - lastInputTime < 180) {
            return true;
        }
        if ((action == "up" || action == "down" || action == "left" || action == "right") && lastInputAction == action && now - lastInputTime < 90) {
            return true;
        }
        lastInputAction = action;
        lastInputTime = now;
        return false;
    }

    private function isTypingName():Boolean {
        if (viewMode != "detail" || renameField == undefined) {
            return false;
        }
        if (editingName) {
            return true;
        }
        var focus:String = Selection.getFocus();
        if (focus == undefined || focus == "") {
            return false;
        }
        return eval(focus) == renameField;
    }

    private function moveSelection(delta:Number):Void {
        if (viewMode == "detail") {
            moveDetailFocus(delta);
            return;
        }
        if (slots.length == 0) {
            return;
        }
        var maxRow:Number = slots.length;
        listRow += delta;
        if (listRow < 0) {
            listRow = 0;
        }
        if (listRow > maxRow) {
            listRow = maxRow;
        }
        if (listRow < slots.length) {
            selected = listRow;
            editIndex = selected;
        }
        draw();
    }

    private function moveDetailFocus(delta:Number):Void {
        if (delta > 0) {
            if (detailFocus == 0) {
                detailFocus = 1;
            } else if (detailFocus >= 1 && detailFocus <= 4) {
                detailFocus = 5;
            }
        } else if (delta < 0) {
            if (detailFocus == 5) {
                detailFocus = 1;
            } else if (detailFocus >= 1 && detailFocus <= 4) {
                detailFocus = 0;
            }
        }
        if (detailFocus < 0) {
            detailFocus = 0;
        }
        if (detailFocus > 5) {
            detailFocus = 5;
        }
        navCursorVisible = true;
        draw();
    }

    private function moveDetailHorizontal(delta:Number):Void {
        if (detailFocus < 1 || detailFocus > 4) {
            if (delta > 0) {
                detailFocus = 1;
            }
        } else {
            detailFocus += delta;
            if (detailFocus < 1) {
                detailFocus = 1;
            }
            if (detailFocus > 4) {
                detailFocus = 4;
            }
        }
        navCursorVisible = true;
        draw();
    }

    private function moveColumn(delta:Number):Void {
        if (viewMode == "detail") {
            moveDetailHorizontal(delta);
            return;
        }
        if (listRow >= slots.length) {
            return;
        }
        listColumn += delta;
        if (listColumn < 0) {
            listColumn = 0;
        }
        if (listColumn > 1) {
            listColumn = 1;
        }
        navCursorVisible = true;
        draw();
    }

    private function acceptSelection():Void {
        if (viewMode == "detail") {
            acceptDetailSelection();
            return;
        }
        if (listRow >= slots.length) {
            if (listRow == slots.length) {
                closeMenu();
            }
            return;
        }
        if (listColumn == 1) {
            var slot:Object = getActiveSlot();
            if (slot != undefined) {
                openDetail(Number(slot.index));
            }
        } else {
            applySelected();
        }
    }

    private function openFocusedDetail():Void {
        if (viewMode == "detail") {
            return;
        }
        if (listRow >= slots.length) {
            return;
        }
        var slot:Object = getActiveSlot();
        if (slot != undefined) {
            listColumn = 1;
            openDetail(Number(slot.index));
        }
    }

    private function acceptDetailSelection():Void {
        if (detailFocus == 0) {
            if (editingName) {
                commitRename();
            } else {
                startRenameTyping();
            }
        } else if (detailFocus == 1) {
            showList();
        } else if (detailFocus == 2) {
            applySelected();
        } else if (detailFocus == 3) {
            saveSelected();
        } else if (detailFocus == 4) {
            clearSelected();
        } else if (detailFocus == 5) {
            closeMenu();
        }
    }

    private function startRenameTyping():Void {
        if (renameField == undefined) {
            return;
        }
        editingName = true;
        setTextInputMode(true);
        Selection.setFocus(renameField);
        renameField.text = renameField.text;
        var len:Number = renameField.text.length;
        Selection.setSelection(len, len);
        draw();
    }

    private function commitRename():Void {
        if (!editingName) {
            return;
        }
        editingName = false;
        setTextInputMode(false);
        renameSelected();
        Selection.setFocus(null);
        draw();
    }

    private function cancelRename():Void {
        if (!editingName) {
            return;
        }
        editingName = false;
        setTextInputMode(false);
        Selection.setFocus(null);
        draw();
    }

    private function applySelected():Void {
        if (selected < 0 || selected >= slots.length) {
            return;
        }
        var slot:Object = slots[selected];
        if (!slot.ready) {
            return;
        }
        lastApplied = Number(slot.index);
        animateCurrent = true;
        draw();
        sendEvent("OPS_ApplySlot", "", Number(slot.index));
    }

    private function saveSelected():Void {
        var slot:Object = getActiveSlot();
        if (slot != undefined) {
            sendEvent("OPS_SaveSlot", "", Number(slot.index));
        }
    }

    private function clearSelected():Void {
        var slot:Object = getActiveSlot();
        if (slot != undefined) {
            lastApplied = -1;
            sendEvent("OPS_ClearSlot", "", Number(slot.index));
        }
    }

    private function renameSelected():Void {
        var slot:Object = getActiveSlot();
        if (slot != undefined && renameField != undefined) {
            sendEvent("OPS_RenameSlot", renameField.text, Number(slot.index));
        }
    }

    private function openDetail(slotIndex:Number):Void {
        selectIndex(slotIndex, false);
        editIndex = selected;
        viewMode = "detail";
        detailFocus = 0;
        draw();
    }

    private function showList():Void {
        viewMode = "list";
        renameField = undefined;
        editingName = false;
        draw();
    }

    private function closeMenu():Void {
        if (closing) {
            return;
        }
        closing = true;
        setTextInputMode(false);
        sendEvent("OPS_CloseMenu", "", 0);
        if (_global.skse != undefined && _global.skse.CloseMenu != undefined) {
            _global.skse.CloseMenu("CustomMenu");
        }
    }

    private function draw():Void {
        var savedRenameText:String = undefined;
        if (editingName && renameField != undefined) {
            savedRenameText = renameField.text;
        }
        if (panel != undefined) {
            panel.removeMovieClip();
        }
        renameField = undefined;
        clickZones = new Array();
        nextDepth = 10;
        panel = root.createEmptyMovieClip("opsPanel", 1);
        positionPanel();
        panel._xscale = menuScale * 100;
        panel._yscale = menuScale * 100;
        bindInputClip(panel);

        if (viewMode == "detail") {
            drawDetail();
        } else {
            drawList();
        }
        drawNavCursor();
        if (!editingName) {
            Selection.setFocus(null);
        } else if (renameField != undefined) {
            if (savedRenameText != undefined) {
                renameField.text = savedRenameText;
            }
            Selection.setFocus(renameField);
            var len:Number = renameField.text.length;
            Selection.setSelection(len, len);
        }
        Mouse.show();
    }

    private function drawList():Void {
        placeAsset(panel, "components/panel_bg.swf", 50, 64, 420, 594, 90);
        placeAsset(panel, "components/panel_cols.swf", 70, 116, 370, 28, 70);
        rect(panel, 58, 72, 398, 576, 0x000000, 62, 0x6E685A, 58, 1);
        rect(panel, 76, 118, 350, 1, 0x827868, 52, -1, 0, 0);
        addText(panel, "title", 78, 86, 260, 26, "Outfits", 22, 0xEEE8DC, true, "left");
        addText(panel, "mark", 368, 91, 56, 18, "OPS", 12, 0xB8A074, false, "right");

        var y:Number = 138;
        var i:Number = 0;
        while (i < slots.length && i < 10) {
            drawSlot(slots[i], 78, y + i * 40, 348, 34, i == selected && listRow < slots.length, Number(slots[i].index) == lastApplied);
            i++;
        }
        animateCurrent = false;

        rect(panel, 76, 560, 350, 1, 0x827868, 52, -1, 0, 0);
        placeAsset(panel, "components/bar_1.swf", 70, 572, 362, 64, 72);
        drawButton("close", 78, 584, 348, 34, "Close", "close", -1, listRow == slots.length);
    }

    private function drawDetail():Void {
        var slot:Object = getActiveSlot();
        if (slot == undefined) {
            viewMode = "list";
            drawList();
            return;
        }

        placeAsset(panel, "components/panel_bg.swf", 50, 64, 440, 594, 90);
        rect(panel, 58, 72, 418, 576, 0x000000, 64, 0x6E685A, 58, 1);
        addText(panel, "title", 78, 86, 280, 26, twoDigits(slot.index + 1) + "  " + clip(slot.name, 24), 21, 0xEEE8DC, true, "left");
        addText(panel, "count", 358, 91, 82, 18, slot.count, 12, 0xC8BA98, false, "right");
        addText(panel, "armor", 260, 91, 88, 18, "AR " + slot.armor, 12, 0xC8BA98, false, "right");
        rect(panel, 76, 118, 364, 1, 0x827868, 52, -1, 0, 0);

        var renameFocused:Boolean = detailFocus == 0;
        addText(panel, "renameLabel", 78, 137, 90, 18, "Name", 12, renameFocused ? 0xEEE8DC : 0xC8BA98, false, "left");
        if (renameFocused && !editingName && debugFocusHighlight) {
            rect(panel, 76, 154, 366, 38, 0x191A1A, 30, 0x827868, 60, 1);
        }
        renameField = addInput(panel, "rename", 78, 158, 244, 30, slot.name);
        addClickZone(78, 158, 244, 30, "renameInput", -1);
        if (editingName) {
            rect(panel, 76, 154, 250, 38, 0x000000, 0, 0x827868, 90, 2);
            addText(panel, "typeHint", 78, 193, 244, 16, "Type name, then press Accept", 10, 0x827868, false, "left");
        }
        drawButton("renameBtn", 332, 156, 108, 34, "Rename", "rename", -1, renameFocused && !editingName);

        addText(panel, "itemsTitle", 78, 218, 220, 20, "Saved Items", 15, 0xEEE8DC, true, "left");
        rect(panel, 76, 243, 364, 1, 0x827868, 40, -1, 0, 0);

        var y:Number = 257;
        var i:Number = 0;
        if (slot.items.length == 0) {
            addText(panel, "empty", 78, y, 330, 22, "No saved items", 14, 0x8C9298, false, "left");
        } else {
            while (i < slot.items.length && i < 10) {
                drawItem(slot.items[i], 78, y + i * 26, 360, 23, i);
                i++;
            }
        }

        rect(panel, 76, 504, 364, 1, 0x827868, 52, -1, 0, 0);
        drawButton("back", 78, 520, 82, 32, "Back", "back", -1, detailFocus == 1);
        drawButton("apply", 168, 520, 82, 32, "Apply", "apply", -1, detailFocus == 2);
        drawButton("save", 258, 520, 82, 32, "Save", "save", -1, detailFocus == 3);
        drawButton("clear", 348, 520, 92, 32, "Clear", "clear", -1, detailFocus == 4);
        drawButton("close", 78, 584, 362, 34, "Close", "close", -1, detailFocus == 5);
    }

    private function drawSlot(slot:Object, x:Number, y:Number, w:Number, h:Number, active:Boolean, worn:Boolean):Void {
        var row:MovieClip = panel.createEmptyMovieClip("slot" + nextDepth, nextDepth++);
        row._x = x;
        row._y = y;
        disableFocusTarget(row);
        var debugActive:Boolean = active && debugFocusHighlight;
        var fill:Number = worn ? 0x14263D : (debugActive ? 0x11161C : 0x07090C);
        var fillAlpha:Number = worn ? 92 : (debugActive ? 78 : 74);
        var stroke:Number = worn ? 0x91B9DC : (debugActive ? 0x827868 : -1);
        var strokeAlpha:Number = worn ? 100 : (debugActive ? 90 : 0);
        var strokeWidth:Number = worn ? 2 : (debugActive ? 1 : 0);
        var textColor:Number = worn ? 0xEEF7FF : 0xEEE8DC;
        var metaColor:Number = worn ? 0xB7CEE3 : (slot.ready ? 0xC8BA98 : 0x8C9298);
        rect(row, 0, 0, w, h, fill, fillAlpha, stroke, strokeAlpha, strokeWidth);
        rect(row, 0, 0, worn ? 6 : (active ? 4 : 3), h, worn ? 0xAACAE7 : (slot.ready ? 0xB8A074 : 0x5F656B), worn ? 100 : (active ? 95 : 90), -1, 0, 0);
        if (worn) {
            rect(row, 3, 3, w - 6, h - 6, 0x000000, 0, 0xC8B574, 62, 1);
            drawMysticMark(row, w - 9, Math.floor(h / 2));
        }
        addText(row, "num", 12, 7, 30, 20, twoDigits(slot.index + 1), 14, textColor, true, "left");
        addText(row, "name", 50, 7, 118, 20, clip(slot.name, 17), 14, textColor, worn, "left");
        addText(row, "count", 170, 8, 52, 18, shortCount(slot.count), 11, metaColor, false, "right");
        addText(row, "armor", 224, 8, 42, 18, "AR " + slot.armor, 11, metaColor, false, "right");

        if (worn && animateCurrent) {
            animateOutfitRow(row);
            animateMysticShimmer(row, w, h);
        }

        var self:OutfitPreviewMenu = this;
        var idx:Number = slot.index;
        addClickZone(x, y, w, h, "applySlot", idx);
        row.useHandCursor = true;
        row.onRollOver = function():Void {
            Mouse.show();
        };
        row.onRelease = function():Void {
            if (self.skipClipRelease()) {
                return;
            }
            self.noteMouseInput(false);
            self.listColumn = 0;
            self.listRow = idx;
            self.selectIndex(idx, false);
            self.applySelected();
        };

        drawEditButton(x + 270, y + 4, idx, active && listColumn == 1);
    }

    private function drawEditButton(x:Number, y:Number, idx:Number, active:Boolean):Void {
        var edit:MovieClip = panel.createEmptyMovieClip("editButton" + nextDepth, nextDepth++);
        edit._x = x;
        edit._y = y;
        disableFocusTarget(edit);
        var debugActive:Boolean = active && debugFocusHighlight;
        rect(edit, 0, 0, 64, 25, debugActive ? 0x141516 : 0x101112, debugActive ? 78 : 75, debugActive ? 0x827868 : 0x4A5056, debugActive ? 88 : 45, 1);
        addText(edit, "edit", 0, 5, 64, 16, "Edit", 11, 0xEEE8DC, false, "center");

        var self:OutfitPreviewMenu = this;
        addClickZone(x, y, 64, 25, "editSlot", idx);
        edit.useHandCursor = true;
        edit.onRollOver = function():Void {
            Mouse.show();
        };
        edit.onRelease = function():Void {
            if (self.skipClipRelease()) {
                return;
            }
            self.noteMouseInput(false);
            self.listColumn = 1;
            self.listRow = idx;
            self.selectIndex(idx, false);
            self.openDetail(idx);
        };
    }

    private function drawItem(label:String, x:Number, y:Number, w:Number, h:Number, index:Number):Void {
        var row:MovieClip = panel.createEmptyMovieClip("item" + nextDepth, nextDepth++);
        row._x = x;
        row._y = y;
        rect(row, 0, 0, w, h, index % 2 == 0 ? 0x0D0E0F : 0x111214, 46, -1, 0, 0);
        addText(row, "itemText", 12, 4, w - 24, 16, clip(label, 45), 12, 0xEEE8DC, false, "left");
    }

    private function drawButton(name:String, x:Number, y:Number, w:Number, h:Number, label:String, action:String, idx:Number, focused:Boolean):Void {
        var button:MovieClip = panel.createEmptyMovieClip(name + nextDepth, nextDepth++);
        button._x = x;
        button._y = y;
        disableFocusTarget(button);
        if (focused) {
            placeAsset(button, debugFocusHighlight ? "components/btn_d.swf" : "components/btn_u.swf", 0, 0, w, h, 76);
            rect(button, 0, 0, w, h, debugFocusHighlight ? 0x191A1A : 0x101112, debugFocusHighlight ? 78 : 70, debugFocusHighlight ? 0x827868 : 0x4A5056, debugFocusHighlight ? 82 : 45, 1);
            addText(button, "label", 0, Math.floor((h - 18) / 2), w, 20, label, 12, 0xEEE8DC, false, "center");
        } else {
            placeAsset(button, "components/btn_u.swf", 0, 0, w, h, 70);
            rect(button, 0, 0, w, h, 0x101112, 70, 0x4A5056, 70, 1);
            addText(button, "label", 0, Math.floor((h - 18) / 2), w, 20, label, 12, 0xEEE8DC, false, "center");
        }

        var self:OutfitPreviewMenu = this;
        addClickZone(x, y, w, h, action, idx);
        button.useHandCursor = true;
        button.onRollOver = function():Void {
            Mouse.show();
        };
        button.onRollOut = function():Void {
            Mouse.show();
        };
        button.onRelease = function():Void {
            if (self.skipClipRelease()) {
                return;
            }
            self.noteMouseInput(false);
            self.focusAction(action, idx);
            self.runAction(action, idx);
        };
    }

    private function focusAction(action:String, idx:Number):Void {
        if (viewMode == "list") {
            if (action == "close") {
                listRow = slots.length;
            } else if (idx >= 0) {
                listRow = idx;
                selectIndex(idx, false);
            }
        } else if (viewMode == "detail") {
            if (action == "rename" || action == "renameInput") detailFocus = 0;
            else if (action == "back") detailFocus = 1;
            else if (action == "apply") detailFocus = 2;
            else if (action == "save") detailFocus = 3;
            else if (action == "clear") detailFocus = 4;
            else if (action == "close") detailFocus = 5;
        }
    }

    private function runAction(action:String, idx:Number):Void {
        if (action == "save") {
            saveSelected();
        } else if (action == "close") {
            closeMenu();
        } else if (action == "back") {
            showList();
        } else if (action == "apply") {
            applySelected();
        } else if (action == "clear") {
            clearSelected();
        } else if (action == "rename") {
            if (editingName) {
                commitRename();
            } else {
                startRenameTyping();
            }
        } else if (action == "renameInput") {
            if (!editingName) {
                startRenameTyping();
            }
        } else if (action == "detail") {
            openDetail(idx);
        }
    }

    private function selectIndex(slotIndex:Number, redraw:Boolean):Void {
        var i:Number = 0;
        while (i < slots.length) {
            if (Number(slots[i].index) == slotIndex) {
                if (selected != i) {
                    selected = i;
                    editIndex = i;
                    if (redraw) {
                        draw();
                    }
                }
                return;
            }
            i++;
        }
    }

    private function getActiveSlot():Object {
        if (editIndex >= 0 && editIndex < slots.length) {
            return slots[editIndex];
        }
        if (selected >= 0 && selected < slots.length) {
            return slots[selected];
        }
        return undefined;
    }

    private function sendEvent(name:String, strArg:String, numArg:Number):Void {
        if (_global.skse != undefined && _global.skse.SendModEvent != undefined) {
            _global.skse.SendModEvent(name, strArg, numArg);
        }
    }

    private function noteMouseInput(redraw:Boolean):Boolean {
        var changed:Boolean = navCursorVisible;
        navCursorVisible = false;
        if (changed && redraw) {
            draw();
        }
        hideNativeCursor();
        Mouse.show();
        return changed;
    }

    private function noteNavInput(redraw:Boolean):Void {
        var changed:Boolean = !navCursorVisible;
        navCursorVisible = true;
        if (changed && redraw) {
            draw();
        }
        hideNativeCursor();
        Mouse.show();
    }

    private function noteControllerInput():Void {
        noteNavInput(true);
    }

    private function addClickZone(x:Number, y:Number, w:Number, h:Number, action:String, idx:Number):Void {
        var zone:Object = new Object();
        zone.x = x;
        zone.y = y;
        zone.w = w;
        zone.h = h;
        zone.action = action;
        zone.idx = idx;
        clickZones.push(zone);
    }

    private function runMouseHitAction():Boolean {
        return runMouseHitActionAt(_root._xmouse, _root._ymouse);
    }

    private function runMouseHitActionAt(stageX:Number, stageY:Number):Boolean {
        if (clickZones == undefined || clickZones.length == 0) {
            return false;
        }
        if (isNaN(stageX) || isNaN(stageY) || menuScale <= 0) {
            return false;
        }
        if (getTimer() - lastMouseHitTime < 120) {
            return true;
        }

        var offsetX:Number = panel == undefined ? 0 : panel._x;
        var offsetY:Number = panel == undefined ? 0 : panel._y;
        var mx:Number = (stageX - offsetX) / menuScale;
        var my:Number = (stageY - offsetY) / menuScale;
        var i:Number = clickZones.length - 1;
        while (i >= 0) {
            var zone:Object = clickZones[i];
            if (mx >= zone.x && mx <= zone.x + zone.w && my >= zone.y && my <= zone.y + zone.h) {
                noteMouseInput(false);
                lastMouseHitTime = getTimer();
                if (zone.action == "applySlot") {
                    listColumn = 0;
                    listRow = Number(zone.idx);
                    selectIndex(Number(zone.idx), false);
                    applySelected();
                } else if (zone.action == "editSlot") {
                    listColumn = 1;
                    listRow = Number(zone.idx);
                    selectIndex(Number(zone.idx), false);
                    openDetail(Number(zone.idx));
                } else {
                    focusAction(String(zone.action), Number(zone.idx));
                    runAction(String(zone.action), Number(zone.idx));
                }
                return true;
            }
            i--;
        }
        return false;
    }

    private function skipClipRelease():Boolean {
        return getTimer() - lastMouseHitTime < 1000;
    }

    private function isPrimaryMouseInput(code:Number, inputDetails:Object):Boolean {
        var control:String = safe(inputDetails.control).toLowerCase();
        var name:String = safe(inputDetails.name).toLowerCase();
        var keyName:String = safe(inputDetails.keyName).toLowerCase();
        var merged:String = control + "|" + name + "|" + keyName;
        if (code == 256) {
            return true;
        }
        return merged.indexOf("mouse") >= 0 && (merged.indexOf("left") >= 0 || merged.indexOf("button0") >= 0 || merged.indexOf("primary") >= 0 || merged.indexOf("click") >= 0);
    }

    private function drawNavCursor():Void {
        if (!navCursorVisible) {
            return;
        }
        var cursor:MovieClip = panel.createEmptyMovieClip("controllerCursor" + nextDepth, nextDepth++);
        var cy:Number;
        var cx:Number;

        if (viewMode == "list") {
            if (slots.length == 0) {
                return;
            }
            if (listRow < slots.length) {
                cy = 155 + selected * 40;
                cx = listColumn == 1 ? 340 : 62;
            } else if (listRow == slots.length) {
                cy = 598;
                cx = 62;
            } else {
                cy = 598;
                cx = 242;
            }
        } else {
            if (detailFocus == 0) {
                cy = 170;
                cx = 62;
            } else if (detailFocus == 1) {
                cy = 533;
                cx = 62;
            } else if (detailFocus == 2) {
                cy = 533;
                cx = 152;
            } else if (detailFocus == 3) {
                cy = 533;
                cx = 242;
            } else if (detailFocus == 4) {
                cy = 533;
                cx = 332;
            } else {
                cy = 598;
                cx = 62;
            }
        }

        cursor.lineStyle(2, 0xEEE8DC, 88, true, "normal", "none", "miter", 3);
        cursor.beginFill(0xB8A074, 82);
        cursor.moveTo(cx, cy);
        cursor.lineTo(cx + 12, cy + 7);
        cursor.lineTo(cx, cy + 14);
        cursor.lineTo(cx + 3, cy + 7);
        cursor.lineTo(cx, cy);
        cursor.endFill();
    }

    private function setTextInputMode(enable:Boolean):Void {
        if (_global.skse != undefined && _global.skse.AllowTextInput != undefined) {
            if (enable) {
                if (!textInputAllowed) {
                    textInputAllowed = true;
                    _global.skse.AllowTextInput(true);
                }
            } else {
                if (textInputAllowed) {
                    textInputAllowed = false;
                    _global.skse.AllowTextInput(false);
                }
            }
        }
    }

    public function setMenuScale(value:Number):Void {
        if (isNaN(value) || value <= 0) {
            return;
        }
        if (value < 0.45) {
            value = 0.45;
        }
        if (value > 1.0) {
            value = 1.0;
        }
        menuScale = value;
        draw();
    }

    private function positionPanel():Void {
        var contentX:Number = 140;
        var contentY:Number = 95;
        panel._x = Math.round(contentX - 50 * menuScale);
        panel._y = Math.round(contentY - 72 * menuScale);
    }

    private function animatePanelIntro():Void {
        if (panel == undefined) {
            return;
        }
        var clip:MovieClip = panel;
        var targetX:Number = clip._x;
        var started:Number = getTimer();
        clip._x = targetX - 24;
        clip._alpha = 0;
        clip.onEnterFrame = function():Void {
            var progress:Number = (getTimer() - started) / 110;
            if (progress >= 1) {
                this._x = targetX;
                this._alpha = 100;
                delete this.onEnterFrame;
                return;
            }
            var eased:Number = 1 - Math.pow(1 - progress, 3);
            this._x = targetX - 24 * (1 - eased);
            this._alpha = Math.round(100 * eased);
        };
    }

    private function animateOutfitRow(row:MovieClip):Void {
        var targetX:Number = row._x;
        var started:Number = getTimer();
        row._x = targetX - 10;
        row._alpha = 35;
        row.onEnterFrame = function():Void {
            var progress:Number = (getTimer() - started) / 180;
            if (progress >= 1) {
                this._x = targetX;
                this._alpha = 100;
                delete this.onEnterFrame;
                return;
            }
            var eased:Number = 1 - Math.pow(1 - progress, 3);
            this._x = targetX - 10 * (1 - eased);
            this._alpha = 35 + Math.round(65 * eased);
        };
    }

    private function animateMysticShimmer(row:MovieClip, w:Number, h:Number):Void {
        var shimmer:MovieClip = row.createEmptyMovieClip("mysticShimmer", row.getNextHighestDepth());
        rect(shimmer, 0, 2, 52, h - 4, 0xB9DBF5, 100, -1, 0, 0);
        var startX:Number = 7;
        var distance:Number = w - 66;
        var started:Number = getTimer();
        shimmer._x = startX;
        shimmer._alpha = 0;
        shimmer.onEnterFrame = function():Void {
            var progress:Number = (getTimer() - started) / 560;
            if (progress >= 1) {
                this.removeMovieClip();
                return;
            }
            this._x = startX + distance * progress;
            this._alpha = Math.round(20 * Math.sin(progress * Math.PI));
        };
    }

    private function drawMysticMark(parent:MovieClip, centerX:Number, centerY:Number):Void {
        var mark:MovieClip = parent.createEmptyMovieClip("mysticMark", parent.getNextHighestDepth());
        mark.lineStyle(1, 0xC8B574, 78);
        mark.beginFill(0x91B9DC, 58);
        mark.moveTo(centerX, centerY - 5);
        mark.lineTo(centerX + 4, centerY);
        mark.lineTo(centerX, centerY + 5);
        mark.lineTo(centerX - 4, centerY);
        mark.lineTo(centerX, centerY - 5);
        mark.endFill();
    }

    public function setDebugFocusHighlight(enabled:Boolean):Void {
        debugFocusHighlight = false;
        draw();
    }

    private function disableFocusTarget(target:Object):Void {
        if (target == undefined || target == null) {
            return;
        }
        target._focusrect = false;
        target.focusEnabled = false;
        target.tabEnabled = false;
        target.tabChildren = false;
    }

    private function addText(parent:MovieClip, name:String, x:Number, y:Number, w:Number, h:Number, text:String, size:Number, color:Number, bold:Boolean, align:String):TextField {
        var fieldName:String = name + nextDepth;
        parent.createTextField(fieldName, nextDepth++, x, y, w, h);
        var tf:TextField = TextField(parent[fieldName]);
        tf._focusrect = false;
        tf.selectable = false;
        tf.tabEnabled = false;
        tf.embedFonts = true;
        tf.antiAliasType = "advanced";
        tf.text = text;
        var fmt:TextFormat = new TextFormat();
        fmt.font = bold ? "$EverywhereBoldFont" : "$EverywhereFont";
        fmt.size = size;
        fmt.color = color;
        fmt.bold = false;
        fmt.align = align;
        tf.setNewTextFormat(fmt);
        tf.setTextFormat(fmt);
        return tf;
    }

    private function addInput(parent:MovieClip, name:String, x:Number, y:Number, w:Number, h:Number, text:String):TextField {
        rect(parent, x, y, w, h, 0x0D0E0F, 70, 0x4A5056, 80, 1);
        var fieldName:String = name + nextDepth;
        parent.createTextField(fieldName, nextDepth++, x + 8, y + 6, w - 16, h - 10);
        var tf:TextField = TextField(parent[fieldName]);
        tf._focusrect = false;
        tf.type = "input";
        tf.selectable = true;
        tf.tabEnabled = false;
        tf.embedFonts = true;
        tf.antiAliasType = "advanced";
        tf.maxChars = 28;
        tf.text = text;
        var fmt:TextFormat = new TextFormat();
        fmt.font = "$EverywhereFont";
        fmt.size = 13;
        fmt.color = 0xEEE8DC;
        tf.setNewTextFormat(fmt);
        tf.setTextFormat(fmt);
        var self:OutfitPreviewMenu = this;
        tf.onSetFocus = function():Void {
            self.editingName = true;
            self.setTextInputMode(true);
        };
        tf.onKillFocus = function():Void {
            if (self.editingName) {
                self.commitRename();
            }
        };
        return tf;
    }

    private function placeAsset(parent:MovieClip, path:String, x:Number, y:Number, w:Number, h:Number, alpha:Number):MovieClip {
        var holder:MovieClip = parent.createEmptyMovieClip("asset" + nextDepth, nextDepth++);
        holder._x = x;
        holder._y = y;
        holder._alpha = alpha;
        holder.loadMovie("OutfitPreviewSelector32/" + path);
        holder.targetW = w;
        holder.targetH = h;
        holder.onEnterFrame = function():Void {
            if (this._width > 0 && this._height > 0) {
                this._width = this.targetW;
                this._height = this.targetH;
                delete this.onEnterFrame;
            }
        };
        return holder;
    }

    private function rect(target:MovieClip, x:Number, y:Number, w:Number, h:Number, fill:Number, alpha:Number, stroke:Number, strokeAlpha:Number, strokeWidth:Number):Void {
        if (stroke >= 0 && strokeWidth > 0) {
            target.lineStyle(strokeWidth, stroke, strokeAlpha, true, "normal", "none", "miter", 3);
        } else {
            target.lineStyle(0, 0, 0, true, "normal", "none", "miter", 3);
        }
        target.beginFill(fill, alpha);
        target.moveTo(x, y);
        target.lineTo(x + w, y);
        target.lineTo(x + w, y + h);
        target.lineTo(x, y + h);
        target.lineTo(x, y);
        target.endFill();
    }

    private function twoDigits(value:Number):String {
        if (value < 10) {
            return "0" + value;
        }
        return String(value);
    }

    private function clip(value:String, max:Number):String {
        if (value == undefined) {
            return "";
        }
        if (value.length <= max) {
            return value;
        }
        return value.substr(0, max - 3) + "...";
    }

    private function safe(value:Object):String {
        if (value == undefined || value == null) {
            return "";
        }
        return String(value);
    }

    private function shortCount(value:String):String {
        var text:String = safe(value);
        text = replace(text, " pieces", "p");
        text = replace(text, " piece", "p");
        return text;
    }

    private function replace(value:String, find:String, repl:String):String {
        var pos:Number = value.indexOf(find);
        if (pos < 0) {
            return value;
        }
        return value.substr(0, pos) + repl + value.substr(pos + find.length);
    }
}
