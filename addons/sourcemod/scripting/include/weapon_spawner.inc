#if defined _weapon_spawner_included
 #endinput
#endif
#define _weapon_spawner_included

/**
 *	Called when plugin ready to register modules.
 *	-
 *	@noreturn
 */
forward void WS_OnLoaded();

/**
 *	Returns if a plugin ready to register modules.
 *	-
 *	@noparams
 *	@return		True if ready to register modules, false otherwise.
 */
native bool WS_IsLoaded();

/**
 *	Callback for registered modules. 
 *	-
 *	@param client	Client index
 *	@param id		Called module unique id
 *	@param name		Called module unique name
 *	@return			True if player get staff, false otherwise.
 */
typedef WS_OnGet = function bool (int client, int id, const char[] name);

/**
 *	Register module
 *	-
 *	@param name			Module unique name
 *	@param callback		Callback called when the module being used
 *	@return				Unique id of registered module
 */
native int WS_Register(const char[] name, WS_OnGet callback);

/**
 *	Fully unregister modules. This must be called on PluginEnd
 *	-
 *	@noparams
 *	@noreturn
 */
native void WS_UnregisterMe();

/* DO NOT EDIT BELOW THIS LINE */

public SharedPlugin __pl_weapon_spawner = 
{
	name = "weapon_spawner",
	file = "weapon_spawner.smx",
#if defined REQUIRE_PLUGIN
	required = 1,
#else
	required = 0,
#endif
};

#if !defined REQUIRE_PLUGIN
public void __pl_weapon_spawner_SetNTVOptional()
{
    MarkNativeAsOptional("WS_IsLoaded");
    MarkNativeAsOptional("WS_Register");
    MarkNativeAsOptional("WS_UnregisterMe");
}
#endif
