import Toybox.Application;
import Toybox.System;
import Toybox.Lang;
import Toybox.Time;


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