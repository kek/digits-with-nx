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

// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import { Socket } from "phoenix"
import { LiveSocket } from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Draw from 'draw-on-canvas'

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")

// Show progress bar on live navigation and form submits
topbar.config({ barColors: { 0: "#29d" }, shadowColor: "rgba(0, 0, 0, .3)" })
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())


// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()

let Hooks = {}
Hooks.Draw = {
    mounted() {
        this.draw = new Draw(this.el, 384, 384, {
            backgroundColor: "black",
            strokeColor: "white",
            strokeWeight: 10
        })
        this.handleEvent("reset", () => {
            this.draw.reset()
        })
        this.handleEvent("predict", () => {
            this.pushEvent("image", this.draw.canvas.toDataURL('image/png'))
        })
    }
}

let liveSocket = new LiveSocket("/live", Socket, {
    params: { _csrf_token: csrfToken },
    hooks: Hooks
})

// connect if there are any LiveViews on the page
liveSocket.connect()

window.liveSocket = liveSocket

