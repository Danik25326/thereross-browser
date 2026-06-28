// =============================================================================
// TRS Browser — trs_browser_main.cc
// Точка входу браузера Thereross.
// Це перший файл де ти можеш щось змінити і побачити результат.
// =============================================================================

#include "trs/browser/trs_browser_main.h"
#include "trs/browser/trs_content_client.h"
#include "trs/ai_engine/ai_sidebar.h"
#include "trs/shield/ua_shield.h"

#include "content/public/app/content_main.h"
#include "content/public/browser/browser_main_runner.h"

namespace trs {

// Версія TRS — змінюй тут при релізах
constexpr char kTRSVersion[] = "0.1.0-alpha";
constexpr char kTRSName[]    = "Thereross";

TRSBrowserMain::TRSBrowserMain() {
  // Ініціалізуємо наші модулі при старті браузера
}

TRSBrowserMain::~TRSBrowserMain() = default;

void TRSBrowserMain::PreMainMessageLoopRun() {
  // Цей метод викликається перед головним циклом подій.
  // Тут ініціалізуємо TRS-специфічні компоненти.

  InitializeUAShield();
  InitializeAIEngine();
}

void TRSBrowserMain::InitializeUAShield() {
  // UA Shield: захист від RU-контенту, трекерів, фішингу
  // Детальніше: trs/shield/ua_shield.cc
  shield_ = std::make_unique<UAShield>();
  shield_->LoadBlocklists();
  shield_->Enable();
}

void TRSBrowserMain::InitializeAIEngine() {
  // AI Engine: нативний помічник (не розширення!)
  // Детальніше: trs/ai_engine/ai_sidebar.cc
  ai_engine_ = std::make_unique<AIEngine>();
  ai_engine_->Initialize();
}

}  // namespace trs

// Головна функція — замінює ChromeMain
int TRSMain(int argc, const char** argv) {
  trs::TRSBrowserMain trs_main;

  // Реєструємо наш контент-клієнт замість Chrome
  trs::TRSContentClient content_client;
  content::SetContentClient(&content_client);

  // Передаємо керування Chromium content framework
  content::ContentMainParams params(&content_client);
  params.argc = argc;
  params.argv = argv;

  return content::ContentMain(std::move(params));
}
