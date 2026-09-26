'use strict';

(function () {
  var reduceMotion = window.matchMedia('(prefers-reduced-motion: reduce)').matches;
  var SVGNS = 'http://www.w3.org/2000/svg';

  // ---------- header surface ----------
  var siteHeader = document.querySelector('.site-header');
  function updateHeaderSurface() {
    siteHeader.classList.toggle('is-scrolled', window.scrollY > 8);
  }
  updateHeaderSurface();
  window.addEventListener('scroll', updateHeaderSurface, { passive: true });

  // ---------- gates ----------
  // Paths match the gate shapes in Design/Showreel/reel.html.
  var GATES = {
    AND: { d: 'M -150 -130 L 20 -130 A 130 130 0 0 1 20 130 L -150 130 Z', f: function (a, b) { return a & b; } },
    OR: { d: 'M -150 -130 Q 40 -130 150 0 Q 40 130 -150 130 Q -90 0 -150 -130 Z', f: function (a, b) { return a | b; } },
    XOR: { d: 'M -115 -130 Q 50 -130 150 0 Q 50 130 -115 130 Q -55 0 -115 -130 Z', arc: true, f: function (a, b) { return a ^ b; } },
    NAND: { d: 'M -150 -130 L -10 -130 A 130 130 0 0 1 -10 130 L -150 130 Z', bubble: true, f: function (a, b) { return 1 - (a & b); } },
    NOR: { d: 'M -150 -130 Q 10 -130 120 0 Q 10 130 -150 130 Q -90 0 -150 -130 Z', bubble: true, f: function (a, b) { return 1 - (a | b); } },
    XNOR: { d: 'M -115 -130 Q 20 -130 120 0 Q 20 130 -115 130 Q -55 0 -115 -130 Z', arc: true, bubble: true, f: function (a, b) { return 1 - (a ^ b); } }
  };

  function el(name, attrs, parent) {
    var node = document.createElementNS(SVGNS, name);
    Object.keys(attrs).forEach(function (k) { node.setAttribute(k, attrs[k]); });
    if (parent) parent.appendChild(node);
    return node;
  }

  function buildGate(svg) {
    var g = el('g', { class: 'gate' }, svg);
    var parts = {
      wa: el('line', { class: 'wire', x1: -330, y1: -65, x2: -60, y2: -65 }, g),
      wb: el('line', { class: 'wire', x1: -330, y1: 65, x2: -60, y2: 65 }, g),
      wq: el('line', { class: 'wire', x1: 60, y1: 0, x2: 330, y2: 0 }, g),
      body: el('path', { class: 'body' }, g),
      arc: el('path', { class: 'arc', d: 'M -162 -130 Q -102 0 -162 130' }, g),
      gap: el('circle', { class: 'bubble-gap', cx: 142, cy: 0, r: 27 }, g),
      bubble: el('circle', { class: 'bubble', cx: 142, cy: 0, r: 22 }, g),
      pa: el('circle', { class: 'pin', cx: -330, cy: -65, r: 26 }, g),
      pb: el('circle', { class: 'pin', cx: -330, cy: 65, r: 26 }, g),
      pq: el('circle', { class: 'pin', cx: 330, cy: 0, r: 26 }, g)
    };
    svg.gateParts = parts;
    return parts;
  }

  function setGate(svg, name, a, b) {
    var p = svg.gateParts || buildGate(svg);
    var gate = GATES[name];
    var q = gate.f(a, b);
    p.body.setAttribute('d', gate.d);
    p.arc.style.display = gate.arc ? '' : 'none';
    p.gap.style.display = p.bubble.style.display = gate.bubble ? '' : 'none';
    [[p.wa, p.pa, a], [p.wb, p.pb, b], [p.wq, p.pq, q], [p.bubble, null, q]].forEach(function (set) {
      set[0].classList.toggle('on', !!set[2]);
      if (set[1]) set[1].classList.toggle('on', !!set[2]);
    });
    return q;
  }

  // Feature cards run their gate through the truth table, one row per beat.
  var cards = Array.prototype.slice.call(document.querySelectorAll('.gate-art[data-cycle]'));
  cards.forEach(function (svg) { setGate(svg, svg.dataset.gate, 0, 0); });
  if (!reduceMotion && cards.length) {
    var row = 0;
    setInterval(function () {
      row = (row + 1) & 3;
      cards.forEach(function (svg, i) { var r = (row + i) & 3; setGate(svg, svg.dataset.gate, r >> 1, r & 1); });
    }, 500);
  }

  // ---------- the lab ----------
  var lab = document.querySelector('.lab');
  if (lab) {
    var state = { gate: 'AND', a: 0, b: 0 };
    var labGate = lab.querySelector('.lab-gate');
    var output = lab.querySelector('.lab-q');
    var led = lab.querySelector('.led');
    var rows = lab.querySelectorAll('.truth tbody tr');
    var render = function () {
      var q = setGate(labGate, state.gate, state.a, state.b);
      output.textContent = 'Q = ' + q;
      led.classList.toggle('on', !!q);
      Array.prototype.forEach.call(rows, function (tr, i) {
        tr.cells[2].textContent = GATES[state.gate].f(i >> 1, i & 1);
        tr.classList.toggle('current', i === state.a * 2 + state.b);
      });
    };
    lab.querySelectorAll('.gate-picker button').forEach(function (btn) {
      btn.addEventListener('click', function () {
        state.gate = btn.textContent;
        lab.querySelectorAll('.gate-picker button').forEach(function (b) { b.setAttribute('aria-pressed', String(b === btn)); });
        labGate.classList.remove('morph'); void labGate.getBoundingClientRect(); labGate.classList.add('morph');
        render();
      });
    });
    lab.querySelectorAll('.switch').forEach(function (btn) {
      btn.addEventListener('click', function () {
        var key = btn.dataset.input;
        state[key] = 1 - state[key];
        btn.setAttribute('aria-pressed', String(!!state[key]));
        render();
      });
    });
    render();
  }

  // ---------- seven-segment stats ----------
  var SEGM = [0x3f, 0x06, 0x5b, 0x4f, 0x66, 0x6d, 0x7d, 0x07, 0x7f, 0x6f];
  function segPolys(h) {
    var w = h * 0.52, th = h * 0.13, gp = th * 0.2, hh = th / 2;
    var pt = { TL: [0, 0], TR: [w, 0], ML: [0, h / 2], MR: [w, h / 2], BL: [0, h], BR: [w, h] };
    return [['TL', 'TR'], ['TR', 'MR'], ['MR', 'BR'], ['BL', 'BR'], ['ML', 'BL'], ['TL', 'ML'], ['ML', 'MR']].map(function (s) {
      var A = pt[s[0]], B = pt[s[1]], dx = B[0] - A[0], dy = B[1] - A[1], L = Math.hypot(dx, dy), ux = dx / L, uy = dy / L, nx = -uy, ny = ux;
      var a = [A[0] + ux * gp, A[1] + uy * gp], b = [B[0] - ux * gp, B[1] - uy * gp];
      return [a, [a[0] + ux * hh + nx * hh, a[1] + uy * hh + ny * hh], [b[0] - ux * hh + nx * hh, b[1] - uy * hh + ny * hh], b,
        [b[0] - ux * hh - nx * hh, b[1] - uy * hh - ny * hh], [a[0] + ux * hh - nx * hh, a[1] + uy * hh - ny * hh]]
        .map(function (p) { return p[0].toFixed(1) + ',' + p[1].toFixed(1); }).join(' ');
    });
  }
  var POLYS = segPolys(100);
  function segDisplay(strong) {
    var digits = Number(strong.dataset.pad || strong.textContent.length);
    var svg = el('svg', { class: 'seg', viewBox: '-12 -4 ' + (digits * 74 + 4) + ' 108', 'aria-hidden': 'true' });
    var cells = [];
    for (var d = 0; d < digits; d++) {
      var g = el('g', { transform: 'translate(' + (d * 74) + ',0) matrix(1,0,-0.09,1,4.5,0)' }, svg);
      cells.push(POLYS.map(function (poly) { return el('polygon', { points: poly }, g); }));
    }
    strong.insertAdjacentElement('afterend', svg);
    strong.classList.add('visually-hidden');
    return function (n) {
      var s = String(n); while (s.length < digits) s = '0' + s;
      cells.forEach(function (segs, i) { var m = SEGM[Number(s[i])]; segs.forEach(function (p, k) { p.classList.toggle('on', !!(m >> k & 1)); }); });
    };
  }
  var stats = Array.prototype.map.call(document.querySelectorAll('[data-seg]'), function (strong) {
    return { target: Number(strong.dataset.seg), show: segDisplay(strong), node: strong.parentNode };
  });
  function countUp(stat) {
    if (reduceMotion) { stat.show(stat.target); return; }
    var start = performance.now();
    (function tick(now) {
      var p = Math.min(1, (now - start) / 700), e = 1 - Math.pow(1 - p, 3);
      stat.show(Math.floor(e * stat.target));
      if (p < 1) requestAnimationFrame(tick);
    })(start);
  }
  stats.forEach(function (s) { s.show(reduceMotion ? s.target : 0); });
  if ('IntersectionObserver' in window) {
    var io = new IntersectionObserver(function (entries) {
      entries.forEach(function (entry) {
        if (!entry.isIntersecting) return;
        io.unobserve(entry.target);
        stats.forEach(function (s) { if (s.node === entry.target) countUp(s); });
      });
    }, { threshold: 0.5 });
    stats.forEach(function (s) { io.observe(s.node); });
  } else {
    stats.forEach(function (s) { s.show(s.target); });
  }

  // ---------- hero traces ----------
  var hero = document.querySelector('.hero');
  var canvas = document.querySelector('.traces');
  var device = document.querySelector('.device-stage');
  var tc = document.querySelector('.hud-tc');
  if (!hero || !canvas || !canvas.getContext) return;
  var ctx = canvas.getContext('2d');
  var seed = 11;
  function rnd() { seed = (seed * 1664525 + 1013904223) >>> 0; return seed / 4294967296; }
  var D8 = [[1, 0], [1, 1], [0, 1], [-1, 1], [-1, 0], [-1, -1], [0, -1], [1, -1]];
  var traces = [];
  for (var i = 0; i < 44; i++) {
    var ang = i / 44 * Math.PI * 2 + (rnd() - 0.5) * 0.12;
    var di = ((Math.round(ang / (Math.PI / 4)) % 8) + 8) % 8, cur = di;
    var x = Math.cos(ang) * 60, y = Math.sin(ang) * 60, pts = [[x, y]], segs = 3 + Math.floor(rnd() * 5);
    for (var s = 0; s < segs; s++) {
      var len = (2 + Math.floor(rnd() * 7)) * 36, dir = D8[cur], n = Math.hypot(dir[0], dir[1]);
      x += dir[0] / n * len; y += dir[1] / n * len; pts.push([x, y]);
      var opts = [(cur + 1) & 7, (cur + 7) & 7, di].filter(function (k) { return Math.min((k - di + 8) & 7, (di - k + 8) & 7) <= 1 && k !== cur; });
      cur = opts[Math.floor(rnd() * opts.length)];
    }
    var cum = [0];
    for (var k = 1; k < pts.length; k++) cum.push(cum[k - 1] + Math.hypot(pts[k][0] - pts[k - 1][0], pts[k][1] - pts[k - 1][1]));
    traces.push({ pts: pts, cum: cum, len: cum[cum.length - 1], delay: rnd() * 0.25, dur: 0.9 + rnd() * 0.9, w: rnd() < 0.3 ? 3 : 1.6, ph: rnd(), sp: 0.5 + rnd() * 0.8, green: rnd() < 0.35 });
  }
  function at(tr, L) {
    for (var i = 1; i < tr.pts.length; i++) if (tr.cum[i] >= L) {
      var f = (L - tr.cum[i - 1]) / (tr.cum[i] - tr.cum[i - 1] || 1);
      return [tr.pts[i - 1][0] + (tr.pts[i][0] - tr.pts[i - 1][0]) * f, tr.pts[i - 1][1] + (tr.pts[i][1] - tr.pts[i - 1][1]) * f];
    }
    return tr.pts[tr.pts.length - 1];
  }
  function range(tr, a, b) {
    a = Math.max(0, a); b = Math.min(tr.len, b); if (b <= a) return;
    var s = at(tr, a); ctx.moveTo(s[0], s[1]);
    for (var i = 1; i < tr.pts.length; i++) if (tr.cum[i] > a && tr.cum[i] < b) ctx.lineTo(tr.pts[i][0], tr.pts[i][1]);
    var e = at(tr, b); ctx.lineTo(e[0], e[1]);
  }
  var W = 0, H = 0, ox = 0, oy = 0, dpr = 1;
  function resize() {
    dpr = Math.min(window.devicePixelRatio || 1, 2);
    W = hero.clientWidth; H = hero.clientHeight;
    canvas.width = Math.round(W * dpr); canvas.height = Math.round(H * dpr);
    var hr = hero.getBoundingClientRect(), dr = device.getBoundingClientRect();
    ox = dr.left + dr.width / 2 - hr.left; oy = dr.top + dr.height / 2 - hr.top;
  }
  var t0 = performance.now(), visible = true;
  function frame(now) {
    var t = reduceMotion ? 10 : (now - t0) / 1000;
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);
    ctx.clearRect(0, 0, W, H);
    ctx.translate(ox, oy);
    var sc = Math.max(1, Math.max(W, H) / 1400);
    ctx.scale(sc, sc);
    ctx.lineCap = ctx.lineJoin = 'round';
    traces.forEach(function (tr) {
      var p = Math.min(1, Math.max(0, (t - tr.delay) / tr.dur)); p = 1 - Math.pow(2, -10 * p);
      if (p <= 0) return;
      var L = p * tr.len;
      ctx.beginPath(); range(tr, 0, L); ctx.strokeStyle = 'rgba(110,185,255,0.28)'; ctx.lineWidth = tr.w; ctx.stroke();
      if (p > 0.98) {
        var e = tr.pts[tr.pts.length - 1];
        ctx.beginPath(); ctx.arc(e[0], e[1], 6, 0, Math.PI * 2); ctx.fillStyle = '#060d1c'; ctx.fill();
        ctx.strokeStyle = 'rgba(150,210,255,0.55)'; ctx.lineWidth = 1.5; ctx.stroke();
      }
      if (t > 1.2 || reduceMotion) {
        var head = ((t * tr.sp * 260 / tr.len + tr.ph) % 1) * tr.len;
        ctx.beginPath(); range(tr, head - 70, head);
        ctx.strokeStyle = tr.green ? 'rgba(77,255,124,0.85)' : 'rgba(191,232,255,0.7)';
        ctx.shadowColor = tr.green ? '#4dff7c' : '#8fdcff'; ctx.shadowBlur = 10; ctx.lineWidth = tr.w + 0.8; ctx.stroke(); ctx.shadowBlur = 0;
      }
    });
    if (tc) {
      var f = Math.floor(t * 60), pad = function (v) { return (v < 10 ? '0' : '') + v; };
      tc.textContent = 'TC 00:' + pad(Math.floor(f / 3600) % 60) + ':' + pad(Math.floor(f / 60) % 60) + ':' + pad(f % 60);
    }
    if (!reduceMotion && visible) requestAnimationFrame(frame);
  }
  resize();
  window.addEventListener('resize', function () { resize(); if (reduceMotion) frame(0); });
  if ('IntersectionObserver' in window && !reduceMotion) {
    new IntersectionObserver(function (entries) {
      var was = visible; visible = entries[0].isIntersecting;
      if (visible && !was) requestAnimationFrame(frame);
    }).observe(hero);
  }
  requestAnimationFrame(frame);
})();
