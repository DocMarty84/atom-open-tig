exec = require('child_process').exec
path = require('path')
platform = require('os').platform

###
   Opens tig in the given directory, as specefied by the config
###
open_tig = (dirpath, filepath, blame) ->
  # Figure out the app and the arguments
  app = atom.config.get('atom-tig.app')
  tig = atom.config.get('atom-tig.tig')
  args = atom.config.get('atom-tig.args')

  # get options
  setWorkingDirectory = atom.config.get('atom-tig.setWorkingDirectory')
  surpressDirArg = atom.config.get('atom-tig.surpressDirectoryArgument')
  runDirectly = atom.config.get('atom-tig.MacWinRunDirectly')

  # Start assembling the command line
  cmdline = "\"#{app}\" -x sh -c \'#{tig} "

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

  # If we do not supress the directory argument, add the directory as an argument
  if !surpressDirArg
      cmdline  += " \"#{dirpath}\""

  # For mac, we prepend open -a unless we run it directly
  if platform() == "darwin" && !runDirectly
    cmdline = "open -a " + cmdline

  # for windows, we prepend start unless we run it directly.
  if platform() == "win32" && !runDirectly
    cmdline = "start \"\" " + cmdline

  # log the command so we have context if it fails
  console.log("atom-tig executing: ", cmdline)

  # Set the working directory if configured
  if setWorkingDirectory
    exec cmdline, cwd: dirpath if dirpath?
  else
    exec cmdline if dirpath?


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
            open_tig(path.dirname(filepath), filepath, false)
    blame: ->
        editor = atom.workspace.getActivePaneItem()
        file = editor?.buffer?.file
        filepath = file?.path
        if filepath
            open_tig(path.dirname(filepath), filepath, true)
    openroot: ->
        open_tig(atom.project.getPaths()[0], false, false)

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
    surpressDirectoryArgument:
      type: 'boolean'
      default: false
    setWorkingDirectory:
      type: 'boolean'
      default: true
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
      surpressDirectoryArgument:
        type: 'boolean'
        default: false
      setWorkingDirectory:
        type: 'boolean'
        default: true
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
      surpressDirectoryArgument:
        type: 'boolean'
        default: true
      setWorkingDirectory:
        type: 'boolean'
        default: true
      MacWinRunDirectly:
        type: 'boolean'
        default: false
