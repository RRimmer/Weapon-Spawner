#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <adminmenu>
#include <weapon_spawner>
#include <csgo_colors>

#pragma newdecls required
#pragma semicolon 1

public Plugin myinfo =
{
	name = "Weapon Spawner | Core",
	author = "Rimmer & firegaming",
	description = "",
	version = "1.0.3",
	url = "https://discord.gg/sR9YAaC"
};

#include "weapon_spawner/config.sp"
#include "weapon_spawner/points_config.sp"
#include "weapon_spawner/forwards.sp"
#include "weapon_spawner/modules.sp"
#include "weapon_spawner/timers.sp"
#include "weapon_spawner/use_counter.sp"

Config g_Config = null;
PointsConfig g_PointConfig = null;
bool g_bLoaded = false;
Modules g_Modules = null;
int g_iTargetRef[MAXPLAYERS+1] = {-1, ...};
RemoveTimers g_RemoveTimers = null;
ReloadTimers g_ReloadTimers = null;
UseCounter g_UseCounter = null;

#include "weapon_spawner/tools.sp"
#include "weapon_spawner/adminmenu.sp"
#include "weapon_spawner/menus.sp"
#include "weapon_spawner/natives.sp"
#include "weapon_spawner/weapons.sp"

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	RegisterForwards();
	RegisterNatives();
	RegPluginLibrary("weapon_spawner");
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("weapon_spawner.phrases");

	g_Config = new Config();
	g_PointConfig = new PointsConfig();
	g_Modules = new Modules();
	g_RemoveTimers = new RemoveTimers();
	g_ReloadTimers = new ReloadTimers();
	g_UseCounter = new UseCounter();

	InitAdminMenu();

	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	RegAdminCmd("wspawner", Cmd_WsSpanwer, ADMFLAG_ROOT);
}

public void OnAllPluginsLoaded()
{
	g_bLoaded = true;
	Fwd_OnLoaded();
}

public void OnMapStart()
{
	g_Config.PrecacheModels();
	g_Config.PrecacheSounds();
	g_PointConfig.Clear();
	g_PointConfig.Load();
	PrecacheTools();

	char szPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, szPath, sizeof(szPath), "configs/weapon_spawner/downloads.txt");
	ReadDownloadsList(szPath);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_RemoveTimers.KillAndClear();
	g_ReloadTimers.KillAndClear();
	CreatePoints();
	g_UseCounter.Clear();
}

public Action Cmd_WsSpanwer(int client, int args)
{
	if(!client)
	{
		ReplyToCommand(client, "[SM] Ingame only.");
		return Plugin_Handled;
	}
	
	DisplayMainAdminMenu(client);
	return Plugin_Handled;
}

void CreatePoints()
{
	int size = g_PointConfig.Length;
	if(!size)
		return;
	
	Point point;
	for(int i = 0; i < size; ++i)
	{
		g_PointConfig.GetArray(i, point, sizeof(point));
		CreatePoint(point);
	}
}

void CreatePoint(Point point)
{
	int id = g_Config.GetId(point.szName);
	if(id == 0)
		return;
	
	int trigger = CreateTrigger(point.vOrigin);
	if(trigger == -1)
		return;

	char szColor[32];
	g_Config.GetTypeColor(id, szColor, sizeof(szColor));
	int light = CreateLight(point.vOrigin, szColor);
	if(light == -1)
	{
		AcceptEntityInput(trigger, "Kill");
		return;
	}
	else
	{
		SetVariantString("!activator");
		AcceptEntityInput(light, "SetParent", trigger, light);
	}
	
	char szModel[PLATFORM_MAX_PATH];
	g_Config.GetBottomModel(szModel, sizeof(szModel));
	int bottom = szModel[0] ? CreateProp("", point.vOrigin, view_as<float>({0.0, 0.0, 0.0})) : -1;
	if(bottom != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(bottom, "SetParent", trigger, bottom);

		RequestFrame(UpdateBottomModel, EntIndexToEntRef(bottom));
	}

	float origin[3], angles[3], heigth;
	g_Config.GetPropInfo(id, angles, szModel, sizeof(szModel), heigth);

	origin[0] = point.vOrigin[0];
	origin[1] = point.vOrigin[1];
	origin[2] = point.vOrigin[2] + heigth;

	int prop = szModel[0] ? CreateProp(szModel, origin, angles) : -1;
	if(prop != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(prop, "SetParent", light, prop);
	}

	float scale;
	g_Config.GetSpriteInfo(id, szModel, sizeof(szModel), heigth, scale);

	origin[0] = point.vOrigin[0];
	origin[1] = point.vOrigin[1];
	origin[2] = point.vOrigin[2] + heigth;

	int sprite = szModel[0] ? CreateSprite(szModel, origin, scale) : -1;
	if(sprite != -1)
	{
		SetVariantString("!activator");
		AcceptEntityInput(sprite, "SetParent", light, sprite);
	}

	SetEntPropEnt(trigger, Prop_Send, "m_hEffectEntity", light);
	SetEntProp(trigger, Prop_Data, "m_iHammerID", id);
	HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);

	float lifetime = g_Config.GetLifetime(id);
	if(lifetime > 0.0)
	{
		int iEntRef = EntIndexToEntRef(trigger);
		Handle timer = CreateTimer(lifetime, Timer_RemoveSpawn, iEntRef);

		RemoveInfo info;
		info.timer = timer;
		info.iEntRef = iEntRef;
		info.spawn_time = GetGameTime();
		info.lifetime = lifetime;

		g_RemoveTimers.AddRemoveInfo(info);
	}
}

public void OnStartTouch(const char[] output, int trigger, int client, float delay)
{
	int id = GetEntProp(trigger, Prop_Data, "m_iHammerID");
	int limit_player = g_Config.GetLimitPerPlayer(id);
	int use_count = g_UseCounter.GetUseCount(client, trigger);
	if(limit_player && use_count >= limit_player)
	{
		CGOPrintToChat(client, "%t", "You Reached Limit", use_count, limit_player);
		return;
	}

	int price = g_Config.GetPrice(id);
	int money = GetEntProp(client, Prop_Send, "m_iAccount");
	if(money < price)
	{
		char szName[128];
		g_Config.GetTypeName(id, szName, sizeof(szName));
		CGOPrintToChat(client, "%t", "Not Enough Money", szName, price);
		return;
	}
	
	switch(g_Config.GetMenuType(id))
	{
		case 0:
		{
			char szItemName[128], szItem[128];
			if(!g_Config.GetRandomItem(id, szItemName, sizeof(szItemName), szItem, sizeof(szItem)))
				return;
			
			if(g_Modules.OnGet(client, szItem))
			{
				SetEntProp(client, Prop_Send, "m_iAccount", money - price);
				CGOPrintToChat(client, "%t", "You Get Item", szItemName, price);
				
				g_UseCounter.IncUseCount(client, trigger);
				if(IsLimitReached(trigger, id))
				{
					DisableSpawn(trigger);
					return;
				}

				ReloadSpawn(trigger, id);
			}
		}

		case 1:
		{
			g_iTargetRef[client] = EntIndexToEntRef(trigger);
			DisplayOfferMenu(client, id);
		}

		case 2:
		{
			g_iTargetRef[client] = EntIndexToEntRef(trigger);
			DisplayItemsListMenu(client, id);
		}
	}
}

public void UpdateBottomModel(any iEntRef)
{
	int iEnt = EntRefToEntIndex(iEntRef);
	if(!IsValidEntity(iEnt))
		return;
	
	char szModel[PLATFORM_MAX_PATH];
	g_Config.GetBottomModel(szModel, sizeof(szModel));
	SetEntityModel(iEnt, szModel);
	SetEntProp(iEnt, Prop_Send, "m_nSkin", g_Config.GetBottomSkin());
}

void ReloadSpawn(int trigger, int id)
{
	float reload_time = g_Config.GetReloadTime(id);
	if(reload_time <= 0.0)
		return;
	
	float fOrigin[3];
	GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", fOrigin);
	char szSound[PLATFORM_MAX_PATH];
	g_Config.GetReloadStartSound(szSound, sizeof(szSound));
	if(szSound[0])
		EmitAmbientSound(szSound, fOrigin);

	DisableSpawn(trigger);
	
	float timeleft = g_RemoveTimers.GetTimeLeft(EntIndexToEntRef(trigger));
	if(timeleft != 0.0 && timeleft < reload_time)
		return;

	Handle timer = CreateTimer(reload_time, Timer_ReloadSpawn, EntIndexToEntRef(trigger));
	g_ReloadTimers.Push(timer);
}

public Action Timer_ReloadSpawn(Handle timer, any iEntRef)
{
	int trigger = EntRefToEntIndex(iEntRef);
	if(IsValidEntity(trigger))
	{
		float fOrigin[3];
		GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", fOrigin);
		int id = GetEntProp(trigger, Prop_Data, "m_iHammerID");

		char szColor[32];
		g_Config.GetTypeColor(id, szColor, sizeof(szColor));
		int light = CreateLight(fOrigin, szColor);
		if(light != -1)
		{
			SetVariantString("!activator");
			AcceptEntityInput(light, "SetParent", trigger, light);
		
			char szModel[PLATFORM_MAX_PATH];
			float origin[3], angles[3], heigth;
			g_Config.GetPropInfo(id, angles, szModel, sizeof(szModel), heigth);

			origin[0] = fOrigin[0];
			origin[1] = fOrigin[1];
			origin[2] = fOrigin[2] + heigth;

			int prop = szModel[0] ? CreateProp(szModel, origin, angles) : -1;
			if(prop != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(prop, "SetParent", light, prop);
			}

			float scale;
			g_Config.GetSpriteInfo(id, szModel, sizeof(szModel), heigth, scale);

			origin[0] = fOrigin[0];
			origin[1] = fOrigin[1];
			origin[2] = fOrigin[2] + heigth;

			int sprite = szModel[0] ? CreateSprite(szModel, origin, scale) : -1;
			if(sprite != -1)
			{
				SetVariantString("!activator");
				AcceptEntityInput(sprite, "SetParent", light, sprite);
			}

			SetEntPropEnt(trigger, Prop_Send, "m_hEffectEntity", light);
			HookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);

			char szSound[PLATFORM_MAX_PATH];
			g_Config.GetReloadFinishSound(szSound, sizeof(szSound));
			if(szSound[0])
				EmitAmbientSound(szSound, fOrigin);
		}
		else
		{
			AcceptEntityInput(trigger, "KillHierarchy");
		}
	}

	g_ReloadTimers.Remove(timer);
	return Plugin_Stop;
}

public Action Timer_RemoveSpawn(Handle timer, any iEntRef)
{
	int trigger = EntRefToEntIndex(iEntRef);
	if(IsValidEntity(trigger))
		DisableSpawn(trigger);

	g_RemoveTimers.Remove(timer);
	return Plugin_Stop;
}

bool IsLimitReached(int trigger, int id)
{
	int limit = g_Config.GetLimit(id);
	if(!limit)
		return false;
	
	int total = g_UseCounter.GetTotal(trigger);
	return (total >= limit);
}

void DisableSpawn(int trigger)
{
	UnhookSingleEntityOutput(trigger, "OnStartTouch", OnStartTouch);
	
	int light = GetEntPropEnt(trigger, Prop_Send, "m_hEffectEntity");
	if(light != -1)
		AcceptEntityInput(light, "KillHierarchy");
}