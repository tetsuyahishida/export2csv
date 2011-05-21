# Loader for as_plugins/as_pluginloader/as_pluginloader.rb

require 'sketchup.rb'
require 'extensions.rb'

as_pluginloader = SketchupExtension.new "Plugin Loader", "as_plugins/as_pluginloader/as_pluginloader.rb"
as_pluginloader.copyright= 'Copyright 2010 Alexander C. Schreyer'
as_pluginloader.creator= 'Alexander C. Schreyer, www.alexschreyer.net'
as_pluginloader.version = '1.2'
as_pluginloader.description = "This will add a menu item to the Plugins menu, which allows for downloading and loading of plugins - on demand."
Sketchup.register_extension as_pluginloader, true
