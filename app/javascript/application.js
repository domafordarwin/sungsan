// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "@hotwired/turbo-rails"
import "controllers"

// Global helper: update survey question options from comma-separated input
window.updateOptions = function(input) {
  const card = input.closest(".survey-question-card")
  const fieldName = input.dataset.fieldName
  if (!fieldName) return

  card.querySelectorAll("input[type=hidden][name*=options]").forEach(h => h.remove())
  const options = input.value.split(",").map(s => s.trim()).filter(Boolean)
  options.forEach(opt => {
    const hidden = document.createElement("input")
    hidden.type = "hidden"
    hidden.name = fieldName
    hidden.value = opt
    card.appendChild(hidden)
  })
}
