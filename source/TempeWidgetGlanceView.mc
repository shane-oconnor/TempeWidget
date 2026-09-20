import Toybox.Graphics;
import Toybox.WatchUi;


(:glance)
class TempeWidgetGlanceView extends WatchUi.GlanceView {

    var state;

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

    /* remove testing glanceView
    // Update the view
    function onUpdate(dc as Dc) as Void {
        // Call the parent onUpdate function to redraw the layout
        GlanceView.onUpdate(dc);
        dc.setColor(Graphics.COLOR_WHITE, -1);
        dc.drawText(10, 10, Graphics.FONT_SYSTEM_TINY, "Open Weather", Graphics.TEXT_JUSTIFY_LEFT | Graphics.TEXT_JUSTIFY_VCENTER);
        System.println("Glance onUpdate:  open weather");

    }
    */

    function onUpdate(dc as Dc) as Void {

        GlanceView.onUpdate(dc);

        var F0 = Graphics.FONT_XTINY;
        var F1 = Graphics.FONT_SMALL;
        dc.setColor(Graphics.COLOR_TRANSPARENT, Graphics.COLOR_BLACK);
        dc.clear();
        dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
        var centerXinc = dc.getWidth() / 3;
        var centerX = centerXinc / 2; 
        var centerY = dc.getHeight() / 2;
        var valueY = centerY - dc.getFontHeight(F1);
        var maxLoop = 1; // a maxloop 1, adds 2 x Tempe
        
        // have removed to loop from here, and set i =2 so picks up tempe
        //var i = 0;

        for (var i = 0; i < maxLoop; ++i) 
        {
            var rgtemp    = rgTemp[i].tempAdj();
            var rgtempMin = rgTemp[i].minAdj();
            var rgtempMax = rgTemp[i].maxAdj();

            dc.setColor(ClrWhite, ClrTrans);
            dc.drawText(centerX, valueY, F1, strTempGlance(rgtemp), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(ClrLtGray, ClrTrans);
            dc.drawText(centerX, centerY, F0, "Tempe"+ (i+1), Graphics.TEXT_JUSTIFY_CENTER);
        
            //System.println("TempWidgetView Glance temp " + strTempGlance(rgTemp[i].temp));
            //System.println("TempWidgetView Glance tos " + strTempGlance(rgTemp[i].tos));

            centerX += centerXinc;

            dc.setColor(ClrWhite, ClrTrans);
            dc.drawText(centerX, valueY, F1, strTempGlance(rgtempMin), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(ClrLtGray, ClrTrans);
            dc.drawText(centerX, centerY, F0, "Min", Graphics.TEXT_JUSTIFY_CENTER);
            //System.println("TempWidgetView Glance tempMin " + strTempGlance(rgtempMin));

            centerX += centerXinc;

            dc.setColor(ClrWhite, ClrTrans);
            dc.drawText(centerX, valueY, F1, strTempGlance(rgtempMax), Graphics.TEXT_JUSTIFY_CENTER);
            dc.setColor(ClrLtGray, ClrTrans);
            dc.drawText(centerX, centerY, F0, "Max", Graphics.TEXT_JUSTIFY_CENTER);
            //System.println("TempWidgetView Glance tempMax " + strTempGlance(rgtempMax));
        }
    }

    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() as Void {
    }

}
