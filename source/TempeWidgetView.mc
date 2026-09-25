import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.SensorHistory;
import Toybox.AntPlus;


class TempeWidgetView extends WatchUi.View {

    var state;

    var screenNum = 0;

    //Nothing in this view is a fixed pixel value. Every metric is derived from
    //dc.getWidth()/getHeight() and the device's own font heights, so the same
    //code lays out on a 176px Instinct and a 466px fenix 9 Pro 51mm.
    //The system fonts already scale per device (fenix 7 "large" is 25px,
    //epix 2 Pro 51mm is 40px), so only the geometry needed deriving.

    function initialize() {
        //System.println("Full: View.initialize");
        View.initialize();
        state = new State();
    }

    // Load your resources here
    function onLayout(dc as Dc) as Void {
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() as Void {
    }

    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        View.onUpdate(dc);

        var clrBack = state.fWhiteBG ? ClrWhite : ClrBlack;
        var clrFore = state.fWhiteBG ? ClrBlack : ClrWhite;
        //screenNum indexes the visible list, not the slot array. That list can
        //shrink under us - a Tempe times out, or the settings change in the
        //Connect app - so clamp it every draw. With nothing visible at all,
        //fall back to slot 0, which then draws as "--".
        var rgVis = state.rgVisible() as Lang.Array<Lang.Number>;
        var cVis = rgVis.size();
        if (screenNum >= cVis) {screenNum = 0;}
        var i = (cVis > 0) ? rgVis[screenNum] : 0;
        var item = rgTemp[i];

        dc.setColor(clrFore, clrBack);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var xCenter = w/2;

        //--- the rows we are going to stack -------------------------------
        var strLbl = item.lbl;
        //Null is a wildcard slot that has not found a sensor yet; "ex" is what
        //this has always shown for that, so keep it.
        var idNow = item.getID();
        var strDbg = state.fDbg ? ((idNow == null) ? "ex" : idNow.toString()) : null;
        var strT   = "Temp : " + strTemp(item.tempAdj());
        var strMin = (item.tempMin != null) ? "Min : " + strTemp(item.minAdj()) : null;
        var strMax = (item.tempMax != null) ? "Max : " + strTemp(item.maxAdj()) : null;

        var batteryStatus = strBatt(item.batStatus);
        var fShowBatt = state.fBtry && (idNow != -1) && (batteryStatus != 0);

        //Past 50% of the timeout the reading is on its way out. Dim the values
        //and the battery -- they are the stale part -- but leave the label at
        //full contrast, since which slot you are looking at has not gone stale.
        //ClrDkGray reads as dimmed against both a black and a white background.
        var clrVal = item.fExpiring() ? ClrDkGray : clrFore;

        //--- battery geometry, proportional to the screen -----------------
        //15% of width reproduces the original 40px icon on a 260px fenix 7
        var battW = w * 15 / 100;
        var battH = battW / 2;

        //--- fonts --------------------------------------------------------
        //82% keeps centred text clear of the bezel on round screens
        var maxW = w * 82 / 100;
        var ladder = [Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL,
                      Graphics.FONT_TINY, Graphics.FONT_XTINY];

        var fVal = fitFont(dc, [strT, strMin, strMax], maxW, 0, ladder);
        var fLbl = fitFont(dc, [strLbl], maxW, 0, ladder);

        var hLbl = dc.getFontHeight(fLbl);
        var hVal = dc.getFontHeight(fVal);
        var hDbg = dc.getFontHeight(Graphics.FONT_XTINY);
        var gap  = hVal / 5;

        //--- centre the whole stack vertically ----------------------------
        var total = hLbl + gap + hVal;
        if (strDbg != null) {total += hDbg;}
        if (strMin != null) {total += gap + hVal;}
        if (strMax != null) {total += gap + hVal;}
        if (fShowBatt)      {total += gap + battH;}

        var y = (h - total) / 2;
        if (y < 0) {y = 0;}

        //--- draw ---------------------------------------------------------
        dc.setColor(clrFore, ClrTrans);
        dc.drawText(xCenter, y, fLbl, strLbl, Graphics.TEXT_JUSTIFY_CENTER);
        y += hLbl;

        if (strDbg != null)
        {
            dc.setColor(ClrDkGray, ClrTrans);
            dc.drawText(xCenter, y, Graphics.FONT_XTINY, strDbg, Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(clrFore, ClrTrans);
            y += hDbg;
        }
        y += gap;

        dc.setColor(clrVal, ClrTrans);
        dc.drawText(xCenter, y, fVal, strT, Graphics.TEXT_JUSTIFY_CENTER);
        y += hVal + gap;

        if (strMin != null)
        {
            dc.drawText(xCenter, y, fVal, strMin, Graphics.TEXT_JUSTIFY_CENTER);
            y += hVal + gap;
        }

        if (strMax != null)
        {
            dc.drawText(xCenter, y, fVal, strMax, Graphics.TEXT_JUSTIFY_CENTER);
            y += hVal + gap;
        }

        if (fShowBatt)
        {
            drawBattery(dc, batteryStatus, clrVal, Graphics.COLOR_DK_RED, clrBack,
                        xCenter, y, battW, battH);
        }

        drawDots(dc, clrFore, screenNum, cVis);

        if (state.fDbg)
        {
            System.println("onUpdate " + strDbg + " batteryStatus : " + batteryStatus);
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

    //---------------------------------
    //xMid is the centre the icon should sit on; the terminal nub is included
    //in the centring so the whole shape reads as centred, unlike before.
    function drawBattery(dc, batteryStatus, primaryColor, lowBatteryColor, bgColor, xMid, y, bw, bh)
    {
        var battery = batteryStatus;

        var nw = bw / 10;
        if (nw < 2) {nw = 2;}
        var nh = bh / 2;
        if (nh < 3) {nh = 3;}

        var x  = xMid - ((bw + nw) / 2);
        var nx = x + bw;
        var ny = y + ((bh - nh) / 2);

        // BATT_STATUS_NEW = 1, BATT_STATUS_GOOD = 2, BATT_STATUS_OK = 3, BATT_STATUS_LOW = 4, BATT_STATUS_CRITICAL = 5
        // 6 is our own cleared/unknown sentinel (State.checkTimeout), not an ANT+ status

        if((battery == 4) || (battery == 5)) //LOW or CRITICAL
        {
            primaryColor = lowBatteryColor;
        }
        else if(battery == 0)
        {
            primaryColor = Graphics.COLOR_TRANSPARENT;
        }

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(x, y, bw, bh);
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(nx-1, ny+1, nx-1, ny + nh-1);

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.drawRectangle(nx, ny, nw, nh);
        dc.setColor(bgColor, Graphics.COLOR_TRANSPARENT);
        dc.drawLine(nx, ny+1, nx, ny + nh-1);

        dc.setColor(primaryColor, Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(x, y, (bw * (6 - battery) / 5), bh);
        if(battery == 3)
        {
            dc.fillRectangle(nx, ny, nw, nh);
        }
    }

    //---------------------------------
    //One dot per visible slot, sized and spaced off the screen width. At 260px
    //this reproduces the previous r=3 / 9px-spacing column exactly. With a
    //single slot there is nothing to page between, so the column is dropped.
    function drawDots(dc, primaryColor, i, cVis)
    {
        if (cVis < 2) {return;}

        var w = dc.getWidth();

        var r = w / 85;
        if (r < 2) {r = 2;}

        var x = w / 20;
        if (x < r + 1) {x = r + 1;}

        var step = r * 3;
        var yTop = (dc.getHeight() / 2) - ((step * (cVis - 1)) / 2);

        dc.setColor(primaryColor, ClrTrans);
        for (var j = 0; j < cVis; ++j)
        {
            var yDot = yTop + (step * j);
            dc.drawCircle(x, yDot, r);
            if (j == i) {dc.fillCircle(x, yDot, r);}
        }
    }

}
