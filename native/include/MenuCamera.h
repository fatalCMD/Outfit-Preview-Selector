#pragma once

class MenuCamera
{
public:
	static MenuCamera& GetSingleton();

	bool Start();
	void Stop();
	void ApplySettings();
	void SetPreviewLight(bool a_enable);
	void SetUserOffsets(float a_side, float a_height);
	[[nodiscard]] bool IsActive() const;

private:
	RE::Setting* overShoulderCombatPosX = nullptr;
	RE::Setting* overShoulderCombatAddY = nullptr;
	RE::Setting* overShoulderCombatPosZ = nullptr;
	RE::Setting* autoVanityModeDelay = nullptr;
	RE::Setting* overShoulderPosX = nullptr;
	RE::Setting* overShoulderPosZ = nullptr;
	RE::Setting* vanityModeMinDist = nullptr;
	RE::Setting* vanityModeMaxDist = nullptr;
	RE::Setting* mouseWheelZoomSpeed = nullptr;
	RE::Setting* togglePOVDelay = nullptr;

	RE::NiPoint2 freeRotation{};
	RE::NiPoint3 posOffsetExpected{};
	RE::NiPointer<RE::BSLight> savedLight;
	RE::ImageSpaceModifierInstanceDOF* previewDOF = nullptr;
	RE::ImageSpaceModifierInstanceDOF* savedDynamicDOF = nullptr;
	RE::NiColor savedLightAmbient{};
	RE::NiColor savedLightDiffuse{};
	RE::NiPoint3 savedLightRadius{};

	float playerAngleX = 0.0f;
	float playerAngleZ = 0.0f;
	float targetZoomOffset = 0.0f;
	float pitchZoomOffset = 0.0f;
	float worldFOV = 0.0f;
	float savedLightFade = 0.0f;
	float savedLightLodDimmer = 0.0f;

	float savedOverShoulderCombatPosX = 0.0f;
	float savedOverShoulderCombatAddY = 0.0f;
	float savedOverShoulderCombatPosZ = 0.0f;
	float savedAutoVanityModeDelay = 0.0f;
	float savedOverShoulderPosX = 0.0f;
	float savedOverShoulderPosZ = 0.0f;
	float savedVanityModeMinDist = 0.0f;
	float savedVanityModeMaxDist = 0.0f;
	float savedMouseWheelZoomSpeed = 0.0f;
	float savedTogglePOVDelay = 0.0f;

	bool active = false;
	bool smoothCamControl = false;
	bool wasFirstPerson = false;
	bool headtrackingEnabled = false;
	bool headTrackSpineEnabled = false;
	bool eyeTrackingEnabled = false;
	bool toggleAnimCam = false;
	bool freeRotationEnabled = false;
	bool previewLightEnabled = false;
	bool lightStateCaptured = false;
	bool savedLightNeverFades = false;
	bool savedLightAffectLand = false;

	[[nodiscard]] bool CaptureINISettings();
	[[nodiscard]] bool CaptureState(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState);
	[[nodiscard]] bool CaptureLightState(RE::PlayerCharacter* a_player);
	void ApplyPreviewLight(RE::PlayerCharacter* a_player);
	void ApplyCameraValues(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState);
	void RestorePreviewLight();
	void ApplyPreviewDepthOfField(RE::PlayerCharacter* a_player);
	void RestorePreviewDepthOfField();
	void ResetSavedState();
};
