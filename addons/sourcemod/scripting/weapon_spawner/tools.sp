#if defined _weapon_spawner_tools_included
	#endinput
#endif
#define _weapon_spawner_tools_included

static const char g_szZoneModel[] = "models/props/de_train/barrel.mdl";

void PrecacheTools()
{
	PrecacheModel(g_szZoneModel);
}

int CreateTrigger(const float fOrigin[3])
{
	int iEnt = CreateEntityByName("trigger_multiple");
	if(iEnt == -1)
		return -1;
	
	SetEntityModel(iEnt, g_szZoneModel);
	DispatchKeyValue(iEnt, "spawnflags", "257");
	DispatchKeyValue(iEnt, "StartDisabled", "0");
	DispatchKeyValueVector(iEnt, "origin", fOrigin);
	DispatchKeyValue(iEnt, "targetname", "wpn_spwn");
	DispatchSpawn(iEnt);
	ActivateEntity(iEnt);

	SetEntProp(iEnt, Prop_Send, "m_nSolidType", 2);
	SetEntProp(iEnt, Prop_Send, "m_fEffects", GetEntProp(iEnt, Prop_Send, "m_fEffects") | 32);

	SetEntPropVector(iEnt, Prop_Send, "m_vecMins", view_as<float>({ -5.0, -5.0, 0.0 }));
	SetEntPropVector(iEnt, Prop_Send, "m_vecMaxs", view_as<float>({ 5.0, 5.0, 60.0 }));

	return iEnt;
}

int CreateProp(const char[] szModel, const float fOrigin[3], const float fAngles[3])
{
	int iEnt = CreateEntityByName("prop_physics_override");
	if(iEnt == -1)
		return - 1;
	
	DispatchKeyValue(iEnt, "model", szModel[0] ? szModel : g_szZoneModel);
	DispatchKeyValueVector(iEnt, "origin", fOrigin);
	DispatchKeyValueVector(iEnt, "angles", fAngles);
	DispatchKeyValue(iEnt, "targetname", "wpn_spwn");
	DispatchKeyValue(iEnt, "spawnflags", "4355");
	DispatchKeyValue(iEnt, "MoveType", "0");
	DispatchKeyValue(iEnt, "CollisionGroup", "2");
	DispatchSpawn(iEnt);

	return iEnt;
}

int CreateSprite(const char[] szMaterial, const float fOrigin[3], float fScale = 1.0)
{
	int iEnt = CreateEntityByName("env_sprite");
	if(iEnt == -1)
		return -1;
	
	DispatchKeyValueVector(iEnt, "origin", fOrigin);
	DispatchKeyValue(iEnt, "model", szMaterial);
	DispatchKeyValueFloat(iEnt, "scale", fScale);
	DispatchKeyValue(iEnt, "spawnflags", "1");
	DispatchKeyValue(iEnt, "targetname", "wpn_spwn");
	DispatchSpawn(iEnt);

	return iEnt;
}

int CreateLight(const float fOrigin[3], const char[] szColor)
{
	int iEnt = CreateEntityByName("point_spotlight");
	if(iEnt == -1)
		return -1;
	
	DispatchKeyValueVector(iEnt, "origin", fOrigin);
	DispatchKeyValue(iEnt, "angles", "-90 0 0");
	DispatchKeyValue(iEnt, "spotlightlength", "70");
	DispatchKeyValue(iEnt, "spotlightwidth", "40");
	DispatchKeyValue(iEnt, "spawnflags", "1");
	DispatchKeyValue(iEnt, "rendercolor", szColor);
	DispatchKeyValue(iEnt, "renderamt", "255");
	DispatchKeyValue(iEnt, "rendermode", "1");
	DispatchKeyValue(iEnt, "scale", "5");
	DispatchSpawn(iEnt);

	return iEnt;
}

void ReadDownloadsList(const char[] szPath)
{
	File file = OpenFile(szPath, "r");
	if(file == null)
		return;
	
	char szSymbols[][] =  { "//", "#", ";" };
	char szBuffer[PLATFORM_MAX_PATH];
	int i, pos;
	while(!file.EndOfFile())
	{
		file.ReadLine(szBuffer, sizeof(szBuffer));

		for(i = 0; i < sizeof(szSymbols); ++i)
		{
			while((pos = StrContains(szBuffer, szSymbols[i])) != -1)
				szBuffer[pos] = '\0';
		}

		TrimString(szBuffer);
		if(szBuffer[0] && FileExists(szBuffer))
			AddFileToDownloadsTable(szBuffer);
	}

	file.Close();
}

void RemoveSpawns(int client)
{
	float fOrigin[3], fAngles[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, fAngles);
	Handle trace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT|CONTENTS_OPAQUE, RayType_Infinite, TR_Filter_AimTarget);
	trace.Close();
}

public bool TR_Filter_AimTarget(int entity, int contentsMask)
{
	static char szTargetname[32];
	if((entity > MaxClients && GetEntPropString(entity, Prop_Data, "m_iName", szTargetname, sizeof(szTargetname)) &&
		StrEqual(szTargetname, "wpn_spwn")))
	{
		int trigger = GetEntPropEnt(entity, Prop_Data, "m_pParent");
		if(trigger == -1)
			return false;
		
		float fOrigin[3];
		GetEntPropVector(trigger, Prop_Send, "m_vecOrigin", fOrigin);
		int idx = g_PointConfig.FindPoint(fOrigin);
		if(idx != -1)
		{
			g_PointConfig.RemovePoint(idx);
			g_PointConfig.Save();

			AcceptEntityInput(trigger, "KillHierarchy");
		}
	}

	return (entity == 0);
}

stock void KillSpawns()
{
	int iEnt = -1;
	char szBuffer[32];
	while((iEnt = FindEntityByClassname(iEnt, "trigger_multiple")) != -1)
	{
		if(GetEntPropString(iEnt, Prop_Data, "m_iName", szBuffer, sizeof(szBuffer)) &&
			StrEqual(szBuffer, "wpn_spwn"))
		{
			AcceptEntityInput(iEnt, "KillHierarchy");
		}
	}
}

stock int FindWeapon(int client, CSWeaponID id)
{
	static int m_hMyWeapons = -1;
	if(m_hMyWeapons == -1)
		m_hMyWeapons = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");
	
	for (int i = 0, weapon; i <= 252; i += 4)
	{
		weapon = GetEntDataEnt2(client, m_hMyWeapons + i);
		if(weapon != -1 && CS_ItemDefIndexToID(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex")) == id)
			return weapon;
	}
	
	return -1;
}

bool GetEndPosition(int client, float fVec[3])
{
	float fOrigin[3], fAngles[3];
	GetClientEyePosition(client, fOrigin);
	GetClientEyeAngles(client, fAngles);
	Handle trace = TR_TraceRayFilterEx(fOrigin, fAngles, MASK_SHOT, RayType_Infinite, TR_Filter_Players);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(fVec, trace);
		trace.Close();
		return true;
	}
	trace.Close();
	return false;
}

public bool TR_Filter_Players(int entity, int contentsMask)
{
	return entity == 0 || entity > MaxClients;
}