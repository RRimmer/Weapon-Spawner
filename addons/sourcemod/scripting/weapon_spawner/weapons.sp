#if defined _weapon_spawner_weapons_included
	#endinput
#endif
#define _weapon_spawner_weapons_included

static const char g_szPrimaryWeapons[][] = {
	"weapon_m4a1",			"weapon_galilar", 
	"weapon_m4a1_silencer",	"weapon_m249", 
	"weapon_mp7",			"weapon_mac10", 
	"weapon_mp5sd",			"weapon_mag7", 
	"weapon_ak47",			"weapon_mp9", 
	"weapon_aug",			"weapon_negev", 
	"weapon_awp",			"weapon_nova", 
	"weapon_bizon",			"weapon_p90", 
	"weapon_famas",			"weapon_sawedoff", 
	"weapon_g3sg1",			"weapon_scar20", 
	"weapon_sg556",			"weapon_ssg08",
	"weapon_ump45",			"weapon_xm1014"
};

static const char g_szSecondaryWeapons[][] = {
	"weapon_cz75a",		"weapon_usp_silencer",
	"weapon_fiveseven",	"weapon_hkp2000",
	"weapon_deagle",	"weapon_revolver",
	"weapon_elite",		"weapon_glock",
	"weapon_p250",		"weapon_tec9"
};

static const char g_szGrenades[][] = {
	"weapon_tagrenade",		"weapon_molotov",
	"weapon_flashbang",		"weapon_incgrenade",
	"weapon_hegrenade",		"weapon_smokegrenade",
	"weapon_decoy"
};

static const char g_szExplosives[][] = {
	"weapon_bumpmine",
	"weapon_breachcharge"
};

static const char g_szMelee[][] = {
	"weapon_axe",
	"weapon_hammer",
	"weapon_spanner",
	"weapon_fists"
};

public void WS_OnLoaded()
{
	for(int i = 0; i < sizeof(g_szPrimaryWeapons); ++i)
		WS_Register(g_szPrimaryWeapons[i], OnGetPrimaryWeapon);
	
	for(int i = 0; i < sizeof(g_szSecondaryWeapons); ++i)
		WS_Register(g_szSecondaryWeapons[i], OnGetSecondaryWeapon);
	
	for(int i = 0; i < sizeof(g_szGrenades); ++i)
		WS_Register(g_szGrenades[i], OnGetGrenade);
	
	WS_Register("weapon_healthshot", OnGetHealthshot);
	WS_Register("weapon_taser", OnGetTaser);
	WS_Register("exojump", OnGetExoJump);

	WS_Register("item_kevlar", OnGetKevlar);
	WS_Register("item_assaultsuit", OnGetAssaultSuit);
	WS_Register("item_heavyassaultsuit", OnGetHeavyAssaultSuit);

	for(int i = 0; i < sizeof(g_szExplosives); ++i)
		WS_Register(g_szExplosives[i], OnGetExplosives);
	
	WS_Register("weapon_shield", OnGetShield);

	for(int i = 0; i < sizeof(g_szMelee); ++i)
		WS_Register(g_szMelee[i], OnGetMelee);
}

public bool OnGetPrimaryWeapon(int client, int id, const char[] name)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_PRIMARY);
	if(weapon != -1)
		CS_DropWeapon(client, weapon, true, true);
	
	return GivePlayerItem(client, name) != -1;
}

public bool OnGetSecondaryWeapon(int client, int id, const char[] name)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(weapon != -1)
		CS_DropWeapon(client, weapon, true, true);
	
	return GivePlayerItem(client, name) != -1;
}

public bool OnGetGrenade(int client, int id, const char[] name)
{
	CSWeaponID weapon_id = CS_AliasToWeaponID(name[7]);
	int weapon = FindWeapon(client, weapon_id);
	if(weapon != -1)
	{
		int ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, ammo_type);
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo + 1, _, ammo_type);
	}
	else
	{
		weapon = GivePlayerItem(client, name);
		if(weapon != -1)
			EquipPlayerWeapon(client, weapon);
	}

	return true;
}

public bool OnGetHealthshot(int client, int id, const char[] name)
{
	int weapon = FindWeapon(client, CSWeapon_HEALTHSHOT);
	if(weapon != -1)
	{
		int ammo_type = GetEntProp(weapon, Prop_Send, "m_iPrimaryAmmoType");
		int ammo = GetEntProp(client, Prop_Data, "m_iAmmo", _, ammo_type);
		SetEntProp(client, Prop_Data, "m_iAmmo", ammo + 1, _, ammo_type);
	}
	else
	{
		GivePlayerItem(client, name);
	}

	return true;
}

public bool OnGetTaser(int client, int id, const char[] name)
{
	int weapon = FindWeapon(client, CSWeapon_TASER);
	if(weapon != -1)
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_iClip1");
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo + 1);
	}
	else
	{
		GivePlayerItem(client, name);
	}

	return true;
}

public bool OnGetExoJump(int client, int id, const char[] name)
{
	if(!GetEntProp(client, Prop_Send, "m_passiveItems", 1, 1))
	{
		SetEntProp(client, Prop_Send, "m_passiveItems", 1, 1, 1);
		return true;
	}
	return false;
}

public bool OnGetKevlar(int client, int id, const char[] name)
{
	if(GetEntProp(client, Prop_Send, "m_ArmorValue") < 100)
	{
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		return true;
	}
	return false;
}

public bool OnGetAssaultSuit(int client, int id, const char[] name)
{
	if(!GetEntProp(client, Prop_Send, "m_bHasHelmet", 1) || GetEntProp(client, Prop_Send, "m_ArmorValue") < 100)
	{
		SetEntProp(client, Prop_Send, "m_bHasHelmet", 1, 1);
		SetEntProp(client, Prop_Send, "m_ArmorValue", 100);
		return true;
	}
	return false;
}

public bool OnGetHeavyAssaultSuit(int client, int id, const char[] name)
{
	return GivePlayerItem(client, name) != -1;
}

public bool OnGetExplosives(int client, int id, const char[] name)
{
	CSWeaponID weapon_id = CS_AliasToWeaponID(name[7]);
	int weapon = FindWeapon(client, weapon_id);
	if(weapon != -1)
	{
		int ammo = GetEntProp(weapon, Prop_Send, "m_iClip1");
		SetEntProp(weapon, Prop_Send, "m_iClip1", ammo + 1);
	}
	else
	{
		int mine = GivePlayerItem(client, name);
		if(mine != -1)
		{
			EquipPlayerWeapon(client, mine);
			SetEntProp(weapon, Prop_Send, "m_iClip1", 1);
		}
	}

	return true;
}

public bool OnGetShield(int client, int id, const char[] name)
{
	int weapon = FindWeapon(client, CSWeapon_SHIELD);
	if(weapon != -1)
		return false;
	
	int shield = GivePlayerItem(client, "weapon_shield");
	if(shield != -1)
	{
		EquipPlayerWeapon(client, shield);
		return true;
	}

	return false;
}

public bool OnGetMelee(int client, int id, const char[] name)
{
	int active_weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	int weapon = FindMeleeWeapon(client);
	if(weapon != -1)
	{
		CSWeaponID weapon_id = CS_ItemDefIndexToID(GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex"));
		CSWeaponID melee_id = CS_AliasToWeaponID(name[7]);
		if(weapon_id == melee_id)		// Same weapon type
			return false;
		
		RemovePlayerItem(client, weapon);
	}

	int melee = GivePlayerItem(client, name);
	if(melee != -1)
	{
		EquipPlayerWeapon(client, melee);

		if(weapon != -1 && weapon == active_weapon)
			FakeClientCommand(client, "use %s", name);

		return true;
	}

	return false;
}