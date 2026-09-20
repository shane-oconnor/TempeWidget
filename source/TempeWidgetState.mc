import Toybox.System;
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.Timer;

(:glance)const cTempItem = 3; 
(:glance)var rgTemp as Lang.Array<TempItem?> = new [cTempItem];

(:glance)
class State
{

    static var timeout; //in seconds
    var fDbg=true;
    var fBtry=true;
    var fWhiteBG=true;
    var cTempe=cTempItem; //visible/polled slots, 1..cTempItem, from TempeCount
    var timer = new Timer.Timer();

    //-------------------------------------------
    function initialize()
    {
        //System.println("init: setEnableSensors");
        Sensor.setEnabledSensors([Sensor.SENSOR_TEMPERATURE]);
        Sensor.enableSensorEvents(method(:onSensorEvents));
        //Syastem.println("init: done setEnableSensors");

        for (var i = 0; i < cTempItem; ++i) {rgTemp[i] = new TempItem(i);}
        updateSettings(); //this actually initializes the tempe's

        checkTimeout(false);
        
        timer.start(method(:onTimerTic),5000,true);
    }
    //---------------------------------
    function checkTimeout(fClear)
    {
        var tmOut = Time.now().value() - timeout;
        for (var i = 0; i < cTempItem; ++i) 
        {
            rgTemp[i].checkTimeout(fClear,tmOut);
        }
    }
    //---------------------------------
    function onTimerTic() //every second
    {
        if (fDbg) {System.println(strTimeOfDay(true) + "onTimerTic Sensor");}
        
        checkTimeout(false);
        
        if ((Toybox has :SensorHistory) && (SensorHistory has :getTemperatureHistory))
        {        
            var tempIter = SensorHistory.getTemperatureHistory({:period => 1});
            if (tempIter != null)
            {
                var sample = tempIter.next();
                if ((sample != null) && (sample.data != null))
                {
                    var tempInt = sample.data;
                    //System.println("tempInt : " + tempInt);
                    for (var i = 0; i < cTempe; ++i) {rgTemp[i].updateTemp(tempInt,-1);}          
                }
            }
        }
        
        for (var i = 0; i < cTempe; ++i) {rgTemp[i].updateTempeTemp();}          
    
        WatchUi.requestUpdate();
    }

    //---------------------------------
    function done()
    {
        //("done: close sensor");
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].releaseTempe();}          
    }           
    
    //---------------------------------
    //this is for the paired tempe
    function onSensorEvents(sinfo as Sensor.Info) as Void //
    {
        if (sinfo != null)
        {
            if ((sinfo has :temperature) && (sinfo.temperature != null)) 
            {
                for (var i = 0; i < cTempe; ++i) {rgTemp[i].updateTemp(sinfo.temperature,-2);}          
                //System.println("paired temp: " + sinfo.temperature); //this hsould never be called
            }
        }
    }
    //-----------------------------------------------
    function updateSettings()
    {
        timeout = getProp("Timeout",1200); //seconds
        fDbg = getProp("Dbg",false);
        fBtry = getProp("Btry",true);
        fWhiteBG = getProp("WhiteBG",false); //white background

        //The settings menu already constrains this to 1-3, but a property can
        //also be pushed from the Connect API, so clamp rather than trust it.
        cTempe = getProp("TempeCount",cTempItem);
        if (cTempe < 1) {cTempe = 1;}
        if (cTempe > cTempItem) {cTempe = cTempItem;}

        //fDbg=true;
        //System.println("timeout: " + timeout);
        rgTemp[0].updateSettings(0,"Tempe1",0.0,fDbg);
        rgTemp[1].updateSettings(0,"Tempe2",0.0,fDbg);
        rgTemp[2].updateSettings(-1,"Internal",0.0,fDbg);
        
        //Release every slot, not just the active ones: a slot that has just
        //been switched off, or repointed at a different device ID, has to give
        //up its ANT channel before the new set is opened.
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].releaseTempe();}   //delete any Tempe objects   
        for (var i = 0; i < cTempe; ++i) {rgTemp[i].initTempe(false);} //init all specified ID's    
        for (var i = 0; i < cTempe; ++i) {rgTemp[i].initTempe(true);}  //init all Zero ID's
        

        WatchUi.requestUpdate();
    }
    
}





(:glance)
class TempItem
{
    var i; //0 - 2
    var id; //-1=internal, -2=paired, 0=any unpaired
    var lbl;
    var tos; // tempoffset when tempe not accurate
    var fDbg=false;
    var tmLast;  //time the last temperature was recorded, epoch seconds
    var temp;    //most recent temperature - null if none
    var tempe; //the tempe object, null if internal or paired
    var tempMin; //min temp on Tempe
    var tempMax; //max temp on Tempe
    var batStatus; // battery status on Tempe

    
    //---------------------------------
    function initialize(i_)
    {
        i = i_;
        //System.println("Testing i_ " + i_);             

        tmLast = Application.Storage.getValue("tmTemp"+i);
        temp = Application.Storage.getValue("Temp"+i);
        //System.println("TempItem initialize() tmLast " + tmLast);
        //System.println("TempItem initialize() Temp " + temp);

        tempMin = Application.Storage.getValue("MinTemp"+i);
        tempMax = Application.Storage.getValue("MaxTemp"+i);
        //System.println("TempItem initialize() TempMin " + tempMin);
        //System.println("TempItem initialize() TempMax " + tempMax);

        //Application.Storage.setValue("StatusBattery"+i, 6);
        batStatus = Application.Storage.getValue("StatusBattery"+i);
        //System.println("TempItem initialize() StatusBattery " + batStatus);

        //tempOffset = Application.Storage.getValue("OffsetTemp"+i);
        //System.println("initialise tempOffset : " + tempOffset);


    }

    //---------------------------------
    function updateSettings(defID, defLbl, defOff, fDbgIn)
    {
        fDbg = fDbgIn; //kept so the rest of the class can gate its own logging
        id = getProp("T"+i+"ID",defID);
        lbl = getProp("T"+i+"Label",defLbl);
        tos = getProp("T"+i+"Offset",defOff);
        if (fDbg) {System.println("Update Settings - : " + tos.toString());}
    }

    //---------------------------------
    //applies the configured offset; null in stays null out
    function adj(val)
    {
        if (val == null) {return(null);}
        if (tos == null) {return(val);}
        return(val + tos);
    }
    function tempAdj() {return(adj(temp));}
    function minAdj()  {return(adj(tempMin));}
    function maxAdj()  {return(adj(tempMax));}

    //---------------------------------
    function fExpiring()
    {
        if (tmLast == null) {return(false);} //it's expired!
        
        
        var pct = (Time.now().value() - tmLast).toFloat() / State.timeout;
        //System.println(Lang.format("$1$: tmOut %: $2$",[i,pct]));
        return(pct > 0.50);     
    }
        
    //---------------------------------
    function toStr()
    {
        return(Lang.format("$1$: $2$,$3$,$4$,$5$",[i,id,lbl,numStr(temp), durStr(tmLast)]));
    }
    //---------------------------------
    //The ANT device number this slot is actually using: the configured id, or
    //for a wildcard slot the one it discovered. Null means a wildcard slot that
    //has not found a sensor yet -- the caller decides how to show that, rather
    //than this returning a String in one state and a Number in the others.
    function getID()
    {
        if (id != 0) {return(id);}
        return((tempe == null) ? null : tempe.antid);
    }
    //---------------------------------
    function releaseTempe()
    {
        if (tempe != null)
        {
            //This now runs on every settings change, against a channel that is
            //very likely open and mid-transfer, not just at shutdown. initTempe
            //already guards its side; an uncaught throw here would take the
            //widget down while the user is only editing a label.
            try
            {
                tempe.closeSensor();
            } catch (ex)
            {
                //nothing useful to do: we are dropping the object regardless
            }
            tempe=null;
        }
    }
    //---------------------------------
    function initTempe(fIfZero)
    {
        if (id >= 0)
        {
            //this check allows us to first open all non-zero ID's first, so zero's don't find them first
            if (fIfZero == (id == 0))
            {
                try
                {
                    //tempe = null;
                    tempe=new TempeWidgetSensor(id,fDbg);  
                } catch (ex)
                {
                    System.println("Exception in TempeWidgetSensor(" + id + "): " + ex.getErrorMessage());
                    tempe = null;
                }
                    
            }
        }
    }
    //---------------------------------
    //Storage is flash, and this ran fifteen times every five seconds for as
    //long as the widget was open. The in-memory fields mirror exactly what was
    //last written, so passing the old field value in lets an unchanged key be
    //skipped. A sensor that is broadcasting nothing new now costs no writes.
    function put(key, val, valOld)
    {
        if (val != valOld) {Application.Storage.setValue(key+i, val);}
    }

    //---------------------------------
    function checkTimeout(fClear,tmOut)
    {    
        //if (true)
        if (fClear || ((tmLast != null) && (tmLast < tmOut)))
        {
            put("Temp",          null, temp);
            put("MinTemp",       null, tempMin);
            put("MaxTemp",       null, tempMax);
            put("tmTemp",        null, tmLast);
            put("StatusBattery", 6,    batStatus);

            tmLast = null;
            temp = null;
            tempMin = null;
            tempMax = null;
            batStatus = 6;
        }
    }
    //---------------------------------
    function updateTempeTemp()
    {
        if ((tempe != null) && (tempe.tmTemp != null))
        {
            put("Temp",          tempe.iTemp,         temp);
            put("MinTemp",       tempe.minTemp,       tempMin);
            put("MaxTemp",       tempe.maxTemp,       tempMax);
            put("tmTemp",        tempe.tmTemp,        tmLast);
            put("StatusBattery", tempe.batteryStatus, batStatus);

            temp = tempe.iTemp;
            tempMin = tempe.minTemp;
            tempMax = tempe.maxTemp;
            tmLast = tempe.tmTemp;
            batStatus = tempe.batteryStatus;
        }
    }
    //---------------------------------
    function updateTemp(tempIn,idSet)
    {
        if (id == idSet) //-1 or -2
        {
            if (tempIn != null)
            {
     
                var tmNow = Time.now().value();

                put("Temp",          tempIn, temp);
                put("tmTemp",        tmNow,  tmLast);
                //An internal or paired sensor has no ANT min/max or battery
                //page. These were already being cleared in storage; the fields
                //were not, so the view kept showing a battery reading that
                //storage said did not exist until the next launch.
                put("MinTemp",       null,   tempMin);
                put("MaxTemp",       null,   tempMax);
                put("StatusBattery", null,   batStatus);

                temp = tempIn;
                tmLast = tmNow;
                tempMin = null;
                tempMax = null;
                batStatus = null;

                if (fDbg) {System.println("UpdateTemp: temp " + temp);}
            }
            //System.println("UpdateTemp: " + toStr());
        }
    }
}        
