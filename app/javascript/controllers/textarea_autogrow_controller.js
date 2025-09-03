import { Controller } from "@hotwired/stimulus"

// Auto-grows a textarea height to fit content
export default class extends Controller {
  connect() {
    // Ensure the element is a textarea
    if (this.element.tagName !== 'TEXTAREA') return
    // Initialize height
    this.grow()
    // Bind input listener
    this.element.addEventListener('input', this.grow)
  }

  disconnect() {
    this.element.removeEventListener('input', this.grow)
  }

  grow = () => {
    // Reset height to measure scrollHeight properly
    this.element.style.height = 'auto'
    // Add small offset for border/padding consistency
    this.element.style.height = `${this.element.scrollHeight}px`
  }
}
