(defun ycmd-setup-completion-at-point-function ()
  "Setup `completion-at-point-functions' for `ycmd-mode'."
  (add-hook 'completion-at-point-functions
            #'ycmd-complete-at-point nil :local))

(add-hook 'ycmd-mode #'ycmd-setup-completion-at-point-function)

(when (require 'company nil t)
  (add-hook 'after-init-hook 'global-company-mode))
(when (require 'elpy nil t)
  (elpy-enable))
