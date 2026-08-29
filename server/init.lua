local REQUIRED_CORE_VERSION <const> = '0.3.0'

local dependency <const> = Siku.version.checkDependency('siku_core', REQUIRED_CORE_VERSION)

if not dependency.ok then
  Siku.print.throw(dependency.message)
end

Siku.print.success(('Linked to siku_core (%s)'):format(dependency.currentVersion))
Siku.version.checkRelease('siku-project/siku_status')

--- Everything that needs the database waits in its own thread: the modules
--- below this file do not exist yet while it loads, and the migration only
--- completes once the database answered.
CreateThread(function()
  if not Siku.migration.run(MigrationConfig) then
    return
  end

  RestoreConnectedSessions()

  Siku.print.success(('%d status(es) registered'):format(StatusRegistry.count()))
end)
