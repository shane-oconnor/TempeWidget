import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;


class TempeWidgetApp extends Application.AppBase {

    var mainView = null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Return the initial view of your application here
    function getInitialView() as [Views] or [Views, InputDelegates] {

        mainView = new TempeWidgetView();

        return [ mainView, new TempeWidgetDelegate(mainView) ];
    }

    (:glance) function getGlanceView() as [GlanceView] or [GlanceView, GlanceViewDelegate] or Null {
        return [new TempeWidgetGlanceView()];
    }

}

function getApp() as TempeWidgetApp {
    return Application.getApp() as TempeWidgetApp;
}