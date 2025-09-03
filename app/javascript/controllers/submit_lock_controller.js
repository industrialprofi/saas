import { Controller } from "@hotwired/stimulus"

// Disables submit when remaining quota is zero
export default class extends Controller {
  static values = {
    remaining: Number
  }

  connect() {
    this.toggle()
  }

  toggle() {
    const button = this.element.querySelector('input[type="submit"], button[type="submit"]')
    const input = this.element.querySelector('input[name="message[content]"], textarea[name="message[content]"]')
    if (!button) return

    const exhausted = (this.remainingValue || 0) <= 0
    button.disabled = exhausted
    if (input) input.disabled = exhausted

    if (exhausted) {
      button.title = "Достигнут дневной лимит запросов"
    } else {
      button.removeAttribute('title')
    }
  }
}
