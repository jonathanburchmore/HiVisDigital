using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;

class NotificationCount extends WatchUi.Drawable {
    var font;
    
    function initialize(dictionary) {
        dictionary.put(:identifier, "NotificationCount");
        Drawable.initialize(dictionary);
        
        font = WatchUi.loadResource(Rez.Fonts.id_suunto_font_25px);
    }

    function draw(dc) {
        var settings = System.getDeviceSettings();
        if (settings.notificationCount) {
             dc.setColor(Graphics.COLOR_RED, Graphics.COLOR_RED);
             dc.fillCircle(locX, locY, 14);
             dc.setColor(Graphics.COLOR_WHITE, Graphics.COLOR_TRANSPARENT);
             if (settings.notificationCount > 9) {
                 dc.drawText(locX, locY - 1, font, "+", Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
             }
             else {
                 dc.drawText(locX, locY - 1, font, settings.notificationCount.format("%d"), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER);
             }
        }
    }
}
