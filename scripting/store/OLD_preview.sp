
enum playerPreview {
	skinIndex, 
	particleSkinIndex, 
	particleIndex, 
	previewTimes, 
	iTrackClient,
	iTrackModel,
	iTrackParticle,
}

int playerOptions[MAXPLAYERS + 1][playerPreview];
float g_fPreviewTime = 15.0;

#define SF_NOUSERCONTROL    2
#define SF_PASSABLE         8


public void Preview_OnPluginStart() {
	
}

public void previewItemToPlayer(int client, int itemid) {
	PrintToChat(client, "%s %s", g_eItems[itemid][szName], g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	char itemtype[64];
	strcopy(itemtype, sizeof(itemtype), g_eTypeHandlers[g_eItems[itemid][iHandler]][szType]);
	if (StrEqual(itemtype, "playerskin")) {
		previewSkin(client, itemid);
	} else if (StrEqual(itemtype, "Aura")) {
		previewParticle(client, itemid);
	} else if(StrEqual(itemtype, "Particles")) {
		createTrackTrainPreview(client, itemid);
	}
}

public void Preview_OnClientPostAdminCheck(int client) {
	playerOptions[client][skinIndex] = -1;
	playerOptions[client][particleSkinIndex] = -1;
	playerOptions[client][particleIndex] = -1;
	playerOptions[client][previewTimes] = -1;
	playerOptions[client][iTrackClient] = -1;
	playerOptions[client][iTrackModel] = -1;
	playerOptions[client][iTrackParticle] = -1;
}

public void resetAllPreviews(int client) {
	killTrainPreviewImmidiatly(client);
}

void previewSkin(int client, int itemid) {
	resetAllPreviews(client);
	int m_iViewModel = CreateEntityByName("prop_dynamic");
	char m_szTargetName[32];
	Format(m_szTargetName, 32, "Store_Preview_%d", m_iViewModel);
	DispatchKeyValue(m_iViewModel, "targetname", m_szTargetName);
	DispatchKeyValue(m_iViewModel, "spawnflags", "64");
	DispatchKeyValue(m_iViewModel, "model", g_eItems[itemid][szUniqueId]);
	DispatchKeyValue(m_iViewModel, "rendermode", "0");
	DispatchKeyValue(m_iViewModel, "renderfx", "0");
	DispatchKeyValue(m_iViewModel, "rendercolor", "255 255 255");
	DispatchKeyValue(m_iViewModel, "renderamt", "255");
	DispatchKeyValue(m_iViewModel, "solid", "0");
	
	DispatchSpawn(m_iViewModel);
	
	SetEntProp(m_iViewModel, Prop_Send, "m_CollisionGroup", 11);
	
	SetVariantString("run_upper_knife");
	
	AcceptEntityInput(m_iViewModel, "SetAnimation");
	AcceptEntityInput(m_iViewModel, "Enable");
	
	int offset = GetEntSendPropOffs(m_iViewModel, "m_clrGlow");
	SetEntProp(m_iViewModel, Prop_Send, "m_bShouldGlow", true, true);
	SetEntProp(m_iViewModel, Prop_Send, "m_nGlowStyle", 0);
	SetEntPropFloat(m_iViewModel, Prop_Send, "m_flGlowMaxDist", 200.0);
	
	//Miku Green
	SetEntData(m_iViewModel, offset, 57, _, true);
	SetEntData(m_iViewModel, offset + 1, 197, _, true);
	SetEntData(m_iViewModel, offset + 2, 187, _, true);
	SetEntData(m_iViewModel, offset + 3, 255, _, true);
	
	float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];
	
	GetClientAbsOrigin(client, m_fOrigin);
	GetClientAbsAngles(client, m_fAngles);
	
	m_fRadians[0] = DegToRad(m_fAngles[0]);
	m_fRadians[1] = DegToRad(m_fAngles[1]);
	
	m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
	m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
	m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);
	
	m_fAngles[0] *= -1.0;
	m_fAngles[1] *= -1.0;
	
	TeleportEntity(m_iViewModel, m_fPosition, m_fAngles, NULL_VECTOR);
	
	int m_iRotator = CreateEntityByName("func_rotating");
	DispatchKeyValueVector(m_iRotator, "origin", m_fPosition);
	DispatchKeyValue(m_iRotator, "targetname", "Item");
	DispatchKeyValue(m_iRotator, "maxspeed", "40");
	DispatchKeyValue(m_iRotator, "friction", "0");
	DispatchKeyValue(m_iRotator, "dmg", "0");
	DispatchKeyValue(m_iRotator, "solid", "0");
	DispatchKeyValue(m_iRotator, "spawnflags", "64");
	DispatchSpawn(m_iRotator);
	
	SetVariantString("!activator");
	AcceptEntityInput(m_iViewModel, "SetParent", m_iRotator, m_iRotator);
	AcceptEntityInput(m_iRotator, "Start");
	
	playerOptions[client][skinIndex] = EntIndexToEntRef(m_iViewModel);
	playerOptions[client][previewTimes] = GetTime() + 60;
	
	SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_SkinPreview);
	
	SetVariantString("idle");
	AcceptEntityInput(m_iViewModel, "SetAnimation");
	
	CreateTimer(g_fPreviewTime, Timer_KillSkinPreview, client);
}

void previewParticle(int client, int itemid) {
	resetAllPreviews(client);
	int m_iViewModel = CreateEntityByName("prop_dynamic");
	char m_szTargetName[32];
	Format(m_szTargetName, 32, "Store_Preview_%d", m_iViewModel);
	DispatchKeyValue(m_iViewModel, "targetname", m_szTargetName);
	DispatchKeyValue(m_iViewModel, "spawnflags", "64");
	DispatchKeyValue(m_iViewModel, "model", "models/player/tm_anarchist_variantb.mdl");
	DispatchKeyValue(m_iViewModel, "rendermode", "0");
	DispatchKeyValue(m_iViewModel, "renderfx", "0");
	DispatchKeyValue(m_iViewModel, "rendercolor", "255 255 255");
	DispatchKeyValue(m_iViewModel, "renderamt", "255");
	DispatchKeyValue(m_iViewModel, "solid", "0");
	
	DispatchSpawn(m_iViewModel);
	
	SetEntProp(m_iViewModel, Prop_Send, "m_CollisionGroup", 11);
	
	SetVariantString("run_upper_knife");
	
	AcceptEntityInput(m_iViewModel, "SetAnimation");
	AcceptEntityInput(m_iViewModel, "Enable");
	
	float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];
	
	GetClientAbsOrigin(client, m_fOrigin);
	GetClientAbsAngles(client, m_fAngles);
	
	m_fRadians[0] = DegToRad(m_fAngles[0]);
	m_fRadians[1] = DegToRad(m_fAngles[1]);
	
	m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
	m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
	m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);
	
	m_fAngles[0] *= -1.0;
	m_fAngles[1] *= -1.0;
	
	TeleportEntity(m_iViewModel, m_fPosition, m_fAngles, NULL_VECTOR);
	
	playerOptions[client][previewTimes] = GetTime() + 60;
	playerOptions[client][particleSkinIndex] = EntIndexToEntRef(m_iViewModel);
	
	SDKHook(m_iViewModel, SDKHook_SetTransmit, Hook_SetTransmit_ParticlePreview);
	
	SetVariantString("idle");
	AcceptEntityInput(m_iViewModel, "SetAnimation");
	
	int particle_system = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle_system, "start_active", "0");
	DispatchKeyValue(particle_system, "effect_name", g_eItems[itemid][szUniqueId]);
	DispatchSpawn(particle_system);
	TeleportEntity(particle_system, m_fPosition, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(particle_system);
	SetVariantString("!activator");
	AcceptEntityInput(particle_system, "SetParent", m_iViewModel, particle_system, 0);
	CreateTimer(0.1, enableParticle, particle_system);
	SDKHook(particle_system, SDKHook_SetTransmit, Hook_SetTransmit_ParticlePreview);
	SetEdictFlags(particle_system, (GetEdictFlags(particle_system) ^ FL_EDICT_ALWAYS));
	
	playerOptions[client][particleIndex] = EntIndexToEntRef(particle_system);
	
	CreateTimer(g_fPreviewTime, Timer_killParticlePreview, client);
}

/* CODE TO RESET PREVIEWS */
public Action Timer_killParticlePreview(Handle timer, int client) {
	if (!IsValidEdict(playerOptions[client][particleSkinIndex])) {
		return;
	}
	int entityIndex = EntRefToEntIndex(playerOptions[client][particleSkinIndex]);
	if (IsValidEdict(entityIndex)) {
		char m_szName[32];
		GetEntPropString(entityIndex, Prop_Data, "m_iName", m_szName, 32);
		if (StrContains(m_szName, "Store_Preview_", false) == 0) {
			SetEntProp(entityIndex, Prop_Send, "m_bShouldGlow", false, true);
			SDKUnhook(entityIndex, SDKHook_SetTransmit, Hook_SetTransmit_ParticlePreview);
			AcceptEntityInput(entityIndex, "Kill");
			removeParticles(client);
		}
	}
	playerOptions[client][particleSkinIndex] = -1;
}

public Action Timer_KillSkinPreview(Handle timer, int client) {
	if (!IsValidEdict(playerOptions[client][skinIndex])) {
		return;
	}
	int removeSkinIndex = EntRefToEntIndex(playerOptions[client][skinIndex]);
	if (IsValidEntity(removeSkinIndex)) {
		SetEntProp(removeSkinIndex, Prop_Send, "m_bShouldGlow", false, true);
		SDKUnhook(removeSkinIndex, SDKHook_SetTransmit, Hook_SetTransmit_SkinPreview);
		AcceptEntityInput(removeSkinIndex, "kill");
	}
	playerOptions[client][skinIndex] = -1;
}

public void removeParticles(int client) {
	if (!IsValidEdict(playerOptions[client][particleIndex])) {
		return;
	}
	int removeParticleIndex = EntRefToEntIndex(playerOptions[client][particleIndex]);
	if (IsValidEntity(removeParticleIndex)) {
		if (IsClientInGame(client)) {
			if (IsValidEdict(removeParticleIndex)) {
				SDKUnhook(removeParticleIndex, SDKHook_SetTransmit, Hook_SetTransmit_ParticlePreview);
				AcceptEntityInput(removeParticleIndex, "kill");
			}
		}
		playerOptions[client][particleIndex] = -1;
	}
}

/* PREVIEW HELPER FUNCTIONS */
public Action enableParticle(Handle Timer, any ent) {
	if (ent > 0 && IsValidEntity(ent)) {
		AcceptEntityInput(ent, "Start");
		setFlags(ent);
	}
}


public void setFlags(int edict) {
	if (GetEdictFlags(edict) & FL_EDICT_ALWAYS) {
		SetEdictFlags(edict, (GetEdictFlags(edict) ^ FL_EDICT_ALWAYS));
	}
}


/* TRANSMIT HOOKS */
public Action Hook_SetTransmit_ParticlePreview(int ent, int client) {
	// Enables TransmissionHook for Particles
	setFlags(ent);
	if (ent == EntRefToEntIndex(playerOptions[client][particleSkinIndex]) || ent == EntRefToEntIndex(playerOptions[client][particleIndex])) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public Action Hook_SetTransmit_SkinPreview(int ent, int client) {
	if (ent == playerOptions[client][skinIndex]) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

public int createTrackTrainPreview(int client, int itemid) {
	killTrainPreviewImmidiatly(client);
	int currTime = GetTime();
	char uniqueId[32];
	Format(uniqueId, sizeof(uniqueId), "%i-%i-%i", currTime, client, GetRandomInt(1, 1000));
	
	float m_fOrigin[3], m_fAngles[3], m_fRadians[2], m_fPosition[3];
	
	GetClientAbsOrigin(client, m_fOrigin);
	GetClientAbsAngles(client, m_fAngles);
	
	m_fRadians[0] = DegToRad(m_fAngles[0]);
	m_fRadians[1] = DegToRad(m_fAngles[1]);
	
	m_fPosition[0] = m_fOrigin[0] + 64 * Cosine(m_fRadians[0]) * Cosine(m_fRadians[1]);
	m_fPosition[1] = m_fOrigin[1] + 64 * Cosine(m_fRadians[0]) * Sine(m_fRadians[1]);
	m_fPosition[2] = m_fOrigin[2] + 4 * Sine(m_fRadians[0]);
	
	m_fAngles[0] *= -1.0;
	m_fAngles[1] *= -1.0;
	
	float startPos[3];
	startPos[0] = m_fPosition[0] + (200.0 * Cosine(m_fRadians[1] + DegToRad(45.0)));
	startPos[1] = m_fPosition[1] + (200.0 * Sine(m_fRadians[1] + DegToRad(45.0)));
	startPos[2] = m_fPosition[2];
	
	float endPos[3];
	endPos[0] = m_fPosition[0] - (200.0 * Cosine(m_fRadians[1] + DegToRad(135.0)));
	endPos[1] = m_fPosition[1] - (200.0 * Sine(m_fRadians[1] + DegToRad(135.0)));
	endPos[2] = m_fPosition[2];
	
	int startPath = CreateEntityByName("path_track");
	if (startPath == -1) {
		LogError("failed to create path_track start");
	}
	DispatchKeyValueVector(startPath, "origin", startPos);
	DispatchKeyValueVector(startPath, "angles", m_fAngles);
	char startPathTargetName[64];
	Format(startPathTargetName, sizeof(startPathTargetName), "startPath_%s", uniqueId);
	char endPathTargetName[64];
	Format(endPathTargetName, sizeof(endPathTargetName), "endPath_%s", uniqueId);
	DispatchKeyValue(startPath, "targetname", startPathTargetName);
	DispatchKeyValue(startPath, "target", endPathTargetName);
	
	int endPath = CreateEntityByName("path_track");
	if (endPath == -1) {
		LogError("failed to create path_track end");
	}
	DispatchKeyValueVector(endPath, "origin", endPos);
	DispatchKeyValueVector(endPath, "angles", m_fAngles);
	DispatchKeyValue(endPath, "targetname", endPathTargetName);
	DispatchSpawn(endPath);
	ActivateEntity(endPath);
	TeleportEntity(endPath, endPos, m_fAngles, NULL_VECTOR);
	AcceptEntityInput(endPath, "EnablePath");
	
	// wait because end was not spawned yet
	DispatchSpawn(startPath);
	ActivateEntity(startPath);
	TeleportEntity(startPath, startPos, m_fAngles, NULL_VECTOR);
	AcceptEntityInput(startPath, "EnablePath");
	
	int trackTrain = CreateEntityByName("func_tracktrain");
	if (trackTrain == -1) {
		LogError("failed to create tracktrain");
	}
	
	char trainTrackTargetName[64];
	Format(trainTrackTargetName, sizeof(trainTrackTargetName), "previewTrainTrack_%s", uniqueId);
	DispatchKeyValue(trackTrain, "targetname", trainTrackTargetName);
	DispatchKeyValue(trackTrain, "target", startPathTargetName);
	DispatchKeyValue(trackTrain, "speed", "125");
	DispatchKeyValue(trackTrain, "startspeed", "125");
	DispatchKeyValue(trackTrain, "orientationtype", "2");
	char spawnflags[12];
	FormatEx(spawnflags, sizeof(spawnflags), "%i", SF_NOUSERCONTROL | SF_PASSABLE);
	DispatchKeyValue(trackTrain, "spawnflags", spawnflags);
	DispatchSpawn(trackTrain);
	ActivateEntity(trackTrain);
	SDKHook(trackTrain, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
	
	int skinModel = createEntityModel(startPos, m_fAngles);
	SDKHook(skinModel, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
	int particle = attachParticleTo(skinModel, g_eItems[itemid][szUniqueId]);
	
	// without delay it spawns somewhere in the map. Thanks valve!
	DataPack linkData = CreateDataPack();
	WritePackCell(linkData, EntIndexToEntRef(trackTrain));
	WritePackCell(linkData, EntIndexToEntRef(skinModel));
	CreateTimer(0.01, createLink, linkData);
	
	AcceptEntityInput(trackTrain, "StartForward");
	
	CreateTimer(2.1, backwards, EntIndexToEntRef(trackTrain));
	
	CreateTimer(g_fPreviewTime, killTrainPreview, EntIndexToEntRef(client));
	
	playerOptions[client][iTrackClient] = EntIndexToEntRef(trackTrain);
	playerOptions[client][iTrackModel] = EntIndexToEntRef(skinModel);
	playerOptions[client][iTrackParticle] = EntIndexToEntRef(particle);
}

public Action createLink(Handle Timer, any datapack) {
	ResetPack(datapack);
	int trackTrain = EntRefToEntIndex(ReadPackCell(datapack));
	int skinModel = EntRefToEntIndex(ReadPackCell(datapack));
	
	if (!IsValidEntity(trackTrain) || !IsValidEntity(skinModel)) {
		// Don't link if entity doesnt exist anymore = cleanup happened
		return;
	}
	
	SetVariantEntity(trackTrain);
	AcceptEntityInput(skinModel, "SetParent");
}

public Action backwards(Handle Timer, any tracktrainobject) {
	int trackTrain = EntRefToEntIndex(tracktrainobject);
	if (!IsValidEntity(trackTrain)) {
		// Don't reverse if entity doesnt exist anymore = cleanup happened
		return;
	}
	AcceptEntityInput(trackTrain, "Reverse");
	CreateTimer(1.5, backwards, EntIndexToEntRef(trackTrain));
}

public int attachParticleTo(int attachToEntity, char[] particleName) {
	if (!IsValidEntity(attachToEntity)) {
		LogError("failed to attach to entity. Id: %i", attachToEntity);
		return -1;
	}
	float m_fPosition[3];
	GetEntPropVector(attachToEntity, Prop_Data, "m_vecOrigin", m_fPosition);
	int particle_system = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle_system, "start_active", "0");
	DispatchKeyValue(particle_system, "effect_name", particleName);
	DispatchSpawn(particle_system);
	TeleportEntity(particle_system, m_fPosition, NULL_VECTOR, NULL_VECTOR);
	ActivateEntity(particle_system);
	SetVariantString("!activator");
	AcceptEntityInput(particle_system, "SetParent", attachToEntity, particle_system, 0);
	CreateTimer(0.1, enableParticle, particle_system);
	SetEdictFlags(particle_system, (GetEdictFlags(particle_system) ^ FL_EDICT_ALWAYS));
	
	SDKHook(particle_system, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
	
	return particle_system;
}

public Action killTrainPreview(Handle Timer, any clientref) {
	int client = EntRefToEntIndex(clientref);
	killTrainPreviewImmidiatly(client);
}

public void killTrainPreviewImmidiatly(int client) {
	int trainIndex = EntRefToEntIndex(playerOptions[client][iTrackClient]);
	int modelIndex = EntRefToEntIndex(playerOptions[client][iTrackModel]);
	int removeParticleIndex = EntRefToEntIndex(playerOptions[client][iTrackParticle]);
	
	if (removeParticleIndex > 64 && IsValidEntity(removeParticleIndex)) {
		SDKUnhook(removeParticleIndex, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
		AcceptEntityInput(removeParticleIndex, "kill");
	}
	
	if (modelIndex > 64 && IsValidEntity(modelIndex)) {
		SDKUnhook(modelIndex, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
		AcceptEntityInput(modelIndex, "kill");
	}
	
	if (trainIndex > 64 && IsValidEntity(trainIndex)) {
		SDKUnhook(trainIndex, SDKHook_SetTransmit, Hook_SetTransmit_PreviewTrain);
		AcceptEntityInput(trainIndex, "kill");
	}
}

public Action Hook_SetTransmit_PreviewTrain(int ent, int client) {
	// Enables TransmissionHook for Particles
	setFlags(ent);
	if (ent == EntRefToEntIndex(playerOptions[client][iTrackClient]) || ent == EntRefToEntIndex(playerOptions[client][iTrackModel]) || ent == EntRefToEntIndex(playerOptions[client][iTrackParticle])) {
		return Plugin_Continue;
	}
	return Plugin_Handled;
}

