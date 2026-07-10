#include "ScaleformBridge.h"

#include "MenuCamera.h"
#include "logger.h"

namespace
{
	std::atomic_bool animationTickConfirmed = false;

	class FSMP25Bridge
	{
	public:
		static FSMP25Bridge& GetSingleton()
		{
			static FSMP25Bridge singleton;
			return singleton;
		}

		void Tick()
		{
			Initialize();
			if (!dispatch || !dispatcher) {
				return;
			}

			const FrameEvent event{ false };
			dispatch(dispatcher, event);
			if (!tickConfirmed.exchange(true)) {
				logger::info("FSMP 2.5 paused-preview physics tick confirmed.");
			}
		}

	private:
		struct FrameEvent
		{
			bool gamePaused;
		};

		using Dispatch = void (*)(void*, const FrameEvent&);

		void Initialize()
		{
			if (initialized.exchange(true)) {
				return;
			}

			constexpr std::uintptr_t DISPATCH_RVA = 0x000BBC60;
			constexpr std::uintptr_t DISPATCHER_RVA = 0x00196F80;
			constexpr std::uintptr_t DISPATCHER_VTABLE_RVA = 0x0015D088;
			constexpr std::uint8_t SIGNATURE[] = { 0x48, 0x89, 0x5C, 0x24, 0x10, 0x48, 0x89, 0x6C, 0x24, 0x18 };

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
			if (nt->Signature != IMAGE_NT_SIGNATURE || nt->OptionalHeader.SizeOfImage <= DISPATCHER_RVA + sizeof(void*)) {
				logger::warn("FSMP build is not compatible with the guarded 2.5 preview bridge.");
				return;
			}

			auto* code = reinterpret_cast<const std::uint8_t*>(base + DISPATCH_RVA);
			if (!std::equal(std::begin(SIGNATURE), std::end(SIGNATURE), code)) {
				logger::warn("FSMP build signature differs from 2.5; paused-preview physics is disabled safely.");
				return;
			}

			auto* candidateDispatcher = reinterpret_cast<void*>(base + DISPATCHER_RVA);
			const auto candidateVtable = *reinterpret_cast<const std::uintptr_t*>(candidateDispatcher);
			if (candidateVtable != base + DISPATCHER_VTABLE_RVA) {
				logger::warn("FSMP 2.5 dispatcher validation failed; paused-preview physics is disabled safely.");
				return;
			}

			dispatcher = candidateDispatcher;
			dispatch = reinterpret_cast<Dispatch>(base + DISPATCH_RVA);
			logger::info("Compatible FSMP 2.5 detected; paused-preview SMP physics enabled at 30 Hz.");
		}

		std::atomic_bool initialized = false;
		std::atomic_bool tickConfirmed = false;
		Dispatch dispatch = nullptr;
		void* dispatcher = nullptr;
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

			const auto savedPauses = ui->numPausesGame;
			ui->numPausesGame = 0;

			FSMP25Bridge::GetSingleton().Tick();

			ui->numPausesGame = savedPauses;

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
	return a_root->SetMember("ReportPreviewAnimationState", reportFunction);
}
