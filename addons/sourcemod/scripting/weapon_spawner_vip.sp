#include <sourcemod>
#include <weapon_spawner>
#include <vip_core>
#include <csgo_colors>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo = 
{
	name = "Weapon Spawner VIP",
	author = "firegaming & Rimmer",
	description = "",
	version = "1.0.0",
	url = "https://discord.gg/sR9YAaC"
};

KeyValues g_Config = null;

public void OnPluginStart()
{
	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/weapon_spawner/vip.txt");
	if(!FileExists(szPath))
		SetFailState("Config file '%s' is not exists.", szPath);
	
	g_Config = new KeyValues("vip");
	if(!g_Config.ImportFromFile(szPath))
		SetFailState("Error reading config file '%s'. Check syntax.", szPath);
	
	LoadTranslations("weapon_spawner_vip.phrases");
	
	if(WS_IsLoaded())
		WS_OnLoaded();
}

public void OnPluginEnd()
{
	WS_UnregisterMe();
}

public void WS_OnLoaded()
{
	g_Config.Rewind();
	if(g_Config.GotoFirstSubKey())
	{
		char szBuffer[128];
		
		do
		{
			if(g_Config.GetSectionName(szBuffer, sizeof(szBuffer)))
				WS_Register(szBuffer, OnGetVip);
		}
		while (g_Config.GotoNextKey());
	}
}

public bool OnGetVip(int client, int id, const char[] name)
{
	if(VIP_IsClientVIP(client))
	{
		CGOPrintToChat(client, "%t", "You Already Have Vip");
		return false;
	}
	
	g_Config.Rewind();
	if(g_Config.JumpToKey(name))
	{
		char szGroup[128];
		g_Config.GetString("group", szGroup, sizeof(szGroup));
		
		//if(!VIP_IsValidVIPGroup(szGroup))
		//	return false;
		
		int time = g_Config.GetNum("time") * 60;
		VIP_GiveClientVIP(0, client, time, szGroup);
		return true;
	}
	
	return false;
}
