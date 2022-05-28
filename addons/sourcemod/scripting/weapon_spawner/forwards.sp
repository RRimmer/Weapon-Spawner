#if defined _weapon_spawner_forwards_included
	#endinput
#endif
#define _weapon_spawner_forwards_included

GlobalForward g_OnLoadedFwd = null;

void RegisterForwards()
{
	g_OnLoadedFwd = new GlobalForward("WS_OnLoaded", ET_Ignore);
}

void Fwd_OnLoaded()
{
	Call_StartForward(g_OnLoadedFwd);
	Call_Finish();
}