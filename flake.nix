{
  description = "NixOS developer environment for the InaSAFE docs + website (MkDocs Material) site.";

  # Pinned to the same nixos-unstable revision as the inasafe and GeoE3
  # flakes (2026-06-15) rather than tracking the nixos-unstable branch HEAD:
  # a later revision shipped a broken `reuse` package (builder fails to
  # produce its "man" output), which broke CI. Bump deliberately, not via
  # `nix flake update`, and verify `nix flake check` passes first.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/b4f4a5cf27a0eb848c6212be746a0a718f3bb019";

  outputs =
    { self, nixpkgs }:
    let
      system = "x86_64-linux";
      pkgs = import nixpkgs { inherit system; };

      mkdocsEnv = pkgs.python3.withPackages (ps: [
        ps.mkdocs
        ps.mkdocs-material
        ps.mkdocs-material-extensions
        ps.mkdocs-glightbox
        ps.mkdocs-git-revision-date-localized-plugin
        ps.mkdocs-mermaid2-plugin
        ps.pymdown-extensions
      ]);

      # Wrap a repo-relative script so `nix run .#foo` runs it inside the
      # project's nix develop shell, no matter the user's current dir.
      mkScriptApp =
        scriptPath:
        {
          type = "app";
          program = "${pkgs.writeShellScript (baseNameOf scriptPath) ''
            ROOT="$(git rev-parse --show-toplevel 2> /dev/null || pwd)"
            cd "$ROOT"
            exec nix develop --command bash "$ROOT/${scriptPath}" "$@"
          ''}";
        };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          mkdocsEnv
          pkgs.git
          pkgs.pre-commit
          # pkgs.reuse was dropped: not yet load-bearing (no REUSE.toml/
          # LICENSE exists — see SPECIFICATION.md), and the specific build
          # that broke CI was this package's "man" output. Re-add once a
          # license is decided and REUSE.toml is actually wired up.
          pkgs.markdownlint-cli
          pkgs.yamllint
          pkgs.yamlfmt
          pkgs.actionlint
          pkgs.cspell
          pkgs.gitleaks
          pkgs.nixfmt-rfc-style
          pkgs.nodejs # runs scripts/migrate_wp_content.mjs
        ];
        shellHook = ''
          if command -v pre-commit >/dev/null && [ -d .git ]; then
            pre-commit install --install-hooks >/dev/null 2>&1 || true
          fi
        '';
      };

      apps.${system} = {
        docs-serve = mkScriptApp "scripts/docs_serve.sh";
        docs-build = mkScriptApp "scripts/docs_build.sh";
      };
    };
}
