#include "MenuCamera.h"

#include "APIManager.h"
#include "Settings.h"

namespace
{
	constexpr float PI = 3.14159265358979323846f;

}

MenuCamera& MenuCamera::GetSingleton()
{
	static MenuCamera instance;
	return instance;
}

bool MenuCamera::CaptureINISettings()
{
	auto* ini = RE::INISettingCollection::GetSingleton();
	if (!ini) {
		return false;
	}

	overShoulderCombatPosX = ini->GetSetting("fOverShoulderCombatPosX:Camera");
	overShoulderCombatAddY = ini->GetSetting("fOverShoulderCombatAddY:Camera");
	overShoulderCombatPosZ = ini->GetSetting("fOverShoulderCombatPosZ:Camera");
	autoVanityModeDelay = ini->GetSetting("fAutoVanityModeDelay:Camera");
	overShoulderPosX = ini->GetSetting("fOverShoulderPosX:Camera");
	overShoulderPosZ = ini->GetSetting("fOverShoulderPosZ:Camera");
	vanityModeMinDist = ini->GetSetting("fVanityModeMinDist:Camera");
	vanityModeMaxDist = ini->GetSetting("fVanityModeMaxDist:Camera");
	mouseWheelZoomSpeed = ini->GetSetting("fMouseWheelZoomSpeed:Camera");
	togglePOVDelay = ini->GetSetting("fTogglePOVDelay:Controls");

	return overShoulderCombatPosX && overShoulderCombatAddY && overShoulderCombatPosZ && autoVanityModeDelay &&
		   overShoulderPosX && overShoulderPosZ && vanityModeMinDist && vanityModeMaxDist && mouseWheelZoomSpeed &&
		   togglePOVDelay;
}

bool MenuCamera::Start()
{
	if (active) {
		ApplySettings();
		return true;
	}

	auto* player = RE::PlayerCharacter::GetSingleton();
	auto* camera = RE::PlayerCamera::GetSingleton();
	if (!player || !camera) {
		logger::warn("[MenuCamera] Could not start. Missing player or camera.");
		return false;
	}

	if (player->IsOnMount()) {
		logger::info("[MenuCamera] Skipped start. Player is mounted.");
		return false;
	}

	if (!CaptureINISettings()) {
		logger::warn("[MenuCamera] Could not start. Missing INI camera settings.");
		return false;
	}

	auto* thirdState = static_cast<RE::ThirdPersonState*>(camera->cameraStates[RE::CameraState::kThirdPerson].get());
	if (!thirdState) {
		logger::warn("[MenuCamera] Could not start. Missing third-person camera state.");
		return false;
	}

	APIs::RequestAPIs();

	if (g_SmoothCam && g_SmoothCam->IsCameraEnabled()) {
		const auto result = g_SmoothCam->RequestCameraControl(g_pluginHandle);

		if (result == SmoothCamAPI::APIResult::OK || result == SmoothCamAPI::APIResult::AlreadyGiven) {
			g_SmoothCam->RequestInterpolatorUpdates(g_pluginHandle, true);
			smoothCamControl = true;
			logger::info("[MenuCamera] SmoothCam camera control acquired.");
		} else {
			logger::warn("[MenuCamera] SmoothCam camera control request failed: {}", static_cast<std::uint8_t>(result));
		}
	}

	if (!CaptureState(player, camera, thirdState)) {
		ResetSavedState();
		return false;
	}

	active = true;
	ApplyCameraValues(player, camera, thirdState);
	if (Settings::previewLightDefaultOn) {
		SetPreviewLight(true);
	}
	logger::info("[MenuCamera] Started.");
	return true;
}

void MenuCamera::Stop()
{
	if (!active) {
		return;
	}

	auto* player = RE::PlayerCharacter::GetSingleton();
	auto* camera = RE::PlayerCamera::GetSingleton();
	if (!player || !camera) {
		ResetSavedState();
		return;
	}

	auto* thirdState = static_cast<RE::ThirdPersonState*>(camera->cameraStates[RE::CameraState::kThirdPerson].get());

	if (smoothCamControl && g_SmoothCam && g_SmoothCam->IsCameraEnabled()) {
		g_SmoothCam->ReleaseCameraControl(g_pluginHandle);
		logger::info("[MenuCamera] SmoothCam camera control released.");
	}

	RestorePreviewLight();

	if (wasFirstPerson) {
		camera->ForceFirstPerson();
	} else {
		camera->ForceThirdPerson();
	}

	player->data.angle.x = playerAngleX;
	player->data.angle.z = playerAngleZ;
	player->SetGraphVariableBool("IsNPC", headtrackingEnabled);
	player->SetGraphVariableBool("bHeadTrackSpine", headTrackSpineEnabled);
	player->SetGraphVariableBool("bUseEyeTracking", eyeTrackingEnabled);

	if (autoVanityModeDelay) {
		autoVanityModeDelay->data.f = savedAutoVanityModeDelay;
	}

	if (togglePOVDelay) {
		togglePOVDelay->data.f = savedTogglePOVDelay;
	}

	if (thirdState) {
		thirdState->toggleAnimCam = toggleAnimCam;
		thirdState->freeRotationEnabled = freeRotationEnabled;
		thirdState->targetZoomOffset = targetZoomOffset;
		thirdState->pitchZoomOffset = pitchZoomOffset;
		thirdState->freeRotation = freeRotation;
		thirdState->posOffsetExpected = thirdState->posOffsetActual = posOffsetExpected;
	}

	if (vanityModeMinDist) {
		vanityModeMinDist->data.f = savedVanityModeMinDist;
	}

	if (vanityModeMaxDist) {
		vanityModeMaxDist->data.f = savedVanityModeMaxDist;
	}

	if (overShoulderCombatPosX) {
		overShoulderCombatPosX->data.f = savedOverShoulderCombatPosX;
	}

	if (overShoulderCombatAddY) {
		overShoulderCombatAddY->data.f = savedOverShoulderCombatAddY;
	}

	if (overShoulderCombatPosZ) {
		overShoulderCombatPosZ->data.f = savedOverShoulderCombatPosZ;
	}

	if (overShoulderPosX) {
		overShoulderPosX->data.f = savedOverShoulderPosX;
	}

	if (overShoulderPosZ) {
		overShoulderPosZ->data.f = savedOverShoulderPosZ;
	}

	camera->cameraTarget = player;
	camera->worldFOV = worldFOV;
	camera->Update();
	player->Update3DPosition(true);

	if (mouseWheelZoomSpeed) {
		mouseWheelZoomSpeed->data.f = savedMouseWheelZoomSpeed;
	}

	ResetSavedState();
	logger::info("[MenuCamera] Stopped and restored camera state.");
}

void MenuCamera::ApplySettings()
{
	if (!active) {
		return;
	}

	auto* player = RE::PlayerCharacter::GetSingleton();
	auto* camera = RE::PlayerCamera::GetSingleton();
	if (!player || !camera) {
		return;
	}

	auto* thirdState = static_cast<RE::ThirdPersonState*>(camera->cameraStates[RE::CameraState::kThirdPerson].get());
	if (!thirdState) {
		return;
	}

	ApplyCameraValues(player, camera, thirdState);
	if (previewLightEnabled) {
		ApplyPreviewLight(player);
	}
}

bool MenuCamera::IsActive() const
{
	return active;
}

void MenuCamera::SetUserOffsets(float a_side, float a_height)
{
	Settings::offsetX = std::clamp(a_side, -160.0f, 160.0f);
	Settings::offsetZ = std::clamp(a_height, -120.0f, 120.0f);
	ApplySettings();
}

void MenuCamera::SetPreviewLight(bool a_enable)
{
	auto* player = RE::PlayerCharacter::GetSingleton();
	if (!player || !active) {
		previewLightEnabled = a_enable;
		return;
	}

	if (a_enable) {
		ApplyPreviewLight(player);
	} else {
		RestorePreviewLight();
	}
}

bool MenuCamera::CaptureState(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState)
{
	if (!a_player || !a_camera || !a_thirdState) {
		return false;
	}

	a_camera->cameraTarget = a_player;
	wasFirstPerson = a_camera->IsInFirstPerson();

	playerAngleX = a_player->data.angle.x;
	playerAngleZ = a_player->data.angle.z;
	freeRotation = a_thirdState->freeRotation;
	posOffsetExpected = a_thirdState->posOffsetExpected;
	targetZoomOffset = a_thirdState->targetZoomOffset;
	pitchZoomOffset = a_thirdState->pitchZoomOffset;
	worldFOV = a_camera->worldFOV;
	toggleAnimCam = a_thirdState->toggleAnimCam;
	freeRotationEnabled = a_thirdState->freeRotationEnabled;

	a_player->GetGraphVariableBool("IsNPC", headtrackingEnabled);
	a_player->GetGraphVariableBool("bHeadTrackSpine", headTrackSpineEnabled);
	a_player->GetGraphVariableBool("bUseEyeTracking", eyeTrackingEnabled);

	savedOverShoulderCombatPosX = overShoulderCombatPosX->GetFloat();
	savedOverShoulderCombatAddY = overShoulderCombatAddY->GetFloat();
	savedOverShoulderCombatPosZ = overShoulderCombatPosZ->GetFloat();
	savedAutoVanityModeDelay = autoVanityModeDelay->GetFloat();
	savedOverShoulderPosX = overShoulderPosX->GetFloat();
	savedOverShoulderPosZ = overShoulderPosZ->GetFloat();
	savedVanityModeMinDist = vanityModeMinDist->GetFloat();
	savedVanityModeMaxDist = vanityModeMaxDist->GetFloat();
	savedMouseWheelZoomSpeed = mouseWheelZoomSpeed->GetFloat();
	savedTogglePOVDelay = togglePOVDelay->GetFloat();

	a_player->SetGraphVariableBool("IsNPC", false);
	a_player->SetGraphVariableBool("bHeadTrackSpine", false);
	a_player->SetGraphVariableBool("bUseEyeTracking", false);

	if (auto* process = a_player->GetActorRuntimeData().currentProcess) {
		process->ClearActionHeadtrackTarget(true);
	}

	return true;
}

bool MenuCamera::CaptureLightState(RE::PlayerCharacter* a_player)
{
	if (!a_player || !Settings::enablePreviewLight) {
		return false;
	}

	auto& info = a_player->GetInfoRuntimeData();
	if (!info.thirdPersonLight || !info.thirdPersonLight->light) {
		logger::info("[MenuCamera] Preview light requested, but no third-person player light is available.");
		return false;
	}

	savedLight = info.thirdPersonLight;
	auto& lightData = savedLight->light->GetLightRuntimeData();
	savedLightAmbient = lightData.ambient;
	savedLightDiffuse = lightData.diffuse;
	savedLightRadius = lightData.radius;
	savedLightFade = lightData.fade;
	savedLightLodDimmer = savedLight->lodDimmer;
	savedLightNeverFades = savedLight->neverFades;
	savedLightAffectLand = savedLight->affectLand;
	lightStateCaptured = true;
	return true;
}

void MenuCamera::ApplyPreviewLight(RE::PlayerCharacter* a_player)
{
	if (!Settings::enablePreviewLight) {
		return;
	}

	if (!lightStateCaptured && !CaptureLightState(a_player)) {
		previewLightEnabled = false;
		return;
	}

	if (!savedLight || !savedLight->light) {
		previewLightEnabled = false;
		return;
	}

	const auto strength = std::clamp(Settings::lightStrength, 0.0f, 4.0f);
	const auto ambient = std::clamp(Settings::lightAmbient, 0.0f, 1.0f);
	const auto radius = std::clamp(Settings::lightRadius, 64.0f, 2048.0f);
	const auto color = RE::NiColor(
		std::clamp(Settings::lightRed, 0.0f, 2.0f),
		std::clamp(Settings::lightGreen, 0.0f, 2.0f),
		std::clamp(Settings::lightBlue, 0.0f, 2.0f));

	auto& lightData = savedLight->light->GetLightRuntimeData();
	lightData.diffuse = color * strength;
	lightData.ambient = color * ambient;
	lightData.radius = RE::NiPoint3(radius, radius, radius);
	lightData.fade = 1.0f;
	savedLight->lodDimmer = 1.0f;
	savedLight->neverFades = true;
	savedLight->affectLand = false;
	previewLightEnabled = true;

	if (a_player) {
		a_player->Update3DPosition(true);
	}
}

void MenuCamera::ApplyCameraValues(RE::PlayerCharacter* a_player, RE::PlayerCamera* a_camera, RE::ThirdPersonState* a_thirdState)
{
	if (!a_player || !a_camera || !a_thirdState) {
		return;
	}

	a_camera->cameraTarget = a_player;
	a_camera->SetState(a_thirdState);

	a_thirdState->toggleAnimCam = true;
	a_thirdState->freeRotationEnabled = true;
	a_thirdState->freeRotation.x = PI - 0.5f;
	a_thirdState->freeRotation.y = 0.0f;
	a_thirdState->targetZoomOffset = 0.0f;
	a_thirdState->pitchZoomOffset = 0.1f;

	autoVanityModeDelay->data.f = 10800.0f;
	togglePOVDelay->data.f = 10800.0f;
	overShoulderCombatPosX->data.f = Settings::offsetX;
	overShoulderCombatAddY->data.f = Settings::offsetY;
	overShoulderCombatPosZ->data.f = Settings::offsetZ;
	overShoulderPosX->data.f = Settings::offsetX;
	overShoulderPosZ->data.f = Settings::offsetZ;
	vanityModeMinDist->data.f = Settings::distance;
	vanityModeMaxDist->data.f = Settings::distance;
	mouseWheelZoomSpeed->data.f = 10000.0f;

	a_player->data.angle.x = 0.1f;
	a_thirdState->posOffsetExpected = a_thirdState->posOffsetActual =
		RE::NiPoint3(Settings::offsetX, Settings::offsetY, Settings::offsetZ);

	a_camera->worldFOV = Settings::fov;
	a_camera->Update();
	a_player->Update3DPosition(true);
}

void MenuCamera::RestorePreviewLight()
{
	if (!lightStateCaptured) {
		previewLightEnabled = false;
		return;
	}

	if (savedLight && savedLight->light) {
		auto& lightData = savedLight->light->GetLightRuntimeData();
		lightData.ambient = savedLightAmbient;
		lightData.diffuse = savedLightDiffuse;
		lightData.radius = savedLightRadius;
		lightData.fade = savedLightFade;
		savedLight->lodDimmer = savedLightLodDimmer;
		savedLight->neverFades = savedLightNeverFades;
		savedLight->affectLand = savedLightAffectLand;
	}

	savedLight.reset(static_cast<RE::BSLight*>(nullptr));
	lightStateCaptured = false;
	previewLightEnabled = false;
}

void MenuCamera::ResetSavedState()
{
	overShoulderCombatPosX = nullptr;
	overShoulderCombatAddY = nullptr;
	overShoulderCombatPosZ = nullptr;
	autoVanityModeDelay = nullptr;
	overShoulderPosX = nullptr;
	overShoulderPosZ = nullptr;
	vanityModeMinDist = nullptr;
	vanityModeMaxDist = nullptr;
	mouseWheelZoomSpeed = nullptr;
	togglePOVDelay = nullptr;
	active = false;
	smoothCamControl = false;
	wasFirstPerson = false;
	previewLightEnabled = false;
	lightStateCaptured = false;
	savedLight.reset(static_cast<RE::BSLight*>(nullptr));
}
