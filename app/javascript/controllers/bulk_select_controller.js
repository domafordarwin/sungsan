import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["selectAll", "checkbox", "count", "submitBtn"]

  connect() {
    this.updateUI()
  }

  toggleAll() {
    const checked = this.selectAllTarget.checked
    this.checkboxTargets.forEach(cb => cb.checked = checked)
    this.updateUI()
  }

  toggle() {
    const allChecked = this.checkboxTargets.every(cb => cb.checked)
    this.selectAllTarget.checked = allChecked
    this.updateUI()
  }

  updateUI() {
    const selected = this.checkboxTargets.filter(cb => cb.checked).length
    this.countTarget.textContent = selected > 0 ? `${selected}명 선택` : ""
    this.submitBtnTarget.disabled = selected === 0
  }
}
