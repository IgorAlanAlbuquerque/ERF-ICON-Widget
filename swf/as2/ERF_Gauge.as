class ERF_Gauge extends MovieClip
{
  private var gauge_mc:MovieClip;

  private var rOut:Number;
  private var strokePx:Number;

  private var _slotBaseOffsetX:Number;
  private var _slotScale:Number;

  private var _ready:Boolean;
  private var _tried:Boolean;

  private var _slotMcs:Array;

  function ERF_Gauge()
  {
    rOut        = 7;
    strokePx    = 1.5;

    _slotBaseOffsetX = -40;
    _slotScale       = 1.0;

    _ready = false;
    _tried = false;

    _slotMcs = [];
  }

  private function _sum(a:Array):Number {
    var s:Number = 0;
    for (var i:Number = 0; i < a.length; ++i) {
      var v:Number = Number(a[i]); if (!isNaN(v)) s += v;
    }
    return s;
  }

  private function _drawArc(mc:MovieClip, f:Number, t:Number, color:Number, alpha:Number):Void {
    if (!mc) return;
    var from:Number = Math.max(0, Math.min(1, f));
    var to:Number   = Math.max(0, Math.min(1, t));
    if (to <= from) return;

    var a0:Number = -Math.PI/2 + from * 2*Math.PI;
    var a1:Number = -Math.PI/2 + to   * 2*Math.PI;

    mc.lineStyle(strokePx, color, alpha);

    var steps:Number = Math.max(6, Math.round((to - from) * 48));
    var ang:Number = a0;
    mc.moveTo(Math.cos(ang)*rOut, Math.sin(ang)*rOut);
    for (var j:Number = 1; j <= steps; j++) {
      ang = a0 + (a1 - a0) * (j / steps);
      mc.lineTo(Math.cos(ang)*rOut, Math.sin(ang)*rOut);
    }
  }

  private function _drawFilledCircle(mc:MovieClip, r:Number, rgb:Number, alpha:Number):Void {
    mc.clear();
    mc.lineStyle(0, 0x000000, 0);
    mc.beginFill(rgb, alpha);
    var steps:Number = 64;
    for (var k:Number = 0; k <= steps; k++) {
      var a:Number = (k/steps) * Math.PI * 2;
      var x:Number = Math.cos(a) * r;
      var y:Number = Math.sin(a) * r;
      if (k == 0) mc.moveTo(x, y); else mc.lineTo(x, y);
    }
    mc.endFill();
  }

  public function onLoad():Void {
    var off:Number = rOut + 2;

    if (gauge_mc) gauge_mc.removeMovieClip();
    var d:Number = this.getNextHighestDepth();
    gauge_mc = this.createEmptyMovieClip("gauge_mc", d);
    gauge_mc._x = off;
    gauge_mc._y = off;

    _ready = true;
    _tried = true;
  }

  private function _tryInit():Void {
    if (_tried) return;
    _tried = true;
    onLoad();
  }

  public function isReady():Boolean {
    if (!_ready) _tryInit();
    return _ready;
  }

  private function _ensureSlot(i:Number):MovieClip {
    if (_slotMcs[i]) return _slotMcs[i];

    var slotDepth:Number = 200 + i;
    var slot:MovieClip = gauge_mc.createEmptyMovieClip("slot_"+i, slotDepth);
    slot._xscale = slot._yscale = _slotScale * 100;

    slot.halo_mc     = slot.createEmptyMovieClip("halo_mc",     0);
    slot.icon_mc     = slot.createEmptyMovieClip("icon_mc",    15); 
    slot.ring_bg_mc  = slot.createEmptyMovieClip("ring_bg_mc", 10);
    slot.ring_fg_mc  = slot.createEmptyMovieClip("ring_fg_mc", 20);
    slot.combo_mc    = slot.createEmptyMovieClip("combo_mc",   30);

    var haloMargin:Number = 2;
    var haloR:Number = rOut + (strokePx * 0.5) + haloMargin;
    _drawFilledCircle(slot.halo_mc, haloR, 0x000000, 100);

    _slotMcs[i] = slot;
    return slot;
  }

  private function _slotClear(slot:MovieClip):Void {
    if (!slot) return;
    if (slot.ring_bg_mc) slot.ring_bg_mc.clear();
    if (slot.ring_fg_mc) slot.ring_fg_mc.clear();
    if (slot.combo_mc)   slot.combo_mc.clear();
    if (slot.icon_mc) {
      slot.icon_mc.clear();
      for (var n:String in slot.icon_mc) {
        if (typeof(slot.icon_mc[n]) == "movieclip") {
          MovieClip(slot.icon_mc[n]).removeMovieClip();
        }
      }
      slot.icon_mc._xscale = slot.icon_mc._yscale = 100;
      slot.icon_mc._x = slot.icon_mc._y = 0;
    }
  }

  private function _applyIcon(slot:MovieClip, linkage:String):Void {
    if (!slot || !slot.icon_mc) return;

    for (var n:String in slot.icon_mc) {
      if (typeof(slot.icon_mc[n]) == "movieclip") {
        MovieClip(slot.icon_mc[n]).removeMovieClip();
      }
    }
    slot.icon_mc.clear();

    if (!linkage || linkage == "" || linkage == undefined) {
      return;
    }

    var child:MovieClip = slot.icon_mc.attachMovie(linkage, "sym", 0);
    if (!child) {
      return;
    }

    var pad:Number = 1;
    var innerR:Number = Math.max(0, rOut - strokePx - pad);
    var targetSize:Number = innerR * 2;

    var b:Object = child.getBounds(slot.icon_mc);
    var w:Number = (b.xMax - b.xMin);
    var h:Number = (b.yMax - b.yMin);
    if (w <= 0 || h <= 0) {
      return;
    }

    var k:Number = targetSize / Math.max(w, h);
    var pct:Number = k * 100;
    child._xscale = child._yscale = pct;

    b = child.getBounds(slot.icon_mc);
    var cx:Number = (b.xMin + b.xMax) * 0.5;
    var cy:Number = (b.yMin + b.yMax) * 0.5;
    child._x = -cx;
    child._y = -cy;
  }

  private function _slotDrawCombo(slot:MovieClip, frac:Number, rgb:Number):Void {
    var f:Number = (isNaN(frac)) ? 0 : Math.max(0, Math.min(1, frac));
    slot.ring_bg_mc.clear();
    _drawArc(slot.ring_bg_mc, 0, 1, 0x000000, 30);

    if (f <= 0) { slot._visible = false; return; }

    var col:Number = (!isNaN(rgb) && rgb != undefined) ? Number(rgb) : 0xFFFFFF;
    slot.combo_mc.clear();
    _drawArc(slot.combo_mc, 0, f, col, 100);

    slot._visible = true;
  }

  private function _slotDrawAccum(slot:MovieClip, values:Array, colors:Array):Void {
    slot.ring_bg_mc.clear();
    slot.ring_fg_mc.clear();

    if (!values || !colors || values.length != colors.length) { slot._visible = false; return; }

    var totalRaw:Number = _sum(values);
    if (totalRaw <= 0) { slot._visible = false; return; }

    var totalShown:Number = Math.min(100, totalRaw);
    var scale:Number      = totalShown / totalRaw;

    _drawArc(slot.ring_bg_mc, 0, 1, 0x000000, 30);

    var cur:Number = 0;
    for (var i2:Number = 0; i2 < values.length; ++i2) {
      var share:Number = Number(values[i2]);
      if (isNaN(share) || share <= 0) continue;

      share *= scale;
      var seg:Number = (share / 100.0);

      var col2:Number = Number(colors[i2]);
      if (isNaN(col2)) col2 = 0xFFFFFF;

      _drawArc(slot.ring_fg_mc, cur, cur + seg, col2, 100);
      cur += seg;
      if (cur >= 1) break;
    }

    slot._visible = true;
  }

  public function setAll(
    comboRemain01:Array, comboTints:Array,
    accumValues:Array, accumColors:Array, iconLinkages:Array,
    isSingle:Boolean, isHorin:Boolean, spacing:Number,
    singlesBefore:Number, singlesAfter:Number
  ):Boolean
  {
    if (!_ready) _tryInit();

    if (isNaN(spacing)) spacing = 40;

    var n:Number = (comboRemain01 != null) ? comboRemain01.length : 0;
    if (comboTints == null) comboTints = [];
    if (iconLinkages == null) iconLinkages = [];

    var baseX:Number = _slotBaseOffsetX;
    var baseY:Number = 0;

    var _placeSlot = function(slot:MovieClip, idx:Number, isHor:Boolean, bx:Number, by:Number, sp:Number):Void {
      if (isHor) {
        slot._x = bx + (idx * sp);
        slot._y = by;
      } else {
        slot._x = bx;
        slot._y = by + (idx * sp);
      }
    };

    var iconAt = function(idx:Number):String {
      if (!iconLinkages) return null;
      if (idx < 0 || idx >= iconLinkages.length) return null;
      return String(iconLinkages[idx]);
    };

    // --- COMBOS (igual antes) ---
    var i:Number;
    for (i = 0; i < n; ++i) {
      var slot:MovieClip = _ensureSlot(i);
      _placeSlot(slot, i, isHorin, baseX, baseY, spacing);

      _slotClear(slot);
      _applyIcon(slot, iconAt(i));

      var remain:Number = Number(comboRemain01[i]);
      var tint:Number   = Number(comboTints[i]);
      _slotDrawCombo(slot, remain, tint);
      slot._visible = true;
    }

    var nextIndex:Number = n;        // índice de slot HUD (combos já ocupam 0..n-1)
    var anyAccumDrawn:Boolean = false;

    // checar se tem algo pra desenhar em accumValues
    var totalAccum:Number = (accumValues != null) ? accumValues.length : 0;
    var hasAccum:Boolean = false;
    if (totalAccum > 0) {
      var sum:Number = 0;
      for (var si:Number = 0; si < totalAccum; ++si) {
        var vv:Number = Number(accumValues[si]);
        if (!isNaN(vv)) sum += vv;
      }
      hasAccum = (sum > 0);
    }

    var gaugeIconIdx:Number = n;  // ícones de gauges começam depois dos combos

    if (hasAccum) {
      if (isSingle) {
        // === SINGLE: 1 gauge por elemento (como estava) ===
        for (var k:Number = 0; k < totalAccum; ++k) {
          var v:Number = Number(accumValues[k]);
          if (isNaN(v) || v <= 0) continue;

          var frac:Number = v / 100.0;
          if (frac < 0) frac = 0;
          else if (frac > 1) frac = 1;

          var col:Number = 0xFFFFFF;
          if (accumColors && k < accumColors.length && !isNaN(Number(accumColors[k]))) {
            col = Number(accumColors[k]);
          }

          var sSingle:MovieClip = _ensureSlot(nextIndex);
          _placeSlot(sSingle, nextIndex, isHorin, baseX, baseY, spacing);

          _slotClear(sSingle);
          _applyIcon(sSingle, iconAt(gaugeIconIdx)); // ícone por gauge
          _slotDrawCombo(sSingle, frac, col);
          sSingle._visible = true;

          nextIndex++;
          gaugeIconIdx++;
          anyAccumDrawn = true;
        }

      } else {
        // === MIXED NOVO: singlesBefore | MIX | singlesAfter ===

        var nb:Number = (isNaN(singlesBefore) || singlesBefore < 0) ? 0 : Math.floor(singlesBefore);
        var na:Number = (isNaN(singlesAfter)  || singlesAfter  < 0) ? 0 : Math.floor(singlesAfter);

        if (nb > totalAccum) nb = totalAccum;
        if (na > totalAccum - nb) na = totalAccum - nb;

        var mixCount:Number = totalAccum - nb - na;

        // --- 1) GAUGES INDIVIDUAIS ANTES DO MISTO ---
        var iB:Number;
        var v:Number, frac:Number, col:Number, s:MovieClip;

        for (iB = 0; iB < nb; ++iB) {
          v = Number(accumValues[iB]);

          // garantir que o slot exista e seja limpo SEMPRE
          s = _ensureSlot(nextIndex);
          _placeSlot(s, nextIndex, isHorin, baseX, baseY, spacing);
          _slotClear(s);
          s._visible = false;

          if (!isNaN(v) && v > 0) {
            frac = v / 100.0;
            if (frac < 0) frac = 0;
            else if (frac > 1) frac = 1;

            col = 0xFFFFFF;
            if (accumColors && iB < accumColors.length && !isNaN(Number(accumColors[iB]))) {
              col = Number(accumColors[iB]);
            }

            _applyIcon(s, iconAt(gaugeIconIdx)); // primeiros singlesBefore ícones
            _slotDrawCombo(s, frac, col);
            s._visible = true;
            anyAccumDrawn = true;
          }

          nextIndex++;
          gaugeIconIdx++;
        }

        // --- 2) GAUGE MISTO (MEIO) ---
        if (mixCount > 0) {
          var mixStart:Number = nb;
          var mixEnd:Number   = totalAccum - na; // exclusivo

          var mixVals:Array = [];
          var mixCols:Array = [];

          var mi:Number;
          for (mi = mixStart; mi < mixEnd; ++mi) {
            v = Number(accumValues[mi]);
            if (isNaN(v) || v <= 0) continue;

            mixVals.push(v);

            col = 0xFFFFFF;
            if (accumColors && mi < accumColors.length && !isNaN(Number(accumColors[mi]))) {
              col = Number(accumColors[mi]);
            }
            mixCols.push(col);
          }

          if (mixVals.length > 0) {
            var aSlot:MovieClip = _ensureSlot(nextIndex);
            _placeSlot(aSlot, nextIndex, isHorin, baseX, baseY, spacing);

            _slotClear(aSlot);
            // ícone para o gauge MISTO = exatamente o próximo depois dos BEFORE
            _applyIcon(aSlot, iconAt(gaugeIconIdx));
            _slotDrawAccum(aSlot, mixVals, mixCols);
            aSlot._visible = true;

            anyAccumDrawn = true;

            nextIndex++;
            gaugeIconIdx++;   // só avança se realmente desenhou o misto
          }
        }

        // --- 3) GAUGES INDIVIDUAIS APÓS O MISTO ---
        if (na > 0) {
          var afterStart:Number = totalAccum - na;
          var iA:Number;

          // Agora forçamos o ponteiro de ícone pros **últimos `na` ícones de gauge**:
          // iconLinkages[n + afterStart .. n + totalAccum - 1]
          gaugeIconIdx = n + afterStart;

          for (iA = 0; iA < na; ++iA) {
            var idxA:Number = afterStart + iA;
            v = Number(accumValues[idxA]);

            s = _ensureSlot(nextIndex);
            _placeSlot(s, nextIndex, isHorin, baseX, baseY, spacing);
            _slotClear(s);
            s._visible = false;

            if (!isNaN(v) && v > 0) {
              frac = v / 100.0;
              if (frac < 0) frac = 0;
              else if (frac > 1) frac = 1;

              col = 0xFFFFFF;
              if (accumColors && idxA < accumColors.length && !isNaN(Number(accumColors[idxA]))) {
                col = Number(accumColors[idxA]);
              }

              _applyIcon(s, iconAt(gaugeIconIdx)); // agora de fato pega os "últimos na"
              _slotDrawCombo(s, frac, col);
              s._visible = true;
              anyAccumDrawn = true;
            }

            nextIndex++;
            gaugeIconIdx++;
          }
        }
      }
    }

    // --- LIMPAR SLOTS SOBRANDO ---
    for (var j:Number = nextIndex; j < _slotMcs.length; ++j) {
      if (_slotMcs[j]) {
        _slotClear(_slotMcs[j]);
        _slotMcs[j]._visible = false;
      }
    }

    var anyVisible:Boolean = (n > 0) || anyAccumDrawn;
    this._visible = anyVisible;
    return anyVisible;
  }
}