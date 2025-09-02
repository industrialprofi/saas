import { Controller } from "@hotwired/stimulus"
import { initFlowbite } from "flowbite"

// Контроллер для инициализации компонентов Flowbite
export default class extends Controller {
  connect() {
    // Инициализируем компоненты Flowbite при подключении контроллера
    initFlowbite()
  }
}
