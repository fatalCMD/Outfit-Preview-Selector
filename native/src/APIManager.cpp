#include "APIManager.h"

SmoothCamAPI::IVSmoothCam2* g_SmoothCam = nullptr;

namespace
{
	bool callbackRegistered = false;
}

void APIs::RegisterCallbacks()
{
	if (callbackRegistered) {
		return;
	}

	const auto* messaging = SKSE::GetMessagingInterface();
	if (!messaging) {
		logger::warn("[SmoothCam] SKSE messaging interface unavailable.");
		return;
	}

	callbackRegistered = SmoothCamAPI::RegisterInterfaceLoaderCallback(
		messaging,
		[](void* a_interfaceInstance, SmoothCamAPI::InterfaceVersion a_interfaceVersion) {
			if (a_interfaceVersion == SmoothCamAPI::InterfaceVersion::V2 ||
				a_interfaceVersion == SmoothCamAPI::InterfaceVersion::V3) {
				APIs::SmoothCam = reinterpret_cast<SmoothCamAPI::IVSmoothCam2*>(a_interfaceInstance);
				g_SmoothCam = APIs::SmoothCam;
				logger::info("[SmoothCam] Obtained SmoothCam API.");
			} else {
				logger::warn("[SmoothCam] Unsupported SmoothCam API version returned.");
			}
		});

	if (!callbackRegistered) {
		logger::warn("[SmoothCam] Callback registration failed.");
	}
}

void APIs::RequestAPIs()
{
	RegisterCallbacks();

	if (SmoothCam) {
		g_SmoothCam = SmoothCam;
		return;
	}

	const auto* messaging = SKSE::GetMessagingInterface();
	if (!messaging || !callbackRegistered) {
		return;
	}

	if (!SmoothCamAPI::RequestInterface(messaging, SmoothCamAPI::InterfaceVersion::V2)) {
		logger::debug("[SmoothCam] Interface request dispatch failed.");
	}
}
