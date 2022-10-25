#pragma newdecls required
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma semicolon 1
Handle
	cvarServerNameFormatCase1 = INVALID_HANDLE,
	cvarMpGameMode = INVALID_HANDLE,
	cvarSI = INVALID_HANDLE,
	cvarMpGameMin = INVALID_HANDLE,
	HostName = INVALID_HANDLE,
	g_hHostName = INVALID_HANDLE,
	g_hMainName = INVALID_HANDLE,
	cvarHostPort = INVALID_HANDLE;
char
	SavePath[256],
	g_sDefaultN[68];
static Handle
	g_hHostNameFormat; 

public void OnPluginStart()
{
	HostName = CreateKeyValues("AnneHappy");
	BuildPath(Path_SM, SavePath, 255, "configs/hostname/hostname.txt");
	if (FileExists(SavePath))
	{
		FileToKeyValues(HostName, SavePath);
	}
	g_hHostName	= FindConVar("hostname");
	g_hMainName = CreateConVar("sn_main_name", "");
	if(FindConVar("l4d_infected_limit"))
		cvarSI = FindConVar("l4d_infected_limit");
	cvarMpGameMin = FindConVar("versus_special_respawn_interval");
	cvarHostPort = FindConVar("hostport");
	g_hHostNameFormat = CreateConVar("sn_hostname_format", "{hostname}{gamemode}");
	cvarServerNameFormatCase1 = CreateConVar("sn_hostname_format1", "{AnneHappy}{Full}{Confogl}");
	if(FindConVar("l4d_ready_cfg_name"))
		cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
	if(FindConVar("l4d_infected_limit"))
		HookConVarChange(cvarSI, OnCvarChanged);
	HookConVarChange(cvarMpGameMin, OnCvarChanged);
	if(FindConVar("l4d_ready_cfg_name"))
		HookConVarChange(cvarMpGameMode, OnCvarChanged);
	GetConVarString(g_hHostName, g_sDefaultN, sizeof(g_sDefaultN));
	if (strlen(g_sDefaultN))
		ChangeServerName();
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);
}

public void Event_PlayerTeam( Event hEvent, const char[] sName, bool bDontBroadcast )
{
	UpdateServerName();
}

public void OnMapStart()
{
	HostName = CreateKeyValues("AnneHappy");
	BuildPath(Path_SM, SavePath, 255, "configs/hostname/hostname.txt");
	FileToKeyValues(HostName, SavePath);
}

public void OnCvarChanged(Handle cvar, const char[] oldVal, const char[] newVal)
{
	UpdateServerName();
}

public void UpdateServerName(){
	char sReadyUpCfgName[128], FinalHostname[128], buffer[128];
	bool IsAnne = false;
	GetConVarString(cvarServerNameFormatCase1, FinalHostname, sizeof(FinalHostname));
	GetConVarString(cvarMpGameMode, sReadyUpCfgName, sizeof(sReadyUpCfgName));	
	if(StrContains(sReadyUpCfgName, "AnneHappy", false)!=-1){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[普通药役]");
		IsAnne = true;
	}	
	else if(StrContains(sReadyUpCfgName, "AllCharger", false)!=-1){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[牛牛冲刺]");
		IsAnne = true;
	}	
	else if(StrContains(sReadyUpCfgName, "Hunters", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[HT训练]");IsAnne = true;}
	else if(StrContains(sReadyUpCfgName, "WitchParty", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[女巫派对]");IsAnne = true;}
	else if(StrContains(sReadyUpCfgName, "Alone", false)!=-1)
		{ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","[单人装逼]");IsAnne = true;}
	else{
		if(FindConVar("l4d_ready_cfg_name")){
			GetConVarString(cvarMpGameMode, buffer, sizeof(buffer));
			Format(buffer, sizeof(buffer),"[%s]", buffer);
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}", buffer);
		}else{
			ReplaceString(FinalHostname, sizeof(FinalHostname), "{Confogl}","");
		}
	}
	if(FindConVar("l4d_infected_limit") && IsAnne){
		Format(buffer, sizeof(buffer),"[%d特%d秒]", GetConVarInt(cvarSI), GetConVarInt(cvarMpGameMin));
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}",buffer);
	}else{
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{AnneHappy}","");
	}
	if(IsTeamFull(IsAnne)){
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "");
	}else
	{
		ReplaceString(FinalHostname, sizeof(FinalHostname), "{Full}", "[缺人]");
	}
	ChangeServerName(FinalHostname);
}

bool IsTeamFull(bool IsAnne = false){
	int sum = 0;
	for(int i = 1; i <= MaxClients; i++){
		if(IsPlayer(i) && !IsFakeClient(i)){
			sum ++;
		}
	}
	if(sum == 0){
		return true;
	}
	if(IsAnne){
		return sum >= (GetConVarInt(FindConVar("survivor_limit")));
	}else{
		return sum >= (GetConVarInt(FindConVar("survivor_limit")) + GetConVarInt(FindConVar("z_max_player_zombies")));
	}
	
}
bool IsPlayer(int client)
{
	if(IsValidClient(client) && (GetClientTeam(client) == 2 || GetClientTeam(client) == 3)){
		return true;
	}
	else{
		return false;
	}
}

public void OnAllPluginsLoaded()
{
	cvarMpGameMode = FindConVar("l4d_infected_limit");
	cvarMpGameMin = FindConVar("versus_special_respawn_interval");
	cvarMpGameMode = FindConVar("l4d_ready_cfg_name");
}
public void OnConfigsExecuted()
{		
	if (!strlen(g_sDefaultN)) return;
		

	if (cvarMpGameMode == INVALID_HANDLE || cvarMpGameMin == INVALID_HANDLE)
	{
	
		ChangeServerName();
	}
	else 
	{
		UpdateServerName();
	}
	
}

void ChangeServerName(char[] sReadyUpCfgName = "")
{
	char sPath[128], ServerPort[128];
	GetConVarString(cvarHostPort, ServerPort, sizeof(ServerPort));
	KvJumpToKey(HostName, ServerPort, false);
	KvGetString(HostName,"servername", sPath, sizeof(sPath));
	KvGoBack(HostName);
	char sNewName[128];
	if(strlen(sReadyUpCfgName) == 0)
	{
		Format(sNewName, sizeof(sNewName), "%s", g_hMainName);
	}
	else
	{
		GetConVarString(g_hHostNameFormat, sNewName, sizeof(sNewName));
		ReplaceString(sNewName, sizeof(sNewName), "{hostname}", sPath);
		ReplaceString(sNewName, sizeof(sNewName), "{gamemode}", sReadyUpCfgName);
	}
	SetConVarString(g_hHostName,sNewName);
	Format(g_sDefaultN,sizeof(g_sDefaultN),"%s",sNewName);
}

public bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}