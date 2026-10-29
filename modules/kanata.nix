{
  # kanata aspect - intercepts the built-in keyboard at the input-device
  # level (via uinput) and runs a Miryoku-style layout on top of it.
  # https://github.com/jtroo/kanata  https://github.com/manna-harbour/miryoku
  #
  # This is Miryoku's QWERTY alpha arrangement (MIRYOKU_ALPHAS=QWERTY), not
  # its Colemak-DH default - every letter/punctuation key is left as plain
  # QWERTY. The only changes versus a stock keyboard are:
  #   - Home row mods: A S D F / J K L ; are tap-hold (tap the letter, hold
  #     for a modifier), mirrored GACS (Gui Alt Ctrl Shift) on each hand.
  #   - Six thumb-cluster keys are tap-hold (tap for their normal key, hold
  #     to activate a layer): Space->Nav, Tab->Mouse, (Caps Lock)->Media on
  #     the left; Backspace->Num, Enter->Sym, Delete->Fun on the right.
  #
  # Miryoku's reference layout needs 3 thumb keys per hand, which a laptop
  # keyboard doesn't have - there's only Space next to a Fn/Alt/Ctrl row.
  # Caps Lock stands in for the missing third left-hand thumb key (freed up
  # since it has no other use here, and already a well-worn convention for
  # this exact problem): tap it for Escape, hold it for the Media layer.
  # The right hand doesn't need a substitute - Backspace, Enter, and Delete
  # already exist as real keys on a standard keyboard.
  #
  # Deliberately left out, as they're meaningful only on the split/custom
  # keyboards Miryoku targets and do nothing on a laptop's own keyboard:
  #   - The Button layer (bottom-row-pinky hold) - mouse buttons for an
  #     external pointing device. The laptop's touchpad doesn't need it,
  #     and the Mouse layer below already puts buttons on the thumbs.
  #   - Media layer's RGB/Bluetooth-profile/output-toggle/external-power
  #     keys and the Stop key (no portable kanata keycode for Stop).
  #   - The bootloader-entry, alternate-base-layer-switching, and
  #     layer-lock "additional features" - QMK/ZMK firmware conveniences
  #     with no equivalent need here.
  # Add them later if wanted; see the reference doc linked above.
  #
  # Copy/Cut/Paste/Undo/Redo are bound to Ctrl+C/X/V/Z/Shift+Z rather than
  # kanata's raw copy/cut/paste/undo/redo key names, because those names
  # don't exist - kanata's key parser (parser/src/keys/mod.rs) has no
  # string alias for the underlying evdev KEY_COPY/KEY_PASTE/KEY_CUT/
  # KEY_UNDO/KEY_REDO codes, and most Linux apps don't bind them anyway.
  #
  # Tap/hold timings (200ms/200ms everywhere) are a reasonable starting
  # point, not a tuned value - adjust to taste once this is actually being
  # typed on; see kanata's tap-hold docs for the tradeoffs.
  den.aspects.kanata.nixos = {
    services.kanata = {
      enable = true;
      keyboards.laptop.config = ''
        (defsrc
          q    w    e    r    t    y    u    i    o    p
          a    s    d    f    g    h    j    k    l    scln
          z    x    c    v    b    n    m    ,    .    /
          caps spc  tab  ret  bspc del
        )

        (defalias
          ;; home row mods, GACS mirrored (left: Gui Alt Ctrl Shift, right: Shift Ctrl Alt Gui)
          a_gui (tap-hold-release 200 200 a lmet)
          s_alt (tap-hold-release 200 200 s lalt)
          d_ctl (tap-hold-release 200 200 d lctl)
          f_sft (tap-hold-release 200 200 f lsft)
          j_sft (tap-hold-release 200 200 j rsft)
          k_ctl (tap-hold-release 200 200 k rctl)
          l_alt (tap-hold-release 200 200 l ralt)
          scl_gui (tap-hold-release 200 200 scln rmet)

          ;; thumb cluster: tap for the base character, hold for the layer
          esc_media (tap-hold-release 200 200 esc (layer-while-held media))
          spc_nav   (tap-hold-release 200 200 spc (layer-while-held nav))
          tab_mouse (tap-hold-release 200 200 tab (layer-while-held mouse))
          ret_sym   (tap-hold-release 200 200 ret (layer-while-held sym))
          bspc_num  (tap-hold-release 200 200 bspc (layer-while-held num))
          del_fun   (tap-hold-release 200 200 del (layer-while-held fun))

          ;; nav/mouse shared clipboard row - see the Ctrl+C/X/V/Z note above
          clip_copy  C-c
          clip_cut   C-x
          clip_paste C-v
          clip_undo  C-z
          clip_redo  C-S-z

          ;; mouse layer movement/wheel
          mv_up    (movemouse-up 10 2)
          mv_down  (movemouse-down 10 2)
          mv_left  (movemouse-left 10 2)
          mv_right (movemouse-right 10 2)
          wh_up    (mwheel-up 20 20)
          wh_down  (mwheel-down 20 20)
          wh_left  (mwheel-left 20 20)
          wh_right (mwheel-right 20 20)

          ;; sym layer: shifted symbols with no plain single-char token
          sym_lp (multi lsft 9)
          sym_rp (multi lsft 0)
          sym_us (multi lsft -)
        )

        (deflayer base
          q        w      e      r      t      y    u      i      o      p
          @a_gui   @s_alt @d_ctl @f_sft g      h    @j_sft @k_ctl @l_alt @scl_gui
          z        x      c      v      b      n    m      ,      .      /
          @esc_media @spc_nav @tab_mouse @ret_sym @bspc_num @del_fun
        )

        ;; primary right-hand layer (left home thumb/Space): navigation + clipboard
        (deflayer nav
          _ _ _ _ _  @clip_redo @clip_paste @clip_copy @clip_cut @clip_undo
          _ _ _ _ _  caps       left        down       up        rght
          _ _ _ _ _  ins        home        pgdn       pgup      end
          _ _ _ _ _ _
        )

        ;; secondary right-hand layer (left Tab): mouse movement/wheel/buttons
        (deflayer mouse
          _ _ _ _ _  @clip_redo @clip_paste @clip_copy @clip_cut @clip_undo
          _ _ _ _ _  _          @mv_left    @mv_down   @mv_up    @mv_right
          _ _ _ _ _  _          @wh_left    @wh_down   @wh_up    @wh_right
          _ _ _ mrgt mlft mmid
        )

        ;; tertiary right-hand layer (left Caps Lock): media transport/volume
        (deflayer media
          _ _ _ _ _  _ _    _    _    _
          _ _ _ _ _  _ prev vold volu next
          _ _ _ _ _  _ _    _    _    _
          _ _ _ _ pp mute
        )

        ;; primary left-hand layer (right Backspace): numpad-style numerals
        (deflayer num
          [    7 8 9 ]    _ _ _ _ _
          scln 4 5 6 eql  _ _ _ _ _
          grv  1 2 3 \    _ _ _ _ _
          .    0 - _ _ _
        )

        ;; secondary left-hand layer (right Enter): the shifted symbols
        ;; for Num's row, pre-shifted so they don't need chording
        (deflayer sym
          S-[     S-7 S-8 S-9 S-]   _ _ _ _ _
          S-scln  S-4 S-5 S-6 S-eql _ _ _ _ _
          S-grv   S-1 S-2 S-3 S-\   _ _ _ _ _
          @sym_lp @sym_rp @sym_us _ _ _
        )

        ;; tertiary left-hand layer (right Delete): function keys + system keys
        (deflayer fun
          f12  f7 f8 f9 prnt  _ _ _ _ _
          f11  f4 f5 f6 slck  _ _ _ _ _
          f10  f1 f2 f3 pause _ _ _ _ _
          menu spc tab _ _ _
        )
      '';
    };
  };
}
