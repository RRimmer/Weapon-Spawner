#if defined _weapon_spawner_timers_included
	#endinput
#endif
#define _weapon_spawner_timers_included

enum struct RemoveInfo
{
	Handle timer;
	int iEntRef;
	float spawn_time;
	float lifetime;
}

methodmap RemoveTimers < ArrayList
{
	public RemoveTimers()
	{
		return view_as<RemoveTimers>(new ArrayList(sizeof(RemoveInfo)));
	}

	public void AddRemoveInfo(RemoveInfo info)
	{
		this.PushArray(info, sizeof(info));
	}

	public void Remove(Handle timer)
	{
		int idx = this.FindValue(timer);
		if(idx != -1)
			this.Erase(idx);
	}

	public float GetTimeLeft(int iEntRef)
	{
		int idx = this.FindValue(iEntRef, 1);
		if(idx != -1)
		{
			RemoveInfo info;
			this.GetArray(idx, info, sizeof(info));
			return (info.spawn_time + info.lifetime) - GetGameTime();
		}
		return 0.0;
	}

	public void KillAndClear()
	{
		int size = this.Length;
		if(!size)
			return;
		
		for(int i = 0; i < size; ++i)
			KillTimer(this.Get(i));

		this.Clear();
	}
};

methodmap ReloadTimers < ArrayList
{
	public ReloadTimers()
	{
		return view_as<ReloadTimers>(new ArrayList());
	}

	public void Remove(Handle timer)
	{
		int idx = this.FindValue(timer);
		if(idx != -1)
			this.Erase(idx);
	}

	public void KillAndClear()
	{
		int size = this.Length;
		if(!size)
			return;
		
		for(int i = 0; i < size; ++i)
			KillTimer(this.Get(i));

		this.Clear();
	}
};