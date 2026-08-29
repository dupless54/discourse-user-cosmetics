import { apiInitializer } from "discourse/lib/api";
import UserCosmeticsShowcase from "../components/user-cosmetics-showcase";

export default apiInitializer("1.8.0", (api) => {
  if (typeof api.renderInOutlet !== "function") {
    return;
  }

  api.renderInOutlet("user-profile-primary", UserCosmeticsShowcase);
});
