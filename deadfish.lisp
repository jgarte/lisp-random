;;;; deadfish.lisp
;;;;
;;;; Copyright (c) 2016 Robert Smith

;;;; Puzzle is here: http://codegolf.stackexchange.com/questions/40124/short-deadfish-numbers/

(load "enumerate-grammar")

(ql:quickload :global-vars)

;;; NOTE: This could be done more efficiently by enumerating base-4
;;; non-negative integers.
(global-vars:define-global-var **deadfish-grammar**
    (with-non-terminals (expr cmd)
      (make-grammar expr
        :expr (alternates cmd (list cmd expr))
        :cmd (alternates (terminal "i")
                         (terminal "s")
                         (terminal "d")
                         (terminal "o"))))
  "Grammar defining the Deadfish language.")

(global-vars:define-global-parameter **optimized-deadfish-grammar**
    (let ((o (terminal "o"))
          (i (terminal "i"))
          (s (terminal "s"))
          (d (terminal "d")))
      (with-non-terminals (expr prefix-expr expr-but-i expr-but-d o-cmd i-cmd s-cmd d-cmd)
        (make-grammar expr
          :expr (alternates o (list prefix-expr o))
          :prefix-expr (alternates o-cmd i-cmd s-cmd d-cmd)
          :expr-but-i (alternates o-cmd s-cmd d-cmd)
          :expr-but-d (alternates o-cmd i-cmd s-cmd)
          :s-cmd (alternates s (list s prefix-expr))
          :i-cmd (alternates i (list i expr-but-d))
          :d-cmd (alternates d (list d expr-but-i))
          :o-cmd (alternates o (list o prefix-expr)))))
  "Optimized grammar defining a subset of the Deadfish language which produce meaningful output.")



(defun execute-sentence (sentence)
  "Given a sentence SENTENCE from the Deadfish language, execute it to produce an integer result."
  (labels ((normalize-register (register)
             ;; Required according to http://esolangs.org/wiki/Deadfish
             (if (or (= -1 register)
                     (= 256 register))
                 0
                 register))
           (run (sentence register history)
             (if (null sentence)
                 (if (zerop (length history))
                     0
                     (parse-integer (format nil "~{~D~}" (nreverse history))
                                    :junk-allowed nil))
                 (let* ((cmd (first sentence))
                        (rest (rest sentence)))
                   (adt:match sym cmd
                     ((terminal x)
                      (cond
                        ((string= "i" x)
                         (run rest (normalize-register (1+ register)) history))
                        ((string= "s" x)
                         (run rest (normalize-register (* register register)) history))
                        ((string= "d" x)
                         (run rest (normalize-register (1- register)) history))
                        ((string= "o" x)
                         (run rest register (cons register history)))))
                     ((non-terminal _) (error "Invalid state: Found non-terminal ~A." cmd)))))))
    (run sentence 0 nil)))

;;; Challenge: Find all of the shortest Deadfish sentences which
;;; compute 0 to 255 inclusive.

(defun sentence-string (sentence)
  (flet ((strip (thing)
           (adt:match sym thing
             ((terminal x) x)
             ((non-terminal _) ""))))
    (apply #'concatenate 'string (mapcar #'strip sentence))))

(defun challenge ()
  (let ((sentences (make-array 256 :initial-element nil))
        (numbers-left 256))
    (flet ((fish (sentence)
             (let ((value (execute-sentence sentence)))
               (cond
                 ;; Value is in range.
                 ((not (<= 0 value 255)) nil)
                 ;; Value has already been found.
                 ((aref sentences value) nil)
                 ;; We got a new one, boys.
                 (t
                  (format t "~D/~D: ~A~%" value numbers-left (sentence-string sentence))
                  (setf (aref sentences value) sentence)
                  (decf numbers-left)))
               (when (zerop numbers-left)
                 (return-from challenge (map 'vector #'sentence-string sentences))))))
      (map-sentences #'fish **optimized-deadfish-grammar**))))

;; CL-USER> (time (challenge))
;; Timing the evaluation of (CHALLENGE)
;; 0/256: o
;; 1/255: io
;; 11/254: ioo
;; 2/253: iio
;; 111/252: iooo
;; 12/251: ioio
;; 10/250: iodo
;; 22/249: iioo
;; 3/248: iiio
;; 4/247: iiso
;; 112/246: iooio
;; 110/245: ioodo
;; 122/244: ioioo
;; 13/243: ioiio
;; 14/242: ioiso
;; 100/241: iodoo
;; 222/240: iiooo
;; 23/239: iioio
;; 24/238: iioso
;; 21/237: iiodo
;; 33/236: iiioo
;; 9/235: iiiso
;; 44/234: iisoo
;; 5/233: iisio
;; 16/232: iisso
;; 113/231: iooiio
;; 114/230: iooiso
;; 123/229: ioioio
;; 124/228: ioioso
;; 121/227: ioiodo
;; 133/226: ioiioo
;; 19/225: ioiiso
;; 144/224: ioisoo
;; 15/223: ioisio
;; 116/222: ioisso
;; 101/221: iodoio
;; 223/220: iiooio
;; 224/219: iiooso
;; 221/218: iioodo
;; 233/217: iioioo
;; 29/216: iioiso
;; 244/215: iiosoo
;; 25/214: iiosio
;; 216/213: iiosso
;; 211/212: iiodoo
;; 20/211: iioddo
;; 34/210: iiioio
;; 39/209: iiioso
;; 32/208: iiiodo
;; 99/207: iiisoo
;; 81/206: iiisso
;; 8/205: iiisdo
;; 45/204: iisoio
;; 43/203: iisodo
;; 55/202: iisioo
;; 6/201: iisiio
;; 17/200: iissio
;; 119/199: iooiiso
;; 115/198: iooisio
;; 129/197: ioioiso
;; 125/196: ioiosio
;; 120/195: ioioddo
;; 134/194: ioiioio
;; 139/193: ioiioso
;; 132/192: ioiiodo
;; 199/191: ioiisoo
;; 181/190: ioiisso
;; 18/189: ioiisdo
;; 145/188: ioisoio
;; 143/187: ioisodo
;; 155/186: ioisioo
;; 117/185: ioissio
;; 102/184: iodoiio
;; 229/183: iiooiso
;; 225/182: iioosio
;; 220/181: iiooddo
;; 234/180: iioioio
;; 239/179: iioioso
;; 232/178: iioiodo
;; 210/177: iioisio
;; 28/176: iioisdo
;; 245/175: iiosoio
;; 243/174: iiosodo
;; 255/173: iiosioo
;; 26/172: iiosiio
;; 217/171: iiossio
;; 215/170: iiossdo
;; 212/169: iiodoio
;; 200/168: iioddoo
;; 35/167: iiioiio
;; 38/166: iiiosdo
;; 31/165: iiioddo
;; 98/164: iiisodo
;; 82/163: iiissio
;; 80/162: iiissdo
;; 88/161: iiisdoo
;; 64/160: iiisdso
;; 7/159: iiisddo
;; 46/158: iisoiio
;; 40/157: iisosso
;; 49/156: iisodso
;; 42/155: iisoddo
;; 56/154: iisioio
;; 54/153: iisiodo
;; 66/152: iisiioo
;; 36/151: iisiiso
;; 160/150: iissoso
;; 118/149: iooiisdo
;; 128/148: ioioisdo
;; 126/147: ioiosiio
;; 135/146: ioiioiio
;; 138/145: ioiiosdo
;; 131/144: ioiioddo
;; 198/143: ioiisodo
;; 182/142: ioiissio
;; 180/141: ioiissdo
;; 188/140: ioiisdoo
;; 164/139: ioiisdso
;; 146/138: ioisoiio
;; 140/137: ioisosso
;; 149/136: ioisodso
;; 142/135: ioisoddo
;; 156/134: ioisioio
;; 154/133: ioisiodo
;; 166/132: ioisiioo
;; 136/131: ioisiiso
;; 103/130: iodoiiio
;; 104/129: iodoiiso
;; 228/128: iiooisdo
;; 226/127: iioosiio
;; 235/126: iioioiio
;; 238/125: iioiosdo
;; 231/124: iioioddo
;; 27/123: iioisddo
;; 246/122: iiosoiio
;; 240/121: iiososso
;; 249/120: iiosodso
;; 242/119: iiosoddo
;; 254/118: iiosiodo
;; 236/117: iiosiiso
;; 218/116: iiossiio
;; 214/115: iiossddo
;; 213/114: iiodoiio
;; 201/113: iioddoio
;; 30/112: iiioisso
;; 37/111: iiiosddo
;; 97/110: iiisoddo
;; 109/109: iiisiodo
;; 83/108: iiissiio
;; 79/107: iiissddo
;; 89/106: iiisdoio
;; 87/105: iiisdodo
;; 65/104: iiisdsio
;; 63/103: iiisdsdo
;; 77/102: iiisddoo
;; 47/101: iisoiiio
;; 41/100: iisossio
;; 48/99: iisodsdo
;; 57/98: iisioiio
;; 53/97: iisioddo
;; 67/96: iisiioio
;; 161/95: iissosio
;; 196/94: iissddso
;; 127/93: ioioisddo
;; 130/92: ioiioisso
;; 137/91: ioiiosddo
;; 197/90: ioiisoddo
;; 183/89: ioiissiio
;; 179/88: ioiissddo
;; 189/87: ioiisdoio
;; 187/86: ioiisdodo
;; 165/85: ioiisdsio
;; 163/84: ioiisdsdo
;; 177/83: ioiisddoo
;; 147/82: ioisoiiio
;; 141/81: ioisossio
;; 148/80: ioisodsdo
;; 157/79: ioisioiio
;; 153/78: ioisioddo
;; 167/77: ioisiioio
;; 105/76: iodoiisio
;; 227/75: iiooisddo
;; 230/74: iioioisso
;; 237/73: iioiosddo
;; 247/72: iiosoiiio
;; 241/71: iiosossio
;; 248/70: iiosodsdo
;; 253/69: iiosioddo
;; 219/68: iiossiiio
;; 202/67: iioddoiio
;; 96/66: iiisodddo
;; 108/65: iiisioddo
;; 84/64: iiissiiio
;; 78/63: iiissdddo
;; 86/62: iiisdoddo
;; 62/61: iiisdsddo
;; 76/60: iiisddodo
;; 50/59: iiisddsio
;; 58/58: iisioiiio
;; 59/57: iisioddso
;; 52/56: iisiodddo
;; 68/55: iisiioiio
;; 162/54: iissosiio
;; 170/53: iissiodso
;; 150/52: iissdoiso
;; 195/51: iissddsdo
;; 169/50: iissdddso
;; 184/49: ioiissiiio
;; 178/48: ioiissdddo
;; 186/47: ioiisdoddo
;; 176/46: ioiisddodo
;; 158/45: ioisioiiio
;; 159/44: ioisioddso
;; 152/43: ioisiodddo
;; 168/42: ioisiioiio
;; 106/41: iodoiisiio
;; 250/40: iioisddsio
;; 252/39: iiosiodddo
;; 203/38: iioddoiiio
;; 204/37: iioddoiiso
;; 95/36: iiisoddddo
;; 107/35: iiisiodddo
;; 85/34: iiissiiiio
;; 61/33: iiisdsdddo
;; 75/32: iiisddoddo
;; 51/31: iiisddsiio
;; 69/30: iisiioiiio
;; 171/29: iissiodsio
;; 151/28: iissdoisio
;; 194/27: iissddsddo
;; 185/26: ioiissiiiio
;; 175/25: ioiisddoddo
;; 251/24: iioisddsiio
;; 209/23: iioddoiiiso
;; 205/22: iioddoiisio
;; 94/21: iiisodddddo
;; 60/20: iiisdsddddo
;; 74/19: iiisddodddo
;; 172/18: iissiodsiio
;; 193/17: iissddsdddo
;; 174/16: ioiisddodddo
;; 208/15: iioddoiiisdo
;; 206/14: iioddoiisiio
;; 93/13: iiisoddddddo
;; 73/12: iiisddoddddo
;; 173/11: iissiodsiiio
;; 192/10: iissddsddddo
;; 207/9: iioddoiiisddo
;; 90/8: iiisodddddsso
;; 92/7: iiisodddddddo
;; 70/6: iiisdsiiiiiio
;; 72/5: iiisddodddddo
;; 190/4: iissiiiodddso
;; 191/3: iissddsdddddo
;; 91/2: iiisodddddssio
;; 71/1: iiisdsiiiiiiio

;; User time    =  0:13:33.207
;; System time  =       24.126
;; Elapsed time =  0:14:16.050
;; Allocation   = 241377567520 bytes
;; 6154386 Page faults
;; Calls to %EVAL    1151650588
;; #("o" "io" "iio" "iiio" "iiso" "iisio" "iisiio" "iiisddo" "iiisdo" "iiiso" "iodo" "ioo" "ioio" "ioiio" "ioiso" "ioisio" "iisso" "iissio" "ioiisdo" "ioiiso" "iioddo" "iiodo" "iioo" "iioio" "iioso" "iiosio" "iiosiio" "iioisddo" "iioisdo" "iioiso" "iiioisso" "iiioddo" "iiiodo" "iiioo" "iiioio" "iiioiio" "iisiiso" "iiiosddo" "iiiosdo" "iiioso" "iisosso" "iisossio" "iisoddo" "iisodo" "iisoo" "iisoio" "iisoiio" "iisoiiio" "iisodsdo" "iisodso" "iiisddsio" "iiisddsiio" "iisiodddo" "iisioddo" "iisiodo" "iisioo" "iisioio" "iisioiio" "iisioiiio" "iisioddso" "iiisdsddddo" "iiisdsdddo" "iiisdsddo" "iiisdsdo" "iiisdso" "iiisdsio" "iisiioo" "iisiioio" "iisiioiio" "iisiioiiio" "iiisdsiiiiiio" "iiisdsiiiiiiio" "iiisddodddddo" "iiisddoddddo" "iiisddodddo" "iiisddoddo" "iiisddodo" "iiisddoo" "iiissdddo" "iiissddo" "iiissdo" "iiisso" "iiissio" "iiissiio" "iiissiiio" "iiissiiiio" "iiisdoddo" "iiisdodo" "iiisdoo" "iiisdoio" "iiisodddddsso" "iiisodddddssio" "iiisodddddddo" "iiisoddddddo" "iiisodddddo" "iiisoddddo" "iiisodddo" "iiisoddo" "iiisodo" "iiisoo" "iodoo" "iodoio" "iodoiio" "iodoiiio" "iodoiiso" "iodoiisio" "iodoiisiio" "iiisiodddo" "iiisioddo" "iiisiodo" "ioodo" "iooo" "iooio" "iooiio" "iooiso" "iooisio" "ioisso" "ioissio" "iooiisdo" "iooiiso" "ioioddo" "ioiodo" "ioioo" "ioioio" "ioioso" "ioiosio" "ioiosiio" "ioioisddo" "ioioisdo" "ioioiso" "ioiioisso" "ioiioddo" "ioiiodo" "ioiioo" "ioiioio" "ioiioiio" "ioisiiso" "ioiiosddo" "ioiiosdo" "ioiioso" "ioisosso" "ioisossio" "ioisoddo" "ioisodo" "ioisoo" "ioisoio" "ioisoiio" "ioisoiiio" "ioisodsdo" "ioisodso" "iissdoiso" "iissdoisio" "ioisiodddo" "ioisioddo" "ioisiodo" "ioisioo" "ioisioio" "ioisioiio" "ioisioiiio" "ioisioddso" "iissoso" "iissosio" "iissosiio" "ioiisdsdo" "ioiisdso" "ioiisdsio" "ioisiioo" "ioisiioio" "ioisiioiio" "iissdddso" "iissiodso" "iissiodsio" "iissiodsiio" "iissiodsiiio" "ioiisddodddo" "ioiisddoddo" "ioiisddodo" "ioiisddoo" "ioiissdddo" "ioiissddo" "ioiissdo" "ioiisso" "ioiissio" "ioiissiio" "ioiissiiio" "ioiissiiiio" "ioiisdoddo" "ioiisdodo" "ioiisdoo" "ioiisdoio" "iissiiiodddso" "iissddsdddddo" "iissddsddddo" "iissddsdddo" "iissddsddo" "iissddsdo" "iissddso" "ioiisoddo" "ioiisodo" "ioiisoo" "iioddoo" "iioddoio" "iioddoiio" "iioddoiiio" "iioddoiiso" "iioddoiisio" "iioddoiisiio" "iioddoiiisddo" "iioddoiiisdo" "iioddoiiiso" "iioisio" "iiodoo" "iiodoio" "iiodoiio" "iiossddo" "iiossdo" "iiosso" "iiossio" "iiossiio" "iiossiiio" "iiooddo" "iioodo" "iiooo" "iiooio" "iiooso" "iioosio" "iioosiio" "iiooisddo" "iiooisdo" "iiooiso" "iioioisso" "iioioddo" "iioiodo" "iioioo" "iioioio" "iioioiio" "iiosiiso" "iioiosddo" "iioiosdo" "iioioso" "iiososso" "iiosossio" "iiosoddo" "iiosodo" "iiosoo" "iiosoio" "iiosoiio" "iiosoiiio" "iiosodsdo" "iiosodso" "iioisddsio" "iioisddsiio" "iiosiodddo" "iiosioddo" "iiosiodo" "iiosioo")
;; CL-USER> (reduce #'+ (subseq * 1) :key #'length)
;; 2036
