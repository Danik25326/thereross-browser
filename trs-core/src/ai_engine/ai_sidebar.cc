// =============================================================================
// TRS Browser — ai_sidebar.cc
// Нативний AI-помічник браузера.
// НЕ розширення — вбудований на рівні браузера.
//
// Функції:
//   - Аналіз відкритої сторінки
//   - Конспект статті
//   - Переклад (акцент на UA↔EN)
//   - Відповіді на питання про контент сторінки
// =============================================================================

#include "trs/ai_engine/ai_sidebar.h"
#include "trs/ai_engine/page_analyzer.h"

#include "base/json/json_writer.h"
#include "base/logging.h"
#include "base/values.h"
#include "content/public/browser/web_contents.h"
#include "net/http/http_request_headers.h"
#include "services/network/public/cpp/resource_request.h"

namespace trs {

// API endpoint — заміни на свій або локальну модель
constexpr char kAIEndpoint[] = "https://api.anthropic.com/v1/messages";
// Або локально: "http://localhost:11434/api/generate" (Ollama)

AIEngine::AIEngine() : initialized_(false) {}
AIEngine::~AIEngine() = default;

void AIEngine::Initialize() {
  page_analyzer_ = std::make_unique<PageAnalyzer>();
  initialized_ = true;
  LOG(INFO) << "[TRS AI] Ініціалізовано";
}

// Головна функція: аналізуємо поточну сторінку
void AIEngine::AnalyzeCurrentPage(content::WebContents* web_contents,
                                   AnalysisType type,
                                   AIResultCallback callback) {
  if (!initialized_) {
    std::move(callback).Run(AIResult::Error("AI не ініціалізовано"));
    return;
  }

  // 1. Витягуємо текст зі сторінки
  page_analyzer_->ExtractText(
      web_contents,
      base::BindOnce(&AIEngine::OnPageTextExtracted,
                     weak_factory_.GetWeakPtr(),
                     type,
                     std::move(callback)));
}

void AIEngine::OnPageTextExtracted(AnalysisType type,
                                    AIResultCallback callback,
                                    const std::string& page_text) {
  if (page_text.empty()) {
    std::move(callback).Run(AIResult::Error("Не вдалося витягти текст"));
    return;
  }

  // 2. Формуємо промпт залежно від типу аналізу
  std::string prompt = BuildPrompt(type, page_text);

  // 3. Відправляємо запит до AI
  SendAIRequest(prompt, std::move(callback));
}

std::string AIEngine::BuildPrompt(AnalysisType type,
                                   const std::string& page_text) {
  // Обрізаємо текст якщо дуже довгий (контекстне вікно)
  std::string text = page_text.substr(0, 8000);

  switch (type) {
    case AnalysisType::kSummarize:
      return "Зроби стислий конспект цього тексту українською мовою "
             "у 5–7 пунктах:\n\n" + text;

    case AnalysisType::kTranslate:
      return "Переклади цей текст українською мовою, зберігаючи стиль:\n\n"
             + text;

    case AnalysisType::kExplain:
      return "Поясни простими словами українською мовою про що цей текст, "
             "для людини яка бачить цю тему вперше:\n\n" + text;

    case AnalysisType::kFacts:
      return "Витягни 5–10 ключових фактів і цифр з цього тексту, "
             "відповідь дай маркованим списком українською:\n\n" + text;

    default:
      return "Проаналізуй цей текст:\n\n" + text;
  }
}

void AIEngine::SendAIRequest(const std::string& prompt,
                              AIResultCallback callback) {
  // Формуємо JSON для Anthropic API
  // Заміни на інший API якщо потрібно
  base::Value::Dict request_body;
  request_body.Set("model", "claude-sonnet-4-6");
  request_body.Set("max_tokens", 1024);

  base::Value::List messages;
  base::Value::Dict message;
  message.Set("role", "user");
  message.Set("content", prompt);
  messages.Append(std::move(message));

  request_body.Set("messages", std::move(messages));

  std::string json_body;
  base::JSONWriter::Write(base::Value(std::move(request_body)), &json_body);

  // TODO: відправити HTTP запит через Chromium network service
  // Повний приклад — в docs/ai_integration.md
  LOG(INFO) << "[TRS AI] Запит відправлено: " << prompt.substr(0, 50) << "...";

  // Тимчасовий stub — замінити на реальний network request
  std::move(callback).Run(AIResult::Success("(AI відповідь з'явиться тут)"));
}

// =============================================================================
// AISidebar — UI частина (WebUI панель у браузері)
// =============================================================================

AISidebar::AISidebar(content::WebContents* web_contents)
    : web_contents_(web_contents) {}

AISidebar::~AISidebar() = default;

void AISidebar::Show() {
  visible_ = true;
  // TODO: показати sidebar WebUI
  LOG(INFO) << "[TRS AI Sidebar] Відкрито";
}

void AISidebar::Hide() {
  visible_ = false;
  LOG(INFO) << "[TRS AI Sidebar] Закрито";
}

void AISidebar::Toggle() {
  visible_ ? Hide() : Show();
}

}  // namespace trs
