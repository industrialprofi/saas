import { Controller } from "@hotwired/stimulus"

// Контроллер для автоматической прокрутки чата при новых сообщениях
export default class extends Controller {
  connect() {
    this.scrollToBottom()
    this.element.addEventListener("DOMNodeInserted", this.scrollToBottom.bind(this))
  }

  disconnect() {
    this.element.removeEventListener("DOMNodeInserted", this.scrollToBottom.bind(this))
  }

  scrollToBottom() {
    this.element.scrollTop = this.element.scrollHeight
  }
}
