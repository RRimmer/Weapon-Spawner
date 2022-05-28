#include <sourcemod>
#include <weapon_spawner>
#include <shop>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Weapon Spawner SHOP",
	author = "Rimmer & firegaming",
	description = "",
	version = "1.0.0",
	url = "https://discord.gg/sR9YAaC"
};

StringMap g_Map = null;

public void OnPluginStart()
{
	g_Map = new StringMap();
	
	if(WS_IsLoaded())
		WS_OnLoaded();
}

public void OnPluginEnd()
{
	WS_UnregisterMe();
}

public void WS_OnLoaded()
{
	g_Map.Clear();
	
	char szBuffer[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/weapon_spawner/credits.txt");
	if(!FileExists(szBuffer))
		SetFailState("Config file '%s' is not exists.", szBuffer);
	
	KeyValues kv = new KeyValues("credits");
	if(!kv.ImportFromFile(szBuffer))
		SetFailState("Error reading config file '%s'. Check syntax.", szBuffer);
	
	if(kv.GotoFirstSubKey(false))
	{
		int credits;
		
		do
		{
			kv.GetSectionName(szBuffer, sizeof(szBuffer));
			credits = kv.GetNum(NULL_STRING);
			g_Map.SetValue(szBuffer, credits);
			WS_Register(szBuffer, OnGetCredits);
		}
		while (kv.GotoNextKey());
	}
	
	kv.Close();
}

public bool OnGetCredits(int client, int id, const char[] name)
{
	int credits;
	if(g_Map.GetValue(name, credits))
	{
		Shop_GiveClientCredits(client, credits);
		return true;
	}
	
	return false;
}