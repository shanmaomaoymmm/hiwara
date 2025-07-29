import { createApp } from "vue";
import App from "./App.vue";
import router from "./router";
import "./assets/main.scss";

import { library } from '@fortawesome/fontawesome-svg-core'
import { FontAwesomeIcon } from '@fortawesome/vue-fontawesome'
import { fas } from '@fortawesome/free-solid-svg-icons'
import { far } from '@fortawesome/free-regular-svg-icons'
import { fab } from '@fortawesome/free-brands-svg-icons'

import 'vuetify/styles'
import { createVuetify } from 'vuetify'
import * as components from 'vuetify/components'
import * as directives from 'vuetify/directives'

const app = createApp(App);
app.use(router);

library.add(fas, far, fab)
app.component('font-awesome-icon', FontAwesomeIcon)

const vuetify = createVuetify({
  components,
  directives,
})
app.use(vuetify);

app.mount("#app");
