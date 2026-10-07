import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  static targets = ["input", "results", "tmdbId", "mediaType", "posterPath", "year", "overview"]

  search() {
    this.clearSelection()
    clearTimeout(this.timer)

    const query = this.inputTarget.value.trim()
    if (query.length < 2) return this.clearResults()

    this.timer = setTimeout(() => this.fetchResults(query), 300)
  }

  async fetchResults(query) {
    try {
      const response = await fetch(`/tmdb/search?q=${encodeURIComponent(query)}`, {
        headers: { Accept: "application/json" }
      })
      if (!response.ok) return this.clearResults()
      this.render(await response.json())
    } catch {
      this.clearResults()
    }
  }

  render(items) {
    this.clearResults()
    items.forEach((item) => {
      const li = document.createElement("li")
      const button = document.createElement("button")
      button.type = "button"
      button.className = "nerv-suggestion"
      button.textContent = item.year ? `${item.title} (${item.year})` : item.title
      button.addEventListener("click", () => this.select(item))
      li.appendChild(button)
      this.resultsTarget.appendChild(li)
    })
  }

  select(item) {
    this.inputTarget.value = item.title
    this.tmdbIdTarget.value = item.tmdb_id ?? ""
    this.mediaTypeTarget.value = item.media_type ?? ""
    this.posterPathTarget.value = item.poster_path ?? ""
    this.yearTarget.value = item.year ?? ""
    this.overviewTarget.value = item.overview ?? ""
    this.clearResults()
  }

  clearSelection() {
    ;[this.tmdbIdTarget, this.mediaTypeTarget, this.posterPathTarget,
      this.yearTarget, this.overviewTarget].forEach((field) => (field.value = ""))
  }

  clearResults() {
    this.resultsTarget.replaceChildren()
  }
}
