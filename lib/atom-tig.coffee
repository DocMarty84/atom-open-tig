exec = require('child_process').exec
path = require('path')
platform = require('os').platform

###
   Opens tig in the given directory, as specefied by the config
###
open_tig = (filepath, blame) ->
  # Figure out the app and the arguments
  app = atom.config.get('atom-tig.app')
  tig = atom.config.get('atom-tig.tig')
  args = atom.config.get('atom-tig.args')

  # get options
  openMaximize = atom.config.get('atom-tig.openMaximize')
  runDirectly = atom.config.get('atom-tig.MacWinRunDirectly')

  # Start assembling the command line
  cmdline = "\"#{app}\" "

  # Add maximize if requested
  if openMaximize
    cmdline += " -m "

  # Add Tig
  cmdline += " -x sh -c \'#{tig} "

  # Add blame if requested
  if blame
    cmdline += " blame "

  # Add arguments
  cmdline += " #{args} "

  # Add file
  if filepath
    cmdline += "\"" + filepath + "\""

  # Close the command line
  cmdline += "\'"

  # For mac, we prepend open -a unless we run it directly
  if platform() == "darwin" && !runDirectly
    cmdline = "open -a " + cmdline

  # for windows, we prepend start unless we run it directly.
  if platform() == "win32" && !runDirectly
    cmdline = "start \"\" " + cmdline

  # log the command so we have context if it fails
  console.log("atom-tig executing: ", cmdline)

  # Set the working directory
  exec cmdline, cwd: atom.project.getPaths()[0] if atom.project.getPaths()[0]?


module.exports =
    activate: ->
        atom.commands.add "atom-workspace", "atom-tig:open", => @open()
        atom.commands.add "atom-workspace", "atom-tig:blame", => @blame()
        atom.commands.add "atom-workspace", "atom-tig:open-project-root", => @openroot()
    open: ->
        editor = atom.workspace.getActivePaneItem()
        file = editor?.buffer?.file
        filepath = file?.path
        if filepath
            open_tig(filepath, false)
    blame: ->
        editor = atom.workspace.getActivePaneItem()
        file = editor?.buffer?.file
        filepath = file?.path
        if filepath
            open_tig(filepath, true)
    openroot: ->
        open_tig(false, false)

# Set per-platform defaults
if platform() == 'darwin'
  # Defaults for Mac, use Terminal.app
  module.exports.config =
    app:
      type: 'string'
      default: 'Terminal.app'
    tig:
      type: 'string'
      default: 'tig'
    args:
      type: 'string'
      default: ''
    openMaximize:
        type: 'boolean'
        default: false
    MacWinRunDirectly:
      type: 'boolean'
      default: false
else if platform() == 'win32'
  # Defaults for windows, use cmd.exe as default
  module.exports.config =
      app:
        type: 'string'
        default: 'C:\\Windows\\System32\\cmd.exe'
      tig:
        type: 'string'
        default: 'tig'
      args:
        type: 'string'
        default: ''
      openMaximize:
        type: 'boolean'
        default: false
      MacWinRunDirectly:
        type: 'boolean'
        default: false
else
  # Defaults for all other systems (linux I assume), use xterm
  module.exports.config =
      app:
        type: 'string'
        default: '/usr/bin/x-terminal-emulator'
      tig:
        type: 'string'
        default: 'tig'
      args:
        type: 'string'
        default: ''
      openMaximize:
        type: 'boolean'
        default: true
      MacWinRunDirectly:
        type: 'boolean'
        default: false
