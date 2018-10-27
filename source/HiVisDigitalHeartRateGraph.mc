using Toybox.WatchUi;
using Toybox.Application;
using Toybox.Graphics;
using Toybox.System;
using Toybox.Time;
using Toybox.Lang;
using Toybox.ActivityMonitor;

class HeartRateGraph extends WatchUi.Drawable {
    var lastfg;
    var lastbg;
    var lastupdate;
    var buffer;
    
    function initialize(dictionary) {
        dictionary.put(:identifier, "HeartRateGraph");
        Drawable.initialize(dictionary);
    }
    
    function update() {
        var app = Application.getApp();
        var now = Time.now();
        
        var fg = app.getProperty("HeartRateGraphColor");
        var bg = app.getProperty("BackgroundColor");
        
        if (buffer == null || fg != lastfg || bg != lastbg) {
            buffer = new Graphics.BufferedBitmap( {
                :width => width,
                :height => height,
                :palette => [
                    bg,
                    fg
                ]
            } );
            
            lastfg = fg;
            lastbg = bg;
        }
        else if (lastupdate != null && now.subtract(lastupdate).value() < 60) {
            return;
        }

        lastupdate = now;
        
        var dc = buffer.getDc();
        dc.setColor(fg, bg);
        dc.clear();
        dc.setPenWidth(2);
         
        // Border
        dc.drawLine(1, 0, 1, height - 1);
        dc.drawLine(0, height - 1, width - 1, height - 1);
        dc.drawLine(width - 1, height - 1, width - 1, 0);
         
        // Ticks
        dc.drawLine((width / 4) - 1, height - 1, (width / 4) - 1, height - 5 - 1);
        dc.drawLine((width / 2) - 1, height - 1, (width / 2) - 1, height - 5 - 1);
        dc.drawLine(width - (width / 4) - 1, height - 1, width - (width / 4) - 1, height - 5 - 1);

        // Graph data
        var hrIterator = ActivityMonitor.getHeartRateHistory(new Time.Duration(3600), false);
        
        var scaleX;
        var scaleY;
        
        scaleX = width / 3600.0;

        var min_hr = hrIterator.getMin();
        var max_hr = hrIterator.getMax();
        
        if (min_hr == 0 && max_hr == 0) {
            return;
        }

        if (min_hr == max_hr) {
            scaleY = min_hr;
        }
        else { 
            scaleY = (height - 7.0) / (max_hr - min_hr);
        }

        var sample = hrIterator.next();
        var pointX;
        var pointY;
        var lastPointX = null;
        var lastPointY = null;
        
        while (sample != null) {
            if (sample.heartRate == ActivityMonitor.INVALID_HR_SAMPLE) {
                lastPointX = null;
                lastPointY = null;
            }
            else {
                pointX = ((3600 - now.subtract(sample.when).value()) * scaleX);
                pointY = height - 7 - ((sample.heartRate - min_hr) * scaleY);

                if (lastPointX == null || lastPointY == null) {
                    dc.drawPoint(pointX, pointY);
                }
                else {
                    dc.drawLine(lastPointX, lastPointY, pointX, pointY);
                }
                
                lastPointX = pointX;
                lastPointY = pointY;
            }
            
            sample = hrIterator.next();
        }
    }

    function draw(dc) {
        update();
        dc.drawBitmap(locX, locY, buffer);
    }
}
