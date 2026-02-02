// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//
// If you have dependencies that try to import CSS, esbuild will generate a separate `app.css` file.
// To load it, simply add a second `<link>` to your `root.html.heex` file.

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import {hooks as colocatedHooks} from "phoenix-colocated/mon_app"
import topbar from "../vendor/topbar"

const csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Custom hooks for chat
const Hooks = {
  ...colocatedHooks,

  // Auto-scroll to bottom of messages container
  ScrollToBottom: {
    mounted() {
      // Compter les messages initiaux
      this.messageCount = this.countMessages()
      this.scrollToBottom()

      this.handleEvent("scroll_to_bottom", () => {
        this.scrollToBottom()
      })
      // Handle scroll to specific message
      this.handleEvent("scroll_to_message", ({ id }) => {
        const element = document.getElementById(`message-${id}`)
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' })
          // Highlight briefly
          element.classList.add('animate-pulse', 'bg-primary/10')
          setTimeout(() => {
            element.classList.remove('animate-pulse', 'bg-primary/10')
          }, 2000)
        }
      })
      // Handle copy to clipboard
      this.handleEvent("copy_to_clipboard", ({ text }) => {
        if (navigator.clipboard) {
          navigator.clipboard.writeText(text).then(() => {
            console.log("Copied to clipboard")
          }).catch(err => {
            console.error("Failed to copy:", err)
          })
        }
      })
    },
    updated() {
      // Ne scroller que si de nouveaux messages ont été ajoutés
      const newCount = this.countMessages()
      if (newCount > this.messageCount) {
        this.scrollToBottom()
      }
      this.messageCount = newCount
    },
    countMessages() {
      // Compter les éléments de message (commençant par "message-")
      return this.el.querySelectorAll('[id^="message-"]').length
    },
    scrollToBottom() {
      this.el.scrollTop = this.el.scrollHeight
    }
  },

  // Auto-resize textarea
  AutoResize: {
    mounted() {
      this.el.addEventListener("input", () => {
        this.resize()
      })
      // Reset on form submit
      this.el.form?.addEventListener("submit", () => {
        setTimeout(() => {
          this.el.style.height = "auto"
        }, 10)
      })
    },
    resize() {
      this.el.style.height = "auto"
      this.el.style.height = Math.min(this.el.scrollHeight, 128) + "px"
    }
  },

  // Format time to local timezone (always HH:MM for messages)
  LocalTime: {
    mounted() {
      this.formatTime()
    },
    updated() {
      this.formatTime()
    },
    formatTime() {
      const iso = this.el.dataset.time
      if (iso) {
        const date = new Date(iso + "Z") // Ajouter Z pour indiquer UTC
        // Toujours afficher HH:MM en heure locale
        const formatted = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
        this.el.textContent = formatted
      }
    }
  },

  // Format time compact (for conversation list - Messenger style: "3h", "2j")
  LocalTimeCompact: {
    mounted() {
      this.formatTime()
    },
    updated() {
      this.formatTime()
    },
    formatTime() {
      const iso = this.el.dataset.time
      if (iso) {
        const date = new Date(iso + "Z")
        const now = new Date()
        const diffMs = now - date
        const diffSecs = Math.floor(diffMs / 1000)
        const diffMins = Math.floor(diffSecs / 60)
        const diffHours = Math.floor(diffMins / 60)
        const diffDays = Math.floor(diffHours / 24)

        let formatted
        if (diffMins < 1) {
          formatted = "1m"
        } else if (diffMins < 60) {
          formatted = `${diffMins}m`
        } else if (diffHours < 24) {
          formatted = `${diffHours}h`
        } else if (diffDays < 7) {
          formatted = `${diffDays}j`
        } else {
          formatted = date.toLocaleDateString([], { day: '2-digit', month: '2-digit' })
        }
        this.el.textContent = formatted
      }
    }
  },

  // Format time relative (for conversation list)
  LocalTimeRelative: {
    mounted() {
      this.formatTime()
    },
    updated() {
      this.formatTime()
    },
    formatTime() {
      const iso = this.el.dataset.time
      if (iso) {
        const date = new Date(iso + "Z")
        const now = new Date()

        // Comparer les dates (sans l'heure)
        const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate())
        const todayOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const diffDays = Math.floor((todayOnly - dateOnly) / (1000 * 60 * 60 * 24))

        let formatted
        if (diffDays === 0) {
          // Aujourd'hui - afficher HH:MM
          formatted = date.toLocaleTimeString([], { hour: '2-digit', minute: '2-digit', hour12: false })
        } else if (diffDays === 1) {
          formatted = "Hier"
        } else if (diffDays < 7) {
          const days = ['Dim', 'Lun', 'Mar', 'Mer', 'Jeu', 'Ven', 'Sam']
          formatted = days[date.getDay()]
        } else {
          formatted = date.toLocaleDateString([], { day: '2-digit', month: '2-digit' })
        }
        this.el.textContent = formatted
      }
    }
  },

  // Format date for dividers
  LocalDate: {
    mounted() {
      this.formatDate()
    },
    updated() {
      this.formatDate()
    },
    formatDate() {
      const iso = this.el.dataset.date
      if (iso) {
        const date = new Date(iso + "Z")
        const now = new Date()

        // Comparer les dates (sans l'heure)
        const dateOnly = new Date(date.getFullYear(), date.getMonth(), date.getDate())
        const todayOnly = new Date(now.getFullYear(), now.getMonth(), now.getDate())
        const diffDays = Math.floor((todayOnly - dateOnly) / (1000 * 60 * 60 * 24))

        const days = ['dimanche', 'lundi', 'mardi', 'mercredi', 'jeudi', 'vendredi', 'samedi']
        const months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre']

        let formatted
        if (diffDays === 0) {
          formatted = "Aujourd'hui"
        } else if (diffDays === 1) {
          formatted = "Hier"
        } else if (diffDays < 7) {
          // Cette semaine - afficher le jour complet avec majuscule
          formatted = days[date.getDay()].charAt(0).toUpperCase() + days[date.getDay()].slice(1)
        } else if (diffDays < 365 && date.getFullYear() === now.getFullYear()) {
          // Cette année - afficher "jour mois" ex: "5 janvier"
          formatted = `${date.getDate()} ${months[date.getMonth()]}`
        } else {
          // Année différente - afficher "jour mois année"
          formatted = `${date.getDate()} ${months[date.getMonth()]} ${date.getFullYear()}`
        }
        this.el.textContent = formatted
      }
    }
  },

  // Chat input with auto-resize and Enter to send
  ChatInput: {
    mounted() {
      this.el.addEventListener("input", () => {
        this.resize()
      })

      // Enter pour envoyer, Shift+Enter pour nouvelle ligne
      this.el.addEventListener("keydown", (e) => {
        if (e.key === "Enter" && !e.shiftKey) {
          e.preventDefault()
          const form = this.el.closest("form")
          // Vérifier s'il y a du texte ou des images en preview
          const hasText = this.el.value.trim() !== ""
          const hasImages = document.querySelectorAll('[phx-click="cancel-chat-upload"]').length > 0
          if (form && (hasText || hasImages)) {
            form.dispatchEvent(new Event("submit", { bubbles: true, cancelable: true }))
          }
        }
      })

      // Reset après envoi
      this.el.form?.addEventListener("submit", () => {
        setTimeout(() => {
          this.el.style.height = "auto"
          this.el.value = ""
          this.el.focus()
        }, 10)
      })

      // Focus initial
      this.el.focus()
    },
    updated() {
      // Re-focus après mise à jour si le champ est vide
      if (this.el.value === "") {
        this.el.focus()
      }
    },
    resize() {
      this.el.style.height = "auto"
      this.el.style.height = Math.min(this.el.scrollHeight, 112) + "px"
    }
  },

  // Context menu for messages (long press on mobile, right-click on desktop)
  MessageContextMenu: {
    mounted() {
      this.longPressTimer = null
      this.longPressTriggered = false
      const messageId = this.el.dataset.messageId

      // Long press pour mobile
      this.el.addEventListener("touchstart", (e) => {
        this.longPressTriggered = false
        this.longPressTimer = setTimeout(() => {
          this.longPressTriggered = true
          // Vibration feedback si disponible
          if (navigator.vibrate) {
            navigator.vibrate(50)
          }
          this.pushEvent("open_context_menu", { id: messageId })
        }, 500) // 500ms pour long press
      })

      this.el.addEventListener("touchend", (e) => {
        clearTimeout(this.longPressTimer)
        // Empêcher le clic si long press a été déclenché
        if (this.longPressTriggered) {
          e.preventDefault()
        }
      })

      this.el.addEventListener("touchmove", () => {
        clearTimeout(this.longPressTimer)
      })

      this.el.addEventListener("touchcancel", () => {
        clearTimeout(this.longPressTimer)
      })

      // Clic droit pour desktop (optionnel)
      this.el.addEventListener("contextmenu", (e) => {
        // Empêcher le menu contextuel natif seulement sur mobile
        if (window.innerWidth < 768) {
          e.preventDefault()
        }
      })
    },

    destroyed() {
      clearTimeout(this.longPressTimer)
    }
  },

  // Scroll to specific message
  ScrollToMessage: {
    mounted() {
      this.handleEvent("scroll_to_message", ({ id }) => {
        const element = document.getElementById(`message-${id}`)
        if (element) {
          element.scrollIntoView({ behavior: 'smooth', block: 'center' })
          // Highlight briefly
          element.classList.add('bg-primary/10')
          setTimeout(() => {
            element.classList.remove('bg-primary/10')
          }, 2000)
        }
      })
    }
  },

  // Copy to clipboard
  CopyToClipboard: {
    mounted() {
      this.handleEvent("copy_to_clipboard", ({ text }) => {
        if (navigator.clipboard) {
          navigator.clipboard.writeText(text).then(() => {
            // Feedback visuel optionnel
            console.log("Copied to clipboard")
          }).catch(err => {
            console.error("Failed to copy:", err)
          })
        }
      })
    }
  }
}

const liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: Hooks,
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", info => {
  // Only show topbar for navigation events, not for form validation/uploads
  // kind can be: "redirect", "patch", "initial"
  // For form changes (like upload validation), kind is usually "patch" but triggered very quickly
  // We use a longer delay to avoid flashing for quick operations
  if (info.detail?.kind === "redirect") {
    topbar.show(100)
  } else {
    topbar.show(500)
  }
})
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

// The lines below enable quality of life phoenix_live_reload
// development features:
//
//     1. stream server logs to the browser console
//     2. click on elements to jump to their definitions in your code editor
//
if (process.env.NODE_ENV === "development") {
  window.addEventListener("phx:live_reload:attached", ({detail: reloader}) => {
    // Enable server log streaming to client.
    // Disable with reloader.disableServerLogs()
    reloader.enableServerLogs()

    // Open configured PLUG_EDITOR at file:line of the clicked element's HEEx component
    //
    //   * click with "c" key pressed to open at caller location
    //   * click with "d" key pressed to open at function component definition location
    let keyDown
    window.addEventListener("keydown", e => keyDown = e.key)
    window.addEventListener("keyup", _e => keyDown = null)
    window.addEventListener("click", e => {
      if(keyDown === "c"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtCaller(e.target)
      } else if(keyDown === "d"){
        e.preventDefault()
        e.stopImmediatePropagation()
        reloader.openEditorAtDef(e.target)
      }
    }, true)

    window.liveReloader = reloader
  })
}

