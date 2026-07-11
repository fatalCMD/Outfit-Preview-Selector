class OutfitPreviewMenu {
    private var root:MovieClip;
    private var panel:MovieClip;
    private var outfitBadge:MovieClip;
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
    private var pageSize:Number;
    private var currentPage:Number;
    private var pageChangePending:Boolean;
    private var lastPageChangeTime:Number;
    private var pendingPageDirection:Number;
    private var slotActionPending:Boolean;
    private var pendingSlotAction:String;
    private var pendingSlotIndex:Number;
    private var lastSlotActionTime:Number;
    private var equippingIndex:Number;
    private var equipStartedTime:Number;
    private var noticeMessage:String;
    private var noticeUntil:Number;
    private var cardView:Boolean;

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
        pageSize = 10;
        currentPage = 0;
        pageChangePending = false;
        lastPageChangeTime = -999;
        pendingPageDirection = 0;
        slotActionPending = false;
        pendingSlotAction = "";
        pendingSlotIndex = -1;
        lastSlotActionTime = -999;
        equippingIndex = -1;
        equipStartedTime = 0;
        noticeMessage = "";
        noticeUntil = 0;
        cardView = false;

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
            self.tickEquipStatus();
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
            while (i < arguments.length && i < 50) {
                rows.push(String(arguments[i]));
                i++;
            }
        } else if (raw != undefined) {
            if (typeof(raw) == "string") {
                rows.push(String(raw));
            } else {
                while (i < raw.length && i < 50) {
                    rows.push(String(raw[i]));
                    i++;
                }
            }
        }

        i = 0;
        while (i < rows.length && i < 50) {
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
        currentPage = Math.floor(selected / pageSize);
        initialized = true;
        draw();
        if (!introPlayed) {
            introPlayed = true;
            animatePanelIntro();
        }
    }

    public function setCurrentOutfit(slotIndex:Number):Void {
        if (isNaN(slotIndex) || slotIndex < 0 || slotIndex >= 50) {
            slotIndex = -1;
        }
        var changed:Boolean = lastApplied != slotIndex;
        if (changed) {
            lastApplied = slotIndex;
            animateCurrent = slotIndex >= 0;
            draw();
        }
    }

    public function setEquipResult(raw:String):Void {
        var parts:Array = safe(raw).split("|");
        var slotIndex:Number = Number(parts[0]);
        var succeeded:Boolean = Number(parts[1]) == 1;
        if (isNaN(slotIndex) || slotIndex != equippingIndex) return;

        equippingIndex = -1;
        equipStartedTime = 0;
        if (succeeded) {
            lastApplied = slotIndex;
            animateCurrent = true;
        } else {
            noticeMessage = parts.length > 2 ? safe(parts[2]) : "Required pieces are missing.";
            noticeUntil = getTimer() + 6500;
        }
        draw();
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

    public function setCardView(enabled:Boolean):Void {
        cardView = enabled;
        draw();
        if (!initialized && panel != undefined) panel._alpha = 0;
    }

    public function setCameraOffsets(raw:String):Void {
        var values:Array = safe(raw).split("|");
        if (values.length < 2) return;
        var side:Number = Number(values[0]);
        var height:Number = Number(values[1]);
        if (isNaN(side) || isNaN(height)) return;
        if (_global.skse != undefined && _global.skse.plugins != undefined) {
            var api:Object = _global.skse.plugins.OutfitPreviewSelectorCamera;
            if (api != undefined && api.SetCameraOffsets != undefined) api.SetCameraOffsets(side, height);
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
        // SkyUI owns the only visible pointer. Native coordinates remain in
        // use for hit testing, but the custom fallback caused cursor jitter.
        hideNativeCursor();
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
        slot.icon = "auto";

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
        if (parts[itemPart + 1] != undefined && safe(parts[itemPart + 1]) != "") slot.icon = safe(parts[itemPart + 1]).toLowerCase();
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
        if (code == 279 || merged.indexOf("triangle") >= 0 || merged.indexOf("buttony") >= 0 || merged.indexOf("ybutton") >= 0) {
            return "edit";
        }
        if (code == 278) {
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
        if (cardView) {
            moveCardVertical(delta);
            return;
        }
        var first:Number = currentPage * pageSize;
        var last:Number = Math.min(first + pageSize, slots.length) - 1;
        if (listRow < first || listRow > slots.length + 1) {
            listRow = first;
        } else if (delta > 0) {
            if (listRow < last) listRow++;
            else if (listRow == last) {
                listRow = slots.length;
                listColumn = currentPage > 0 ? 0 : 1;
            }
            else if (listRow == slots.length) listRow = slots.length + 1;
        } else if (delta < 0) {
            if (listRow == slots.length + 1) {
                listRow = slots.length;
                listColumn = currentPage < getPageCount() - 1 ? 1 : 0;
            }
            else if (listRow == slots.length) listRow = last;
            else if (listRow > first) listRow--;
        }
        if (listRow < slots.length) {
            selected = listRow;
            editIndex = selected;
        }
        draw();
    }

    private function moveCardVertical(delta:Number):Void {
        var first:Number = currentPage * pageSize;
        var last:Number = Math.min(first + pageSize, slots.length) - 1;
        if (listRow < slots.length) {
            var target:Number = selected + delta * 2;
            if (target >= first && target <= last) {
                selected = target; listRow = target;
            } else if (delta > 0) {
                listRow = slots.length; listColumn = 0;
            }
        } else if (listRow == slots.length) {
            if (delta > 0) listRow = slots.length + 1;
            else { listRow = selected; }
        } else if (delta < 0) {
            listRow = slots.length; listColumn = 0;
        }
        editIndex = selected; navCursorVisible = true; draw();
    }

    private function moveCardHorizontal(delta:Number):Void {
        var first:Number = currentPage * pageSize;
        var last:Number = Math.min(first + pageSize, slots.length) - 1;
        var local:Number = selected - first;
        var target:Number = selected + delta;
        if (listRow < slots.length && target >= first && target <= last && Math.floor((target - first) / 2) == Math.floor(local / 2)) {
            selected = target; listRow = target; editIndex = target;
        }
        navCursorVisible = true; draw();
    }

    private function moveDetailFocus(delta:Number):Void {
        if (delta > 0) {
            if (detailFocus == 0) {
                detailFocus = 1;
            } else if (detailFocus == 1) {
                detailFocus = 2;
            } else if (detailFocus >= 2 && detailFocus <= 5) {
                detailFocus = 6;
            }
        } else if (delta < 0) {
            if (detailFocus == 6) {
                detailFocus = 2;
            } else if (detailFocus >= 2 && detailFocus <= 5) {
                detailFocus = 1;
            } else if (detailFocus == 1) {
                detailFocus = 0;
            }
        }
        if (detailFocus < 0) {
            detailFocus = 0;
        }
        if (detailFocus > 6) {
            detailFocus = 6;
        }
        navCursorVisible = true;
        draw();
    }

    private function moveDetailHorizontal(delta:Number):Void {
        if (detailFocus == 1) {
            cycleSelectedIcon(delta);
            return;
        }
        if (detailFocus < 2 || detailFocus > 5) {
            if (delta > 0) {
                detailFocus = 2;
            }
        } else {
            detailFocus += delta;
            if (detailFocus < 2) {
                detailFocus = 2;
            }
            if (detailFocus > 5) {
                detailFocus = 5;
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
        if (listRow > slots.length) {
            return;
        }
        if (cardView && listRow < slots.length) {
            moveCardHorizontal(delta);
            return;
        }
        listColumn += delta;
        if (listColumn < 0) {
            listColumn = 0;
        }
        var maxColumn:Number = listRow == slots.length ? 2 : 1;
        if (listColumn > maxColumn) {
            listColumn = maxColumn;
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
                if (listColumn == 0) toggleCardView();
                else requestPageChange(listColumn == 1 ? -1 : 1);
            } else if (listRow == slots.length + 1) {
                closeMenu();
            }
            return;
        }
        if (!cardView && listColumn == 1) {
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
            cycleSelectedIcon(1);
        } else if (detailFocus == 2) {
            showList();
        } else if (detailFocus == 3) {
            applySelected();
        } else if (detailFocus == 4) {
            saveSelected();
        } else if (detailFocus == 5) {
            clearSelected();
        } else if (detailFocus == 6) {
            closeMenu();
        }
    }

    private function cycleSelectedIcon(delta:Number):Void {
        var slot:Object = getActiveSlot();
        if (slot == undefined) return;
        var choices:Array = new Array("auto", "armor", "heavy", "light", "arcane", "clothing");
        var current:Number = 0; var i:Number = 0;
        while (i < choices.length) { if (choices[i] == safe(slot.icon).toLowerCase()) current = i; i++; }
        current = (current + delta + choices.length) % choices.length;
        slot.icon = choices[current];
        sendEvent("OPS_SetIcon", String(slot.icon), Number(slot.index));
        detailFocus = 1; navCursorVisible = true; draw();
    }

    private function iconLabel(value:String):String {
        if (value == "auto" || value == "") return "AUTO DETECT";
        return value.toUpperCase();
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
        if (equippingIndex >= 0) {
            return;
        }
        if (selected < 0 || selected >= slots.length) {
            return;
        }
        var slot:Object = slots[selected];
        if (!slot.ready) {
            return;
        }
        pausePreviewPhysics(1200);
        equippingIndex = Number(slot.index);
        equipStartedTime = getTimer();
        draw();
        sendEvent("OPS_ApplySlot", "", Number(slot.index));
    }

    private function tickEquipStatus():Void {
        var now:Number = getTimer();
        if (equippingIndex >= 0 && equipStartedTime > 0 && now - equipStartedTime > 5000) {
            equippingIndex = -1;
            equipStartedTime = 0;
            draw();
        }
        if (noticeMessage != "" && noticeUntil > 0 && now >= noticeUntil) {
            noticeMessage = "";
            noticeUntil = 0;
            draw();
        }
    }

    private function pausePreviewPhysics(duration:Number):Void {
        if (_global.skse != undefined && _global.skse.plugins != undefined) {
            var api:Object = _global.skse.plugins.OutfitPreviewSelectorCamera;
            if (api != undefined && api.PausePreviewPhysics != undefined) {
                api.PausePreviewPhysics(duration);
            }
        }
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
            if (Number(slot.index) == lastApplied) lastApplied = -1;
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
        drawOutfitBadge();
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

    private function drawOutfitBadge():Void {
        if (outfitBadge != undefined) outfitBadge.removeMovieClip();
        var slot:Object = getEquippedSlot();
        if (slot == undefined) return;

        outfitBadge = root.createEmptyMovieClip("opsOutfitBadge", 2);
        outfitBadge._x = 900;
        outfitBadge._y = 533;
        disableFocusTarget(outfitBadge);
        rect(outfitBadge, 0, 0, 316, 86, 0x050608, 78, 0xB89A55, 88, 1);
        rect(outfitBadge, 5, 5, 306, 76, 0x090B0E, 66, 0x6E5B32, 68, 1);
        rect(outfitBadge, 58, 17, 1, 52, 0xB89A55, 58, -1, 0, 0);
        drawMysticMark(outfitBadge, 17, 17);
        drawMysticMark(outfitBadge, 299, 17);
        drawOutfitIcon(outfitBadge, 31, 43, classifyOutfit(slot), slot.ready ? 0xE0BF64 : 0x746B59);
        addText(outfitBadge, "badgeLabel", 70, 13, 220, 15, "GEAR PRESET  " + twoDigits(slot.index + 1), 9, 0xA98C4D, true, "left");
        addText(outfitBadge, "badgeName", 70, 31, 220, 31, clip(slot.name, 25), 18, 0xF0E8D8, true, "left");
        rect(outfitBadge, 70, 66, 220, 1, 0xD7B65C, 52, -1, 0, 0);

        var shimmer:MovieClip = outfitBadge.createEmptyMovieClip("badgeShimmer" + nextDepth, nextDepth++);
        rect(shimmer, 0, 0, 38, 1, 0xF4D987, 90, -1, 0, 0);
        shimmer._x = 70;
        shimmer._y = 66;
        shimmer.onEnterFrame = function():Void {
            this._x += 1.6;
            this._alpha = 54 + Math.sin(getTimer() / 150) * 34;
            if (this._x > 252) this._x = 70;
        };

        outfitBadge._alpha = 0;
        outfitBadge.onEnterFrame = function():Void {
            this._alpha += 16;
            if (this._alpha >= 100) {
                this._alpha = 100;
                delete this.onEnterFrame;
            }
        };
    }

    private function drawList():Void {
        placeAsset(panel, "components/panel_bg.swf", 50, 64, 420, 644, 90);
        if (!cardView) placeAsset(panel, "components/panel_cols.swf", 70, 116, 370, 28, 70);
        rect(panel, 58, 72, 398, 626, 0x000000, 62, 0x6E685A, 58, 1);
        drawOrnateFrame(panel, 62, 76, 390, 618);
        rect(panel, 76, 118, 350, 1, 0x827868, 52, -1, 0, 0);
        addText(panel, "title", 78, 86, 348, 26, "G E A R       P R E S E T S", 18, 0xEEE8DC, true, "center");

        var y:Number = 138;
        var first:Number = currentPage * pageSize;
        var last:Number = Math.min(first + pageSize, slots.length);
        var i:Number = first;
        while (i < last) {
            if (cardView) {
                var local:Number = i - first;
                drawCard(slots[i], 78 + (local % 2) * 176, y + Math.floor(local / 2) * 80, 170, 72, i == selected && listRow < slots.length, Number(slots[i].index) == lastApplied, isEquippingSlot(slots[i]));
            } else {
                drawSlot(slots[i], 78, y + (i - first) * 40, 348, 34, i == selected && listRow < slots.length, Number(slots[i].index) == lastApplied, isEquippingSlot(slots[i]));
            }
            i++;
        }
        animateCurrent = false;

        if (cardView && navCursorVisible) addText(panel, "cardPrompt", 78, 530, 348, 12, "A / CROSS  EQUIP       Y / TRIANGLE  EDIT", 9, 0xB8A074, false, "center");

        rect(panel, 76, 544, 350, 1, 0x827868, 42, -1, 0, 0);
        drawButton("viewToggle", 78, 558, 116, 34, cardView ? "LIST VIEW" : "CARD VIEW", "toggleCards", -1, listRow == slots.length && listColumn == 0);
        addText(panel, "page", 212, 562, 76, 22, (currentPage + 1) + " / " + getPageCount(), 12, 0xC8BA98, false, "center");
        drawPageArrow("pagePrev", 306, 558, 56, 34, -1, currentPage > 0, listRow == slots.length && listColumn == 1);
        drawPageArrow("pageNext", 370, 558, 56, 34, 1, currentPage < getPageCount() - 1, listRow == slots.length && listColumn == 2);
        rect(panel, 76, 620, 350, 1, 0x827868, 52, -1, 0, 0);
        placeAsset(panel, "components/bar_1.swf", 70, 632, 362, 64, 72);
        drawButton("close", 78, 644, 348, 34, "Close", "close", -1, listRow == slots.length + 1);
        if (noticeMessage != "") {
            drawMissingNotice();
        }
    }

    private function drawCard(slot:Object, x:Number, y:Number, w:Number, h:Number, active:Boolean, worn:Boolean, equipping:Boolean):Void {
        var card:MovieClip = panel.createEmptyMovieClip("card" + nextDepth, nextDepth++);
        card._x = x; card._y = y; disableFocusTarget(card);
        var stroke:Number = equipping ? 0xD2B56A : (worn ? 0x91B9DC : (active ? 0x827868 : 0x4A453A));
        rect(card, 0, 0, w, h, equipping ? 0x29200E : (worn ? 0x14263D : 0x080A0D), 90, stroke, active || worn || equipping ? 88 : 48, active ? 2 : 1);
        if (active && navCursorVisible) drawAnimatedFocus(card, w, h);
        rect(card, 8, 10, 43, 43, 0x111317, 90, 0x8F7B4E, 68, 1);
        drawOutfitIcon(card, 29, 31, classifyOutfit(slot), slot.ready ? 0xD5B96C : 0x68645C);
        addText(card, "cardNum", 8, 56, 43, 13, twoDigits(slot.index + 1), 9, 0x9C8D6E, true, "center");
        addText(card, "cardName", 59, 9, 101, 18, clip(slot.name, 14), 12, worn ? 0xEEF7FF : 0xEEE8DC, true, "left");
        var self:OutfitPreviewMenu = this; var idx:Number = slot.index;
        if (!equipping) addClickZone(x, y, w, h, "applySlot", idx);
        if (equipping) {
            drawEquipIndicator(card, 68, 42);
            addText(card, "cardEquip", 80, 34, 78, 16, "EQUIPPING", 9, 0xD8C184, true, "left");
        } else {
            addText(card, "cardMeta", 59, 34, 54, 15, shortCount(slot.count) + "  AR " + slot.armor, 9, slot.ready ? 0xC8BA98 : 0x777B80, false, "left");
        }
        if (equipping) return;
        card.useHandCursor = true;
        card.onRelease = function():Void { if (!self.skipClipRelease()) { self.noteMouseInput(false); self.requestSlotAction("applySlot", idx); } };
    }

    private function drawAnimatedFocus(card:MovieClip, w:Number, h:Number):Void {
        var focus:MovieClip = card.createEmptyMovieClip("goldFocus" + nextDepth, nextDepth++);
        rect(focus, 2, 2, w - 4, h - 4, 0x000000, 0, 0xE0B94E, 100, 2);
        rect(focus, 5, 5, w - 10, h - 10, 0x000000, 0, 0x8D7132, 72, 1);
        focus.lineStyle(2, 0xF1D276, 100, true, "normal", "none", "miter", 3);
        focus.moveTo(2, 13); focus.lineTo(2, 2); focus.lineTo(13, 2);
        focus.moveTo(w - 13, 2); focus.lineTo(w - 2, 2); focus.lineTo(w - 2, 13);
        focus.moveTo(w - 2, h - 13); focus.lineTo(w - 2, h - 2); focus.lineTo(w - 13, h - 2);
        focus.moveTo(13, h - 2); focus.lineTo(2, h - 2); focus.lineTo(2, h - 13);
        focus.onEnterFrame = function():Void {
            this._alpha = 72 + Math.sin(getTimer() / 180) * 24;
        };
    }

    private function classifyOutfit(slot:Object):String {
        var chosen:String = safe(slot.icon).toLowerCase();
        if (chosen != "" && chosen != "auto") return chosen;
        var words:String = safe(slot.name).toLowerCase() + " " + safe(slot.items).toLowerCase();
        if (words.indexOf("mage") >= 0 || words.indexOf("robe") >= 0 || words.indexOf("witch") >= 0 || words.indexOf("sorcer") >= 0) return "arcane";
        if (words.indexOf("assassin") >= 0 || words.indexOf("thief") >= 0 || words.indexOf("rogue") >= 0 || words.indexOf("leather") >= 0) return "light";
        if (words.indexOf("knight") >= 0 || words.indexOf("plate") >= 0 || words.indexOf("heavy") >= 0 || words.indexOf("daedric") >= 0) return "heavy";
        if (Number(slot.armor) <= 0) return "clothing";
        return "armor";
    }

    private function drawOutfitIcon(target:MovieClip, cx:Number, cy:Number, kind:String, color:Number):Void {
        target.lineStyle(2, color, 95, true, "normal", "none", "miter", 3);
        if (kind == "arcane") {
            target.moveTo(cx, cy - 14); target.lineTo(cx + 4, cy - 4); target.lineTo(cx + 14, cy); target.lineTo(cx + 4, cy + 4); target.lineTo(cx, cy + 14); target.lineTo(cx - 4, cy + 4); target.lineTo(cx - 14, cy); target.lineTo(cx - 4, cy - 4); target.lineTo(cx, cy - 14);
        } else if (kind == "light") {
            target.moveTo(cx - 10, cy - 12); target.lineTo(cx + 10, cy + 12); target.moveTo(cx + 10, cy - 12); target.lineTo(cx - 10, cy + 12); target.moveTo(cx - 13, cy - 8); target.lineTo(cx - 8, cy - 13); target.moveTo(cx + 13, cy - 8); target.lineTo(cx + 8, cy - 13);
        } else if (kind == "clothing") {
            target.moveTo(cx - 7, cy - 13); target.lineTo(cx + 7, cy - 13); target.lineTo(cx + 12, cy + 13); target.lineTo(cx - 12, cy + 13); target.lineTo(cx - 7, cy - 13); target.moveTo(cx - 7, cy - 5); target.lineTo(cx + 7, cy - 5);
        } else {
            target.moveTo(cx, cy - 14); target.lineTo(cx + 12, cy - 8); target.lineTo(cx + 9, cy + 7); target.lineTo(cx, cy + 14); target.lineTo(cx - 9, cy + 7); target.lineTo(cx - 12, cy - 8); target.lineTo(cx, cy - 14);
            if (kind == "heavy") { target.moveTo(cx - 8, cy - 4); target.lineTo(cx + 8, cy - 4); target.moveTo(cx, cy - 11); target.lineTo(cx, cy + 10); }
        }
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
        drawOrnateFrame(panel, 62, 76, 410, 568);
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

        addText(panel, "iconTitle", 78, 211, 70, 18, "Card Icon", 12, detailFocus == 1 ? 0xEEE8DC : 0xC8BA98, false, "left");
        drawButton("iconPrev", 154, 204, 38, 30, "<", "iconPrev", -1, detailFocus == 1);
        rect(panel, 200, 204, 154, 30, 0x0D0E0F, 72, 0x6E685A, 60, 1);
        drawOutfitIcon(panel, 218, 219, classifyOutfit(slot), 0xD5B96C);
        addText(panel, "iconName", 236, 211, 112, 18, iconLabel(safe(slot.icon)), 10, 0xEEE8DC, true, "center");
        drawButton("iconNext", 362, 204, 38, 30, ">", "iconNext", -1, detailFocus == 1);

        addText(panel, "itemsTitle", 78, 252, 220, 20, "Saved Items", 15, 0xEEE8DC, true, "left");
        rect(panel, 76, 277, 364, 1, 0x827868, 40, -1, 0, 0);

        var y:Number = 289;
        var i:Number = 0;
        if (slot.items.length == 0) {
            addText(panel, "empty", 78, y, 330, 22, "No saved items", 14, 0x8C9298, false, "left");
        } else {
            while (i < slot.items.length && i < 8) {
                drawItem(slot.items[i], 78, y + i * 26, 360, 23, i);
                i++;
            }
        }

        rect(panel, 76, 504, 364, 1, 0x827868, 52, -1, 0, 0);
        drawButton("back", 78, 520, 82, 32, "Back", "back", -1, detailFocus == 2);
        drawButton("apply", 168, 520, 82, 32, "Apply", "apply", -1, detailFocus == 3);
        drawButton("save", 258, 520, 82, 32, "Save", "save", -1, detailFocus == 4);
        drawButton("clear", 348, 520, 92, 32, "Clear", "clear", -1, detailFocus == 5);
        drawButton("close", 78, 584, 362, 34, "Close", "close", -1, detailFocus == 6);
    }

    private function drawSlot(slot:Object, x:Number, y:Number, w:Number, h:Number, active:Boolean, worn:Boolean, equipping:Boolean):Void {
        var row:MovieClip = panel.createEmptyMovieClip("slot" + nextDepth, nextDepth++);
        row._x = x;
        row._y = y;
        disableFocusTarget(row);
        var debugActive:Boolean = active && debugFocusHighlight;
        var fill:Number = equipping ? 0x29200E : (worn ? 0x14263D : (debugActive ? 0x11161C : 0x07090C));
        var fillAlpha:Number = equipping ? 94 : (worn ? 92 : (debugActive ? 78 : 74));
        var stroke:Number = equipping ? 0xD2B56A : (worn ? 0x91B9DC : (debugActive ? 0x827868 : -1));
        var strokeAlpha:Number = equipping ? 90 : (worn ? 100 : (debugActive ? 90 : 0));
        var strokeWidth:Number = equipping ? 1 : (worn ? 2 : (debugActive ? 1 : 0));
        var textColor:Number = worn ? 0xEEF7FF : 0xEEE8DC;
        var metaColor:Number = worn ? 0xB7CEE3 : (slot.ready ? 0xC8BA98 : 0x8C9298);
        rect(row, 0, 0, w, h, fill, fillAlpha, stroke, strokeAlpha, strokeWidth);
        if (active && listColumn == 0 && navCursorVisible) drawAnimatedFocus(row, w, h);
        rect(row, 0, 0, worn ? 6 : (active ? 4 : 3), h, worn ? 0xAACAE7 : (slot.ready ? 0xB8A074 : 0x5F656B), worn ? 100 : (active ? 95 : 90), -1, 0, 0);
        if (worn) {
            rect(row, 3, 3, w - 6, h - 6, 0x000000, 0, 0xC8B574, 62, 1);
            drawMysticMark(row, w - 9, Math.floor(h / 2));
        }
        addText(row, "num", 12, 7, 30, 20, twoDigits(slot.index + 1), 14, textColor, true, "left");
        addText(row, "name", 50, 7, 118, 20, clip(slot.name, 17), 14, textColor, worn, "left");
        if (equipping) {
            drawEquipIndicator(row, 180, Math.floor(h / 2));
            addText(row, "equipping", 194, 8, 72, 18, "EQUIPPING", 10, 0xD8C184, true, "left");
        } else {
            addText(row, "count", 170, 8, 52, 18, shortCount(slot.count), 11, metaColor, false, "right");
            addText(row, "armor", 224, 8, 42, 18, "AR " + slot.armor, 11, metaColor, false, "right");
        }

        if (worn && animateCurrent) {
            animateOutfitRow(row);
            animateMysticShimmer(row, w, h);
        }

        if (equipping) return;

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
            self.requestSlotAction("applySlot", idx);
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
        if (active && navCursorVisible) drawAnimatedFocus(edit, 64, 25);
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
            self.requestSlotAction("editSlot", idx);
        };
    }

    private function drawEquipIndicator(parent:MovieClip, centerX:Number, centerY:Number):Void {
        var spinner:MovieClip = parent.createEmptyMovieClip("equipSpinner" + nextDepth, nextDepth++);
        spinner._x = centerX;
        spinner._y = centerY;
        spinner.lineStyle(2, 0xD8C184, 92, true, "normal", "none", "miter", 3);
        spinner.moveTo(0, -6);
        spinner.lineTo(0, -2);
        spinner.moveTo(6, 0);
        spinner.lineTo(2, 0);
        spinner.moveTo(0, 6);
        spinner.lineTo(0, 2);
        spinner.moveTo(-6, 0);
        spinner.lineTo(-2, 0);
        spinner.onEnterFrame = function():Void {
            this._rotation += 14;
        };
    }

    private function drawMissingNotice():Void {
        var notice:MovieClip = panel.createEmptyMovieClip("missingNotice" + nextDepth, nextDepth++);
        notice._x = 86;
        notice._y = 292;
        rect(notice, 0, 0, 330, 132, 0x120D08, 98, 0xD2B56A, 94, 2);
        rect(notice, 5, 5, 320, 122, 0x000000, 0, 0x7D693D, 68, 1);
        drawMysticMark(notice, 20, 20);
        drawMysticMark(notice, 310, 20);
        addText(notice, "noticeTitle", 34, 14, 262, 22, "ENSEMBLE INCOMPLETE", 15, 0xE7D49A, true, "center");
        var message:TextField = addText(notice, "noticeMessage", 22, 45, 286, 50, noticeMessage, 12, 0xEEE8DC, false, "center");
        message.multiline = true;
        message.wordWrap = true;
        addText(notice, "noticeHint", 22, 104, 286, 16, "Current attire remains unchanged  -  click to dismiss", 9, 0xA89362, false, "center");
        addClickZone(86, 292, 330, 132, "dismissNotice", -1);
    }

    private function drawItem(label:String, x:Number, y:Number, w:Number, h:Number, index:Number):Void {
        var row:MovieClip = panel.createEmptyMovieClip("item" + nextDepth, nextDepth++);
        row._x = x;
        row._y = y;
        rect(row, 0, 0, w, h, index % 2 == 0 ? 0x0D0E0F : 0x111214, 46, -1, 0, 0);
        addText(row, "itemText", 12, 4, w - 24, 16, clip(label, 45), 12, 0xEEE8DC, false, "left");
    }

    private function drawPageArrow(name:String, x:Number, y:Number, w:Number, h:Number, direction:Number, enabled:Boolean, focused:Boolean):Void {
        var arrow:MovieClip = panel.createEmptyMovieClip(name + nextDepth, nextDepth++);
        arrow._x = x;
        arrow._y = y;
        disableFocusTarget(arrow);
        var edge:Number = enabled ? 0xB89A55 : 0x4A453A;
        rect(arrow, 0, 0, w, h, 0x0D0E0F, enabled ? 78 : 46, edge, enabled ? 82 : 42, focused ? 2 : 1);
        if (focused && navCursorVisible) drawAnimatedFocus(arrow, w, h);
        var cx:Number = Math.floor(w / 2);
        var cy:Number = Math.floor(h / 2);
        arrow.lineStyle(2, enabled ? 0xD5B96C : 0x5F5A50, enabled ? 96 : 48, true, "normal", "none", "miter", 3);
        arrow.moveTo(cx - direction * 2, cy - 7);
        arrow.lineTo(cx + direction * 6, cy);
        arrow.lineTo(cx - direction * 2, cy + 7);
        if (enabled) {
            addClickZone(x, y, w, h, direction < 0 ? "prevPage" : "nextPage", -1);
            var self:OutfitPreviewMenu = this;
            arrow.useHandCursor = true;
            arrow.onRelease = function():Void {
                if (self.skipClipRelease()) return;
                self.noteMouseInput(false);
                self.requestPageChange(direction);
            };
        }
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
        if (focused && navCursorVisible) drawAnimatedFocus(button, w, h);

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
                listRow = slots.length + 1;
            } else if (action == "toggleCards" || action == "prevPage" || action == "nextPage") {
                listRow = slots.length;
                listColumn = action == "toggleCards" ? 0 : (action == "prevPage" ? 1 : 2);
            } else if (idx >= 0) {
                listRow = idx;
                selectIndex(idx, false);
            }
        } else if (viewMode == "detail") {
            if (action == "rename" || action == "renameInput") detailFocus = 0;
            else if (action == "iconPrev" || action == "iconNext") detailFocus = 1;
            else if (action == "back") detailFocus = 2;
            else if (action == "apply") detailFocus = 3;
            else if (action == "save") detailFocus = 4;
            else if (action == "clear") detailFocus = 5;
            else if (action == "close") detailFocus = 6;
        }
    }

    private function runAction(action:String, idx:Number):Void {
        if (action == "dismissNotice") {
            noticeMessage = "";
            noticeUntil = 0;
            draw();
        } else if (action == "save") {
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
        } else if (action == "toggleCards") {
            toggleCardView();
        } else if (action == "iconPrev") {
            cycleSelectedIcon(-1);
        } else if (action == "iconNext") {
            cycleSelectedIcon(1);
        } else if (action == "prevPage") {
            requestPageChange(-1);
        } else if (action == "nextPage") {
            requestPageChange(1);
        }
    }

    private function toggleCardView():Void {
        cardView = !cardView;
        sendEvent("OPS_SetCardView", "", cardView ? 1 : 0);
        draw();
    }

    private function getPageCount():Number {
        return Math.max(1, Math.ceil(slots.length / pageSize));
    }

    private function requestPageChange(delta:Number):Void {
        if (pageChangePending || getTimer() - lastPageChangeTime < 350) return;
        var target:Number = currentPage + delta;
        if (target < 0 || target >= getPageCount()) return;

        pageChangePending = true;
        pendingPageDirection = delta;
        var self:OutfitPreviewMenu = this;
        var task:MovieClip = root.createEmptyMovieClip("opsDeferredPageChange", 9995);
        task.onEnterFrame = function():Void {
            delete this.onEnterFrame;
            var requestedDirection:Number = self.pendingPageDirection;
            self.pendingPageDirection = 0;
            self.pageChangePending = false;
            this.removeMovieClip();
            self.changePage(requestedDirection);
        };
    }

    private function changePage(delta:Number):Void {
        var target:Number = currentPage + delta;
        if (target < 0 || target >= getPageCount() || target == currentPage) return;
        lastPageChangeTime = getTimer();
        currentPage = target;
        selected = Math.min(currentPage * pageSize, slots.length - 1);
        editIndex = selected;
        listRow = selected;
        listColumn = 0;
        draw();
    }

    private function requestSlotAction(action:String, idx:Number):Void {
        if (action == "applySlot" && equippingIndex >= 0) return;
        if (slotActionPending || getTimer() - lastSlotActionTime < 350) return;
        slotActionPending = true;
        pendingSlotAction = action;
        pendingSlotIndex = idx;
        var self:OutfitPreviewMenu = this;
        var task:MovieClip = root.createEmptyMovieClip("opsDeferredSlotAction", 9994);
        task.onEnterFrame = function():Void {
            delete this.onEnterFrame;
            var requestedAction:String = self.pendingSlotAction;
            var requestedIndex:Number = self.pendingSlotIndex;
            self.pendingSlotAction = "";
            self.pendingSlotIndex = -1;
            self.slotActionPending = false;
            self.lastSlotActionTime = getTimer();
            this.removeMovieClip();

            if (requestedAction == "applySlot") {
                self.listColumn = 0;
                self.listRow = requestedIndex;
                self.selectIndex(requestedIndex, false);
                self.applySelected();
            } else if (requestedAction == "editSlot") {
                self.listColumn = 1;
                self.listRow = requestedIndex;
                self.selectIndex(requestedIndex, false);
                self.openDetail(requestedIndex);
            }
        };
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

    private function getEquippedSlot():Object {
        if (lastApplied < 0) return undefined;
        var i:Number = 0;
        while (i < slots.length) {
            if (slots[i].ready && Number(slots[i].index) == lastApplied) return slots[i];
            i++;
        }
        return undefined;
    }

    private function isEquippingSlot(slot:Object):Boolean {
        if (equippingIndex < 0 || slot == undefined || !slot.ready) return false;
        var index:Number = Number(slot.index);
        return !isNaN(index) && index >= 0 && index < 50 && index == equippingIndex;
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
                    requestSlotAction("applySlot", Number(zone.idx));
                } else if (zone.action == "editSlot") {
                    requestSlotAction("editSlot", Number(zone.idx));
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
        if (viewMode == "list") {
            return;
        }
        if (viewMode == "detail" && detailFocus >= 2) {
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
                var localSlot:Number = selected - currentPage * pageSize;
                if (cardView) {
                    cy = 155 + Math.floor(localSlot / 2) * 80;
                    cx = 62 + (localSlot % 2) * 176;
                } else {
                    cy = 155 + localSlot * 40;
                    cx = listColumn == 1 ? 340 : 62;
                }
            } else if (listRow == slots.length) {
                cy = 568;
                cx = listColumn == 0 ? 62 : (listColumn == 1 ? 290 : 354);
            } else {
                cy = 658;
                cx = 62;
            }
        } else {
            if (detailFocus == 0) {
                cy = 170;
                cx = 62;
            } else if (detailFocus == 1) {
                cy = 212;
                cx = 138;
            } else if (detailFocus == 2) {
                cy = 533;
                cx = 62;
            } else if (detailFocus == 3) {
                cy = 533;
                cx = 152;
            } else if (detailFocus == 4) {
                cy = 533;
                cx = 242;
            } else if (detailFocus == 5) {
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
        var targetY:Number = clip._y;
        var started:Number = getTimer();
        var sweep:MovieClip = clip.createEmptyMovieClip("introSweep" + nextDepth, nextDepth++);
        sweep._x = 76;
        sweep._y = 118;
        rect(sweep, 0, 0, 350, 2, 0xD8C184, 100, -1, 0, 0);
        sweep._xscale = 0;
        sweep._alpha = 0;
        clip._x = targetX - 18;
        clip._y = targetY + 10;
        clip._alpha = 0;
        clip.onEnterFrame = function():Void {
            var progress:Number = (getTimer() - started) / 240;
            if (progress >= 1) {
                this._x = targetX;
                this._y = targetY;
                this._alpha = 100;
                sweep.removeMovieClip();
                delete this.onEnterFrame;
                return;
            }
            var eased:Number = 1 - Math.pow(1 - progress, 3);
            this._x = targetX - 18 * (1 - eased);
            this._y = targetY + 10 * (1 - eased);
            this._alpha = Math.round(100 * eased);
            sweep._xscale = Math.round(100 * eased);
            sweep._alpha = Math.round(72 * Math.sin(progress * Math.PI));
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

    private function drawOrnateFrame(parent:MovieClip, x:Number, y:Number, w:Number, h:Number):Void {
        rect(parent, x, y, w, h, 0x000000, 0, 0xC4A45A, 78, 1);
        rect(parent, x + 4, y + 4, w - 8, h - 8, 0x000000, 0, 0x7D693D, 48, 1);
        drawCornerOrnament(parent, x, y, 1, 1);
        drawCornerOrnament(parent, x + w, y, -1, 1);
        drawCornerOrnament(parent, x, y + h, 1, -1);
        drawCornerOrnament(parent, x + w, y + h, -1, -1);
    }

    private function drawCornerOrnament(parent:MovieClip, x:Number, y:Number, sx:Number, sy:Number):Void {
        var corner:MovieClip = parent.createEmptyMovieClip("corner" + nextDepth, nextDepth++);
        corner._x = x;
        corner._y = y;
        corner._xscale = sx * 100;
        corner._yscale = sy * 100;
        corner.lineStyle(1, 0xD2B56A, 88, true, "normal", "none", "miter", 3);
        corner.moveTo(0, 22);
        corner.lineTo(7, 15);
        corner.lineTo(7, 7);
        corner.lineTo(15, 7);
        corner.lineTo(22, 0);
        corner.moveTo(4, 29);
        corner.lineTo(12, 21);
        corner.lineTo(12, 12);
        corner.lineTo(21, 12);
        corner.lineTo(29, 4);
        corner.beginFill(0xB89A55, 72);
        corner.moveTo(7, 7);
        corner.lineTo(11, 3);
        corner.lineTo(15, 7);
        corner.lineTo(11, 11);
        corner.lineTo(7, 7);
        corner.endFill();
        corner.lineStyle(1, 0x9D8248, 70, true, "normal", "none", "miter", 3);
        corner.moveTo(15, 18);
        corner.lineTo(20, 14);
        corner.lineTo(24, 18);
        corner.lineTo(20, 22);
        corner.lineTo(15, 18);
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
