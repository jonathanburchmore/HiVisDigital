using Toybox.WatchUi;
using Toybox.Graphics;
using Toybox.Time;
using Toybox.Time.Gregorian;
using Toybox.System;
using Toybox.Lang;
using Toybox.Application;

class HiVisDigitalView extends WatchUi.WatchFace {
	var font_seconds;
	var font_hr;
	var lat;
	var lon;
	var since_last_hr;
	var last_hr;
	var last_suntimes;
	var today_sunrise;
	var today_sunset;
	var tomorrow_sunrise;
	var visible;
	
    function initialize() {
        WatchFace.initialize();
    
        font_seconds = WatchUi.loadResource(Rez.Fonts.id_suunto_font_40px);
        font_hr = WatchUi.loadResource(Rez.Fonts.id_suunto_font_25px);
		
		visible = true;
    }
    
    function updateLocation() {
		var app = Application.getApp();
		var activityinfo = Activity.getActivityInfo();
		
		var oldlat = lat;
		var oldlon = lon;

		if (activityinfo.currentLocation != null) {
            lat  = activityinfo.currentLocation.toDegrees()[0];
            lon = activityinfo.currentLocation.toDegrees()[1];
		}
		else {
            if (lat == null || lon == null) {
	            // try to get from object store
            	lat = app.getProperty("lat");
            	lon = app.getProperty("lon");
            }

            if (lat == null || lon == null) {
            	// fall back to Ramona's position
            	lat = 33.040615;
            	lon = -116.873421;
            }
        }
        
        if (lat != oldlat || lon != oldlon) {
        	last_suntimes = null;

            app.setProperty("lat", lat);
            app.setProperty("lon", lon);
        }
    }
    
    function updateSunTimes() {
    	updateLocation();

    	if (last_suntimes != null && last_suntimes == Time.today()) {
    		return;
    	}
    	
    	var noon = Time.today().add(new Time.Duration(Gregorian.SECONDS_PER_DAY / 2));
        var today_suntimes = SunMoon.sunriseSet(noon, lat, lon);
        var tomorrow_suntimes = SunMoon.sunriseSet(noon.add(new Time.Duration(Gregorian.SECONDS_PER_DAY)), lat, lon);
        
        today_sunrise = today_suntimes.get("sunrise");
        today_sunset = today_suntimes.get("sunset");
        tomorrow_sunrise = tomorrow_suntimes.get("sunset");

    	last_suntimes = Time.today();
    }
    
    function shortHour(hour) {
        if (!System.getDeviceSettings().is24Hour) {
            if (hour > 12) {
                hour = hour - 12;
            }
        }
        
        return hour;
    }

    // Load your resources here
    function onLayout(dc) {
        setLayout(Rez.Layouts.WatchFace(dc));
    }

    // Called when this View is brought to the foreground. Restore
    // the state of this View and prepare it to be shown. This includes
    // loading resources into memory.
    function onShow() {
		visible = true;
		requestUpdate();
    }

    // Update the view
    function onUpdate(dc) {
		if (!visible) {
			return;
		}
		
		var app = Application.getApp();
		
		// Get the current time and format it correctly
		var clockTime = System.getClockTime();
		var settings = System.getDeviceSettings();
		
		// Time
		var textMinutes = clockTime.min.format("%02d");
		var label_minutes = View.findDrawableById("Minutes");
		label_minutes.setColor(app.getProperty("MinutesColor"));
		label_minutes.setText(textMinutes);
		
		var label_hour = View.findDrawableById("Hour");
		label_hour.setColor(app.getProperty("HourColor"));
		label_hour.setText(shortHour(clockTime.hour).format("%d"));
		label_hour.setLocation(label_minutes.locX - dc.getTextWidthInPixels(textMinutes, WatchUi.loadResource(Rez.Fonts.id_suunto_font_130px)), label_minutes.locY);
		
		var label_seconds = View.findDrawableById("Seconds");
		label_seconds.setColor(app.getProperty("SecondsColor"));
		label_seconds.setText(clockTime.sec.format("%02d"));

		var date = Gregorian.info(Time.now(), Time.FORMAT_MEDIUM);
		var label_dayofweek = View.findDrawableById("DayOfWeek");
		label_dayofweek.setColor(app.getProperty("DayOfWeekColor"));
		label_dayofweek.setText(date.day_of_week);

		var label_dayofmonth = View.findDrawableById("DayOfMonth");
		label_dayofmonth.setColor(app.getProperty("DayOfMonthColor"));
		label_dayofmonth.setText(date.day.format("%d"));

		// Battery level        
        var stats = System.getSystemStats();
        var label_battery = View.findDrawableById("Battery");
        label_battery.setColor(app.getProperty("BatteryColor"));
        if (stats.charging) {
        	label_battery.setText("F");
        }
        else if (stats.battery > 75) {
        	label_battery.setText("G");
        }
        else if (stats.battery > 50) {
        	label_battery.setText("H");
        }
        else if (stats.battery > 25) {
        	label_battery.setText("I");
        }
        else {
        	label_battery.setText("J");
        }
        
        // Bluetooth status
        var label_bluetooth = View.findDrawableById("Bluetooth");
        label_bluetooth.setColor(app.getProperty("BluetoothColor"));
        if (settings.phoneConnected) {
        	label_bluetooth.setText("D");
        }
        else {
        	label_bluetooth.setText("E");
        }
        
        // Sunrise/Sunset
        updateSunTimes();

		var label_sun = View.findDrawableById("Sun");
		label_sun.setColor(app.getProperty("SunColor"));
		
		var now = Time.now();
		if (now.lessThan(today_sunrise)) {
			var sunrise = Gregorian.info(today_sunrise, Time.FORMAT_SHORT);
			label_sun.setText(Lang.format("( $1$:$2$", [shortHour(sunrise.hour), sunrise.min.format("%02d")]));
		}
		else if (now.lessThan(today_sunset)) { 
			var sunset = Gregorian.info(today_sunset, Time.FORMAT_SHORT);
			label_sun.setText(Lang.format(") $1$:$2$", [shortHour(sunset.hour), sunset.min.format("%02d")]));
		}
		else {
			var sunrise = Gregorian.info(tomorrow_sunrise, Time.FORMAT_SHORT);
			label_sun.setText(Lang.format("( $1$:$2$", [shortHour(sunrise.hour), sunrise.min.format("%02d")]));
		}
		
		// Heart rate
		var activityinfo = Activity.getActivityInfo();
		var label_hr = View.findDrawableById("HeartRate");
		label_hr.setColor(app.getProperty("HeartRateColor"));
		if (activityinfo.currentHeartRate == null) {
			label_hr.setText("");
		}
		else {
			label_hr.setText(Lang.format("* $1$", [activityinfo.currentHeartRate]));
		}
		
		since_last_hr = 0;
		last_hr = activityinfo.currentHeartRate;

		// Call the parent onUpdate function to redraw the layout
		dc.clearClip();
		View.onUpdate(dc);
    }

    function onPartialUpdate(dc) {
    	var app = Application.getApp();
    	
    	// Seconds
        var clockTime = System.getClockTime();
		dc.setClip(195, 60, 35, 35);
        dc.setColor(app.getProperty("BackgroundColor"), Graphics.COLOR_TRANSPARENT);
        dc.fillRectangle(195, 60, 35, 35);
        dc.setColor(app.getProperty("SecondsColor"), app.getProperty("BackgroundColor"));
        dc.drawText(195, 55, font_seconds, clockTime.sec.format("%02d"), Graphics.TEXT_JUSTIFY_LEFT);

        // Heart rate
		var activityinfo = Activity.getActivityInfo();
		since_last_hr = since_last_hr + 1;
		if (since_last_hr >= 3 && activityinfo.currentHeartRate != last_hr) {
			last_hr = activityinfo.currentHeartRate;
			since_last_hr = 0;
			
			dc.setClip(90, 209, 65, 25);
	        dc.setColor(app.getProperty("BackgroundColor"), Graphics.COLOR_TRANSPARENT);
	        dc.fillRectangle(90, 209, 65, 25);
	        if (activityinfo.currentHeartRate != null) {
		        dc.setColor(app.getProperty("HeartRateColor"), app.getProperty("BackgroundColor"));
	       		dc.drawText(120, 220, font_hr, Lang.format("* $1$", [activityinfo.currentHeartRate]), Graphics.TEXT_JUSTIFY_CENTER|Graphics.TEXT_JUSTIFY_VCENTER); 
	        }
	    }
    }
    
    // Called when this View is removed from the screen. Save the
    // state of this View here. This includes freeing resources from
    // memory.
    function onHide() {
		visible = false;
    }

    // The user has just looked at their watch. Timers and animations may be started here.
    function onExitSleep() {
    }

    // Terminate any active timers and prepare for slow updates.
    function onEnterSleep() {
    }
}
