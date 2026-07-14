#pragma once

class MenuCamera
{
public:
	enum class ControlMode : std::uint32_t
	{
		kRotate = 0,
		kZoom = 1,
		kVertical = 2
	};

	static MenuCamera& GetSingleton();

	bool Start();
	void Stop();
	void ApplySettings();
	void SetPreviewLight(bool a_enable);
	void SetUserOffsets(float a_side, float a_height);
	void SetControlMode(std::uint32_t a_mode);
	void AdjustZoom(float a_delta);
	void AdjustHeight(float a_delta);
	void RotateCharacter(float a_radians);
	[[nodiscard]] bool IsActive() const;
	[[nodiscard]] ControlMode GetControlMode() const;
	[[nodiscard]] float GetPreviewHeight() const;

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
	RE::NiPoint3 savedLightLocalPosition{};
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
	float previewDistance = 182.0f;
	float previewHeight = -24.0f;

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
	bool savedLightPositionCaptured = false;
	bool cameraValuesDirty = false;
	ControlMode controlMode = ControlMode::kRotate;

	[[nodiscard]] bool CaptureINISettings();
	[[nodiscard]] bool CaptureState(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState);
	[[nodiscard]] bool CaptureLightState(RE::PlayerCharacter* a_player);
	void ApplyPreviewLight(RE::PlayerCharacter* a_player);
	void ApplyCameraValues(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState, bool a_resetOrientation);
	void RestorePreviewLight();
	void ResetSavedState();
};
