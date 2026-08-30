import Component from "@glimmer/component";
import { get } from "@ember/object";
import { i18n } from "discourse-i18n";

export default class UserCosmeticsShowcase extends Component {
  get user() {
    return (
      this.args.outletArgs?.user ??
      this.args.outletArgs?.model ??
      this.args.model
    );
  }

  get showcase() {
    const value = get(this.user, "cosmetics_showcase");
    return Array.isArray(value) ? value : [];
  }

  get countLabel() {
    return i18n("discourse_user_cosmetics.showcase.profile_count", {
      count: this.showcase.length,
    });
  }

  <template>
    {{#if this.showcase.length}}
      <section
        class="duc-profile-showcase"
        aria-label={{i18n "discourse_user_cosmetics.showcase.profile_title"}}
      >
        <header class="duc-profile-showcase__header">
          <div>
            <h3>{{i18n "discourse_user_cosmetics.showcase.profile_title"}}</h3>
            <p>{{i18n "discourse_user_cosmetics.showcase.profile_subtitle"}}</p>
          </div>
          <span class="duc-profile-showcase__count">{{this.countLabel}}</span>
        </header>

        <div class="duc-profile-showcase__grid">
          {{#each this.showcase as |item|}}
            <article
              class="duc-profile-showcase__item
                duc-profile-showcase__item--{{item.kind}}"
            >
              <div class="duc-profile-showcase__preview">
                {{#if item.image_url}}
                  <img src={{item.image_url}} alt="" loading="lazy" />
                {{else}}
                  <span
                    class="duc-profile-showcase__placeholder"
                    aria-hidden="true"
                  ></span>
                {{/if}}
              </div>

              <div class="duc-profile-showcase__meta">
                <strong title={{item.name}}>{{item.name}}</strong>
                {{#if item.rarity_label}}
                  <span>{{item.rarity_label}}</span>
                {{/if}}
              </div>
            </article>
          {{/each}}
        </div>
      </section>
    {{/if}}
  </template>
}
