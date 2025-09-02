import { Controller } from "@hotwired/stimulus"

// Контроллер для сброса формы после отправки
export default class extends Controller {
  reset() {
    this.element.reset()
  }
}
