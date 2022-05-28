#if defined _weapon_spawner_natives_included
	#endinput
#endif
#define _weapon_spawner_natives_included

void RegisterNatives()
{
	CreateNative("WS_IsLoaded", __isLoaded);
	CreateNative("WS_Register", __register);
	CreateNative("WS_UnregisterMe", __unregiterMe);
}

public int __isLoaded(Handle plugin, int numParams)
{
	return g_bLoaded;
}

public int __register(Handle plugin, int numParams)
{
	int length, error;
	if((error = GetNativeStringLength(1, length)) != SP_ERROR_NONE)
		ThrowNativeError(error, "Error getting string size (%d)", error);
	
	if(length == 0)
		ThrowNativeError(SP_ERROR_NATIVE, "Param 1 is empty string");
	
	char[] szName = new char[length + 1];
	GetNativeString(1, szName, length + 1);
	Function callback = GetNativeFunction(2);
	return g_Modules.Register(plugin, szName, callback);
}

public int __unregiterMe(Handle plugin, int numParams)
{
	g_Modules.Unregister(plugin);
	return 0;
}