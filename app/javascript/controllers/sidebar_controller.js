import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["sidebar"]

  toggle() {
    const sidebar = document.querySelector(".sidebar")
    const overlay = document.querySelector(".sidebar-overlay")
    sidebar.classList.toggle("open")
    overlay.classList.toggle("open")
    document.body.classList.toggle("sidebar-open")
  }

  close() {
    const sidebar = document.querySelector(".sidebar")
    const overlay = document.querySelector(".sidebar-overlay")
    sidebar.classList.remove("open")
    overlay.classList.remove("open")
    document.body.classList.remove("sidebar-open")
  }
}
