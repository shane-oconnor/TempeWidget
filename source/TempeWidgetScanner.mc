import Toybox.System;
import Toybox.Ant;
import Toybox.Lang;
import Toybox.Time;

//Finds every Tempe in range without pairing to any of them.
//
//A normal receive channel searches until one sensor answers and then tracks
//that one sensor. Two wildcard slots therefore race for the same Tempe, and
//nothing stops both from winning it. A receive-only channel with background
//scanning switched on never leaves search: it keeps handing over every
//broadcast it hears, and each broadcast carries the sensor's own device number.
//That is all this class does - hear device numbers and report each new one to
//State, which assigns it to a slot and opens a normal channel to it. The data
//itself is still parsed by TempeWidgetSensor on that slot's channel, so the
//battery page request and the page 1 decoding are unchanged.
(:glance)
class TempeScanner
{
    var antChannel;  //Ant.GenericChannel
    var chanAssign;
    var deviceCfg;
    var state;       //told about each device number the first time it is heard
    var fDbg = false;

    //---------------------------------
    function initialize(stateIn, fDbgIn)
    {
        state = stateIn;
        fDbg = fDbgIn;

        chanAssign = new Ant.ChannelAssignment(Ant.CHANNEL_TYPE_RX_ONLY, Ant.NETWORK_PLUS);
        chanAssign.setBackgroundScan(true);
        antChannel = new Ant.GenericChannel(method(:onMessage), chanAssign);

        //Same radio parameters as TempeWidgetSensor, wildcard device number.
        deviceCfg = new Ant.DeviceConfig( {
            :deviceNumber => 0,
            :deviceType => 25,                 //ANT+ environment profile
            :transmissionType => 0,
            :messagePeriod => 65535,
            :radioFrequency => 57,
            :searchTimeoutLowPriority => 12,   //30s, the most Connect IQ allows
            :searchTimeoutHighPriority => 0,
            :searchThreshold => 0} );
        antChannel.setDeviceConfig(deviceCfg);

        open();
    }

    //---------------------------------
    function open()
    {
        if (fDbg) {System.println(strTimeOfDay(true) + " scanner open");}
        antChannel.open();
    }

    //---------------------------------
    function release()
    {
        antChannel.release(); //closes as well
    }

    //---------------------------------
    function onMessage(msg as Ant.Message) as Void
    {
        if (Ant.MSG_ID_BROADCAST_DATA == msg.messageId)
        {
            var id = msg.deviceNumber;
            if ((id != null) && (id != 0))
            {
                state.onTempeSeen(id, msg.rssi);
            }
        }
        else if (Ant.MSG_ID_CHANNEL_RESPONSE_EVENT == msg.messageId)
        {
            var payload = msg.getPayload();
            if (Ant.MSG_ID_RF_EVENT == (payload[0] & 0xFF))
            {
                //The search timeout closes the channel every 30s; a scan that
                //has stopped hears nothing, so open it again.
                if (Ant.MSG_CODE_EVENT_CHANNEL_CLOSED == (payload[1] & 0xFF))
                {
                    open();
                }
            }
        }
    }
}
