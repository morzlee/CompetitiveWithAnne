#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <caster_system>
#include <l4dstats>
enum L4D2Team
{
	L4D2Team_None = 0,
	L4D2Team_Spectator,
	L4D2Team_Survivor,
	L4D2Team_Infected
};

new bool:readyUpIsAvailable;
new bool:g_bl4dstatsSystemAvailable;
new Handle:sv_mincmdrate;
new Handle:sv_maxcmdrate;
new Handle:sv_minupdaterate;
new Handle:sv_maxupdaterate;
new Handle:sv_minrate;
new Handle:sv_maxrate;
new Handle:sv_client_min_interp_ratio;
new Handle:sv_client_max_interp_ratio;

new String:netvars[8][8];

new Float:fLastAdjusted[MAXPLAYERS + 1];

public Plugin:myinfo =
{
    name = "Lightweight Spectating",
    author = "Visor",
    description = "Forces low rates on spectators",
    version = "1.2.1",
    url = "https://github.com/SirPlease/L4D2-Competitive-Rework"
};

public OnPluginStart()
{
    sv_mincmdrate = FindConVar("sv_mincmdrate");
    sv_maxcmdrate = FindConVar("sv_maxcmdrate");
    sv_minupdaterate = FindConVar("sv_minupdaterate");
    sv_maxupdaterate = FindConVar("sv_maxupdaterate");
    sv_minrate = FindConVar("sv_minrate");
    sv_maxrate = FindConVar("sv_maxrate");
    sv_client_min_interp_ratio = FindConVar("sv_client_min_interp_ratio");
    sv_client_max_interp_ratio = FindConVar("sv_client_max_interp_ratio");
    RegConsoleCmd("sm_specrates", SetRates, "当你分数大于30w可以手动输入这个指令来设置旁观100tick");
    RegAdminCmd("sm_adminrates", AdminSetRates, ADMFLAG_GENERIC, "管理员手动提升100tick");
    HookEvent("player_team", OnTeamChange);
}

public Action SetRates(int client, int args)
{ 
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(g_bl4dstatsSystemAvailable && l4dstats_GetClientScore(client) < 300000 )
	{
		PrintToChat(client, "你的分数小于30W，无法设置旁观速率");
		return Plugin_Handled;
	}
	if( getSpecNum() > 4)
	{
		PrintToChat(client, "旁观超过4人无法设置100tick旁观速率");
		return Plugin_Handled;
	}
	AdjustRates(client);
	return Plugin_Continue;	
}
public Action AdminSetRates(int client, int args)
{ 
	if(!IsValidClient(client))
		return Plugin_Continue;
	AdjustRates(client);
	return Plugin_Continue;	
}

public OnPluginEnd()
{
    SetConVarString(sv_minupdaterate, netvars[2]);
    SetConVarString(sv_mincmdrate, netvars[0]);
}

public OnAllPluginsLoaded()
{
    readyUpIsAvailable = LibraryExists("caster_system");
    g_bl4dstatsSystemAvailable = LibraryExists("l4d_stats");
}

public OnLibraryRemoved(const String:name[])
{
    if (StrEqual(name, "caster_system", true))
    {
        readyUpIsAvailable = false;
    }
    else if ( StrEqual(name, "l4d_stats") ) { g_bl4dstatsSystemAvailable = true; }
}

public OnLibraryAdded(const String:name[])
{
    if (StrEqual(name, "caster_system", true))
    {
        readyUpIsAvailable = true;
    }
    else if ( StrEqual(name, "l4d_stats") ) { g_bl4dstatsSystemAvailable = false; }
}

public OnConfigsExecuted()
{
    GetConVarString(sv_mincmdrate, netvars[0], 8);
    GetConVarString(sv_maxcmdrate, netvars[1], 8);
    GetConVarString(sv_minupdaterate, netvars[2], 8);
    GetConVarString(sv_maxupdaterate, netvars[3], 8);
    GetConVarString(sv_minrate, netvars[4], 8);
    GetConVarString(sv_maxrate, netvars[5], 8);
    GetConVarString(sv_client_min_interp_ratio, netvars[6], 8);
    GetConVarString(sv_client_max_interp_ratio, netvars[7], 8);

    SetConVarInt(sv_minupdaterate, 30);
    SetConVarInt(sv_mincmdrate, 30);
}

public OnClientPutInServer(client)
{
	fLastAdjusted[client] = 0.0;
	if(getSpecNum() > 4){
		for(int i = 1; i <= MaxClients; i++){
			if(IsValidClient(i) && IsClientInGame(i) && GetClientTeam(i) == 1 && GetUserAdmin(i) == INVALID_ADMIN_ID){
				SetSpectatorRates(i);
			}
    	}
    }
}

stock int getSpecNum(){
    int count = 0;
    for(int i = 1; i <= MaxClients; i++){
        if(IsValidClient(i) && IsClientInGame(i) && GetClientTeam(i) == 3){
            count ++;
        }
    }
    return count;
}


public OnTeamChange(Handle:event, String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    CreateTimer(10.0, TimerAdjustRates, client, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:TimerAdjustRates(Handle:timer, any:client)
{
    AdjustRates(client);
    return Plugin_Handled;
}

public OnClientSettingsChanged(client) 
{
    AdjustRates(client);
}

AdjustRates(client)
{
    if (!IsValidClient(client))
        return;

    if (fLastAdjusted[client] < GetEngineTime() - 1.0)
    {
        fLastAdjusted[client] = GetEngineTime();

        new L4D2Team:team = L4D2Team:GetClientTeam(client);
        if (team == L4D2Team_Survivor || team == L4D2Team_Infected || (readyUpIsAvailable && IsClientCaster(client)) || (g_bl4dstatsSystemAvailable && l4dstats_GetClientScore(client) >= 300000) || GetUserAdmin(client) != INVALID_ADMIN_ID)
        {
            ResetRates(client);
        }
        else if (team == L4D2Team_Spectator)
        {
            SetSpectatorRates(client);
        }
    }
}

SetSpectatorRates(client)
{
    SendConVarValue(client, sv_mincmdrate, "30");
    SendConVarValue(client, sv_maxcmdrate, "30");
    SendConVarValue(client, sv_minupdaterate, "30");
    SendConVarValue(client, sv_maxupdaterate, "30");
    SendConVarValue(client, sv_minrate, "10000");
    SendConVarValue(client, sv_maxrate, "10000");

    SetClientInfo(client, "cl_updaterate", "30");
    SetClientInfo(client, "cl_cmdrate", "30");
}

ResetRates(client)
{
    SendConVarValue(client, sv_mincmdrate, netvars[0]);
    SendConVarValue(client, sv_maxcmdrate, netvars[1]);
    SendConVarValue(client, sv_minupdaterate, netvars[2]);
    SendConVarValue(client, sv_maxupdaterate, netvars[3]);
    SendConVarValue(client, sv_minrate, netvars[4]);
    SendConVarValue(client, sv_maxrate, netvars[5]);

    SetClientInfo(client, "cl_updaterate", netvars[3]);
    SetClientInfo(client, "cl_cmdrate", netvars[1]);
}

bool:IsValidClient(client)
{
    return client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}