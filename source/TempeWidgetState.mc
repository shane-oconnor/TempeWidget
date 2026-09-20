import Toybox.System;
import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;
import Toybox.Sensor;
import Toybox.SensorHistory;
import Toybox.Time;
import Toybox.Timer;

(:glance)const cTempItem = 3; 
(:glance)var rgTemp = new [cTempItem];

(:glance)
class State
{

    static var timeout; //in seconds
    var fDbg=true;
    var fBtry=true;
    var fWhiteBG=true;
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

        //System.println(dbgStr());
        checkTimeout(false);
        //System.println(dbgStr());
        
        timer.start(method(:onTimerTic),5000,true);
    }
    //---------------------------------
    function getTemp(i) {return(rgTemp[i].temp);}
    function getLbl(i) {return(rgTemp[i].lbl);}
    
    //---------------------------------
    function dbgStr()
    {
        //return( Lang.format("$1$, $2$, $3$", [rgTemp[0].toStr(),rgTemp[1].toStr(),rgTemp[2].toStr()]));
        //return( Lang.format("debStr $1$, $2$, $3$", [rgTemp[0].toStr(),rgTemp[0].toStr(),rgTemp[0].toStr()]));
        return( Lang.format("debStr $1$", [rgTemp[0].toStr()]));

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
    //-----------------------------------------------
    function clearCache(){checkTimeout(true);}
    //---------------------------------
    function onTimerTic() //every second
    {
        System.println(strTimeOfDay(true) + "onTimerTic Sensor");
        
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
                    for (var i = 0; i < cTempItem; ++i) {rgTemp[i].updateTemp(tempInt,-1);}          
                }
            }
        }
        
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].updateTempeTemp();}          
    
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
                for (var i = 0; i < cTempItem; ++i) {rgTemp[i].updateTemp(sinfo.temperature,-2);}          
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
        //fDbg=true;
        //System.println("timeout: " + timeout);
        rgTemp[0].updateSettings(0,"Tempe1",0.0);
        rgTemp[1].updateSettings(0,"Tempe2",0.0);
        rgTemp[2].updateSettings(-1,"Internal",0.0);
        
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].releaseTempe();}   //delete any Tempe objects   
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].initTempe(false);} //init all specified ID's    
        for (var i = 0; i < cTempItem; ++i) {rgTemp[i].initTempe(true);}  //init all Zero ID's
        

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
    var disable=false; //disable the Tempe screen property
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
    function updateSettings(defID, defLbl, defOff)
    {
        id = getProp("T"+i+"ID",defID);
        lbl = getProp("T"+i+"Label",defLbl);
        tos = getProp("T"+i+"Offset",defOff);
        System.println("Update Settings - : " + tos.toString());
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
    function getID()
    {
        if ((id == 0) && (tempe == null)) {return("ex");}
        return ((id == 0) ? tempe.antid : id);
    }
    //---------------------------------
    function releaseTempe()
    {
        if (tempe != null)
        {
            tempe.closeSensor();
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
                    tempe=new TempeWidgetSensor(id);  
                } catch (ex)
                {
                    System.println("Exception in TempeWidgetSensor(" + id + "): " + ex.getErrorMessage());
                    tempe = null;
                }
                    
            }
        }
    }
    //---------------------------------
    function checkTimeout(fClear,tmOut)
    {    
        //if (true)
        if (fClear || ((tmLast != null) && (tmLast < tmOut)))
        {
            tmLast = null;
            temp = null;
            tempMin = null;
            tempMax = null;
            //tempOffset = null;
            batStatus = 6;
            Application.Storage.setValue("Temp"+i,temp);
            Application.Storage.setValue("MinTemp"+i,tempMin);
            Application.Storage.setValue("MaxTemp"+i,tempMax);
            Application.Storage.setValue("tmTemp"+i,tmLast);
            Application.Storage.setValue("StatusBattery"+i, batStatus);
            //Application.Storage.setValue("OffsetTemp"+i, tempOffset);
        }
    }
    //---------------------------------
    function updateTempeTemp()
    {
        if ((tempe != null) && (tempe.tmTemp != null))
        {
            temp = tempe.iTemp;
            tempMin = tempe.minTemp;
            tempMax = tempe.maxTemp;
            tmLast = tempe.tmTemp;
            batStatus = tempe.batteryStatus;
            Application.Storage.setValue("Temp"+i,temp);
            Application.Storage.setValue("MinTemp"+i,tempMin);
            Application.Storage.setValue("MaxTemp"+i,tempMax);
            Application.Storage.setValue("tmTemp"+i,tmLast);
            Application.Storage.setValue("StatusBattery"+i, batStatus);
            //Application.Storage.setValue("OffsetTemp"+i, tempOffset);
            //System.println("UpdateTempeTemp: " + toStr());
            //System.println("UpdateTempeTemp: temp " + temp);
            //System.println("UpdateTempeTemp: tempMin " + (Application.Storage.getValue("MinTemp"+i)));
            //System.println("UpdateTempeTemp: tempMax " + tempMax);
            //System.println("UpdateTempeTemp: tmLast " + tmLast);
            //System.println("UpdateTempeTemp: batStatus " + batStatus);
            //System.println("UpdateTempeTemp: tempOffset " + tempOffset);
        }
    }
    //---------------------------------
    function updateTemp(tempIn,idSet)
    {
        if (id == idSet) //-1 or -2
        {
            if (tempIn != null)
            {
     
                temp = tempIn;
                tmLast = Time.now().value();
                Application.Storage.setValue("Temp"+i,temp);
                Application.Storage.setValue("tmTemp"+i,tmLast);
                Application.Storage.setValue("MinTemp"+i,null);
                Application.Storage.setValue("MaxTemp"+i,null);
                Application.Storage.setValue("StatusBattery"+i, null);
                //System.println("UpdateTemp: tempOffset " + tempOffset);
                System.println("UpdateTemp: temp " + temp);
            }
            //System.println("UpdateTemp: " + toStr());
        }
    }
}        
