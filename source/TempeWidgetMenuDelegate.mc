import Toybox.WatchUi;
import Toybox.Lang;
import Toybox.Application;
import Toybox.System;

//The on-device menu, reached with the menu button or a long press. It covers
//the few things worth doing without the phone: starting the Tempe search over,
//seeing which sensor is which, and the two display toggles. Everything writes
//the same properties the Connect app does and then re-reads them through
//State.updateSettings(), so there is one code path for a setting either way.

//---------------------------------
function buildMainMenu(state)
{
    var menu = new WatchUi.Menu2({:title => "TempeWidget " + WatchUi.loadResource(Rez.Strings.Version)});
    menu.addItem(new WatchUi.MenuItem("Sensors", "which is which", :sensors, null));
    menu.addItem(new WatchUi.MenuItem("Forget Tempes", "search again", :rescan, null));
    menu.addItem(new WatchUi.ToggleMenuItem("Show battery", null, :btry, state.fBtry, null));
    menu.addItem(new WatchUi.ToggleMenuItem("White background", null, :whitebg, state.fWhiteBG, null));
    return(menu);
}

//---------------------------------
//One line per slot with the sensor it is bound to, then any Tempe the scanner
//has heard that no slot has taken - which is how a third sensor shows up when
//every slot is already spoken for.
function buildSensorsMenu(state)
{
    var menu = new WatchUi.Menu2({:title => "Sensors"});
    var rgUsed = [] as Lang.Array<Lang.Number>;
    for (var i = 0; i < cTempItem; ++i)
    {
        var item = rgTemp[i];
        var idNow = item.getID();
        var sub;
        if (item.id == -1)      {sub = "watch sensor";}
        else if (item.id == -2) {sub = "paired Tempe";}
        else if (idNow == null) {sub = "searching...";}
        else
        {
            sub = "#" + idNow + "  " + strAge(item.tmLast);
            rgUsed.add(idNow);
        }
        menu.addItem(new WatchUi.MenuItem(item.lbl, sub, i, null));
    }

    var rgSeen = state.rgSeen as Lang.Dictionary<Lang.Number, Lang.Array<Lang.Number?>>;
    var rgKeys = rgSeen.keys() as Lang.Array<Lang.Number>;
    for (var k = 0; k < rgKeys.size(); ++k)
    {
        var id = rgKeys[k];
        if (rgUsed.indexOf(id) >= 0) {continue;}
        var seen = rgSeen[id] as Lang.Array<Lang.Number?>;
        var sub = "heard " + strAge(seen[0]);
        if (seen[1] != null) {sub += "  " + seen[1] + " dBm";}
        menu.addItem(new WatchUi.MenuItem("Tempe #" + id, sub, id, null));
    }
    return(menu);
}

//---------------------------------
class TempeWidgetMenuDelegate extends WatchUi.Menu2InputDelegate
{
    var state;

    function initialize(stateIn)
    {
        Menu2InputDelegate.initialize();
        state = stateIn;
    }

    //---------------------------------
    function onSelect(item as WatchUi.MenuItem) as Void
    {
        var id = item.getId();
        if (id == :sensors)
        {
            WatchUi.pushView(buildSensorsMenu(state), new TempeWidgetSensorsDelegate(), WatchUi.SLIDE_LEFT);
        }
        else if (id == :rescan)
        {
            //Only the Tempe slots go back to "find one"; the watch sensor and
            //a paired Tempe are not something the scanner can find.
            for (var i = 0; i < cTempItem; ++i)
            {
                if (rgTemp[i].id > 0) {setProp("T" + i + "ID", 0);}
            }
            state.updateSettings();
            WatchUi.popView(WatchUi.SLIDE_DOWN);
        }
        else if (id == :btry)
        {
            setProp("Btry", (item as WatchUi.ToggleMenuItem).isEnabled());
            state.updateSettings();
        }
        else if (id == :whitebg)
        {
            setProp("WhiteBG", (item as WatchUi.ToggleMenuItem).isEnabled());
            state.updateSettings();
        }
    }

    //---------------------------------
    function setProp(key, val)
    {
        try
        {
            Application.Properties.setValue(key, val);
        } catch (ex)
        {
            System.println("Properties.setValue(" + key + "): " + ex.getErrorMessage());
        }
    }
}

//---------------------------------
//The sensors list is read-only: selecting a line just closes it.
class TempeWidgetSensorsDelegate extends WatchUi.Menu2InputDelegate
{
    function initialize()
    {
        Menu2InputDelegate.initialize();
    }

    function onSelect(item as WatchUi.MenuItem) as Void
    {
        WatchUi.popView(WatchUi.SLIDE_RIGHT);
    }
}
