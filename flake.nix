{
  description = "NixOS developer environment for the InaSAFE docs + website (MkDocs Material) site.";

  # Tracking nixos-unstable by branch rather than a pinned revision for now —
  # flake.lock pins the actual resolved commit on first `nix flake lock`/
  # `check`, so this is still reproducible once the lockfile is committed.
  # Bump by running `nix flake update` periodically.
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

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
          pkgs.reuse
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
