# User Cosmetics library layer

- Presenter output is a public UI contract; keep it minimal and backward-compatible.
- CSS generation must treat stored/admin input as untrusted and prevent arbitrary CSS/URL injection.
- Seeder operations are idempotent and must not overwrite intentional admin customization.
- Keep helper queries bounded and preloaded where collections are involved.
