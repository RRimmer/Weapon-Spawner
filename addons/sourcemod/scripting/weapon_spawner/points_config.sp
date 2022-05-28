#if defined _weapon_spawner_points_config_included
	#endinput
#endif
#define _weapon_spawner_points_config_included

enum struct Point
{
	float vOrigin[3];
	char szName[128];
}

methodmap PointsConfig < ArrayList
{
	public PointsConfig()
	{
		return view_as<PointsConfig>(new ArrayList(sizeof(Point)));
	}

	public void Load()
	{
		char szBuffer[PLATFORM_MAX_PATH], szMap[64];
		GetCurrentMap(szMap, sizeof(szMap));
		ReplaceString(szMap, sizeof(szMap), "/", "_");
		BuildPath(Path_SM, szBuffer, sizeof(szBuffer), "configs/weapon_spawner/maps/%s.txt", szMap);
		if(!FileExists(szBuffer))
			return;
		
		KeyValues kv = new KeyValues("cfg");
		if(!kv.ImportFromFile(szBuffer))
		{
			LogError("Error reading config file '%s'.", szBuffer);
			return;
		}

		if(kv.GotoFirstSubKey())
		{
			Point point;

			do
			{
				kv.GetVector("origin", point.vOrigin);
				kv.GetString("name", point.szName, sizeof(point.szName));
				this.PushArray(point, sizeof(point));
			}
			while(kv.GotoNextKey());
		}

		kv.Close();
	}

	public void Save()
	{
		KeyValues kv = new KeyValues("cfg");

		int size = this.Length;
		if(size)
		{
			Point point;
			char szNum[16];
			for(int i = 0; i < size; ++i)
			{
				IntToString(i, szNum, sizeof(szNum));
				if(kv.JumpToKey(szNum, true))
				{
					this.GetArray(i, point, sizeof(point));
					kv.SetVector("origin", point.vOrigin);
					kv.SetString("name", point.szName);
					kv.GoBack();
				}
			}
		}

		char szPath[PLATFORM_MAX_PATH], szMap[64];
		GetCurrentMap(szMap, sizeof(szMap));
		ReplaceString(szMap, sizeof(szMap), "/", "_");
		BuildPath(Path_SM, szPath, sizeof(szPath), "configs/weapon_spawner/maps/%s.txt", szMap);

		kv.Rewind();
		kv.ExportToFile(szPath);
		kv.Close();
	}

	public void AddPoint(Point point)
	{
		this.PushArray(point, sizeof(point));
	}

	public int FindPoint(const float vVec[3])
	{
		float fVec[3];
		for(int i = 0; i < this.Length; ++i)
		{
			this.GetArray(i, fVec, sizeof(fVec));
			if(GetVectorDistance(fVec, vVec) < 0.001)
				return i;
		}
		return -1;
	}

	public void RemovePoint(int idx)
	{
		this.Erase(idx);
	}
};