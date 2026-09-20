import Toybox.Application;
import Toybox.Lang;
import Toybox.WatchUi;


class TempeWidgetApp extends Application.AppBase {

    var mainView as TempeWidgetView? = null;

    function initialize() {
        AppBase.initialize();
    }

    // onStart() is called on application start up
    function onStart(state as Dictionary?) as Void {
    }

    // onStop() is called when your application is exiting
    function onStop(state as Dictionary?) as Void {
    }

    // Settings pushed from the phone arrive here while the widget is running.
    // Re-reading them is what makes a label, offset, device ID or the slot
    // count take effect without a relaunch; State.updateSettings() closes and
    // reopens the ANT channels, so a changed device ID is picked up too.
    function onSettingsChanged() as Void {
        if (mainView != null) {
            mainView.state.updateSettings();
        }
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