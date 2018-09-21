# TimeZone-Alfred

Do you like [Alfred](https://www.alfredapp.com/)? I like too… I’ve recently found bunch of very nice Workflows. For me, the most used one is for sure Time Zone.

The workflow has been created by Mr Carlos from New Zealand and published on the [Alfred Forum](http://www.alfredforum.com/topic/491-timezones-a-world-clock-script-filter-updated-to-v17/). I’ve enhanced the workflow by adding a few new functionalities:

* Converting any time to all pre-defined time zones
* Enabling 24-hrs time format
* Displaying phone country code

After all it looks like below:

![Preview 1](https://jhartman.pl/wp-content/uploads/2016/12/Alfred2.png)

Conversion of a time in your local time to your pre-defined time-zones – “tz <time>” in formats HH, HHMM or HH:MM:

![Preview 2](https://jhartman.pl/wp-content/uploads/2016/12/Alfred3.png)

## Commands

* **Keyword**: *tz* (or hotkey) - bring up the list of saved cities with their respective current times. (Keep typing the name of a place for a one-off lookup.)
* **Keyword**: *tz <time>* - (where time is HH, HHMM or HH:MM) - convert provided time into the time of your cities. 
* **Keyword**: *timezone add [your city]* - add your city to the list. (To remove a city, option-select it from the main list.)
* **Keyword**: *timezone edit* - open for edit of cities file.
* **Keyword**: *timezone move* - move the saved cities file (timezones.txt) to a location of your choice (so you can sync it in your Dropbox or whatever you want).
* **Keyword**: *timezone 12h*, *timezone 24h* - change format of displayed time.


## Installation steps

1. Install Alfred
2. Purchase premium version of Alfred to enable Workflows
3. Download latest ZIP file from [releases](https://github.com/jaroslawhartman/TimeZones-Alfred/releases)
4. Unzip and double click to add to Alfred
