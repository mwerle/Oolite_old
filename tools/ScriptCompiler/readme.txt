Oolite script compiler.

Copyright (c) 2006 David Taylor. All rights reserved.

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/2.0/
or send a letter to Creative Commons, 559 Nathan Abbott Way, Stanford, California 94305, USA.

You are free:

o to copy, distribute, display, and perform the work
o to make derivative works

Under the following conditions:

o Attribution. You must give the original author credit.
o Noncommercial. You may not use this work for commercial purposes.
o Share Alike. If you alter, transform, or build upon this work,
  you may distribute the resulting work only under a license identical to this one.

For any reuse or distribution, you must make clear to others the license terms of this work.
Any of these conditions can be waived if you get permission from the copyright holder.
Your fair use and other rights are in no way affected by the above.


Introduction
------------

This program reads an Oolite script written in a BASIC-like syntax and creates an XML
PList version of it.

The format of the BASIC-like file is:

scriptname

// comments must start with // and be the only thing on the line
if xxx [and xxx ...] then
	// indentation is ignored
	actions
[else
	actions]
endif

if xxx [and xxx ...] then
	actions
[else
	actions]
endif


The scriptname must be a single word on the first line of the script file.

Comments must be the only thing on a line, and start with //. Leading whitespace is ignored.
Comments can appear anywhere after the script name.

The script itself must only have "if" statements at the "top level". Multiple conditions
can be given to an if statement by using "and". The conditions be put on more than one line.
Newlines are ignored between "if" and "then"

The end of the conditions is marked with the word "then", which must be followed by
one or more "actions" which are written exactly as they are in the XML version of the script.
You can only put one action on each line, and leading whitespace is ignored.

You can use "else" followed by more actions to generate the else array of the XML script.

The if/else block is finished with the word "endif"


Installation
------------

You must have a working JRE to use this program.

Create a directory for the program, such as C:\ooscript. Then create a set of directories under
that called "dt\oolite\scriptcompiler". The ScriptCompiler.class file goes in the bottom directory.

In the above example, the fully qualified filename for the class file will be:
C:\ooscript\dt\oolite\scriptcompiler.class


How to run it
-------------

You can use the compile.bat file that is included as follows:

compile <script name>

e.g.

compile "C:/Program Files/Oolite/Addons/longway.oxp/Config/script.oos"

If you are not using Windows, issue the command:

java -classpath <parent directory of the "dt" package directory> dt.oolite.scriptcompiler.ScriptCompiler <script name>

Using the installation example above (note filenames with space MUST be surrounded by double quotes):

C:\>java -classpath c:\ooscript dt.oolite.scriptcompiler.ScriptCompiler "C:/Program Files/Oolite/Addons/longway.oxp/Config/script.oos"
Oolite script compiler
Copyright 2006 David Taylor. All rights reserved.
transforming C:/Program Files/Oolite/Addons/longway.oxp/Config/script.oos
to C:/Program Files/Oolite/Addons/longway.oxp/Config/script.plist


Example input/output
--------------------

Translating the longway_round mission to the simplified script syntax gives:

long_way_round
if galaxy_number equal 0 then
	if dockedAtMainStation_bool equal YES then
		if mission_longwayround undefined and planet_number equal 3 then
			setMissionMusic: none
			setGuiToMissionScreen
			addMissionText: long_way_round_Biarge_briefing
			set: mission_longwayround STAGE1
			setMissionDescription: em1_short_desc1
		endif

		if mission_longwayround equal STAGE1 and plaent_number equal 248 then
			setMissionMusic: none
			setGuiToMissionScreen
			addMissionText: long_way_round_Soladies_briefing
			awardCredits: 500
			set: mission_longwayround STAGE2
			setMissionDescription: em1_short_desc2
		endif

		if mission_longwayround equal STAGE2 and planet_number equal 233 then
			setMissionMusic: none
			setMissionImage: loyalistflag.png
			setGuiToMissionScreen
			addMissionText: long_way_round_Qubeen_briefing
			awardCredits: 2000
			setMissionImage: none
			set: mission_longwayround MISSION_COMPLETE
			clearMissionDescription
		endif
	endif

	if mission_longwayround equal STAGE2 and
	   planet_number equal 233 and
	   status_string equal STATUS_EXITING_WITCHSPACE then
		addShips: rebel 2
	endif

	if mission_longwayround equal STAGE2 and
	   status_string equal STATUS_IN_FLIGHT and
	   planet_number equal 233 and
	   scriptTimer_number lessthan 60 then
		checkForShips: rebel
		if shipsFound_number lessthan 5 and d100_number lessthan 50 then
			addShips: rebel 1
		endif
	endif
endif

Running this through the script compiler gives:

<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple Computer//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>long_way_round</key>
    <array>
        <dict>
            <key>conditions</key>
            <array>
                <string>galaxy_number equal 0</string>
            </array>
            <key>do</key>
            <array>
                <dict>
                    <key>conditions</key>
                    <array>
                        <string>dockedAtMainStation_bool equal YES</string>
                    </array>
                    <key>do</key>
                    <array>
                        <dict>
                            <key>conditions</key>
                            <array>
                                <string>mission_longwayround undefined</string>
                                <string>planet_number equal 3</string>
                            </array>
                            <key>do</key>
                            <array>
                                <string>setMissionMusic: none</string>
                                <string>setGuiToMissionScreen</string>
                                <string>addMissionText: long_way_round_Biarge_briefing</string>
                                <string>set: mission_longwayround STAGE1</string>
                                <string>setMissionDescription: em1_short_desc1</string>
                            </array>
                        </dict>
                        <dict>
                            <key>conditions</key>
                            <array>
                                <string>mission_longwayround equal STAGE1</string>
                                <string>plaent_number equal 248</string>
                            </array>
                            <key>do</key>
                            <array>
                                <string>setMissionMusic: none</string>
                                <string>setGuiToMissionScreen</string>
                                <string>addMissionText: long_way_round_Soladies_briefing</string>
                                <string>awardCredits: 500</string>
                                <string>set: mission_longwayround STAGE2</string>
                                <string>setMissionDescription: em1_short_desc2</string>
                            </array>
                        </dict>
                        <dict>
                            <key>conditions</key>
                            <array>
                                <string>mission_longwayround equal STAGE2</string>
                                <string>planet_number equal 233</string>
                            </array>
                            <key>do</key>
                            <array>
                                <string>setMissionMusic: none</string>
                                <string>setMissionImage: loyalistflag.png</string>
                                <string>setGuiToMissionScreen</string>
                                <string>addMissionText: long_way_round_Qubeen_briefing</string>
                                <string>awardCredits: 2000</string>
                                <string>setMissionImage: none</string>
                                <string>set: mission_longwayround MISSION_COMPLETE</string>
                                <string>clearMissionDescription</string>
                            </array>
                        </dict>
                    </array>
                </dict>
                <dict>
                    <key>conditions</key>
                    <array>
                        <string>mission_longwayround equal STAGE2</string>
                        <string>planet_number equal 233</string>
                        <string>status_string equal STATUS_EXITING_WITCHSPACE</string>
                    </array>
                    <key>do</key>
                    <array>
                        <string>addShips: rebel 2</string>
                    </array>
                </dict>
                <dict>
                    <key>conditions</key>
                    <array>
                        <string>mission_longwayround equal STAGE2</string>
                        <string>status_string equal STATUS_IN_FLIGHT</string>
                        <string>planet_number equal 233</string>
                        <string>scriptTimer_number lessthan 60</string>
                    </array>
                    <key>do</key>
                    <array>
                        <string>checkForShips: rebel</string>
                        <dict>
                            <key>conditions</key>
                            <array>
                                <string>shipsFound_number lessthan 5</string>
                                <string>d100_number lessthan 50</string>
                            </array>
                            <key>do</key>
                            <array>
                                <string>addShips: rebel 1</string>
                            </array>
                        </dict>
                    </array>
                </dict>
            </array>
        </dict>
    </array>
</dict>
</plist>
