#if defined _weapon_spawner_config_included
	#endinput
#endif
#define _weapon_spawner_config_included

methodmap Config < KeyValues
{
	public Config()
	{
		char szBuffer[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/weapon_spawner/weapon_spawner.txt");
		if(!FileExists(szBuffer))
		{
			SetFailState("Config file '%s' is not exists", szBuffer);
			return null;
		}

		KeyValues kv = new KeyValues("weapon_spawner");
		if(!kv.ImportFromFile(szBuffer))
		{
			SetFailState("Error reading config file '%s'. Check syntax.", szBuffer);
			return null;
		}

		return view_as<Config>(kv);
	}

	public bool GetTypeName(int id, char[] szName, int maxlen)
	{
		this.Rewind();
		return this.FindKeyById(id, szName, maxlen);
	}

	public int AddSpawnTypesToMenu(Menu menu)
	{
		int total = 0;

		this.Rewind();
		if(this.GotoFirstSubKey())
		{
			int id;
			char szInfo[128], szDisplay[128];

			do
			{
				this.GetSectionName(szDisplay, sizeof(szDisplay));
				this.GetSectionSymbol(id);
				IntToString(id, szInfo, sizeof(szInfo));
				menu.AddItem(szInfo, szDisplay);
				++total;
			}
			while(this.GotoNextKey());
		}

		return total;
	}

	public int AddItemsToMenu(int id, Menu menu)
	{
		int total = 0;

		this.Rewind();
		if(this.JumpToKeySymbol(id) && this.JumpToKey("items") && this.GotoFirstSubKey(false))
		{
			char szInfo[128], szDisplay[128];

			do
			{
				this.GetSectionName(szDisplay, sizeof(szDisplay));
				this.GetString(NULL_STRING, szInfo, sizeof(szInfo));
				menu.AddItem(szInfo, szDisplay);
				++total;
			}
			while(this.GotoNextKey(false));
		}

		return total;
	}

	public void PrecacheModels()
	{
		this.Rewind();

		char szBuffer[PLATFORM_MAX_PATH];
		this.GetString("bottom_model", szBuffer, sizeof(szBuffer));
		if(szBuffer[0])
			PrecacheModel(szBuffer);

		if(this.GotoFirstSubKey())
		{
			do
			{
				this.GetString("prop_model", szBuffer, sizeof(szBuffer));
				if(szBuffer[0])
					PrecacheModel(szBuffer);
				
				this.GetString("sprite_model", szBuffer, sizeof(szBuffer));
				if(szBuffer[0])
					PrecacheModel(szBuffer);
			}
			while(this.GotoNextKey());
		}
	}

	public void PrecacheSounds()
	{
		char szKeys[][] = {"sound_reload_start", "sound_reload_finish"};
		char szBuffer[PLATFORM_MAX_PATH];
		this.Rewind();
		for(int i = 0; i < sizeof(szKeys); ++i)
		{
			this.GetString(szKeys[i], szBuffer, sizeof(szBuffer));
			if(szBuffer[0])
			{
				PrecacheSound(szBuffer);
				Format(szBuffer, sizeof(szBuffer), "sound/%s", szBuffer);
				if(FileExists(szBuffer))
					AddFileToDownloadsTable(szBuffer);
			}
		}
	}

	public void GetReloadStartSound(char[] szSound, int maxlength)
	{
		this.Rewind();
		this.GetString("sound_reload_start", szSound, maxlength);
	}

	public void GetReloadFinishSound(char[] szSound, int maxlength)
	{
		this.Rewind();
		this.GetString("sound_reload_finish", szSound, maxlength);
	}

	public int GetPrice(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetNum("price", -1) : -1;
	}

	public int GetId(const char[] szName)
	{
		this.Rewind();
		if(this.JumpToKey(szName))
		{
			int id;
			this.GetSectionSymbol(id);
			return id;
		}
		return 0;
	}

	public void GetBottomModel(char[] szModel, int maxlength)
	{
		this.Rewind();
		this.GetString("bottom_model", szModel, maxlength);
	}

	public int GetBottomSkin()
	{
		this.Rewind();
		return this.GetNum("bottom_skin");
	}

	public void GetPropInfo(int id, float fAngles[3], char[] szModel, int maxlength, float &heigth)
	{
		this.Rewind();
		if(this.JumpToKeySymbol(id))
		{
			this.GetVector("prop_angles", fAngles);
			this.GetString("prop_model", szModel, maxlength);
			heigth = this.GetFloat("prop_height", 40.0);
		}
	}

	public void GetSpriteInfo(int id, char[] szMaterial, int maxlength, float &heigth, float &scale)
	{
		this.Rewind();
		if(this.JumpToKeySymbol(id))
		{
			this.GetString("sprite_model", szMaterial, maxlength);
			heigth = this.GetFloat("sprite_heigth", 40.0);
			scale = this.GetFloat("sprite_scale", 1.0);
		}
	}

	public float GetLifetime(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetFloat("time") : 0.0;
	}

	public int GetMenuType(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetNum("menu") : -1;
	}

	public int GetItemCount(int id)
	{
		int count = 0;
		this.Rewind();
		if(this.JumpToKeySymbol(id) && this.JumpToKey("items") && this.GotoFirstSubKey(false))
		{
			do{ ++count; }while(this.GotoNextKey(false));
		}
		return count;
	}

	public bool GetRandomItem(int id, char[] szName, int name_len, char[] szItem, int item_len)
	{
		int count = this.GetItemCount(id);
		if(!count)
			return false;
		
		this.Rewind();
		if(this.JumpToKeySymbol(id) && this.JumpToKey("items") && this.GotoFirstSubKey(false))
		{
			int rand = GetRandomInt(0, count - 1);
			for(int i = 0; i < rand; ++i)
				this.GotoNextKey(false);

			this.GetSectionName(szName, name_len);
			this.GetString(NULL_STRING, szItem, item_len);
			return true;
		}

		return false;
	}

	public void GetTypeColor(int id, char[] szColor, int maxlength)
	{
		this.Rewind();
		if(this.JumpToKeySymbol(id))
			this.GetString("color", szColor, maxlength, "255 255 255");
		else
			strcopy(szColor, maxlength, "255 255 255");
	}

	public float GetReloadTime(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetFloat("reload_time") : 0.0;
	}

	public int GetLimit(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetNum("limit") : 0;
	}

	public int GetLimitPerPlayer(int id)
	{
		this.Rewind();
		return this.JumpToKeySymbol(id) ? this.GetNum("limit_player") : 0;
	}
};