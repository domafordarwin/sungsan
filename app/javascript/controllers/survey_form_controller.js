import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["container"]

  addQuestion() {
    const template = document.getElementById("question-template")
    const clone = template.content.cloneNode(true)
    const idx = Date.now()

    clone.querySelectorAll("[name]").forEach(el => {
      el.name = el.name.replace("NEW_IDX", idx)
    })
    clone.querySelectorAll("[id]").forEach(el => {
      el.id = el.id.replace("NEW_IDX", idx)
    })
    clone.querySelectorAll("[for]").forEach(el => {
      el.htmlFor = el.htmlFor.replace("NEW_IDX", idx)
    })

    // Handle options field
    clone.querySelectorAll(".options-input").forEach(el => {
      const fieldName = el.dataset.fieldName.replace("NEW_IDX", idx)
      el.addEventListener("change", function() {
        // Remove old hidden fields
        const card = this.closest(".survey-question-card")
        card.querySelectorAll("input[type=hidden][name*=options]").forEach(h => h.remove())

        // Create hidden fields for each option
        const options = this.value.split(",").map(s => s.trim()).filter(Boolean)
        options.forEach(opt => {
          const hidden = document.createElement("input")
          hidden.type = "hidden"
          hidden.name = fieldName
          hidden.value = opt
          card.appendChild(hidden)
        })
      })
    })

    this.containerTarget.appendChild(clone)
  }
}
