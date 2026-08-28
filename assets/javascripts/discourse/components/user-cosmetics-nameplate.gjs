import Component from "@glimmer/component";
import { get } from "@ember/object";
import { htmlSafe } from "@ember/template";

export default class UserCosmeticsNameplate extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get nameplate() {
    return get(this.user, "cosmetics")?.nameplate;
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

    return htmlSafe(`
      /* 1. Kullanıcı Kartındaki İsim Alanı */
      #user-card .name-username-wrapper {
        ${bgCss}
        background-size: cover;
        background-position: center;
        padding: 4px 10px !important;
        border-radius: 8px;
        width: fit-content;
        max-width: 100%;
      }

      /* 2. Profil Sayfası (Sadece Ana Nick Alanı: İkiye bölünmeyi önler) */
      .user-profile-names .user-profile-names__primary {
        ${bgCss}
        background-size: cover;
        background-position: center;
        padding: 4px 14px !important;
        border-radius: 10px;
        display: inline-block !important; /* Sadece yazı kadar yer kaplamasını sağlar */
        width: fit-content;
        max-width: 100%;
      }

      /* YAZI OKUNABİLİRLİĞİ: Her renk arkaplanda kusursuz okunması için 3 katmanlı kalın siyah gölge */
      #user-card .name-username-wrapper,
      #user-card .name-username-wrapper *,
      .user-profile-names .user-profile-names__primary,
      .user-profile-names .user-profile-names__primary * {
        color: #ffffff !important;
        text-shadow: 
          0px 1px 2px #000000, 
          0px 0px 4px #000000, 
          0px 0px 8px #000000 !important;
      }
    `);
  }

  <template>
    {{#if this.nameplate}}
      <style>{{this.nameplateStyle}}</style>
    {{/if}}
  </template>
}