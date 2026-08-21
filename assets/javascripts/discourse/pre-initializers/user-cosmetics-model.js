import { withPluginApi } from "discourse/lib/plugin-api";

export default {
  name: "user-cosmetics-model",
  before: "inject-discourse-objects",
  initialize() {
    withPluginApi("1.8.0", (api) => {
      // Kullanıcı (user) modeline eklenecek veri alanı çok erken aşamada yüklenmeli.
      if (typeof api.addModelField === "function") {
        api.addModelField("user", "cosmetics", { defaultValue: null });
      }
    });
  },
};