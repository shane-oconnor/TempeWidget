import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Graphics;
import Toybox.SensorHistory;


const ClrTrans = -1;//Graphics.COLOR_TRANSPARENT;
const ClrLtGray = 0xAAAAAA;//Graphics.COLOR_LT_GRAY;
const ClrWhite = 0xFFFFFF;//Graphics.COLOR_WHITE;
const ClrBlack = 0x000000;//Graphics.COLOR_BLACK;
const ClrDkGray = 0x555555;//Graphics.COLOR_DK_GRAY;
const ClrYellow = 0xFFAA00; //Graphics.COLOR_YELLOW;

//Accent by temperature band, one set for a black background and one for white.
//Only the label and the range marker take the accent; the reading itself stays
//at full contrast so the number is never harder to read for being warm.
const ClrCold  = 0x55AAFF; const ClrColdW  = 0x0055AA; //at or below 0
const ClrCool  = 0x00CCFF; const ClrCoolW  = 0x0088AA; //0 to 10
const ClrMild  = 0x55DD99; const ClrMildW  = 0x008855; //10 to 20
const ClrWarm  = 0xFFAA00; const ClrWarmW  = 0xAA5500; //20 to 28
const ClrHot   = 0xFF5544; const ClrHotW   = 0xAA0000; //above 28


//---------------------------------
//outside of a class
(:glance)
function getProp(key,valDef)
{
    var val = Application.Properties.getValue(key);
    //System.println(Lang.format("loadVal($1$,$2$)=$3$",[key,valDef,val]));
    return((val == null) ? valDef : val); 
}

//---------------------------------
//Largest font from ladder (ordered largest first) that renders every non-null
//string within maxW, and whose line height is within maxH. Pass maxH = 0 when
//only the width matters. Falls back to the smallest font in the ladder.
//Shared: both views size themselves off the device's own font metrics rather
//than any fixed pixel value.
(:glance)
function fitFont(dc as Graphics.Dc, strs as Lang.Array<Lang.String?>,
                 maxW as Lang.Number, maxH as Lang.Number,
                 ladder as Lang.Array<Graphics.FontDefinition>)
                 as Graphics.FontDefinition
{
    for (var j = 0; j < ladder.size(); ++j)
    {
        if ((maxH > 0) && (dc.getFontHeight(ladder[j]) > maxH)) {continue;}

        var fFits = true;
        for (var k = 0; k < strs.size(); ++k)
        {
            if ((strs[k] != null) && (dc.getTextWidthInPixels(strs[k], ladder[j]) > maxW))
            {
                fFits = false;
            }
        }
        if (fFits) {return(ladder[j]);}
    }
    return(ladder[ladder.size()-1]);
}

//---------------------------------
//Trim a string until it renders within maxW at the given font. fitFont falls
//back to the smallest font in its ladder, so on a narrow column a long label
//can still overflow -- clipping the caption beats letting neighbouring columns
//run into each other.
(:glance)
function fitStr(dc as Graphics.Dc, str as Lang.String,
                font as Graphics.FontDefinition, maxW as Lang.Number)
{
    var out = str;
    while ((out.length() > 1) && (dc.getTextWidthInPixels(out, font) > maxW))
    {
        out = out.substring(0, out.length() - 1);
    }
    return(out);
}

//---------------------------------
//Bands are in °C whatever the display unit, so an offset-adjusted reading is
//what gets passed in. Null (no reading) takes the muted caption colour.
function clrForTemp(temp, fWhiteBG)
{
    if (temp == null) {return(fWhiteBG ? ClrDkGray : ClrLtGray);}
    if (temp <= 0)    {return(fWhiteBG ? ClrColdW  : ClrCold);}
    if (temp < 10)    {return(fWhiteBG ? ClrCoolW  : ClrCool);}
    if (temp < 20)    {return(fWhiteBG ? ClrMildW  : ClrMild);}
    if (temp < 28)    {return(fWhiteBG ? ClrWarmW  : ClrWarm);}
    return(fWhiteBG ? ClrHotW : ClrHot);
}

//---------------------------------
//How long ago a reading arrived, for the full view's footer (issue #17).
function strAge(tm)
{
    if (tm == null) {return("--");}
    var d = Time.now().value() - tm;
    if (d < 60)   {return("just now");}
    if (d < 3600) {return((d / 60).toString() + " min ago");}
    return((d / 3600).toString() + " h ago");
}

//---------------------------------
function strUnit()
{
    return((System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC) ? "°C" : "°F");
}

//---------------------------------
//The low and high of the watch's own temperature record over the last six
//hours, for a slot that has no 24 hour pair from a Tempe. The iterator keeps
//these itself, so nothing is walked. Null where there is no history.
(:glance)
function histMinMax() as Lang.Array<Lang.Float>?
{
    if (!((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory))) {return(null);}
    var it = SensorHistory.getTemperatureHistory({:period => new Time.Duration(6 * 3600)});
    if (it != null)
    {
        var vMin = it.getMin();
        var vMax = it.getMax();
        if ((vMin != null) && (vMax != null)) {return([vMin, vMax]);}
    }
    return(null);
}

(:glance)
function numStr(num)
{
    if (num == null) {return("--");}
    return(num.format("%.0f"));
}

(:glance)
function durStr(tm)
{
    if (tm == null) {return("--");}
    return((Time.now().value() - tm).toString()); //tm is epoch seconds
}

(:glance)
function strTimeOfDay(fLong){return(strTime(System.getClockTime(),fLong));}

(:glance)
function strTime(clockTime,fLong)
{    
    var hour, min;

    hour = clockTime.hour % 12;
    hour = (hour == 0) ? 12 : hour;
    min = clockTime.min;

    var str = Lang.format("$1$:$2$",[hour, min.format("%02d")]);

    if (fLong)
    {
        //var ampm = (clockTime.hour < 12) ? "a" : "p";
        str = str + Lang.format(":$1$",[clockTime.sec.format("%02d")]);
    }
    return (str);
}

(:glance)
function strTemp(temp)
{
    var str = "";
    if (temp == null) {str += "--";}
    else
    {
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC)
        {
            str += temp.format("%.1f") + "°C";
        }
        else
        {
            str +=  (temp * 9.0 / 5.0 + 32).format("%.1f") + "°F";
        }       
    }
    return(str);
}     

(:glance)
function strTempGlance(temp)
{
    var str = "";
    if (temp == null) {str += "--";}
    else
    {
        if (System.getDeviceSettings().temperatureUnits == System.UNIT_METRIC)
        {
            str += temp.format("%.1f");
        }
        else
        {
            str +=  (temp * 9.0 / 5.0 + 32).format("%.1f");
        }       
    }
    return(str);
}       

(:glance)
function strBatt(temp)
{
    var str;
    //System.println("strBatt str : " + str);
    //System.println("strBatt temp : " + temp);

    if (temp == null ) {str = 0;}
    else {str = temp;}
        //System.println("strBatt str 2: " + str);

    return(str);
}     