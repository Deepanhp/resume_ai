import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    this.refreshInterval = setInterval(() => {
      this.refresh()
    }, 5000) // Refresh every 5 seconds
  }

  disconnect() {
    if (this.refreshInterval) {
      clearInterval(this.refreshInterval)
    }
  }

  refresh() {
    this.element.requestSubmit()
  }
} 