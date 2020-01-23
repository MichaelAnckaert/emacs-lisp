;;;; nad.el - Edit region in a narrowed view with a specific mode
;;;; Update: 2020-01-23
;;;; Author: Michael Anckaert <michael.anckaert@sinax.be>
;;;; https://www.sinax.be

(defvar *nad-saved-mode* nil)

(defun nad-store-mode (&rest args)
  "Hook to add before narrow. Stores the current mode so we can restore it later"
  (setf *nad-saved-mode* major-mode)
  (message "Stored mode: %s" *nad-saved-mode*))

(defun nad-restore-mode (&rest args)
  "hook to add after widen. Restores the saved mode"
  (message "Restoring mode to %s" *nad-saved-mode*)
  (funcall *nad-saved-mode*))

(defun nad-edit-region (mode)
  "Function that prompts for the requested mode and narrows the buffer to better edit the current region"
  (interactive "sMode to edit region in: ")
  (narrow-to-region (mark) (point))
  (message "Setting mode to %s" mode)
  (funcall (intern mode)))
  
(advice-add 'narrow-to-region :before #'nad-store-mode)
(advice-add 'widen :after #'nad-restore-mode)


;;; The section below is a solution from
;;; https://www.emacswiki.org/emacs/IndirectBuffers It creates an
;;; indirect buffer (interesting!!) from the current buffer. One
;;; issue: the mode works, for example python mode, but syntax
;;; highlighting does not since the indirect buffer shares the text
;;; _and properties_ with the source buffer.

(defvar indirect-mode-name nil
  "Mode to set for indirect buffers.")
(make-variable-buffer-local 'indirect-mode-name)

(defun indirect-region (start end)
  "Edit the current region in another buffer.
    If the buffer-local variable `indirect-mode-name' is not set, prompt
    for mode name to choose for the indirect buffer interactively.
    Otherwise, use the value of said variable as argument to a funcall."
  (interactive "r")
  (let ((buffer-name (generate-new-buffer-name "*indirect*"))
	(mode
	 (if (not indirect-mode-name)
	     (setq indirect-mode-name
		   (intern
		    (completing-read 
		     "Mode: "
		     (mapcar (lambda (e) 
			       (list (symbol-name e)))
			     (apropos-internal "-mode$" 'commandp))
		     nil t)))
	   indirect-mode-name)))
    (pop-to-buffer (make-indirect-buffer (current-buffer) buffer-name))
    (funcall mode)
    (narrow-to-region start end)
    (goto-char (point-min))
    (shrink-window-if-larger-than-buffer)))
