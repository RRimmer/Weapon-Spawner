#if defined _weapon_spawner_use_counter_included
	#endinput
#endif
#define _weapon_spawner_use_counter_included

methodmap UseCounter < KeyValues
{
	public UseCounter()
	{
		return view_as<UseCounter>(new KeyValues("counter"));
	}

	public void Clear()
	{
		this.Rewind();
		if(this.GotoFirstSubKey())
		{
			while(this.DeleteThis() == 1) {}
		}
	}

	public bool IncUseCount(int client, int iEnt)
	{
		char szBuffer[16];
		int iEntRef = EntIndexToEntRef(iEnt);
		IntToString(iEntRef, szBuffer, sizeof(szBuffer));

		this.Rewind();
		if(this.JumpToKey(szBuffer, true))
		{
			IntToString(client, szBuffer, sizeof(szBuffer));
			int value = this.GetNum(szBuffer);
			this.SetNum(szBuffer, value + 1);
			return true;
		}
		return false;
	}

	public int GetUseCount(int client, int iEnt)
	{
		char szBuffer[16];
		int iEntRef = EntIndexToEntRef(iEnt);
		IntToString(iEntRef, szBuffer, sizeof(szBuffer));

		this.Rewind();
		if(this.JumpToKey(szBuffer))
		{
			IntToString(client, szBuffer, sizeof(szBuffer));
			return this.GetNum(szBuffer);
		}
		return 0;
	}

	public int GetTotal(int iEnt)
	{
		int total = 0;
		
		char szBuffer[16];
		int iEntRef = EntIndexToEntRef(iEnt);
		IntToString(iEntRef, szBuffer, sizeof(szBuffer));

		this.Rewind();
		if(this.JumpToKey(szBuffer) && this.GotoFirstSubKey(false))
		{
			do
			{ 
				total += this.GetNum(NULL_STRING); 
			}
			while(this.GotoNextKey(false));
		}

		return total;
	}
};
