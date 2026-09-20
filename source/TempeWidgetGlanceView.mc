import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;


(:glance)
class TempeWidgetGlanceView extends WatchUi.GlanceView {

    var state;

    //Like the main view, nothing here is a fixed pixel value. Columns are a
    //fraction of dc.getWidth() and the two rows are stacked off the device's
    //own font heights, so the same code fills a 176px fenix 6 strip and a
    //359px fenix 9 Pro 51mm one.

    function initialize() {
        GlanceView.initialize();
        //System.println("Glance: glanceViewInit");
        state = new State();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
       //setLayout(Rez.Layouts.MainLayout(dc));
    }

    // Called when this View is brought to the foreground. Restore  
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    function onUpdate(dc as Dc) as Void {

        GlanceView.onUpdate(dc);

        var clrBack = state.fWhiteBG ? ClrWhite : ClrBlack;
        var clrFore = state.fWhiteBG ? ClrBlack : ClrWhite;
        var clrLbl  = state.fWhiteBG ? ClrDkGray : ClrLtGray;

        dc.setColor(clrFore, clrBack);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();

        //One column per configured slot, captioned with that slot's own label.
        //A single slot has the strip to itself, so it spends the space on the
        //min and max instead -- which is what this view used to show for slot 0
        //whatever the user had actually configured.
        var n = (state.cTempe < 2) ? 3 : state.cTempe;
        var rgLbl = new [n]; //captions, one per column
        var rgVal = new [n]; //formatted readings, one per column
        var rgDim = new [n]; //true where that reading is on its way out

        if (state.cTempe < 2)
        {
            var item = rgTemp[0];
            var fDim = item.fExpiring();

            rgLbl[0] = item.lbl;  rgVal[0] = strTempGlance(item.tempAdj()); rgDim[0] = fDim;
            rgLbl[1] = "Min";     rgVal[1] = strTempGlance(item.minAdj());  rgDim[1] = fDim;
            rgLbl[2] = "Max";     rgVal[2] = strTempGlance(item.maxAdj());  rgDim[2] = fDim;
        }
        else
        {
            for (var j = 0; j < n; ++j)
            {
                var item = rgTemp[j];

                rgLbl[j] = item.lbl;
                rgVal[j] = strTempGlance(item.tempAdj());
                rgDim[j] = item.fExpiring();
            }
        }

        //--- fonts, sized once so every column matches -----------------------
        //85% of the column keeps neighbouring readings from touching.
        var colW = w / n;
        var maxW = colW * 85 / 100;

        var fLbl = fitFont(dc, rgLbl, maxW, h / 3,
                           [Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var hLbl = dc.getFontHeight(fLbl);

        var fVal = fitFont(dc, rgVal, maxW, h - hLbl,
                           [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL,
                            Graphics.FONT_TINY, Graphics.FONT_XTINY]);
        var hVal = dc.getFontHeight(fVal);

        //A label is free text from the settings menu, so the smallest font is
        //not necessarily small enough. Clip what is left over.
        for (var j = 0; j < n; ++j)
        {
            rgLbl[j] = fitStr(dc, rgLbl[j], fLbl, maxW);
        }

        //--- centre the value/label stack vertically -------------------------
        var yVal = (h - (hVal + hLbl)) / 2;
        if (yVal < 0) {yVal = 0;}

        //--- draw ------------------------------------------------------------
        for (var j = 0; j < n; ++j)
        {
            var x = (colW * j) + (colW / 2);

            //A reading past 50% of the timeout drops to the caption's tone, so
            //a stale column reads as muted beside a fresh one.
            dc.setColor(rgDim[j] ? clrLbl : clrFore, ClrTrans);
            dc.drawText(x, yVal, fVal, rgVal[j], Graphics.TEXT_JUSTIFY_CENTER);

            dc.setColor(clrLbl, ClrTrans);
            dc.drawText(x, yVal + hVal, fLbl, rgLbl[j], Graphics.TEXT_JUSTIFY_CENTER);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
