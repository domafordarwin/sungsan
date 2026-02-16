import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["display", "form"]

  toggle() {
    this.displayTarget.hidden = true
    this.formTarget.hidden = false
    this.formTarget.querySelector("input[type='text']")?.focus()
  }

  cancel() {
    this.formTarget.hidden = true
    this.displayTarget.hidden = false
  }
}
