class Main {
    static function main(root:MovieClip):Void {
        Stage.scaleMode = "noScale";
        Stage.align = "TL";
        Stage.showMenu = false;
        _root.main = new OutfitPreviewMenu(root);
    }
}
