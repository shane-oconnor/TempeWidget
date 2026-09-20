import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;
import Toybox.Graphics;


const ClrTrans = -1;//Graphics.COLOR_TRANSPARENT;
const ClrLtGray = 0xAAAAAA;//Graphics.COLOR_LT_GRAY;
const ClrWhite = 0xFFFFFF;//Graphics.COLOR_WHITE;
const ClrBlack = 0x000000;//Graphics.COLOR_BLACK;
const ClrDkGray = 0x555555;//Graphics.COLOR_DK_GRAY;
const ClrYellow = 0xFFAA00; //Graphics.COLOR_YELLOW;


enum {F0, F1, F2, F3, F4,FN0, FN1, FN2, FN3, FX1, FX2}

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