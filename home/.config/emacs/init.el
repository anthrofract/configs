(setq inhibit-startup-message t)
(setq auto-save-default nil)

(setq custom-safe-themes t)
(load-theme 'doom-material-dark t)

(set-face-attribute 'default nil :font "JetBrains Mono NL" :height 130)
(add-to-list 'default-frame-alist '(fullscreen . maximized))

(menu-bar-mode -1)
(tool-bar-mode -1)
(scroll-bar-mode -1)
(blink-cursor-mode -1)

(global-display-line-numbers-mode 1)

(vertico-mode 1)
(setq completion-styles '(orderless basic))

(setq which-key-idle-delay 0)
(which-key-mode 1)

(require 'project)

(require 'consult)
(consult-customize consult-find consult-fd :state (consult--file-preview))

(require 'multiple-cursors)
(setq mc/always-run-for-all t)

(require 'magit)

(require 'helix)
(helix-mode)
(helix-define-key 'space "f" #'consult-fd)
(helix-define-key 'space "/" #'consult-ripgrep)

(require 'eglot)

(require 'treesit-auto)
(setq treesit-auto-install nil)
(treesit-auto-add-to-auto-mode-alist 'all)
(global-treesit-auto-mode)

(add-hook 'rust-ts-mode-hook #'eglot-ensure)
