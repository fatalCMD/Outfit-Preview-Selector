#include "APIManager.h"
#include "EventProcessor.h"
#include "Plugin.h"
#include "Settings.h"
#include "ScaleformBridge.h"
#include "logger.h"

SKSE::PluginHandle g_pluginHandle = SKSE::kInvalidPluginHandle;

namespace
{
	void OnMessage(SKSE::MessagingInterface::Message* a_message)
	{
		switch (a_message->type) {
		case SKSE::MessagingInterface::kPostLoad:
			APIs::RegisterCallbacks();
			break;
		case SKSE::MessagingInterface::kPostPostLoad:
		case SKSE::MessagingInterface::kNewGame:
		case SKSE::MessagingInterface::kPostLoadGame:
			APIs::RequestAPIs();
			break;
		case SKSE::MessagingInterface::kDataLoaded:
			Settings::Load();
			APIs::RequestAPIs();
			EventProcessor::Register();
			break;
		default:
			break;
		}
	}
}

EXTERN_C [[maybe_unused]] __declspec(dllexport) bool SKSEAPI SKSEPlugin_Load(const SKSE::LoadInterface* a_skse)
{
	SetupLog(Plugin::NAME);
	logger::info("{} loaded"sv, Plugin::NAME);

	SKSE::Init(a_skse);
	g_pluginHandle = a_skse->GetPluginHandle();

	if (const auto* scaleform = SKSE::GetScaleformInterface();
		scaleform && scaleform->Register(ScaleformBridge::Register, "OutfitPreviewSelectorCamera")) {
		logger::info("Scaleform player-animation bridge registered.");
	} else {
		logger::warn("Scaleform player-animation bridge could not be registered.");
	}

	if (const auto* messaging = SKSE::GetMessagingInterface()) {
		messaging->RegisterListener(OnMessage);
	} else {
		logger::error("Messaging interface not found.");
		return false;
	}

	return true;
}

EXTERN_C [[maybe_unused]] __declspec(dllexport) constinit auto SKSEPlugin_Version = []() noexcept {
	SKSE::PluginVersionData v;
	v.PluginName("OutfitPreviewSelectorCamera");
	v.PluginVersion(Plugin::VERSION);
	v.UsesAddressLibrary(true);
	v.HasNoStructUse(true);
	return v;
}();

EXTERN_C [[maybe_unused]] __declspec(dllexport) bool SKSEAPI SKSEPlugin_Query(const SKSE::QueryInterface*, SKSE::PluginInfo* a_pluginInfo)
{
	a_pluginInfo->name = SKSEPlugin_Version.pluginName;
	a_pluginInfo->infoVersion = SKSE::PluginInfo::kVersion;
	a_pluginInfo->version = SKSEPlugin_Version.pluginVersion;

	return true;
}
