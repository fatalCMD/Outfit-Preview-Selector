class MCMIntro {
    static function build(root:MovieClip):Void {
        root._alpha = 0;
        root._focusrect = false;
        root.focusEnabled = false;
        root.tabEnabled = false;
        root.tabChildren = false;

        var art:MovieClip = root.createEmptyMovieClip("opsMCMArt", 1);
        drawPanel(art);

        var started:Number = getTimer();
        root.onEnterFrame = function():Void {
            var progress:Number = (getTimer() - started) / 720;
            if (progress >= 1) {
                this._alpha = 100;
                delete this.onEnterFrame;
                return;
            }
            var eased:Number = 1 - Math.pow(1 - progress, 3);
            this._alpha = Math.round(100 * eased);
        };
    }

    static function drawPanel(target:MovieClip):Void {
        rect(target, 65, 35, 640, 376, 0x050607, 84, 0xC5A252, 82, 1);
        rect(target, 71, 41, 628, 364, 0x090B0E, 72, 0x705B30, 62, 1);
        rect(target, 78, 48, 614, 350, 0x000000, 0, 0xB69148, 38, 1);

        corner(target, 78, 48, 1, 1);
        corner(target, 692, 48, -1, 1);
        corner(target, 78, 398, 1, -1);
        corner(target, 692, 398, -1, -1);

        target.lineStyle(1, 0x8E7440, 58, true, "normal", "none", "miter", 3);
        target.moveTo(160, 110);
        target.lineTo(315, 110);
        target.moveTo(455, 110);
        target.lineTo(610, 110);
        diamond(target, 385, 110, 8, 0xD6B660, 85);

        emblem(target, 385, 185);

        addText(target, "opsName", 120, 255, 530, 34, "OUTFIT PREVIEW SELECTOR", 24, 0xEEE7D9, true, "center");
        addText(target, "opsTitle", 120, 298, 530, 24, "G E A R   P R E S E T S", 14, 0xD3B56D, true, "center");
        addText(target, "opsSub", 145, 338, 480, 18, "FIFTY PRESETS  /  CHARACTER PREVIEW  /  OUTFIT CONTROL", 9, 0x9E927A, false, "center");

        target.lineStyle(1, 0x8E7440, 46, true, "normal", "none", "miter", 3);
        target.moveTo(205, 370);
        target.lineTo(565, 370);
        diamond(target, 385, 370, 4, 0xB99A52, 70);
    }

    static function emblem(target:MovieClip, cx:Number, cy:Number):Void {
        target.lineStyle(2, 0xD3B15C, 92, true, "normal", "none", "miter", 3);
        target.moveTo(cx, cy - 57);
        target.lineTo(cx + 46, cy - 23);
        target.lineTo(cx + 35, cy + 35);
        target.lineTo(cx, cy + 58);
        target.lineTo(cx - 35, cy + 35);
        target.lineTo(cx - 46, cy - 23);
        target.lineTo(cx, cy - 57);

        target.lineStyle(1, 0x7B6335, 76, true, "normal", "none", "miter", 3);
        target.moveTo(cx, cy - 48);
        target.lineTo(cx + 37, cy - 18);
        target.lineTo(cx + 28, cy + 29);
        target.lineTo(cx, cy + 48);
        target.lineTo(cx - 28, cy + 29);
        target.lineTo(cx - 37, cy - 18);
        target.lineTo(cx, cy - 48);

        target.lineStyle(3, 0xE5C873, 94, true, "normal", "none", "miter", 3);
        target.moveTo(cx - 18, cy - 22);
        target.lineTo(cx - 4, cy - 33);
        target.lineTo(cx + 18, cy - 22);
        target.lineTo(cx + 8, cy - 10);
        target.lineTo(cx + 18, cy + 28);
        target.lineTo(cx, cy + 17);
        target.lineTo(cx - 18, cy + 28);
        target.lineTo(cx - 8, cy - 10);
        target.lineTo(cx - 18, cy - 22);

        diamond(target, cx, cy - 2, 7, 0xE7CB7A, 92);
    }

    static function corner(target:MovieClip, x:Number, y:Number, sx:Number, sy:Number):Void {
        var clip:MovieClip = target.createEmptyMovieClip("corner" + target.getNextHighestDepth(), target.getNextHighestDepth());
        clip._x = x;
        clip._y = y;
        clip._xscale = sx * 100;
        clip._yscale = sy * 100;
        clip.lineStyle(1, 0xD1AD59, 88, true, "normal", "none", "miter", 3);
        clip.moveTo(0, 32);
        clip.lineTo(9, 23);
        clip.lineTo(9, 9);
        clip.lineTo(23, 9);
        clip.lineTo(32, 0);
        clip.moveTo(5, 40);
        clip.lineTo(14, 31);
        clip.lineTo(14, 14);
        clip.lineTo(31, 14);
        clip.lineTo(40, 5);
        diamond(clip, 10, 10, 5, 0xD9B65E, 84);
    }

    static function diamond(target:MovieClip, cx:Number, cy:Number, radius:Number, color:Number, alpha:Number):Void {
        target.lineStyle(1, color, alpha, true, "normal", "none", "miter", 3);
        target.beginFill(color, Math.round(alpha * 0.34));
        target.moveTo(cx, cy - radius);
        target.lineTo(cx + radius, cy);
        target.lineTo(cx, cy + radius);
        target.lineTo(cx - radius, cy);
        target.lineTo(cx, cy - radius);
        target.endFill();
    }

    static function rect(target:MovieClip, x:Number, y:Number, w:Number, h:Number, fill:Number, alpha:Number, stroke:Number, strokeAlpha:Number, strokeWidth:Number):Void {
        target.lineStyle(strokeWidth, stroke, strokeAlpha, true, "normal", "none", "miter", 3);
        target.beginFill(fill, alpha);
        target.moveTo(x, y);
        target.lineTo(x + w, y);
        target.lineTo(x + w, y + h);
        target.lineTo(x, y + h);
        target.lineTo(x, y);
        target.endFill();
    }

    static function addText(parent:MovieClip, name:String, x:Number, y:Number, w:Number, h:Number, text:String, size:Number, color:Number, bold:Boolean, align:String):TextField {
        var depth:Number = parent.getNextHighestDepth();
        parent.createTextField(name + depth, depth, x, y, w, h);
        var field:TextField = TextField(parent[name + depth]);
        field._focusrect = false;
        field.selectable = false;
        field.tabEnabled = false;
        field.embedFonts = true;
        field.antiAliasType = "advanced";
        var format:TextFormat = new TextFormat();
        format.font = bold ? "$EverywhereBoldFont" : "$EverywhereFont";
        format.size = size;
        format.color = color;
        format.align = align;
        field.text = text;
        field.setNewTextFormat(format);
        field.setTextFormat(format);
        return field;
    }
}
