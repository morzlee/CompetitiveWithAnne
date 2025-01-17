#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <builtinvotes>
#include <colors>
#include <left4dhooks>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util_rounds>
#undef REQUIRE_PLUGIN
//#include <readyup>
#include <l4d2_boss_percents>
#include <witch_and_tankifier>

#define PLUGIN_VERSION "3.2.6"

public Plugin myinfo =
{
	name = "[L4D2] Vote Boss",
	author = "Spoon, Forgetest",
	version = PLUGIN_VERSION,
	description = "Votin for boss change.",
	url = "https://github.com/spoon-l4d2"
};

Handle
	g_forwardUpdateBosses;

ConVar
	g_hCvarBossVoting,
	g_hCvarBossVotingLimit;

bool
	bv_bTank,
	bv_bWitch;

int
	bv_iTank,
	g_iRound,
	bv_iWitch;

public void OnPluginStart()
{
	LoadTranslations("l4d_boss_vote.phrases");
	g_forwardUpdateBosses = CreateGlobalForward("OnUpdateBosses", ET_Ignore, Param_Cell, Param_Cell);
	
	g_hCvarBossVoting = CreateConVar("l4d_boss_vote", "1", "Enable boss voting", FCVAR_NOTIFY, true, 0.0, true, 1.0); // Sets if boss voting is enabled or disabled
	g_hCvarBossVotingLimit = CreateConVar("l4d_boss_vote_limit", "0", "Enable boss voting after limit round", FCVAR_NOTIFY, true, 0.0); 

	HookEvent("map_transition", ResetRound, EventHookMode_PostNoCopy);
	
	RegConsoleCmd("sm_voteboss", VoteBossCmd); // Allows players to vote for custom boss spawns
	RegConsoleCmd("sm_bossvote", VoteBossCmd); // Allows players to vote for custom boss spawns
	
	RegAdminCmd("sm_ftank", ForceTankCommand, ADMFLAG_BAN);
	RegAdminCmd("sm_fwitch", ForceWitchCommand, ADMFLAG_BAN);

	g_iRound = 0;
}

public void ResetRound(Handle event, const char[] name, bool dontBroadcast)
{
	g_iRound = 0;
}

public Action L4D_OnFirstSurvivorLeftSafeArea(int client){
	g_iRound += 1;
	return Plugin_Continue;
}

public bool Reachlimit()
{
	if(FindConVar("l4d_infected_limit") && GetConVarInt(FindConVar("l4d_infected_limit")) > 8)
	{
		return false;
	}
	if(g_iRound < g_hCvarBossVotingLimit.IntValue)
	{
		return false;
	}
	return true;
}

bool RunVoteChecks(int client)
{
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "%t %t", "Tag", "NotAvailable");
		return false;
	}
	//if (!IsInReady())
	//{
		//CPrintToChat(client, "%t %t", "Tag", "Available");
		//return false;
	//}
	if (InSecondHalfOfRound())
	{
		CPrintToChat(client, "%t %t", "Tag", "FirstRound");
		return false;
	}
	if (GetClientTeam(client) == 1)
	{
		CPrintToChat(client, "%t %t", "Tag", "NotAvailableForSpec");
		return false;
	}
	if (!IsNewBuiltinVoteAllowed())
	{
		CPrintToChat(client, "%t %t", "Tag", "CannotBeCalled");
		return false;
	}
	if(!Reachlimit())
	{
		CPrintToChat(client, "%t %t", "Tag", "RoundNotReachLimit", g_hCvarBossVotingLimit.IntValue - g_iRound);
		return false;
	}
	return true;
}

public Action VoteBossCmd(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) {
		return Plugin_Handled;
	}
	
	if (!RunVoteChecks(client)) {
		return Plugin_Handled;
	}

	if (args != 2)
	{
		CReplyToCommand(client, "%t", "Usage");
		CReplyToCommand(client, "%t", "Usage2");
		return Plugin_Handled;
	}
	
	// Get all non-spectating players
	int iNumPlayers;
	int[] iPlayers = new int[MaxClients];
	for (int i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i) || (GetClientTeam(i) == 1))
		{
			continue;
		}
		iPlayers[iNumPlayers++] = i;
	}
	
	// Get Requested Boss Percents
	char bv_sTank[8];
	char bv_sWitch[8];
	GetCmdArg(1, bv_sTank, 8);
	GetCmdArg(2, bv_sWitch, 8);
	
	bv_iTank = -1;
	bv_iWitch = -1;
	
	// Make sure the args are actual numbers
	if (!IsInteger(bv_sTank) || !IsInteger(bv_sWitch))
	{
		CReplyToCommand(client, "%t %t", "Tag", "Invalid");
		return Plugin_Handled;
	}
	
	// Check to make sure static bosses don't get changed
	if (!IsStaticTankMap())
	{
		bv_bTank = (bv_iTank = StringToInt(bv_sTank)) > 0;
	}
	else
	{
		bv_bTank = false;
		CReplyToCommand(client, "%t %t", "Tag", "TankStatic");
	}
	
	if (!IsStaticWitchMap())
	{
		bv_bWitch = (bv_iWitch = StringToInt(bv_sWitch)) > 0;
	}
	else
	{
		bv_bWitch = false;
		CReplyToCommand(client, "%t %t", "Tag", "WitchStatic");
	}
	
	// Check if percent is within limits
	if (bv_bTank && !IsTankPercentValid(bv_iTank))
	{
		bv_bTank = false;
		CReplyToCommand(client, "%t %t", "Tag", "TankBanned");
	}
	
	if (bv_bWitch && !IsWitchPercentValid(bv_iWitch, true))
	{
		bv_bWitch = false;
		CReplyToCommand(client, "%t %t", "Tag", "WitchBanned");
	}
	
	char bv_voteTitle[64];
	
	// Set vote title
	if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
	{
		Format(bv_voteTitle, 64, "%T", "SetBosses", LANG_SERVER, bv_sTank, bv_sWitch);
	}
	else if (bv_bTank)	// Only Tank can be changed
	{
		if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "%T", "SetTank", LANG_SERVER, bv_sTank);
		}
		else
		{
			Format(bv_voteTitle, 64, "%T", "SetOnlyTank", LANG_SERVER, bv_sTank);
		}
	}
	else if (bv_bWitch) // Only Witch can be changed
	{
		if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "%T", "SetWitch", LANG_SERVER, bv_sWitch);
		}
		else
		{
			Format(bv_voteTitle, 64, "%T", "SetOnlyWitch", LANG_SERVER, bv_sWitch);
		}
	}
	else // Neither can be changed... ok...
	{
		if (bv_iTank == 0 && bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "%T", "SetBossesDisabled", LANG_SERVER);
		}
		else if (bv_iTank == 0)
		{
			Format(bv_voteTitle, 64, "%T", "SetTankDisabled", LANG_SERVER);
		}
		else if (bv_iWitch == 0)
		{
			Format(bv_voteTitle, 64, "%T", "SetWitchDisabled", LANG_SERVER);
		}
		else // Probably not.
		{
			return Plugin_Handled;
		}
	}
	
	// Start the vote!
	Handle bv_hVote = CreateBuiltinVote(BossVoteActionHandler, BuiltinVoteType_Custom_YesNo, BuiltinVoteAction_Cancel | BuiltinVoteAction_VoteEnd | BuiltinVoteAction_End);
	SetBuiltinVoteArgument(bv_hVote, bv_voteTitle);
	SetBuiltinVoteInitiator(bv_hVote, client);
	SetBuiltinVoteResultCallback(bv_hVote, BossVoteResultHandler);
	DisplayBuiltinVote(bv_hVote, iPlayers, iNumPlayers, 20);
	FakeClientCommand(client, "Vote Yes");

	return Plugin_Handled;
}

public void BossVoteActionHandler(Handle vote, BuiltinVoteAction action, int param1, int param2)
{
	switch (action)
	{
		case BuiltinVoteAction_End:
		{
			CloseHandle(vote);
		}
		case BuiltinVoteAction_Cancel:
		{
			DisplayBuiltinVoteFail(vote, view_as<BuiltinVoteFailReason>(param1));
		}
	}
}

public void BossVoteResultHandler(Handle vote, int num_votes, int num_clients, const int[][] client_info, int num_items, const int[][] item_info)
{
	for (int i=0; i<num_items; i++)
	{
		if (item_info[i][BUILTINVOTEINFO_ITEM_INDEX] == BUILTINVOTES_VOTE_YES)
		{
			if (item_info[i][BUILTINVOTEINFO_ITEM_VOTES] > (num_clients / 2))
			{
			
//				// One last ready-up check.
//				if (!IsInReady())  {
//					DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
//					CPrintToChatAll("%t", "OnlyReadyUp");
//					return;
//				}
				
				if (bv_bTank && bv_bWitch)	// Both Tank and Witch can be changed 
				{
					char buffer[64];
					Format(buffer, sizeof(buffer), "%T", "SettingBoss", LANG_SERVER);
					DisplayBuiltinVotePass(vote, buffer);
				}
				else if (bv_bTank)	// Only Tank can be changed -- Witch must be static
				{
					char buffer[64];
					Format(buffer, sizeof(buffer), "%T", "SettingTank", LANG_SERVER);
					DisplayBuiltinVotePass(vote, buffer);
				}
				else if (bv_bWitch) // Only Witch can be changed -- Tank must be static
				{
					char buffer[64];
					Format(buffer, sizeof(buffer), "%T", "SettingWitch", LANG_SERVER);
					DisplayBuiltinVotePass(vote, buffer);
				}
				else // Neither can be changed... ok...
				{
					char buffer[64];
					Format(buffer, sizeof(buffer), "%T", "SettingBossDisabled", LANG_SERVER);
					DisplayBuiltinVotePass(vote, buffer);
				}
				
				SetWitchPercent(bv_iWitch);
				SetTankPercent(bv_iTank);
				
				if (bv_iWitch == 0)
				{
					SetWitchDisabled(true);
				}
				
				if (bv_iTank == 0)
				{
					SetTankDisabled(true);
				}
				
				// Update our shiz yo
				UpdateBossPercents();
				
				// Forward da message man :)
				Call_StartForward(g_forwardUpdateBosses);
				Call_PushCell(bv_iTank);
				Call_PushCell(bv_iWitch);
				Call_Finish();
				
				return;
			}
		}
	}
	
	// Vote Failed
	DisplayBuiltinVoteFail(vote, BuiltinVoteFail_Loses);
	return;
}

bool IsInteger(const char[] buffer)
{
	// negative check
	if ( !IsCharNumeric(buffer[0]) && buffer[0] != '-' )
		return false;
	
	int len = strlen(buffer);
	for (int i = 1; i < len; i++)
	{
		if ( !IsCharNumeric(buffer[i]) )
			return false;
	}

	return true;
}

/* ========================================================
// ==================== Admin Commands ====================
// ========================================================
 *
 * Where the admin commands for setting boss spawns will go
 *
 * vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
*/

public Action ForceTankCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) {
		return Plugin_Handled;
	}
	
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "%t", "CommandNotAvailable");
		return Plugin_Handled;
	}
	
	if (IsStaticTankMap())
	{
		CPrintToChat(client, "%t", "TankSpawnStatic");
		return Plugin_Handled;
	}
	
//	if (!IsInReady())
//	{
//		CPrintToChat(client, "%t", "OnlyReadyUp");
//		return Plugin_Handled;
//}
	
	// Get Requested Tank Percent
	char bv_sTank[32];
	GetCmdArg(1, bv_sTank, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sTank))
		return Plugin_Handled;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sTank);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "%t", "PercentageInvalid");
		return Plugin_Handled;
	}
	
	// Check if percent is within limits
	if (!IsTankPercentValid(p_iRequestedPercent))
	{
		CPrintToChat(client, "%t", "Percentagebanned");
		return Plugin_Handled;
	}
	
	// Set the boss
	SetTankPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("%t", "TankSpawnAdmin", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	UpdateBossPercents();
	
	// Forward da message man :)
	Call_StartForward(g_forwardUpdateBosses);
	Call_PushCell(p_iRequestedPercent);
	Call_PushCell(-1);
	Call_Finish();

	return Plugin_Handled;
}

public Action ForceWitchCommand(int client, int args)
{
	if (!GetConVarBool(g_hCvarBossVoting)) {
		return Plugin_Handled;
	}
	
	if (IsDarkCarniRemix())
	{
		CPrintToChat(client, "%t", "CommandNotAvailable");
		return Plugin_Handled;
	}
	
	if (IsStaticWitchMap())
	{
		CPrintToChat(client, "%t", "WitchSpawnStatic");
		return Plugin_Handled;
	}
	
	//if (!IsInReady())
	//{
		//CPrintToChat(client, "%t", "OnlyReadyUp");
		//return Plugin_Handled;
	//}
	
	// Get Requested Witch Percent
	char bv_sWitch[32];
	GetCmdArg(1, bv_sWitch, 32);
	
	// Make sure the cmd argument is a number
	if (!IsInteger(bv_sWitch))
		return Plugin_Handled;
	
	// Convert it to in int boy
	int p_iRequestedPercent = StringToInt(bv_sWitch);
	
	if (p_iRequestedPercent < 0)
	{
		CPrintToChat(client, "%t", "PercentageInvalid");
		return Plugin_Handled;
	}
	
	// Check if percent is within limits
	if (!IsWitchPercentValid(p_iRequestedPercent))
	{
		CPrintToChat(client, "%t", "Percentagebanned");
		return Plugin_Handled;
	}
	
	// Set the boss
	SetWitchPercent(p_iRequestedPercent);
	
	// Let everybody know
	char clientName[32];
	GetClientName(client, clientName, sizeof(clientName));
	CPrintToChatAll("%t", "WitchSpawnAdmin", p_iRequestedPercent, clientName);
	
	// Update our shiz yo
	UpdateBossPercents();
	
	// Forward da message man :)
	Call_StartForward(g_forwardUpdateBosses);
	Call_PushCell(-1);
	Call_PushCell(p_iRequestedPercent);
	Call_Finish();

	return Plugin_Handled;
}
