#include "ScaleformBridge.h"

#include "MenuCamera.h"
#include "logger.h"

namespace
{
	std::atomic_bool animationTickConfirmed = false;

	class FSMP25Bridge
	{
	public:
		struct FrameEvent
		{
			bool gamePaused;
		};

		using WorldUpdate = void (*)(void*, const FrameEvent&);

		static FSMP25Bridge& GetSingleton()
		{
			static FSMP25Bridge singleton;
			return singleton;
		}

		void Tick()
		{
			Initialize();
			if (originalWorldUpdate) {
				lastPreviewRequest.store(GetTickCount64());
				if (!tickConfirmed.exchange(true)) {
					logger::info("FSMP 2.5 preview physics activated through its normal frame pipeline.");
				}
			}
		}

		void Pause(std::uint32_t a_milliseconds)
		{
			const auto duration = std::clamp<std::uint32_t>(a_milliseconds, 250, 3000);
			pauseUntil.store(GetTickCount64() + duration);
		}

	private:
		static void WorldUpdateHook(void* a_world, const FrameEvent& a_event)
		{
			GetSingleton().RunWorldUpdate(a_world, a_event);
		}

		void RunWorldUpdate(void* a_world, const FrameEvent& a_event)
		{
			if (!originalWorldUpdate) {
				return;
			}

			auto* ui = RE::UI::GetSingleton();
			const auto lastRequest = lastPreviewRequest.load();
			const auto now = GetTickCount64();
			const bool previewActive = ui && MenuCamera::GetSingleton().IsActive() && now >= pauseUntil.load() &&
				lastRequest != 0 && now - lastRequest < 100;
			if (!previewActive) {
				originalWorldUpdate(a_world, a_event);
				return;
			}

			const auto savedPauses = ui->numPausesGame;
			ui->numPausesGame = 0;
			const FrameEvent previewEvent{ false };
			originalWorldUpdate(a_world, previewEvent);
			ui->numPausesGame = savedPauses;
		}

		static void WriteAbsoluteJump(std::uint8_t* a_buffer, std::uintptr_t a_destination)
		{
			a_buffer[0] = 0xFF;
			a_buffer[1] = 0x25;
			a_buffer[2] = 0x00;
			a_buffer[3] = 0x00;
			a_buffer[4] = 0x00;
			a_buffer[5] = 0x00;
			for (std::size_t i = 0; i < sizeof(a_destination); ++i) {
				a_buffer[6 + i] = static_cast<std::uint8_t>((a_destination >> (i * 8)) & 0xFF);
			}
		}

		void Initialize()
		{
			if (initialized.exchange(true)) {
				return;
			}

			constexpr std::uintptr_t WORLD_UPDATE_RVA = 0x000B90B0;
			constexpr std::uint8_t SIGNATURE[] = {
				0x48, 0x8B, 0xC4, 0x53, 0x55, 0x56, 0x57, 0x41, 0x56,
				0x41, 0x57, 0x48, 0x81, 0xEC, 0xE8, 0x00, 0x00, 0x00
			};

			auto* module = GetModuleHandleW(L"hdtSMP64.dll");
			if (!module) {
				logger::info("FSMP is not loaded; preview animation will run without SMP physics.");
				return;
			}

			const auto base = reinterpret_cast<std::uintptr_t>(module);
			auto* dos = reinterpret_cast<const IMAGE_DOS_HEADER*>(base);
			if (dos->e_magic != IMAGE_DOS_SIGNATURE) {
				logger::warn("FSMP compatibility check rejected an invalid module header.");
				return;
			}
			auto* nt = reinterpret_cast<const IMAGE_NT_HEADERS64*>(base + dos->e_lfanew);
			if (nt->Signature != IMAGE_NT_SIGNATURE ||
				nt->OptionalHeader.SizeOfImage <= WORLD_UPDATE_RVA + sizeof(SIGNATURE)) {
				logger::warn("FSMP build is not compatible with the guarded 2.5 preview bridge.");
				return;
			}

			auto* code = reinterpret_cast<const std::uint8_t*>(base + WORLD_UPDATE_RVA);
			if (!std::equal(std::begin(SIGNATURE), std::end(SIGNATURE), code)) {
				logger::warn("FSMP build signature differs from 2.5; paused-preview physics is disabled safely.");
				return;
			}

			constexpr std::size_t OVERWRITTEN_SIZE = 18;
			constexpr std::size_t ABSOLUTE_JUMP_SIZE = 14;
			fsmpTrampoline.create(64);
			auto* gateway = static_cast<std::uint8_t*>(
				fsmpTrampoline.allocate(OVERWRITTEN_SIZE + ABSOLUTE_JUMP_SIZE));
			std::copy_n(code, OVERWRITTEN_SIZE, gateway);
			WriteAbsoluteJump(gateway + OVERWRITTEN_SIZE, base + WORLD_UPDATE_RVA + OVERWRITTEN_SIZE);
			originalWorldUpdate = reinterpret_cast<WorldUpdate>(gateway);

			std::uint8_t hookPatch[OVERWRITTEN_SIZE];
			std::fill_n(hookPatch, OVERWRITTEN_SIZE, static_cast<std::uint8_t>(0x90));
			WriteAbsoluteJump(hookPatch, reinterpret_cast<std::uintptr_t>(&WorldUpdateHook));
			REL::safe_write(base + WORLD_UPDATE_RVA, hookPatch, OVERWRITTEN_SIZE);
			logger::info("Compatible FSMP 2.5 detected; normal-pipeline preview physics hook installed.");
		}

		std::atomic_bool initialized = false;
		std::atomic_bool tickConfirmed = false;
		std::atomic<ULONGLONG> lastPreviewRequest = 0;
		std::atomic<ULONGLONG> pauseUntil = 0;
		SKSE::Trampoline fsmpTrampoline{ "OPS FSMP bridge" };
		WorldUpdate originalWorldUpdate = nullptr;
	};

	class PausePreviewPhysics final : public RE::GFxFunctionHandler
	{
	public:
		void Call(Params& a_params) override
		{
			std::uint32_t duration = 1200;
			if (a_params.argCount >= 1 && a_params.args[0].IsNumber()) {
				const auto requested = a_params.args[0].GetNumber();
				if (std::isfinite(requested) && requested > 0.0) {
					duration = static_cast<std::uint32_t>(requested);
				}
			}
			FSMP25Bridge::GetSingleton().Pause(duration);
		}
	};

	class TickPlayerAnimation final : public RE::GFxFunctionHandler
	{
	public:
		void Call(Params& a_params) override
		{
			if (a_params.argCount < 1 || !a_params.args[0].IsNumber()) {
				return;
			}

			auto* ui = RE::UI::GetSingleton();
			auto* player = RE::PlayerCharacter::GetSingleton();
			if (!ui || !ui->GameIsPaused() || !MenuCamera::GetSingleton().IsActive() || !player || !player->Get3D()) {
				return;
			}

			const auto requestedDelta = static_cast<float>(a_params.args[0].GetNumber());
			if (!std::isfinite(requestedDelta) || requestedDelta <= 0.0f) {
				return;
			}

			player->UpdateAnimation((std::min)(requestedDelta, 0.05f));
			player->Update3DPosition(true);

			FSMP25Bridge::GetSingleton().Tick();

			if (!animationTickConfirmed.exchange(true)) {
				logger::info("Player-only animation and scene propagation confirmed while the game is paused.");
			}
		}
	};

	class ReportPreviewAnimationState final : public RE::GFxFunctionHandler
	{
	public:
		void Call(Params& a_params) override
		{
			if (a_params.argCount < 1 || !a_params.args[0].IsBool()) {
				logger::warn("Preview animation state callback received an invalid value.");
				return;
			}

			logger::info("Preview animation state received from MCM: enabled={}", a_params.args[0].GetBool());
		}
	};
}

bool ScaleformBridge::Register(RE::GFxMovieView* a_view, RE::GFxValue* a_root)
{
	if (!a_view || !a_root) {
		return false;
	}

	RE::GFxValue tickFunction;
	a_view->CreateFunction(&tickFunction, new TickPlayerAnimation());
	if (!a_root->SetMember("TickPlayerAnimation", tickFunction)) {
		return false;
	}

	RE::GFxValue reportFunction;
	a_view->CreateFunction(&reportFunction, new ReportPreviewAnimationState());
	if (!a_root->SetMember("ReportPreviewAnimationState", reportFunction)) {
		return false;
	}

	RE::GFxValue pausePhysicsFunction;
	a_view->CreateFunction(&pausePhysicsFunction, new PausePreviewPhysics());
	return a_root->SetMember("PausePreviewPhysics", pausePhysicsFunction);
}
