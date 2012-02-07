[ The instructions bellow were written having in mind a
Mac OS X, Ubuntu GNU/Linux or Windows XP installation ]

There are two graphic user interfaces:
1) RubyCocoa based - csv2uppaal.dmg (installer for Mac OS X)
2) Tk based - tklauncher.rb (to be run on Linux distributions or Windows)

###
# RubyCocoa version of the GUI
###

Mac users should prefer this version of the GUI. We provide a standard 
.dmg installer.  Just drag the application icon above the Applications shortcut 
for installation.


###
# Tk version of the GUI
###

The Tk version of the GUI is called 'tklauncher.rb' This is a prefered
GUI for Ubuntu and Windows users. 

On GNU/Linux, make sure you have ruby, Tk and the Ruby-Tk binding 
available by running:
sudo apt-get install tk libtcltk-ruby 
And then run in the terminal: ruby tklauncher.rb

For other linux distributions, a good tutorial on how to install Tcl/Tk and 
its bindings is here http://tkdocs.com/tutorial/install.html.

We also tested it against RVM rubies.
http://rvm.beginrescueend.com/

On Windows, if you have set up the Tcl/Tk checkbox on rubyinstaller
everthing should run fine.