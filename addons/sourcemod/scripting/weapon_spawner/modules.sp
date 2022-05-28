#if defined _weapon_spawner_modules_included
	#endinput
#endif
#define _weapon_spawner_modules_included

enum struct Module
{
	int id;
	Handle plugin;
	Function OnGet;
}

methodmap Modules < StringMap
{
	public Modules()
	{
		return view_as<Modules>(new StringMap());
	}

	public bool IsRegistered(const char[] szName)
	{
		Module module;
		return this.GetArray(szName, module, sizeof(module));
	}

	public int Register(Handle plugin, const char[] szName, Function OnGet)
	{
		static int id = 0;

		Module module;
		module.id = ++id;
		module.plugin = plugin;
		module.OnGet = OnGet;

		return this.SetArray(szName, module, sizeof(module)) ? id : 0;
	}

	public void Unregister(Handle plugin)
	{
		char szKey[128];
		Module module;
		StringMapSnapshot snapshot = this.Snapshot();
		for(int i = 0; i < snapshot.Length; ++i)
		{
			snapshot.GetKey(i, szKey, sizeof(szKey));
			if(this.GetArray(szKey, module, sizeof(module)) && module.plugin == plugin)
				this.Remove(szKey);
		}

		snapshot.Close();
	}

	public bool OnGet(int client, const char[] szName)
	{
		Module module;
		if(!this.GetArray(szName, module, sizeof(module)) || module.OnGet == INVALID_FUNCTION)
			return false;
		
		bool result = false;
		Call_StartFunction(module.plugin, module.OnGet);
		Call_PushCell(client);
		Call_PushCell(module.id);
		Call_PushString(szName);
		return (Call_Finish(result) == SP_ERROR_NONE) ? result : false;
	}
};
