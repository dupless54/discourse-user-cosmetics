import Component from "@glimmer/component";
import { htmlSafe } from "@ember/template"; // Ember'ın güvenlik kilidini açıyoruz

export default class UserCosmeticsNameplate extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get nameplate() {
    return this.user?.cosmetics?.nameplate;
  }

  get nameplateStyle() {
    const n = this.nameplate;
    if (!n) {
      return htmlSafe("");
    }

    let bgCss = "";
    if (n.image_url) {
      bgCss = `background-image: url("${n.image_url}");`;
    } else if (n.gradient_from && n.gradient_to) {
      bgCss = `background-image: linear-gradient(90deg, ${n.gradient_from}, ${n.gradient_to});`;
    } else {
      return htmlSafe("");
    }

    // Doğrudan Discourse'un kendi İsim/Nick kutularını hedefleyip arkaplanı yerleştiriyoruz
    return htmlSafe(`
      /* 1. Kullanıcı Kartındaki İsim Alanı */
      #user-card .name-username-wrapper {
        ${bgCss}
        background-size: cover;
        background-position: center;
        padding: 6px 12px !important;
        border-radius: 8px;
        width: fit-content; /* Arkaplanın tüm satırı kaplamaması, sadece yazı kadar olması için */
      }

      /* 2. Profil Sayfasındaki İsim Alanı */
      .user-profile-names {
        ${bgCss}
        background-size: cover;
        background-position: center;
        padding: 10px 16px !important;
        border-radius: 12px;
        width: fit-content;
      }

      /* Yazıların animasyon veya renkli arkaplanda her zaman net okunabilmesi için gölge ayarı */
      #user-card .name-username-wrapper .name,
      #user-card .name-username-wrapper .username,
      .user-profile-names .name,
      .user-profile-names .username {
        color: #ffffff !important;
        text-shadow: 0 1px 3px rgba(0, 0, 0, 0.9), 0 0 2px rgba(0, 0, 0, 0.5);
      }
    `);
  }

  <template>
    {{#if this.nameplate}}
      {{!-- Nameplate'i ayrı bir kutu olarak değil, CSS injection ile ana kutulara uyguluyoruz --}}
      <style>{{this.nameplateStyle}}</style>
    {{/if}}
  </template>
}