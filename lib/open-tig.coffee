exec = require('child_process').exec
path = require('path')
platform = require('os').platform
fs = require('fs')

###
   Opens tig in the given directory, as specefied by the config
###

get_filepath = () ->
  editor = atom.workspace.getActivePaneItem()
  file = editor?.buffer?.file
  return file?.path

git_directory = (filepath) ->
  if not filepath
    return atom.project.getPaths()[0]

  filepath_info = path.parse(filepath)
  dirpath = filepath_info.dir
  dirpath_split = dirpath.split(path.sep)

  while filepath_info.root != dirpath
    if fs.existsSync(path.join(dirpath, ".git"))
      return dirpath
    dirpath_split.pop()
    dirpath = dirpath_split.join(path.sep)

  return atom.project.getPaths()[0]

open_tig = (filepath, mode) ->
  # get options
  app = atom.config.get('open-tig.app')
  tig = atom.config.get('open-tig.tig')
  openMaximize = atom.config.get('open-tig.openMaximize')
  maximizeArg = atom.config.get('open-tig.maximizeArg')
  runDirectly = atom.config.get('open-tig.MacWinRunDirectly')
  workingDirectoryParam = atom.config.get('open-tig.workingDirectoryParam')

  # get git directory
  git_dir = git_directory(filepath)

  #### Start assembling the command line ####
  cmdline = "\"#{app}\""

  # For mac, we need to use osascript to force the app to run a command
  if platform() == "darwin" && !runDirectly
    cmdline = "osascript -e 'tell application " + cmdline + " to do script \"cd " + git_dir + " && "

  # For windows, we prepend start unless we run it directly.
  if platform() == "win32" && !runDirectly
    cmdline = "start \"\" " + cmdline

  # Set the working directory
  if workingDirectoryParam && git_dir
    cmdline += " " + workingDirectoryParam + " " + git_dir

  # Add maximize if requested
  if openMaximize && platform() != "darwin"
    cmdline += " " + maximizeArg

  #### Build tig part of the command line ####
  tig_cmdline = "#{tig}"

  # Add blame if requested
  if mode == 'blame'
    tig_cmdline += " blame"

  # Add file
  if filepath && mode != 'root'
    if platform() == "darwin" && !runDirectly
      tig_cmdline += " \\\"" + filepath + "\\\""
    else
      tig_cmdline += " \"" + filepath + "\""

  # Add cursor position
  if mode == 'blame'
    editor = atom.workspace.getActivePaneItem()
    row = (editor?.getCursorBufferPosition()?.row + 1).toString()
    if row
      tig_cmdline += " +" + row

  # Add tig part of the command line
  if platform() != "darwin" || runDirectly
    cmdline += " -e \'" + tig_cmdline + "\'"
  else
    cmdline += tig_cmdline

  #### Close and run the command line ####
  # Close the script command on mac
  if platform() == "darwin" && !runDirectly
    cmdline += "\" in window 1'"

  # Add maximize on mac if requested
  if openMaximize && platform() == "darwin" && !runDirectly
    cmdline += " && osascript -e 'tell application \"Finder\"' -e 'set desktopSize to bounds of window of desktop' -e 'end tell' -e 'tell application \"#{app}\"' -e 'set bounds of window 1 to desktopSize' -e 'activate' -e 'end tell'"

  if workingDirectoryParam
    console.log("open-tig executing: ", cmdline)
    exec cmdline
  else
    console.log("open-tig executing: ", git_dir, cmdline)
    exec cmdline, cwd: git_dir if git_dir?


module.exports =
  activate: ->
    atom.commands.add "atom-workspace", "open-tig:open", => @open()
    atom.commands.add "atom-workspace", "open-tig:blame", => @blame()
    atom.commands.add "atom-workspace", "open-tig:open-project-root", => @openroot()
  open: ->
    filepath = get_filepath()
    if filepath
      open_tig(filepath, 'file')
  blame: ->
    filepath = get_filepath()
    if filepath
      open_tig(filepath, 'blame')
  openroot: ->
    open_tig(get_filepath(), 'root')

# Set per-platform defaults
if platform() == 'darwin'
  # Defaults for Mac, use Terminal.app
  default_app = 'Terminal.app'
  default_openMaximize = true
  default_maximizeArg = ''
else if platform() == 'win32'
  # Defaults for windows, use cmd.exe as default
  default_app = 'C:\\Windows\\System32\\cmd.exe'
  default_openMaximize = false
  default_maximizeArg = ''
else
  # Defaults for all other systems (linux I assume), use xterm
  default_app = '/usr/bin/x-terminal-emulator'
  default_openMaximize = true
  default_maximizeArg = '-m'

module.exports.config =
  app:
    type: 'string'
    default: default_app
    order: 10
    title: 'Terminal Executable'
  tig:
    type: 'string'
    default: 'tig'
    order: 20
    title: 'Tig Executable'
  openMaximize:
    type: 'boolean'
    default: default_openMaximize
    order: 30
    title: 'Open Maximized'
  maximizeArg:
    type: 'string'
    default: default_maximizeArg
    order: 40
    title: 'Maximized Argument'
    description: '''For Linux: (1) terminator => -m (2) gnome-terminal => --maximize (3) konsole => --fullscreen'''
  MacWinRunDirectly:
    type: 'boolean'
    default: false
    order: 50
    title: 'Run Directly (Win & MacOS only)'
  workingDirectoryParam:
    type: 'string'
    default: ''
    order: 60
    title: 'Working Directory'
    description: '''This might be required on some systems.'''
