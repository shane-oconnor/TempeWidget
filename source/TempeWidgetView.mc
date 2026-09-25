import Toybox.Graphics;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.System;
import Toybox.SensorHistory;
import Toybox.Time;


class TempeWidgetView extends WatchUi.View {

    var state;

    var screenNum = 0; //index into State.rgVisible(), not a slot number

    //Vector fonts are requested by pixel height, so the hero font is cached by
    //the size it was made at. Null where the device has no vector fonts.
    var rgHero as Lang.Dictionary<Lang.Number, Graphics.FontType> = {};

    //The watch sensor's last six hours, filled by histSamples() for the
    //internal page. A null sample is a gap in the record.
    var rgHist as Lang.Array<Lang.Float?> = [];
    var histMin as Lang.Float? = null;
    var histMax as Lang.Float? = null;

    //Nothing in this view is a fixed pixel value. Every metric is derived from
    //dc.getWidth()/getHeight() and the device's own font heights, so the same
    //code lays out on a 176px Instinct and a 466px fenix 9 Pro 51mm.
    //
    //One page per visible sensor:
    //
    //        Tempe1  #25367         label in the temperature's colour, ANT id muted
    //          21.7 °C              the reading, as large as the screen allows
    //     v 18.2       ^ 24.6       the Tempe's 24 hour low and high
    //     |-------o---------|       where now sits between them
    //     12 min ago   [|||  ]      age of the reading, Tempe battery
    //
    //The internal sensor has no 24 hour pair; it gets the watch's own 6 hour
    //history drawn as a line instead, with the low and high of that window.

    function initialize() {
        View.initialize();
        state = new State();
    }

    function onLayout(dc as Dc) as Void {
    }

    function onShow() as Void {
    }

    //---------------------------------
    function onUpdate(dc as Dc) as Void {
        View.onUpdate(dc);

        var fWhite  = state.fWhiteBG;
        var clrBack = fWhite ? ClrWhite : ClrBlack;
        var clrFore = fWhite ? ClrBlack : ClrWhite;
        var clrDim  = fWhite ? ClrDkGray : ClrLtGray;

        //screenNum indexes the visible list, not the slot array. That list can
        //shrink under us - a Tempe times out, or the settings change in the
        //Connect app - so clamp it every draw. With nothing visible at all,
        //slot 0 draws as "--" under a searching note.
        var rgVis = state.rgVisible() as Lang.Array<Lang.Number>;
        var cVis = rgVis.size();
        if (screenNum >= cVis) {screenNum = 0;}
        var i = (cVis > 0) ? rgVis[screenNum] : 0;
        var item = rgTemp[i];
        var fSearch = (cVis == 0);

        dc.setColor(clrFore, clrBack);
        dc.clear();

        var w = dc.getWidth();
        var h = dc.getHeight();
        var xC = w / 2;

        //--- what this page has to say ------------------------------------
        var fTempe    = (item.id >= 0);   //an ANT Tempe, specific or discovered
        var fInternal = (item.id == -1);
        var idNow = item.getID();

        var tAdj = item.tempAdj();
        var strLbl  = item.lbl;
        var strID   = (fTempe && (idNow != null) && (idNow > 0)) ? "#" + idNow : null;
        var strHero = strTempGlance(tAdj);
        var strUnit = strUnit();
        var strNote = fSearch ? "searching..." : null;

        //Low and high: the Tempe's own 24h pair, or the watch's 6h history.
        var tMin = item.minAdj();
        var tMax = item.maxAdj();
        var fHist = fInternal && histSamples();
        if (fHist)
        {
            tMin = item.adj(histMin);
            tMax = item.adj(histMax);
        }
        var fRange = (tMin != null) && (tMax != null);
        var strMin = fRange ? strTempGlance(tMin) : null;
        var strMax = fRange ? strTempGlance(tMax) : null;

        var strAge = fSearch ? null : strAge(item.tmLast);
        var batteryStatus = strBatt(item.batStatus);
        var fShowBatt = state.fBtry && fTempe && (batteryStatus != 0);

        //--- colours ------------------------------------------------------
        //Past 50% of the timeout the reading is on its way out. Dim the values
        //and the battery - they are the stale part - but leave the label at
        //full contrast, since which slot you are looking at has not gone stale.
        var fStale = item.fExpiring();
        var clrVal = fStale ? ClrDkGray : clrFore;
        var clrAcc = fStale ? clrDim : clrForTemp(tAdj, fWhite);

        //--- fonts --------------------------------------------------------
        //82% keeps centred text clear of the bezel on round screens
        var maxW = w * 82 / 100;
        var ladder = [Graphics.FONT_MEDIUM, Graphics.FONT_SMALL,
                      Graphics.FONT_TINY, Graphics.FONT_XTINY];

        var fLbl  = fitFont(dc, [strLbl], maxW * 7 / 10, 0, ladder);
        var fSub  = Graphics.FONT_XTINY;
        var fUnit = fitFont(dc, [strUnit], w / 6, 0, ladder);
        var fMM   = fitFont(dc, [strMin, strMax], w * 32 / 100, 0, ladder);

        var wUnit = dc.getTextWidthInPixels(strUnit, fUnit);
        var padUnit = w / 60;
        var fHero = heroFont(dc, strHero, maxW - wUnit - padUnit, h * 30 / 100);

        var hLbl  = dc.getFontHeight(fLbl);
        var hSub  = dc.getFontHeight(fSub);
        var hHero = dc.getFontHeight(fHero);
        var hMM   = dc.getFontHeight(fMM);
        var gap   = h / 40;

        //--- geometry of the non-text rows ---------------------------------
        var rMark = w / 45;              //range bar marker
        if (rMark < 4) {rMark = 4;}
        var hBar  = (rMark * 2) + 2;     //room for the marker over the track
        var hChart = h * 20 / 100;
        var battW = w * 11 / 100;
        var battH = battW / 2;
        var arrow = hMM / 3;             //the little up/down triangles
        if (arrow < 4) {arrow = 4;}

        //--- centre the whole stack vertically ----------------------------
        var total = hLbl + gap + hHero;
        if (strID != null)  {total += hSub;}
        if (strNote != null){total += gap + hSub;}
        if (fRange)         {total += gap + hMM;}
        if (fRange && fTempe) {total += gap + hBar;}
        if (fHist)          {total += gap + hChart;}
        if ((strAge != null) || fShowBatt) {total += gap + ((battH > hSub) ? battH : hSub);}

        var y = (h - total) / 2;
        if (y < 0) {y = 0;}

        //--- label and id -------------------------------------------------
        dc.setColor(clrAcc, ClrTrans);
        dc.drawText(xC, y, fLbl, strLbl, Graphics.TEXT_JUSTIFY_CENTER);
        y += hLbl;

        if (strID != null)
        {
            dc.setColor(clrDim, ClrTrans);
            dc.drawText(xC, y, fSub, strID, Graphics.TEXT_JUSTIFY_CENTER);
            y += hSub;
        }
        y += gap;

        //--- the reading --------------------------------------------------
        //Number and unit are drawn separately: the number can use a font that
        //has no degree sign, and the unit sits small at the number's shoulder.
        var wNum = dc.getTextWidthInPixels(strHero, fHero);
        var x0 = xC - ((wNum + padUnit + wUnit) / 2);
        dc.setColor(clrVal, ClrTrans);
        dc.drawText(x0, y, fHero, strHero, Graphics.TEXT_JUSTIFY_LEFT);
        dc.setColor(clrDim, ClrTrans);
        dc.drawText(x0 + wNum + padUnit, y + (hHero / 8), fUnit, strUnit, Graphics.TEXT_JUSTIFY_LEFT);
        y += hHero;

        if (strNote != null)
        {
            y += gap;
            dc.setColor(clrDim, ClrTrans);
            dc.drawText(xC, y, fSub, strNote, Graphics.TEXT_JUSTIFY_CENTER);
            y += hSub;
        }

        //--- low and high -------------------------------------------------
        if (fRange)
        {
            y += gap;
            var xL = xC - (w * 18 / 100);
            var xR = xC + (w * 18 / 100);
            var yA = y + ((hMM - arrow) / 2);
            var wL = dc.getTextWidthInPixels(strMin, fMM);
            var wR = dc.getTextWidthInPixels(strMax, fMM);

            dc.setColor(clrVal, ClrTrans);
            dc.drawText(xL + (arrow / 2) + 2, y, fMM, strMin, Graphics.TEXT_JUSTIFY_CENTER);
            dc.drawText(xR + (arrow / 2) + 2, y, fMM, strMax, Graphics.TEXT_JUSTIFY_CENTER);

            dc.setColor(clrDim, ClrTrans);
            var xa = xL - (wL / 2) - (arrow / 2) - 2;
            dc.fillPolygon([[xa - arrow / 2, yA], [xa + arrow / 2, yA], [xa, yA + arrow]]);
            xa = xR - (wR / 2) - (arrow / 2) - 2;
            dc.fillPolygon([[xa - arrow / 2, yA + arrow], [xa + arrow / 2, yA + arrow], [xa, yA]]);
            y += hMM;
        }

        //--- where now sits between them ----------------------------------
        if (fRange && fTempe)
        {
            y += gap;
            drawRange(dc, xC, y + (hBar / 2), w / 2, rMark, [tAdj, tMin, tMax], clrDim, clrAcc);
            y += hBar;
        }

        //--- six hour line for the watch sensor ----------------------------
        if (fHist)
        {
            y += gap;
            drawChart(dc, xC - (w * 30 / 100), y, w * 60 / 100, hChart, clrAcc, clrDim);
            y += hChart;
        }

        //--- footer: age and battery --------------------------------------
        if ((strAge != null) || fShowBatt)
        {
            y += gap;
            var hFoot = (battH > hSub) ? battH : hSub;
            if (fShowBatt)
            {
                if (strAge != null)
                {
                    dc.setColor(clrDim, ClrTrans);
                    dc.drawText(xC - (w * 12 / 100), y + ((hFoot - hSub) / 2), fSub, strAge, Graphics.TEXT_JUSTIFY_CENTER);
                }
                drawBattery(dc, batteryStatus, clrVal, Graphics.COLOR_DK_RED, clrBack,
                            xC + (w * 12 / 100), y + ((hFoot - battH) / 2), battW, battH);
            }
            else
            {
                dc.setColor(clrDim, ClrTrans);
                dc.drawText(xC, y + ((hFoot - hSub) / 2), fSub, strAge, Graphics.TEXT_JUSTIFY_CENTER);
            }
        }

        drawDots(dc, clrFore, screenNum, cVis);

        if (state.fDbg)
        {
            System.println("onUpdate slot " + i + " id " + idNow + " battery " + batteryStatus);
        }
    }

    function onHide() as Void {
    }

    //---------------------------------
    //The largest font the reading fits in. Devices with vector fonts get one
    //sized to the screen and shrunk until the string fits maxW; the rest walk
    //the number-font ladder, which is the biggest text they have.
    function heroFont(dc, str, maxW, hWant)
    {
        if (Graphics has :getVectorFont)
        {
            var size = hWant;
            for (var n = 0; n < 4; ++n)
            {
                var f = rgHero.get(size);
                if (f == null)
                {
                    f = Graphics.getVectorFont({:face => ["RobotoCondensedBold", "RobotoRegular"], :size => size});
                    if (f == null) {break;} //no such face: use the ladder
                    rgHero.put(size, f);
                }
                var wStr = dc.getTextWidthInPixels(str, f);
                if (wStr <= maxW) {return(f);}
                size = size * maxW / wStr; //shrink in proportion and try again
            }
        }
        return(fitFont(dc, [str], maxW, hWant * 12 / 10,
                       [Graphics.FONT_NUMBER_THAI_HOT, Graphics.FONT_NUMBER_HOT,
                        Graphics.FONT_NUMBER_MEDIUM, Graphics.FONT_NUMBER_MILD,
                        Graphics.FONT_LARGE, Graphics.FONT_MEDIUM, Graphics.FONT_SMALL]));
    }

    //---------------------------------
    //The watch's own temperature history for the last six hours, oldest first,
    //into rgHist/histMin/histMax. True when there is a line worth drawing.
    function histSamples()
    {
        rgHist = [] as Lang.Array<Lang.Float?>;
        histMin = null;
        histMax = null;
        if (!((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory))) {return(false);}

        var it = SensorHistory.getTemperatureHistory({:period => new Time.Duration(6 * 3600),
                                                      :order => SensorHistory.ORDER_OLDEST_FIRST});
        if (it != null)
        {
            var sample = it.next();
            while (sample != null)
            {
                var v = sample.data;
                rgHist.add(v);
                if (v != null)
                {
                    if ((histMin == null) || (v < histMin)) {histMin = v;}
                    if ((histMax == null) || (v > histMax)) {histMax = v;}
                }
                sample = it.next();
            }
        }
        return((rgHist.size() >= 2) && (histMin != null));
    }

    //---------------------------------
    //A thin track from low to high with a dot where the current reading sits.
    //Both ends carry a tick so the track reads as a range and not a rule.
    function drawRange(dc, xC, yMid, wBar, r, rgT as Lang.Array<Lang.Float?>, clrTrack, clrMark)
    {
        var t = rgT[0];
        var tMin = rgT[1];
        var tMax = rgT[2];
        var x0 = xC - (wBar / 2);
        var hTrack = r / 2;
        if (hTrack < 2) {hTrack = 2;}

        dc.setColor(clrTrack, ClrTrans);
        dc.fillRoundedRectangle(x0, yMid - (hTrack / 2), wBar, hTrack, hTrack / 2);
        dc.fillRectangle(x0, yMid - r, hTrack, r * 2);
        dc.fillRectangle(x0 + wBar - hTrack, yMid - r, hTrack, r * 2);

        if (t == null) {return;}
        var pos = 0.5;
        if (tMax > tMin) {pos = (t - tMin) / (tMax - tMin);}
        if (pos < 0) {pos = 0;}
        if (pos > 1) {pos = 1;}
        var xm = x0 + (wBar * pos).toNumber();

        dc.setColor(clrMark, ClrTrans);
        dc.fillCircle(xm, yMid, r);
    }

    //---------------------------------
    //Six hours of the watch sensor as a line, scaled to its own low and high.
    function drawChart(dc, x, y, cw, ch, clrLine, clrAxis)
    {
        var rg = rgHist;
        var n = rg.size();
        var vMin = histMin;
        var vMax = histMax;
        if ((vMin == null) || (vMax == null) || (n < 2)) {return;}
        var span = vMax - vMin;
        if (span < 1.0) {span = 1.0;} //a flat line sits mid-chart, not on the axis

        dc.setColor(clrAxis, ClrTrans);
        dc.drawLine(x, y + ch, x + cw, y + ch);

        if (dc has :setAntiAlias) {dc.setAntiAlias(true);}
        var pen = cw / 120;
        if (pen < 2) {pen = 2;}
        dc.setPenWidth(pen);
        dc.setColor(clrLine, ClrTrans);

        var xPrev = null;
        var yPrev = null;
        for (var k = 0; k < n; ++k)
        {
            var v = rg[k];
            if (v == null) {xPrev = null; continue;}
            var xk = x + ((cw * k) / (n - 1));
            var yk = y + ch - (((v - vMin) / span) * (ch - pen)).toNumber() - (pen / 2);
            if (xPrev != null) {dc.drawLine(xPrev, yPrev, xk, yk);}
            xPrev = xk;
            yPrev = yk;
        }
        dc.setPenWidth(1);
        if (dc has :setAntiAlias) {dc.setAntiAlias(false);}
    }

    //---------------------------------
    //xMid is the centre the icon should sit on; the terminal nub is included
    //in the centring so the whole shape reads as centred.
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
    //One dot per visible page, sized and spaced off the screen width. With a
    //single page there is nothing to page between, so the column is dropped.
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
