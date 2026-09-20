import Toybox.Lang;
import Toybox.WatchUi;

class TempeWidgetDelegate extends WatchUi.BehaviorDelegate {

    var mainView = 0;

    function initialize(view) 
    {
        mainView = view;
        BehaviorDelegate.initialize();
        //("Glance: Delegate - Init");
    }
    //---------------------------------
    function onBack()
    {
        //The guard is deliberate. Devices whose API marks System.exit() as
        //no-return reject a bare "return" after it as unreachable; older
        //widget-era devices reject its absence as "not all paths return a
        //value". mainView is always set, so this satisfies both checkers.
        if (mainView != null) {System.exit();} //fixed a bug on some device
        return(false);
    }
    //---------------------------------
    function onSwipe(swipeEvent)
    {
        var dir = swipeEvent.getDirection();
        switch (dir)
        {
        case WatchUi.SWIPE_UP:
            return nextScreen();
        case WatchUi.SWIPE_DOWN:
            return priorScreen();
        case WatchUi.SWIPE_RIGHT:
            System.exit();
        default:
            break;
        }
        return(false);
    }

    function onNextPage() {
        return nextScreen();
    }

    function onPreviousPage() {
        return priorScreen();
    }

    function onSelect() {
        return nextScreen();
    }

    function onMenu() {
        //WatchUi.pushView(new Rez.Menus.MainMenu(), new TempeWidgetMenuDelegate(), WatchUi.SLIDE_UP);
        return true;
    }
    function nextScreen() 
    {

        if(mainView.screenNum < (cTempItem - 1)){
            mainView.screenNum++;
        }else{
            mainView.screenNum = 0;
        }


        //mainView.screenNum = mainView.screenNum == 0 ? 1 : 0;
        WatchUi.requestUpdate();
        return true;
    }

    function priorScreen() 
    {
        //System.println("Pre if screenNum : " + mainView.screenNum);
        if(mainView.screenNum <= 0){
            mainView.screenNum = (cTempItem-1);
            //System.println("post - 1screenNum : " + mainView.screenNum);
        }else{
            mainView.screenNum--;
            //System.println("post -- : " + mainView.screenNum);
        }


        //mainView.screenNum = mainView.screenNum == 0 ? 1 : 0;
        WatchUi.requestUpdate();
        return true;
    }


}